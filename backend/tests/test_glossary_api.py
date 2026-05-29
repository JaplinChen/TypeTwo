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
from app.routers.auth import _login_failures
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


def test_import_preview_reports_changes_without_writing() -> None:
    with TestClient(app) as client:
        headers = auth_headers(client)
        imported = client.post(
            "/glossary/import",
            headers=headers,
            json={"glossary": {"既有詞": "Existing term"}},
        )
        preview = client.post(
            "/glossary/import/preview",
            headers=headers,
            json={
                "glossary": {
                    "既有詞": "Updated term",
                    "新增詞": "New term",
                    "": "Blank source",
                },
                "langGlossary": {"預覽-越南文": {"預覽簽核": "Ký duyệt"}},
            },
        )
        after_preview = client.get("/glossary", headers=headers)

        assert imported.status_code == 200
        assert preview.status_code == 200
        body = preview.json()
        assert body["imported"] == 2
        assert body["updated"] == 1
        assert body["unchanged"] == 0
        assert body["skipped"] == 1
        assert [item["action"] for item in body["items"]] == [
            "updated",
            "imported",
            "skipped",
            "imported",
        ]
        assert body["items"][0]["currentTargetText"] == "Existing term"
        assert body["items"][2]["message"] == "原文不可為空"
        glossary = after_preview.json()["glossary"]
        assert glossary["既有詞"] == "Existing term"
        assert "新增詞" not in glossary


def test_import_keep_existing_does_not_overwrite_existing_term() -> None:
    with TestClient(app) as client:
        headers = auth_headers(client)
        imported = client.post(
            "/glossary/import",
            headers=headers,
            json={"glossary": {"保留既有": "Existing"}},
        )
        preview = client.post(
            "/glossary/import/preview",
            headers=headers,
            json={
                "glossary": {"保留既有": "Updated"},
                "conflictStrategy": "keepExisting",
            },
        )
        second = client.post(
            "/glossary/import",
            headers=headers,
            json={
                "glossary": {"保留既有": "Updated"},
                "conflictStrategy": "keepExisting",
            },
        )
        bundle = client.get("/glossary", headers=headers)

        assert imported.status_code == 200
        assert preview.status_code == 200
        assert preview.json()["skipped"] == 1
        assert preview.json()["items"][0]["message"] == "已保留既有詞彙"
        assert second.status_code == 200
        assert second.json() == {"imported": 0, "updated": 0}
        assert bundle.json()["glossary"]["保留既有"] == "Existing"


def test_request_id_header_is_returned() -> None:
    with TestClient(app) as client:
        generated = client.get("/health")
        provided = client.get("/health", headers={"X-Request-ID": "request-1"})

        assert generated.status_code == 200
        assert generated.headers["X-Request-ID"]
        assert provided.headers["X-Request-ID"] == "request-1"


def test_health_includes_version_environment_and_migration_revision() -> None:
    with TestClient(app) as client:
        response = client.get("/health")

        assert response.status_code == 200
        body = response.json()
        assert body["version"] == "0.1.0"
        assert body["environment"] == "development"
        assert "migrationRevision" in body


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


def test_editor_can_restore_term_from_history() -> None:
    with TestClient(app) as client:
        headers = auth_headers(client)
        created = client.post(
            "/glossary",
            headers=headers,
            json={
                "sourceText": "回復詞",
                "targetText": "Original",
                "contextKey": "global",
            },
        )
        updated = client.put(
            f"/glossary/{created.json()['id']}",
            headers=headers,
            json={"targetText": "Updated"},
        )
        history = client.get(
            f"/glossary/{created.json()['id']}/history",
            headers=headers,
        )
        restored = client.post(
            f"/glossary/{created.json()['id']}/history/"
            f"{history.json()[0]['id']}/restore",
            headers=headers,
        )
        history_after_restore = client.get(
            f"/glossary/{created.json()['id']}/history",
            headers=headers,
        )

        assert created.status_code == 201
        assert updated.status_code == 200
        assert history.status_code == 200
        assert restored.status_code == 200
        assert restored.json()["targetText"] == "Original"
        assert restored.json()["version"] == 3
        assert history_after_restore.json()[-1]["operation"] == "restore"
        assert history_after_restore.json()[-1]["reason"].startswith("history:")


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


