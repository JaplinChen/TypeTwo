import sys
import logging
import threading
import unittest
from pathlib import Path
from unittest.mock import patch
import requests

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from translate_engine import (
    flask_app,
    _apply_glossary_post,
    _glossary_matches,
    _glossary_rules,
    _pick_relevant_glossary,
    _resolve_glossary,
)


class GlossaryMatchesTest(unittest.TestCase):
    def test_ascii_word_boundary_no_false_match(self):
        self.assertFalse(_glossary_matches("file", "profile"))

    def test_ascii_word_boundary_matches_whole_word(self):
        self.assertTrue(_glossary_matches("file", "edit the file here"))

    def test_ascii_case_insensitive(self):
        self.assertTrue(_glossary_matches("API", "use api directly"))

    def test_non_ascii_substring(self):
        self.assertTrue(_glossary_matches("文件", "編輯文件夾中的文件"))

    def test_non_ascii_no_match(self):
        self.assertFalse(_glossary_matches("報告", "這是文件"))


class GlossaryRulesTest(unittest.TestCase):
    def test_sorted_longest_first(self):
        glossary = {"API": "介面", "API key": "API 金鑰", "SDK": "套件"}
        rules = _glossary_rules(glossary)
        lines = rules.splitlines()
        lengths = [len(line.split(" → ")[0].lstrip("- ")) for line in lines]
        self.assertEqual(lengths, sorted(lengths, reverse=True))


class ApplyGlossaryPostTest(unittest.TestCase):
    def test_replaces_ascii_term_in_output(self):
        result = _apply_glossary_post("使用 API 即可", {"API": "應用程式介面"})
        self.assertEqual(result, "使用 應用程式介面 即可")

    def test_case_insensitive_replacement(self):
        result = _apply_glossary_post("use api here", {"API": "應用程式介面"})
        self.assertEqual(result, "use 應用程式介面 here")

    def test_no_false_replacement(self):
        result = _apply_glossary_post("the profile page", {"file": "檔案"})
        self.assertEqual(result, "the profile page")

    def test_longer_term_replaced_first(self):
        result = _apply_glossary_post("use API key", {"API": "介面", "API key": "API 金鑰"})
        self.assertEqual(result, "use API 金鑰")

    def test_non_ascii_term_skipped(self):
        result = _apply_glossary_post("文件說明", {"文件": "document"})
        self.assertEqual(result, "文件說明")


class ResolveGlossaryTest(unittest.TestCase):
    def _cfg(self, **kwargs):
        return {"sourceLang": "en", "targetLang": "zh", **kwargs}

    def test_global_only(self):
        cfg = self._cfg(glossary={"API": "介面"})
        self.assertEqual(_resolve_glossary(cfg), {"API": "介面"})

    def test_lang_pair_merges_and_overrides_global(self):
        cfg = self._cfg(
            glossary={"API": "介面", "SDK": "套件"},
            langGlossary={"en-zh": {"API": "應用程式介面", "Hello": "你好"}},
        )
        result = _resolve_glossary(cfg)
        self.assertEqual(result["API"], "應用程式介面")
        self.assertEqual(result["SDK"], "套件")
        self.assertEqual(result["Hello"], "你好")

    def test_unmatched_pair_falls_back_to_global(self):
        cfg = self._cfg(
            glossary={"API": "介面"},
            langGlossary={"en-jp": {"API": "インターフェース"}},
        )
        self.assertEqual(_resolve_glossary(cfg)["API"], "介面")

    def test_empty_config(self):
        self.assertEqual(_resolve_glossary({}), {})


class PickRelevantGlossaryTest(unittest.TestCase):
    def test_uses_reverse_term_when_target_is_source_side_language(self):
        cfg = {
            "sourceLang": "auto",
            "targetLang": "繁體中文",
            "secondTargetLang": "越南文",
            "glossary": {"業務": "Kinh doanh"},
        }

        self.assertEqual(
            _pick_relevant_glossary("kinh doanh", cfg),
            {"Kinh doanh": "業務"},
        )

    def test_does_not_reverse_when_output_would_conflict_with_target_language(self):
        cfg = {
            "sourceLang": "繁體中文",
            "targetLang": "越南文",
            "glossary": {"業務": "Kinh doanh"},
        }

        self.assertEqual(_pick_relevant_glossary("kinh doanh", cfg), {})

    def test_uses_reverse_language_pair_entries(self):
        cfg = {
            "sourceLang": "越南文",
            "targetLang": "繁體中文",
            "glossary": {},
            "langGlossary": {"繁體中文-越南文": {"業務": "Kinh doanh"}},
        }

        self.assertEqual(
            _pick_relevant_glossary("kinh doanh", cfg),
            {"Kinh doanh": "業務"},
        )


class TranslateRouteTest(unittest.TestCase):
    def test_translate_route_applies_template_and_relevant_glossary(self):
        captured = {}

        cfg = {
            "provider": "Ollama",
            "model": "translategemma:4b",
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

    def test_translate_route_applies_reverse_glossary(self):
        captured = {}
        cfg = {
            "provider": "Ollama",
            "model": "translategemma:4b",
            "sourceLang": "auto",
            "targetLang": "繁體中文",
            "secondTargetLang": "越南文",
            "template": "{translation}",
            "glossary": {"業務": "Kinh doanh"},
        }

        def fake_do_translate(text, incoming_cfg, glossary):
            captured["cfg"] = incoming_cfg
            captured["glossary"] = glossary
            return "kinh doanh"

        with flask_app.test_client() as client:
            with patch("translate_engine.load_cfg", return_value=cfg):
                with patch("translate_engine.do_translate", side_effect=fake_do_translate):
                    response = client.post("/translate", json={"text": "kinh doanh"})

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_data(as_text=True), "業務")
        self.assertEqual(captured["cfg"]["targetLang"], "繁體中文")
        self.assertEqual(captured["glossary"], {"Kinh doanh": "業務"})

    def test_translate_route_returns_empty_for_blank_input(self):
        with flask_app.test_client() as client:
            with patch("translate_engine.load_cfg", return_value={}):
                response = client.post("/translate", json={"text": "   "})

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_data(as_text=True), "")

    def test_translate_route_preserves_upstream_http_status_and_retry_after(self):
        upstream = requests.Response()
        upstream.status_code = 429
        upstream._content = b"quota exceeded"
        upstream.headers["Retry-After"] = "7"
        upstream.url = "https://example.test"

        with flask_app.test_client() as client:
            with patch("translate_engine.load_cfg", return_value={}):
                with patch(
                    "translate_engine.do_translate",
                    side_effect=requests.HTTPError("quota exceeded", response=upstream),
                ):
                    with self.assertLogs(level=logging.ERROR) as captured_logs:
                        response = client.post("/translate", json={"text": "hello"})

        self.assertEqual(response.status_code, 429)
        self.assertEqual(response.headers.get("Retry-After"), "7")
        self.assertEqual(response.get_data(as_text=True), "quota exceeded")
        self.assertTrue(
            any("Bridge provider HTTP error" in line for line in captured_logs.output)
        )

    def test_quit_route_invokes_registered_handler(self):
        quit_called = threading.Event()

        def on_quit():
            quit_called.set()

        with flask_app.test_client() as client:
            with patch("translate_engine._quit_handler", on_quit):
                response = client.post("/quit")

        self.assertEqual(response.status_code, 200)
        self.assertTrue(quit_called.wait(timeout=1))


if __name__ == "__main__":
    unittest.main()
