import json
import sys
from pathlib import Path


def _base_dir() -> Path:
    if getattr(sys, "frozen", False):
        return Path(sys.executable).parent
    return Path(__file__).parent


CFG_PATH = _base_dir() / "translator_config.json"
BRIDGE_URL = "http://127.0.0.1:8765"


_cfg_cache: dict | None = None
_cfg_mtime: float = 0.0


def load_cfg() -> dict:
    global _cfg_cache, _cfg_mtime
    try:
        mtime = CFG_PATH.stat().st_mtime
    except OSError:
        mtime = 0.0
    if _cfg_cache is None or mtime != _cfg_mtime:
        _cfg_cache = json.loads(CFG_PATH.read_text(encoding="utf-8"))
        _cfg_mtime = mtime
    return _cfg_cache


def save_cfg(cfg: dict):
    global _cfg_cache, _cfg_mtime
    CFG_PATH.write_text(json.dumps(cfg, ensure_ascii=False, indent=2), encoding="utf-8")
    _cfg_cache = cfg
    _cfg_mtime = CFG_PATH.stat().st_mtime