def test_editor_can_reject_pending_with_reason_in_history() -> None:
    create_user("reject-user@example.com", "secret", "user")
    with TestClient(app) as client:
        user_headers = login_headers(client, "reject-user@example.com", "secret")
        admin_headers = auth_headers(client)
        created = client.post(
            "/glossary",
            headers=user_headers,
            json={
                "sourceText": "待退回詞",
                "targetText": "Rejected term",
                "contextKey": "global",
            },
        )
        rejected = client.post(
            f"/glossary/{created.json()['id']}/reject",
            headers=admin_headers,
            json={"reason": "譯文不符合公司用語"},
        )
        history = client.get(
            f"/glossary/{created.json()['id']}/history",
            headers=admin_headers,
        )

        assert rejected.status_code == 200
        assert rejected.json()["status"] == "rejected"
        assert history.status_code == 200
        assert history.json()[-1]["operation"] == "reject"
        assert history.json()[-1]["reason"] == "譯文不符合公司用語"


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


def test_login_rate_limit_after_repeated_failures() -> None:
    _login_failures.clear()
    create_user("rate-limit@example.com", "secret", "user")
    with TestClient(app) as client:
        responses = [
            client.post(
                "/auth/login",
                json={"email": "rate-limit@example.com", "password": "wrong"},
            )
            for _ in range(6)
        ]

        assert [response.status_code for response in responses[:5]] == [401] * 5
        assert responses[5].status_code == 429
        assert responses[5].json()["detail"] == "登入失敗次數過多，請稍後再試"
    _login_failures.clear()


def test_successful_login_clears_rate_limit_failures() -> None:
    _login_failures.clear()
    create_user("rate-limit-clear@example.com", "secret", "user")
    with TestClient(app) as client:
        for _ in range(4):
            response = client.post(
                "/auth/login",
                json={
                    "email": "rate-limit-clear@example.com",
                    "password": "wrong",
                },
            )
            assert response.status_code == 401

        success = client.post(
            "/auth/login",
            json={"email": "rate-limit-clear@example.com", "password": "secret"},
        )
        next_failure = client.post(
            "/auth/login",
            json={"email": "rate-limit-clear@example.com", "password": "wrong"},
        )

        assert success.status_code == 200
        assert next_failure.status_code == 401
    _login_failures.clear()


def test_admin_can_reset_user_password_and_force_change() -> None:
    create_user("reset-password@example.com", "old-secret", "user")
    with TestClient(app) as client:
        admin_headers = auth_headers(client)
        users = client.get("/users", headers=admin_headers)
        user_id = next(
            item["id"]
            for item in users.json()
            if item["email"] == "reset-password@example.com"
        )

        reset = client.post(
            f"/users/{user_id}/reset-password",
            headers=admin_headers,
        )
        temporary_password = reset.json()["temporaryPassword"]
        old_login = client.post(
            "/auth/login",
            json={"email": "reset-password@example.com", "password": "old-secret"},
        )
        new_login = client.post(
            "/auth/login",
            json={
                "email": "reset-password@example.com",
                "password": temporary_password,
            },
        )

        assert reset.status_code == 200
        assert len(temporary_password) >= 12
        assert reset.json()["user"]["mustChangePassword"] is True
        assert old_login.status_code == 401
        assert new_login.status_code == 200
        assert new_login.json()["mustChangePassword"] is True


def test_disabling_user_invalidates_existing_token() -> None:
    create_user("disable-token@example.com", "secret", "user")
    with TestClient(app) as client:
        admin_headers = auth_headers(client)
        user_headers = login_headers(client, "disable-token@example.com", "secret")
        users = client.get("/users", headers=admin_headers)
        user_id = next(
            item["id"]
            for item in users.json()
            if item["email"] == "disable-token@example.com"
        )

        me_before_disable = client.get("/auth/me", headers=user_headers)
        disabled = client.put(
            f"/users/{user_id}",
            headers=admin_headers,
            json={"isActive": False},
        )
        me_after_disable = client.get("/auth/me", headers=user_headers)
        glossary_after_disable = client.get("/glossary", headers=user_headers)

        assert me_before_disable.status_code == 200
        assert disabled.status_code == 200
        assert disabled.json()["isActive"] is False
        assert me_after_disable.status_code == 401
        assert glossary_after_disable.status_code == 401


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
