import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

os.environ["DATABASE_URL"] = "sqlite:///:memory:"
os.environ["JWT_SECRET"] = "test-secret-that-is-long-enough-for-hs256"
os.environ["ADMIN_EMAIL"] = "admin@example.com"
os.environ["ADMIN_PASSWORD"] = "secret"
os.environ["AUTO_CREATE_TABLES"] = "true"

from fastapi.testclient import TestClient

from app.database import SessionLocal
from app.main import app
from app.models import User
from app.security import hash_password


def auth_headers(client: TestClient) -> dict[str, str]:
    response = client.post(
        "/auth/login",
        json={"email": "admin@example.com", "password": "secret"},
    )
    assert response.status_code == 200
    token = response.json()["accessToken"]
    return {"Authorization": f"Bearer {token}"}


def create_user(email: str, password: str, role: str = "user") -> None:
    with SessionLocal() as db:
        if db.query(User).filter(User.email == email).first() is not None:
            return
        db.add(User(email=email, password_hash=hash_password(password), role=role))
        db.commit()


def login_headers(client: TestClient, email: str, password: str) -> dict[str, str]:
    response = client.post(
        "/auth/login",
        json={"email": email, "password": password},
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['accessToken']}"}


def test_import_and_export_glossary_bundle() -> None:
    with TestClient(app) as client:
        headers = auth_headers(client)
        response = client.post(
            "/glossary/import",
            headers=headers,
            json={
                "glossary": {"申請": "Nộp đơn"},
                "langGlossary": {"繁體中文-越南文": {"簽核": "Ký duyệt"}},
            },
        )

        assert response.status_code == 200
        assert response.json() == {"imported": 2, "updated": 0}

        response = client.get("/glossary", headers=headers)

        assert response.status_code == 200
        body = response.json()
        assert body["glossary"] == {"申請": "Nộp đơn"}
        assert body["langGlossary"] == {"繁體中文-越南文": {"簽核": "Ký duyệt"}}
        assert "syncedAt" in body


def test_create_update_delete_term() -> None:
    with TestClient(app) as client:
        headers = auth_headers(client)
        response = client.post(
            "/glossary",
            headers=headers,
            json={
                "sourceText": "表單",
                "targetText": "Biểu mẫu",
                "contextKey": "global",
            },
        )

        assert response.status_code == 201
        term = response.json()
        assert term["version"] == 1

        response = client.put(
            f"/glossary/{term['id']}",
            headers=headers,
            json={"targetText": "Biểu đơn"},
        )

        assert response.status_code == 200
        assert response.json()["targetText"] == "Biểu đơn"
        assert response.json()["version"] == 2

        response = client.delete(f"/glossary/{term['id']}", headers=headers)
        assert response.status_code == 204

        response = client.get("/glossary", headers=headers)
        assert "表單" not in response.json()["glossary"]


def test_create_rejects_duplicate_active_term() -> None:
    with TestClient(app) as client:
        headers = auth_headers(client)
        payload = {
            "sourceText": "簽核",
            "targetText": "Ký duyệt",
            "contextKey": "global",
        }

        first = client.post("/glossary", headers=headers, json=payload)
        second = client.post("/glossary", headers=headers, json=payload)

        assert first.status_code == 201
        assert second.status_code == 409


def test_unauthorized_user_cannot_write_glossary() -> None:
    with TestClient(app) as client:
        response = client.post(
            "/glossary",
            json={
                "sourceText": "未授權",
                "targetText": "Unauthorized",
                "contextKey": "global",
            },
        )

        assert response.status_code == 401


def test_regular_user_creates_pending_and_editor_approves() -> None:
    create_user("user@example.com", "secret", "user")
    with TestClient(app) as client:
        user_headers = login_headers(client, "user@example.com", "secret")
        admin_headers = auth_headers(client)
        created = client.post(
            "/glossary",
            headers=user_headers,
            json={
                "sourceText": "使用者建議詞",
                "targetText": "User suggestion",
                "contextKey": "global",
                "status": "approved",
            },
        )

        assert created.status_code == 201
        assert created.json()["status"] == "pending"

        approved = client.post(
            f"/glossary/{created.json()['id']}/approve",
            headers=admin_headers,
        )
        history = client.get(
            f"/glossary/{created.json()['id']}/history",
            headers=admin_headers,
        )

        assert approved.status_code == 200
        assert approved.json()["status"] == "approved"
        assert history.status_code == 200
        assert [item["operation"] for item in history.json()] == [
            "create",
            "approve",
        ]


