import logging

import requests
from flask import Flask, Response, jsonify, request

from config import BRIDGE_URL, load_cfg  # noqa: F401 – re-exported for callers

_BRIDGE_PORT = int(BRIDGE_URL.split(":")[-1])

flask_app = Flask(__name__)


def _clamp_temp(cfg: dict) -> float:
    return max(0.0, min(2.0, float(cfg.get("temperature", 0.0))))


def _build_system_prompt(cfg: dict, relevant_glossary: dict | None = None) -> str:
    parts = [f"Translate {cfg['sourceLang']} to {cfg['targetLang']}. Output only the translation."]
    if relevant_glossary:
        rules = "\n".join(f"- {src} → {tgt}" for src, tgt in relevant_glossary.items())
        parts.append(f"Use these exact translations for the terms below (do not alter them):\n{rules}")
    instructions = cfg.get("extraInstructions", [])
    if instructions:
        parts.append("Rules:\n" + "\n".join(f"- {r}" for r in instructions))
    return "\n\n".join(parts)


def _translate_ollama(text: str, cfg: dict, glossary: dict | None = None) -> str:
    payload = {
        "model": cfg["model"],
        "stream": False,
        "messages": [
            {"role": "system", "content": _build_system_prompt(cfg, glossary)},
            {"role": "user", "content": text},
        ],
        "options": {"temperature": _clamp_temp(cfg)},
    }
    r = requests.post(cfg["endpoint"], json=payload, timeout=60)
    r.raise_for_status()
    return r.json()["message"]["content"].strip()


def _translate_openai(text: str, cfg: dict, glossary: dict | None = None) -> str:
    headers = {
        "Authorization": f"Bearer {cfg['apiKey']}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": cfg["model"],
        "messages": [
            {"role": "system", "content": _build_system_prompt(cfg, glossary)},
            {"role": "user", "content": text},
        ],
        "temperature": _clamp_temp(cfg),
    }
    r = requests.post(cfg["endpoint"], headers=headers, json=payload, timeout=60)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"].strip()


def _translate_gemini(text: str, cfg: dict, glossary: dict | None = None) -> str:
    model = cfg["model"]
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={cfg['apiKey']}"
    payload = {
        "system_instruction": {"parts": [{"text": _build_system_prompt(cfg, glossary)}]},
        "contents": [{"role": "user", "parts": [{"text": text}]}],
        "generationConfig": {"temperature": _clamp_temp(cfg)},
    }
    r = requests.post(url, json=payload, timeout=60)
    r.raise_for_status()
    candidates = r.json().get("candidates", [])
    if not candidates:
        raise RuntimeError(f"Gemini returned no candidates: {r.text[:200]}")
    return candidates[0]["content"]["parts"][0]["text"].strip()


def do_translate(text: str, cfg: dict, glossary: dict | None = None) -> str:
    provider = str(cfg.get("provider", "Ollama")).lower()
    if provider == "ollama":
        return _translate_ollama(text, cfg, glossary)
    if provider in ("openai", "azure openai"):
        return _translate_openai(text, cfg, glossary)
    if provider == "gemini":
        return _translate_gemini(text, cfg, glossary)
    raise RuntimeError(f"Unsupported provider: {cfg.get('provider')}")


# ── Flask routes ──────────────────────────────────────────────────────────────

@flask_app.get("/health")
def health():
    cfg = load_cfg()
    return jsonify({"ok": True, "provider": cfg.get("provider"), "model": cfg.get("model")})


@flask_app.post("/translate")
def translate_route():
    cfg = load_cfg()
    data = request.get_json(silent=True) or {}
    text = str(data.get("text", "")).strip()
    if not text:
        return Response(b"", mimetype="text/plain")
    try:
        glossary = cfg.get("glossary", {})
        relevant = {src: tgt for src, tgt in glossary.items() if src in text} or None
        logging.debug("INPUT: %r", text)
        translated = do_translate(text, cfg, relevant)
        logging.debug("OUTPUT: %r", translated)
    except Exception as e:
        return Response(f"[翻譯失敗: {e}]".encode("utf-8"), status=500, mimetype="text/plain")
    template = str(cfg.get("template", "{source_label}:\n{source}\n\n{target_label}:\n{translation}"))
    output = (
        template
        .replace("{source_label}", str(cfg.get("sourceLabel", "")))
        .replace("{target_label}", str(cfg.get("targetLabel", "")))
        .replace("{source}", text)
        .replace("{translation}", translated)
    )
    return Response(output.encode("utf-8"), mimetype="text/plain")


def run_bridge():
    from werkzeug.serving import make_server
    logging.getLogger("werkzeug").setLevel(logging.WARNING)
    srv = make_server("127.0.0.1", _BRIDGE_PORT, flask_app)
    srv.serve_forever()
