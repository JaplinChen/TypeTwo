import tkinter as tk
from tkinter import ttk

# ── 字體 ──────────────────────────────────────────────────────────────────────
FONT_UI    = ("Segoe UI", 10)
FONT_UI_SM = ("Segoe UI", 9)
FONT_UI_B  = ("Segoe UI", 10, "bold")
FONT_MONO  = ("Consolas", 10)
FONT_VIET  = ("Segoe UI", 11)

# ── 色彩 ──────────────────────────────────────────────────────────────────────
C_BG          = "#f5f5f5"
C_SURFACE     = "#ffffff"
C_BORDER      = "#d0d0d0"
C_ACCENT      = "#0078d4"
C_ACCENT_HOV  = "#106ebe"
C_TEXT        = "#1a1a1a"
C_MUTED       = "#6b6b6b"
C_STATUS_BG   = "#1e1e2e"
C_SUCCESS     = "#107c10"
C_ERROR       = "#c42b1c"
C_WARN        = "#c47f00"
C_BRIDGE_RUN  = "#22cc66"
C_BRIDGE_STOP = "#cc4444"
C_BRIDGE_BTN_START_BG  = "#1a5c30"
C_BRIDGE_BTN_START_FG  = "#aaffc8"
C_BRIDGE_BTN_STOP_BG   = "#8b2020"
C_BRIDGE_BTN_STOP_FG   = "#ffcccc"


def setup_style(root: tk.Tk):
    style = ttk.Style(root)
    style.theme_use("clam")

    style.configure(".",
        background=C_BG,
        foreground=C_TEXT,
        font=FONT_UI,
        bordercolor=C_BORDER,
        troughcolor=C_BG,
        focuscolor=C_ACCENT,
    )
    style.configure("TFrame", background=C_BG)
    style.configure("TLabel", background=C_BG, foreground=C_TEXT, font=FONT_UI)
    style.configure("Muted.TLabel", background=C_BG, foreground=C_MUTED, font=FONT_UI_SM)

    style.configure("TLabelframe", background=C_BG, bordercolor=C_BORDER, relief="solid")
    style.configure("TLabelframe.Label",
        background=C_BG, foreground=C_ACCENT, font=FONT_UI_B, padding=(4, 0))

    style.configure("TNotebook", background=C_BG, bordercolor=C_BORDER, tabmargins=[0, 0, 0, 0])
    style.configure("TNotebook.Tab",
        background="#e0e0e0", foreground=C_MUTED, font=FONT_UI, padding=(14, 6))
    style.map("TNotebook.Tab",
        background=[("selected", C_SURFACE), ("active", "#ececec")],
        foreground=[("selected", C_ACCENT)])

    style.configure("TButton",
        background="#e8e8e8", foreground=C_TEXT, font=FONT_UI,
        relief="flat", borderwidth=1, bordercolor=C_BORDER, padding=(10, 5))
    style.map("TButton",
        background=[("active", "#d8d8d8"), ("pressed", "#c8c8c8")])

    style.configure("Accent.TButton",
        background=C_ACCENT, foreground="white", font=FONT_UI_B,
        relief="flat", borderwidth=0, padding=(12, 6))
    style.map("Accent.TButton",
        background=[("active", C_ACCENT_HOV), ("pressed", "#005a9e")])

    style.configure("TEntry",
        fieldbackground=C_SURFACE, foreground=C_TEXT, font=FONT_UI,
        bordercolor=C_BORDER, insertcolor=C_TEXT, padding=(6, 4))
    style.map("TEntry", bordercolor=[("focus", C_ACCENT)])

    style.configure("TCombobox",
        fieldbackground=C_SURFACE, foreground=C_TEXT, font=FONT_UI,
        bordercolor=C_BORDER, arrowcolor=C_MUTED, padding=(6, 4))
    style.map("TCombobox",
        bordercolor=[("focus", C_ACCENT)],
        fieldbackground=[("readonly", C_SURFACE)])

    style.configure("TScale", background=C_BG, troughcolor="#d8d8d8", sliderrelief="flat")

    style.configure("Treeview",
        background=C_SURFACE, foreground=C_TEXT, font=FONT_UI,
        fieldbackground=C_SURFACE, rowheight=28, bordercolor=C_BORDER)
    style.configure("Treeview.Heading",
        background="#ebebeb", foreground=C_TEXT, font=FONT_UI_B,
        relief="flat", padding=(6, 4))
    style.map("Treeview",
        background=[("selected", C_ACCENT)],
        foreground=[("selected", "white")])

    style.configure("TScrollbar",
        background="#d0d0d0", troughcolor=C_BG, bordercolor=C_BG,
        arrowcolor=C_MUTED, relief="flat")
