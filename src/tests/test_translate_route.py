import sys
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from translate_engine import flask_app


class TranslateRouteTest(unittest.TestCase):
    def test_translate_route_applies_template_and_relevant_glossary(self):
        captured = {}

        cfg = {
            "provider": "Ollama",
            "model": "translategemma",
            "sourceLabel": "原文",
            "targetLabel": "譯文",
            "template": "[{source_label}]\n{source}\n\n[{target_label}]\n{translation}",
            "glossary": {
                "API": "應用程式介面",
                "SDK": "軟體開發套件",
            },
        }

        def fake_do_translate(text, incoming_cfg, glossary):
            captured["text"] = text
            captured["cfg"] = incoming_cfg
            captured["glossary"] = glossary
            return "翻譯完成"

        with flask_app.test_client() as client:
            with patch("translate_engine.load_cfg", return_value=cfg):
                with patch("translate_engine.do_translate", side_effect=fake_do_translate):
                    response = client.post("/translate", json={"text": "Use API only"})

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.get_data(as_text=True),
            "[原文]\nUse API only\n\n[譯文]\n翻譯完成",
        )
        self.assertEqual(captured["text"], "Use API only")
        self.assertEqual(captured["glossary"], {"API": "應用程式介面"})

    def test_translate_route_returns_empty_for_blank_input(self):
        with flask_app.test_client() as client:
            with patch("translate_engine.load_cfg", return_value={}):
                response = client.post("/translate", json={"text": "   "})

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_data(as_text=True), "")


if __name__ == "__main__":
    unittest.main()
