import threading
import tkinter as tk
from tkinter import messagebox, ttk

from providers import NEEDS_APIKEY, PROVIDER_DEFAULTS, PROVIDERS, check_connection, get_models
from styles import (
    C_ACCENT, C_ERROR, C_MUTED, C_SUCCESS,
    FONT_UI, FONT_UI_SM,
)


class EngineMixin:
    """翻譯引擎分頁 + 連線/模型操作。"""

    def _build_engine_tab(self):
        f = self._tab_engine
        self._var_provider  = tk.StringVar()
        self._var_model     = tk.StringVar()
        self._var_endpoint  = tk.StringVar()
        self._var_apikey    = tk.StringVar()
        self._var_temp      = tk.DoubleVar(value=0.0)

        lf = ttk.LabelFrame(f, text="翻譯引擎", padding=(12, 8))
        lf.pack(fill="x", pady=(0, 10))

        row = 0
        ttk.Label(lf, text="引擎類型").grid(row=row, column=0, sticky="w", pady=4)
        self._cb_provider = ttk.Combobox(lf, textvariable=self._var_provider,
                                         values=PROVIDERS, width=22, state="readonly")
        self._cb_provider.grid(row=row, column=1, sticky="ew", padx=(12, 0))
        self._cb_provider.bind("<<ComboboxSelected>>", self._on_provider_change)
        row += 1

        ttk.Label(lf, text="模型名稱").grid(row=row, column=0, sticky="w", pady=4)
        mf = ttk.Frame(lf)
        mf.grid(row=row, column=1, sticky="ew", padx=(12, 0))
        self._cb_model = ttk.Combobox(mf, textvariable=self._var_model, width=26)
        self._cb_model.pack(side="left", fill="x", expand=True)
        ttk.Button(mf, text="取得模型", command=self._fetch_models).pack(side="left", padx=(6, 0))
        row += 1

        ttk.Label(lf, text="伺服器位址").grid(row=row, column=0, sticky="w", pady=4)
        ef = ttk.Frame(lf)
        ef.grid(row=row, column=1, sticky="ew", padx=(12, 0))
        ttk.Entry(ef, textvariable=self._var_endpoint).pack(side="left", fill="x", expand=True)
        ttk.Button(ef, text="測試連線", command=self._test_connection).pack(side="left", padx=(6, 0))
        self._lbl_conn_status = ttk.Label(ef, text="", width=8)
        self._lbl_conn_status.pack(side="left", padx=(6, 0))
        row += 1

        self._lbl_apikey = ttk.Label(lf, text="API 金鑰")
        self._lbl_apikey.grid(row=row, column=0, sticky="w", pady=4)
        self._frm_apikey = ttk.Frame(lf)
        self._frm_apikey.grid(row=row, column=1, sticky="ew", padx=(12, 0))
        self._entry_apikey = ttk.Entry(self._frm_apikey, textvariable=self._var_apikey, show="*")
        self._entry_apikey.pack(side="left", fill="x", expand=True)
        ttk.Button(self._frm_apikey, text="👁", width=3,
                   command=self._toggle_apikey).pack(side="left", padx=(4, 0))
        row += 1

        ttk.Label(lf, text="翻譯風格").grid(row=row, column=0, sticky="w", pady=4)
        sf = ttk.Frame(lf)
        sf.grid(row=row, column=1, sticky="ew", padx=(12, 0))
        ttk.Label(sf, text="精準", style="Muted.TLabel").pack(side="left")
        ttk.Scale(sf, variable=self._var_temp, from_=0.0, to=1.0,
                  orient="horizontal", length=160).pack(side="left", padx=8)
        ttk.Label(sf, text="流暢", style="Muted.TLabel").pack(side="left")
        self._lbl_temp_val = ttk.Label(sf, text="0.0", width=4, style="Muted.TLabel")
        self._lbl_temp_val.pack(side="left", padx=(8, 0))
        self._var_temp.trace_add("write", self._on_temp_change)

        lf.columnconfigure(1, weight=1)

    def _toggle_apikey(self):
        self._entry_apikey.config(
            show="" if self._entry_apikey.cget("show") == "*" else "*"
        )

    def _on_provider_change(self, _event=None):
        provider = self._var_provider.get()
        d = PROVIDER_DEFAULTS.get(provider, {})
        if d.get("endpoint"):
            self._var_endpoint.set(d["endpoint"])
        if d.get("model"):
            self._var_model.set(d["model"])
        self._update_apikey_visibility()

    def _update_apikey_visibility(self):
        if self._var_provider.get() in NEEDS_APIKEY:
            self._lbl_apikey.grid()
            self._frm_apikey.grid()
        else:
            self._lbl_apikey.grid_remove()
            self._frm_apikey.grid_remove()

    def _on_temp_change(self, *_):
        try:
            self._lbl_temp_val.config(text=f"{self._var_temp.get():.1f}")
        except tk.TclError:
            pass

    def _fetch_models(self):
        provider = self._var_provider.get()
        endpoint = self._var_endpoint.get().strip()
        apikey   = self._var_apikey.get().strip()

        def _run():
            try:
                models = get_models(provider, endpoint, apikey)
                if models:
                    self.after(0, lambda: self._cb_model.config(values=models))
                    self.after(0, lambda: messagebox.showinfo("取得模型", f"找到 {len(models)} 個模型"))
                else:
                    self.after(0, lambda: messagebox.showwarning("取得模型", "未找到任何模型"))
            except Exception as e:
                self.after(0, lambda: messagebox.showerror("取得模型失敗", str(e)))

        threading.Thread(target=_run, daemon=True).start()

    def _test_connection(self):
        provider = self._var_provider.get()
        endpoint = self._var_endpoint.get().strip()
        apikey   = self._var_apikey.get().strip()
        self._lbl_conn_status.config(text="測試中…", foreground=C_MUTED)

        def _run():
            ok, msg = check_connection(provider, endpoint, apikey)
            color = C_SUCCESS if ok else C_ERROR
            label = "✓ 正常" if ok else "✗ 失敗"
            self.after(0, lambda: self._lbl_conn_status.config(text=label, foreground=color))
            if not ok:
                self.after(0, lambda: messagebox.showerror("連線失敗", msg))

        threading.Thread(target=_run, daemon=True).start()
