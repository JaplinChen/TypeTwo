import json
import sys
import threading
import unittest
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from providers import check_connection, get_models
from translate_engine import do_translate


class _CaptureHandler(BaseHTTPRequestHandler):
    requests_seen = []

    def do_GET(self):
        self.__class__.requests_seen.append(
            {
                "method": "GET",
                "path": self.path,
                "headers": dict(self.headers),
            }
        )
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(
            json.dumps(
                {
                    "data": [
                        {"id": "qwen3-8b"},
                        {"id": "gemma-3-12b-it"},
                    ]
                }
            ).encode("utf-8")
        )

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length).decode("utf-8")
        self.__class__.requests_seen.append(
            {
                "method": "POST",
                "path": self.path,
                "headers": dict(self.headers),
                "body": json.loads(body),
            }
        )
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(
            json.dumps(
                {
                    "choices": [
                        {
                            "message": {
                                "content": "lm-studio-translation",
                            }
                        }
                    ]
                }
            ).encode("utf-8")
        )

    def log_message(self, format, *args):
        return


class LMStudioTest(unittest.TestCase):
    def setUp(self):
        _CaptureHandler.requests_seen = []
        self.server = HTTPServer(("127.0.0.1", 0), _CaptureHandler)
        self.thread = threading.Thread(
            target=self.server.serve_forever,
            daemon=True,
        )
        self.thread.start()
        port = self.server.server_address[1]
        self.endpoint = f"http://127.0.0.1:{port}/v1/chat/completions"

    def tearDown(self):
        self.server.shutdown()
        self.thread.join(timeout=2)
        self.server.server_close()

    def test_translate_and_model_listing_use_openai_compatible_protocol(self):
        cfg = {
            "provider": "LM Studio",
            "endpoint": self.endpoint,
            "model": "qwen3-8b",
            "apiKey": "",
            "sourceLang": "繁體中文",
            "targetLang": "英文",
            "temperature": 0,
        }

        models = get_models("LM Studio", self.endpoint, "")
        translated = do_translate("hello", cfg)
        ok, message = check_connection("LM Studio", self.endpoint, "")

        self.assertEqual(models, ["gemma-3-12b-it", "qwen3-8b"])
        self.assertEqual(translated, "lm-studio-translation")
        self.assertTrue(ok, message)
        self.assertEqual(len(_CaptureHandler.requests_seen), 3)

        get_requests = [
            req for req in _CaptureHandler.requests_seen if req["method"] == "GET"
        ]
        post_requests = [
            req for req in _CaptureHandler.requests_seen if req["method"] == "POST"
        ]

        self.assertEqual(len(get_requests), 2)
        self.assertEqual(len(post_requests), 1)
        for req in get_requests:
            self.assertEqual(req["path"], "/v1/models")
            self.assertNotIn("Authorization", req["headers"])

        post_request = post_requests[0]
        self.assertEqual(post_request["path"], "/v1/chat/completions")
        self.assertEqual(post_request["body"]["model"], "qwen3-8b")
        self.assertNotIn("Authorization", post_request["headers"])

    def test_model_listing_preserves_path_prefix(self):
        endpoint = (
            f"http://127.0.0.1:{self.server.server_address[1]}"
            "/proxy/lmstudio/v1/chat/completions"
        )

        models = get_models("LM Studio", endpoint, "")
        ok, message = check_connection("LM Studio", endpoint, "")

        self.assertEqual(models, ["gemma-3-12b-it", "qwen3-8b"])
        self.assertTrue(ok, message)

        get_requests = [
            req for req in _CaptureHandler.requests_seen if req["method"] == "GET"
        ]
        self.assertEqual(len(get_requests), 2)
        for req in get_requests:
            self.assertEqual(req["path"], "/proxy/lmstudio/v1/models")


if __name__ == "__main__":
    unittest.main()
