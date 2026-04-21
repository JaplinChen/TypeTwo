import json
import sys
import threading
import unittest
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from providers import check_connection
from translate_engine import do_translate


class _CaptureHandler(BaseHTTPRequestHandler):
    requests_seen = []
    response_payload = {
        "choices": [
            {
                "message": {
                    "content": "python-azure-translation",
                }
            }
        ]
    }

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length).decode("utf-8")
        self.__class__.requests_seen.append(
            {
                "path": self.path,
                "headers": dict(self.headers),
                "body": json.loads(body),
            }
        )
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(self.response_payload).encode("utf-8"))

    def log_message(self, format, *args):
        return


class AzureOpenAITest(unittest.TestCase):
    def setUp(self):
        _CaptureHandler.requests_seen = []
        self.server = HTTPServer(("127.0.0.1", 0), _CaptureHandler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        port = self.server.server_address[1]
        self.endpoint = (
            f"http://127.0.0.1:{port}/openai/deployments/demo/"
            "chat/completions?api-version=2024-02-01"
        )

    def tearDown(self):
        self.server.shutdown()
        self.thread.join(timeout=2)
        self.server.server_close()

    def test_translate_and_connection_use_api_key_protocol(self):
        cfg = {
            "provider": "Azure OpenAI",
            "endpoint": self.endpoint,
            "apiKey": "azure-key",
            "sourceLang": "繁體中文",
            "targetLang": "英文",
            "temperature": 0,
        }

        translated = do_translate("hello", cfg)
        ok, message = check_connection("Azure OpenAI", self.endpoint, "azure-key")

        self.assertEqual(translated, "python-azure-translation")
        self.assertTrue(ok, message)
        self.assertEqual(len(_CaptureHandler.requests_seen), 2)

        for req in _CaptureHandler.requests_seen:
            self.assertEqual(req["headers"].get("api-key"), "azure-key")
            self.assertNotIn("Authorization", req["headers"])
            self.assertIn("messages", req["body"])
            self.assertNotIn("model", req["body"])


if __name__ == "__main__":
    unittest.main()
