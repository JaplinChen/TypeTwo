import logging
import threading

import requests
from flask import Flask, Response, jsonify, request

from config import BRIDGE_URL, load_cfg, retry_after_seconds
from glossary import apply_glossary_post, effective_cfg, pick_relevant_glossary
from translation_providers import do_translate

_BRIDGE_PORT = int(BRIDGE_URL.split(":")[-1])
_BRIDGE_APP = "TypeTwo"
_BRIDGE_API_VERSION = 1

flask_app = Flask(__name__)
_quit_handler = None


def set_quit_handler(handler):
    global _quit_handler
    _quit_handler = handler


@flask_app.get("/health")
def health():
    cfg = load_cfg()
    return jsonify({
        "ok": True,
        "app": _BRIDGE_APP,
        "apiVersion": _BRIDGE_API_VERSION,
        "routes": ["/health", "/translate", "/quit"],
        "provider": cfg.get("provider"),
        "model": cfg.get("model"),
    })


@flask_app.post("/quit")
def quit_route():
    if _quit_handler is None:
        return jsonify({"ok": False, "error": "quit handler unavailable"}), 503
    threading.Thread(target=_quit_handler, daemon=True).start()
    return jsonify({"ok": True})


@flask_app.post("/translate")
def translate_route():
    original_cfg = load_cfg()
    data = request.get_json(silent=True) or {}
    text = str(data.get("text", "")).strip()
    if not text:
        return Response(b"", mimetype="text/plain")
    try:
        cfg = effective_cfg(text, original_cfg)
        matched = pick_relevant_glossary(text, cfg, original_cfg)
        relevant = matched or None
        logging.debug("INPUT: %r", text)
        translated = do_translate(text, cfg, relevant)
        if relevant:
            translated = apply_glossary_post(translated, relevant)
        logging.debug("OUTPUT: %r", translated)
    except requests.HTTPError as e:
        logging.exception("Bridge provider HTTP error")
        status = e.response.status_code if e.response is not None else 502
        headers = {}
        if e.response is not None:
            retry_after = e.response.headers.get("Retry-After")
            if retry_after:
                headers["Retry-After"] = retry_after
        body = str(e)
        if e.response is not None and e.response.text:
            body = e.response.text
        return Response(body.encode("utf-8"), status=status, headers=headers, mimetype="text/plain")
    except Exception as e:
        logging.exception("Bridge translate failed")
        return Response(str(e).encode("utf-8"), status=500, mimetype="text/plain")
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
