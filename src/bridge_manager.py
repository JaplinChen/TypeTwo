import subprocess
import sys
import threading
from pathlib import Path

import requests

from config import _base_dir, BRIDGE_URL


def _typetwo_exe() -> Path | None:
    p = _base_dir() / "TypeTwo.exe"
    return p if p.exists() else None


class BridgeManager:
    def __init__(self, on_status_change):
        self._proc: subprocess.Popen | None = None
        self._lock = threading.Lock()
        self._on_status_change = on_status_change

    def is_running(self) -> bool:
        try:
            requests.get(f"{BRIDGE_URL}/health", timeout=1)
            return True
        except Exception:
            return False

    def start(self):
        if self.is_running():
            self._on_status_change(True, "TypeTwo：已在運行中")
            return
        exe = _typetwo_exe()
        if exe is None:
            raise FileNotFoundError("找不到 TypeTwo.exe\n請確認檔案與本程式在同一資料夾。")
        flags = subprocess.CREATE_NO_WINDOW if sys.platform == "win32" else 0
        with self._lock:
            self._proc = subprocess.Popen([str(exe)], creationflags=flags)
        self._on_status_change(True, "TypeTwo：啟動中…")

    def stop(self):
        with self._lock:
            if self._proc and self._proc.poll() is None:
                self._proc.terminate()
                self._proc = None
        self._on_status_change(False, "TypeTwo：已停止")

    def restart(self, after_ms: int = 800, schedule_fn=None):
        self.stop()
        if schedule_fn:
            schedule_fn(after_ms, self.start)
        else:
            self.start()

    def poll_once(self, schedule_next_ms: int, schedule_fn):
        def _check():
            ok = self.is_running()
            schedule_fn(0, lambda: self._on_status_change(ok, ""))
        threading.Thread(target=_check, daemon=True).start()
        schedule_fn(schedule_next_ms, lambda: self.poll_once(schedule_next_ms, schedule_fn))
