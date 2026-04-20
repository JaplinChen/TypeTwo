import threading
import tkinter as tk
from tkinter import messagebox, ttk

import requests

from bridge_manager import BridgeManager
from config import BRIDGE_URL, load_cfg
from mixin_config_io import ConfigIOMixin
from mixin_engine import EngineMixin
from mixin_glossary import GlossaryMixin
from styles import (
    C_ACCENT, C_BG, C_BORDER, C_ERROR,
    C_BRIDGE_BTN_START_BG, C_BRIDGE_BTN_START_FG,
    C_BRIDGE_BTN_STOP_BG, C_BRIDGE_BTN_STOP_FG,
    C_BRIDGE_RUN, C_BRIDGE_STOP,
    C_MUTED, C_STATUS_BG, C_SUCCESS, C_SURFACE, C_TEXT,
    FONT_MONO, FONT_UI, FONT_UI_SM, FONT_VIET,
    setup_style,
)


class App(tk.Tk, EngineMixin, GlossaryMixin, ConfigIOMixin):
    def __init__(self):
        super().__init__()
        self.title("TypeTwo 設定")
        self.resizable(True, True)
        self.geometry("900x620")
        self.minsize(700, 560)
        self.configure(bg=C_BG)
        self._cfg = load_cfg()
        self._bridge = BridgeManager(self._on_bridge_status)
        setup_style(self)
        self._build_ui()
        self._load_to_ui()
        self._bridge.poll_once(5000, self.after)

    # ── UI 骨架 ───────────────────────────────────────────────────────────────

    def _build_ui(self):
        self._build_status_bar()

        bar = ttk.Frame(self, padding=(12, 6, 12, 10))
        bar.pack(side="bottom", fill="x")
        ttk.Button(bar, text="儲存設定", style="Accent.TButton",
                   command=self._save).pack(side="right", padx=(6, 0))
        ttk.Button(bar, text="重新載入", command=self._reload).pack(side="right")
        self._lbl_save_status = ttk.Label(bar, text="")
        self._lbl_save_status.pack(side="left")

        nb = ttk.Notebook(self)
        nb.pack(fill="both", expand=True, padx=12, pady=(8, 4))
        self._tab_engine = ttk.Frame(nb, padding=14)
        self._tab_lang   = ttk.Frame(nb, padding=14)
        self._tab_rules  = ttk.Frame(nb, padding=14)
        self._tab_gloss  = ttk.Frame(nb, padding=14)
        self._tab_proc   = ttk.Frame(nb, padding=14)
        self._tab_test   = ttk.Frame(nb, padding=14)
        nb.add(self._tab_engine, text="  翻譯設定  ")
        nb.add(self._tab_lang,   text="  語言設定  ")
        nb.add(self._tab_rules,  text="  翻譯規則  ")
        nb.add(self._tab_gloss,  text="  詞彙表  ")
        nb.add(self._tab_proc,   text="  限定程式  ")
        nb.add(self._tab_test,   text="  快速測試  ")

        self._build_engine_tab()
        self._build_language_tab()
        self._build_rules_tab()
        self._build_glossary_tab()
        self._build_processes_tab()
        self._build_test_tab()

    # ── 狀態列 ────────────────────────────────────────────────────────────────

    def _build_status_bar(self):
        bar = tk.Frame(self, bg=C_STATUS_BG, height=42)
        bar.pack(fill="x")
        bar.pack_propagate(False)

        self._dot_canvas = tk.Canvas(bar, width=12, height=12,
                                     bg=C_STATUS_BG, highlightthickness=0)
        self._dot_canvas.pack(side="left", padx=(14, 6), pady=15)
        self._dot = self._dot_canvas.create_oval(1, 1, 11, 11, fill="#555", outline="")

        self._lbl_bridge = tk.Label(bar, text="TypeTwo：偵測中…",
                                    bg=C_STATUS_BG, fg="#aaaacc", font=FONT_UI_SM)
        self._lbl_bridge.pack(side="left")

        btn_kw = dict(relief="flat", bd=0, padx=12, pady=0,
                      font=FONT_UI_SM, cursor="hand2", height=1)
        tk.Button(bar, text="■ 停止",
                  bg=C_BRIDGE_BTN_STOP_BG, fg=C_BRIDGE_BTN_STOP_FG,
                  activebackground="#a02828", activeforeground="white",
                  command=self._stop_bridge, **btn_kw).pack(side="right", padx=(0, 12), pady=8)
        tk.Button(bar, text="▶ 啟動",
                  bg=C_BRIDGE_BTN_START_BG, fg=C_BRIDGE_BTN_START_FG,
                  activebackground="#22733b", activeforeground="white",
                  command=self._start_bridge, **btn_kw).pack(side="right", padx=(0, 4), pady=8)

    def _on_bridge_status(self, running: bool, label: str = ""):
        color = C_BRIDGE_RUN if running else C_BRIDGE_STOP
        text  = label or ("TypeTwo：運行中" if running else "TypeTwo：未啟動")
        self._dot_canvas.itemconfig(self._dot, fill=color)
        self._lbl_bridge.config(text=text)

    # ── 語言設定分頁 ──────────────────────────────────────────────────────────

    def _build_language_tab(self):
        f = self._tab_lang
        self._var_src_lang  = tk.StringVar()
        self._var_tgt_lang  = tk.StringVar()
        self._var_src_label = tk.StringVar()
        self._var_tgt_label = tk.StringVar()

        lf = ttk.LabelFrame(f, text="語言設定", padding=(12, 8))
        lf.pack(fill="x")

        for i, (label, var, hint) in enumerate([
            ("翻譯來源", self._var_src_lang,  "例：繁體中文"),
            ("翻譯目標", self._var_tgt_lang,  "例：越南文"),
            ("來源標題", self._var_src_label, "例：中文"),
            ("目標標題", self._var_tgt_label, "例：Tiếng Việt"),
        ]):
            ttk.Label(lf, text=label).grid(row=i, column=0, sticky="w", pady=4)
            ttk.Entry(lf, textvariable=var, width=26).grid(row=i, column=1,
                                                            sticky="ew", padx=(12, 0))
            ttk.Label(lf, text=hint, style="Muted.TLabel").grid(row=i, column=2,
                                                                  sticky="w", padx=(10, 0))

        ttk.Label(lf, text="輸出格式").grid(row=4, column=0, sticky="nw", pady=4)
        self._txt_template = tk.Text(lf, width=36, height=4, wrap="none",
                                     font=FONT_MONO, bg=C_SURFACE, fg=C_TEXT,
                                     insertbackground=C_TEXT, relief="solid", bd=1,
                                     highlightthickness=1, highlightcolor=C_ACCENT,
                                     highlightbackground=C_BORDER, padx=6, pady=4)
        self._txt_template.grid(row=4, column=1, columnspan=2, sticky="ew", padx=(12, 0))
        ttk.Label(lf, text="變數：{source_label}  {source}  {target_label}  {translation}",
                  style="Muted.TLabel").grid(row=5, column=1, columnspan=2,
                                             sticky="w", padx=(12, 0), pady=(2, 0))
        lf.columnconfigure(1, weight=1)

    # ── 翻譯規則分頁 ──────────────────────────────────────────────────────────

    def _build_rules_tab(self):
        lf = ttk.LabelFrame(self._tab_rules,
                            text="翻譯規則（翻譯時強制遵守，每行一條）", padding=(12, 8))
        lf.pack(fill="both", expand=True)
        self._txt_rules = tk.Text(lf, wrap="word", undo=True,
                                  font=FONT_UI, bg=C_SURFACE, fg=C_TEXT,
                                  insertbackground=C_TEXT, relief="solid", bd=1,
                                  highlightthickness=1, highlightcolor=C_ACCENT,
                                  highlightbackground=C_BORDER, padx=8, pady=6)
        self._txt_rules.pack(fill="both", expand=True)

    # ── 限定程式分頁 ──────────────────────────────────────────────────────────

    def _build_processes_tab(self):
        lf = ttk.LabelFrame(self._tab_proc,
                            text="限定觸發翻譯的程式（留空 = 全部允許，Enter 新增）",
                            padding=(12, 8))
        lf.pack(fill="both", expand=True)

        self._lst_procs = tk.Listbox(lf, height=10, selectmode="single",
                                     activestyle="none", font=FONT_UI,
                                     bg=C_SURFACE, fg=C_TEXT,
                                     selectbackground=C_ACCENT, selectforeground="white",
                                     relief="solid", bd=1, highlightthickness=1,
                                     highlightcolor=C_BORDER, highlightbackground=C_BORDER)
        self._lst_procs.pack(fill="both", expand=True)

        pb = ttk.Frame(lf)
        pb.pack(fill="x", pady=(6, 0))
        self._ent_proc = ttk.Entry(pb, width=22)
        self._ent_proc.pack(side="left")
        self._ent_proc.bind("<Return>", lambda e: self._proc_add())
        ttk.Label(pb, text="例：Teams.exe",
                  style="Muted.TLabel").pack(side="left", padx=(10, 0))
        ttk.Button(pb, text="新增", command=self._proc_add).pack(side="left", padx=(10, 0))
        ttk.Button(pb, text="刪除選取", command=self._proc_del).pack(side="left", padx=(4, 0))

    def _proc_add(self):
        val = self._ent_proc.get().strip()
        if val:
            self._lst_procs.insert("end", val)
            self._ent_proc.delete(0, "end")

    def _proc_del(self):
        sel = self._lst_procs.curselection()
        if sel:
            self._lst_procs.delete(sel[0])

    # ── 快速測試分頁 ──────────────────────────────────────────────────────────

    def _build_test_tab(self):
        f = self._tab_test
        self._txt_test_in = tk.Text(f, height=5, wrap="word",
                                    font=FONT_VIET, bg=C_SURFACE, fg=C_TEXT,
                                    insertbackground=C_TEXT, relief="solid", bd=1,
                                    highlightthickness=1, highlightcolor=C_ACCENT,
                                    highlightbackground=C_BORDER, padx=8, pady=6)
        self._txt_test_in.pack(fill="x")
        self._txt_test_in.bind("<Control-Return>", lambda e: self._do_test())

        btn_row = ttk.Frame(f)
        btn_row.pack(fill="x", pady=(6, 0))
        ttk.Button(btn_row, text="翻譯  Ctrl+Enter", style="Accent.TButton",
                   command=self._do_test).pack(side="left")
        self._lbl_test_hint = ttk.Label(btn_row, text="", style="Muted.TLabel")
        self._lbl_test_hint.pack(side="left", padx=(10, 0))

        self._txt_test_out = tk.Text(f, state="disabled",
                                     font=FONT_VIET, bg=C_SURFACE, fg=C_TEXT,
                                     relief="solid", bd=1, highlightthickness=1,
                                     highlightcolor=C_BORDER, highlightbackground=C_BORDER,
                                     padx=8, pady=6, wrap="word")
        self._txt_test_out.pack(fill="both", expand=True, pady=(6, 0))

    def _do_test(self):
        text = self._txt_test_in.get("1.0", "end-1c").strip()
        if not text:
            return
        self._lbl_test_hint.config(text="")
        self._txt_test_out.config(state="normal")
        self._txt_test_out.delete("1.0", "end")
        self._txt_test_out.insert("1.0", "翻譯中…")
        self._txt_test_out.config(state="disabled")

        def _run():
            try:
                r = requests.post(f"{BRIDGE_URL}/translate", json={"text": text}, timeout=60)
                result = r.text if r.status_code == 200 else f"[HTTP {r.status_code}] {r.text[:200]}"
            except Exception as e:
                result = f"[無法連線] {e}"
                self.after(0, lambda: self._lbl_test_hint.config(
                    text="請先按左上方 ▶ 啟動 Bridge", foreground=C_ERROR))
            self.after(0, lambda: self._show_test_output(result))

        threading.Thread(target=_run, daemon=True).start()

    def _show_test_output(self, text: str):
        self._txt_test_out.config(state="normal")
        self._txt_test_out.delete("1.0", "end")
        self._txt_test_out.insert("1.0", text)
        self._txt_test_out.config(state="disabled")

    # ── Bridge 控制 ───────────────────────────────────────────────────────────

    def _start_bridge(self):
        try:
            self._bridge.start()
            self.after(2000, lambda: self._bridge.poll_once(5000, self.after))
        except FileNotFoundError as e:
            messagebox.showerror("找不到 Bridge", str(e))
        except Exception as e:
            messagebox.showerror("啟動失敗", str(e))

    def _stop_bridge(self):
        self._bridge.stop()


if __name__ == "__main__":
    app = App()
    app.mainloop()