def test_admin_can_manage_users_and_regular_user_cannot() -> None:
    create_user("regular@example.com", "secret", "user")
    with TestClient(app) as client:
        admin_headers = auth_headers(client)
        regular_headers = login_headers(client, "regular@example.com", "secret")

        created = client.post(
            "/users",
            headers=admin_headers,
            json={
                "email": "editor@example.com",
                "password": "secret",
                "role": "editor",
            },
        )
        assert created.status_code == 201
        assert created.json()["role"] == "editor"

        updated = client.put(
            f"/users/{created.json()['id']}",
            headers=admin_headers,
            json={"role": "user", "isActive": False},
        )
        assert updated.status_code == 200
        assert updated.json()["role"] == "user"
        assert updated.json()["isActive"] is False

        denied = client.get("/users", headers=regular_headers)
        assert denied.status_code == 403


def test_auth_me_and_change_password_flow() -> None:
    create_user("change-password@example.com", "old-secret", "user")
    with TestClient(app) as client:
        headers = login_headers(client, "change-password@example.com", "old-secret")

        me = client.get("/auth/me", headers=headers)
        wrong_current = client.post(
            "/auth/change-password",
            headers=headers,
            json={"currentPassword": "wrong-secret", "newPassword": "new-secret"},
        )
        changed = client.post(
            "/auth/change-password",
            headers=headers,
            json={"currentPassword": "old-secret", "newPassword": "new-secret"},
        )
        old_login = client.post(
            "/auth/login",
            json={"email": "change-password@example.com", "password": "old-secret"},
        )
        new_login = client.post(
            "/auth/login",
            json={"email": "change-password@example.com", "password": "new-secret"},
        )

        assert me.status_code == 200
        assert me.json()["email"] == "change-password@example.com"
        assert me.json()["lastLoginAt"] is not None
        assert wrong_current.status_code == 400
        assert changed.status_code == 200
        assert changed.json()["mustChangePassword"] is False
        assert old_login.status_code == 401
        assert new_login.status_code == 200


def test_changes_include_deleted_terms() -> None:
    with TestClient(app) as client:
        headers = auth_headers(client)
        created = client.post(
            "/glossary",
            headers=headers,
            json={
                "sourceText": "待刪除",
                "targetText": "Delete me",
                "contextKey": "global",
            },
        )
        assert created.status_code == 201
        since = "2000-01-01T00:00:00Z"

        deleted = client.delete(
            f"/glossary/{created.json()['id']}",
            headers=headers,
        )
        assert deleted.status_code == 204

        changes = client.get(f"/glossary/changes?since={since}", headers=headers)

        assert changes.status_code == 200
        matching = [
            item for item in changes.json() if item["sourceText"] == "待刪除"
        ]
        assert matching
        assert matching[-1]["deletedAt"] is not None


def test_validation_rejects_invalid_glossary_status_and_blank_source() -> None:
    with TestClient(app) as client:
        headers = auth_headers(client)

        invalid_status = client.post(
            "/glossary",
            headers=headers,
            json={
                "sourceText": "狀態錯誤",
                "targetText": "Invalid status",
                "contextKey": "global",
                "status": "published",
            },
        )
        blank_source = client.post(
            "/glossary",
            headers=headers,
            json={
                "sourceText": "   ",
                "targetText": "Blank source",
                "contextKey": "global",
            },
        )
        invalid_query = client.get(
            "/glossary?status=published",
            headers=headers,
        )

        assert invalid_status.status_code == 422
        assert blank_source.status_code == 422
        assert invalid_query.status_code == 422


def test_user_validation_normalizes_email_and_rejects_weak_input() -> None:
    with TestClient(app) as client:
        admin_headers = auth_headers(client)

        invalid_role = client.post(
            "/users",
            headers=admin_headers,
            json={
                "email": "bad-role@example.com",
                "password": "secret",
                "role": "owner",
            },
        )
        weak_password = client.post(
            "/users",
            headers=admin_headers,
            json={
                "email": "weak@example.com",
                "password": "12345",
                "role": "user",
            },
        )
        created = client.post(
            "/users",
            headers=admin_headers,
            json={
                "email": "  MixedCaseUser@example.com ",
                "password": "secret",
                "role": "USER",
            },
        )
        login = client.post(
            "/auth/login",
            json={"email": "MIXEDCASEUSER@example.com", "password": "secret"},
        )

        assert invalid_role.status_code == 422
        assert weak_password.status_code == 422
        assert created.status_code == 201
        assert created.json()["email"] == "mixedcaseuser@example.com"
        assert created.json()["role"] == "user"
        assert login.status_code == 200
