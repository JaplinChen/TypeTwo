"""Tests for clipboard_hotkey._classify_error HTTP status routing."""
import sys
import unittest
from pathlib import Path
from unittest.mock import MagicMock

import requests

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from clipboard_hotkey import _classify_error  # noqa: E402


def _http_error(status: int, retry_after: str | None = None) -> requests.HTTPError:
    response = MagicMock()
    response.status_code = status
    response.headers = {}
    if retry_after is not None:
        response.headers["Retry-After"] = retry_after
    err = requests.HTTPError(f"HTTP {status}")
    err.response = response
    return err


class ClassifyErrorHttpStatusTest(unittest.TestCase):
    def test_500_returns_service_unavailable(self):
        msg = _classify_error(_http_error(500))
        self.assertIn("AI 服務暫時不可用", msg)

    def test_502_returns_service_unavailable(self):
        msg = _classify_error(_http_error(502))
        self.assertIn("AI 服務暫時不可用", msg)

    def test_503_returns_service_unavailable(self):
        msg = _classify_error(_http_error(503))
        self.assertIn("AI 服務暫時不可用", msg)

    def test_504_returns_service_unavailable(self):
        msg = _classify_error(_http_error(504))
        self.assertIn("AI 服務暫時不可用", msg)

    def test_401_returns_invalid_api_key(self):
        msg = _classify_error(_http_error(401))
        self.assertIn("API Key", msg)

    def test_403_returns_invalid_api_key(self):
        msg = _classify_error(_http_error(403))
        self.assertIn("API Key", msg)

    def test_429_with_numeric_retry_after_includes_seconds(self):
        msg = _classify_error(_http_error(429, retry_after="42"))
        self.assertIn("42", msg)

    def test_429_without_retry_after_uses_generic_quota_message(self):
        msg = _classify_error(_http_error(429))
        self.assertIn("API 請求限額", msg)

    def test_400_falls_through_to_check_settings(self):
        # Non-server / non-auth / non-quota status falls through.
        msg = _classify_error(_http_error(400))
        self.assertIn("provider 設定", msg)

    def test_connection_error_returns_connection_failed(self):
        msg = _classify_error(requests.ConnectionError("connection refused"))
        self.assertIn("無法連線", msg)

    def test_generic_exception_returns_check_settings(self):
        msg = _classify_error(RuntimeError("something else"))
        self.assertIn("provider 設定", msg)


if __name__ == "__main__":
    unittest.main()
