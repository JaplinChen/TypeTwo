import json
import sys
import threading
import time
from email.utils import parsedate_to_datetime
from pathlib import Path


def base_dir() -> Path:
    if getattr(sys, "frozen", False):
        return Path(sys.executable).parent
    return Path(__file__).parent


CFG_PATH = base_dir() / "translator_config.json"
BRIDGE_URL = "http://127.0.0.1:8765"


_cfg_cache: dict | None = None
_cfg_mtime: float = 0.0
_cfg_lock = threading.Lock()


def load_cfg() -> dict:
    global _cfg_cache, _cfg_mtime
    with _cfg_lock:
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
    with _cfg_lock:
        CFG_PATH.write_text(json.dumps(cfg, ensure_ascii=False, indent=2), encoding="utf-8")
        _cfg_cache = cfg
        try:
            _cfg_mtime = CFG_PATH.stat().st_mtime
        except OSError:
            _cfg_mtime = 0.0


def retry_after_seconds(value: str | None) -> int | None:
    if not value:
        return None
    try:
        return max(0, int(float(value)))
    except ValueError:
        pass
    try:
        retry_at = parsedate_to_datetime(value)
    except (TypeError, ValueError, IndexError):
        return None
    delta = retry_at.timestamp() - time.time()
    return max(0, int(delta))


_SUPPORTED_LOCALES = {"zh", "en", "vi"}

def load_locale() -> str:
    """Read ui_locale.txt from the same directory as the exe/script."""
    path = base_dir() / "ui_locale.txt"
    try:
        val = path.read_text(encoding="utf-8").strip()
        if val in _SUPPORTED_LOCALES:
            return val
    except OSError:
        pass
    return "zh"
