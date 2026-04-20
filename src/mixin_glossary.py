import json
import tkinter as tk
from pathlib import Path
from tkinter import filedialog, messagebox, ttk

from styles import C_ACCENT, C_BORDER, C_SURFACE, C_TEXT, FONT_UI


class GlossaryMixin:
    """詞彙表分頁 + CRUD 操作。"""

    def _build_glossary_tab(self):
        lf = ttk.LabelFrame(self._tab_gloss,
                            text="固定詞彙表（雙擊欄位可直接編輯）", padding=(12, 8))
        lf.pack(fill="both", expand=True)

        tv_frame = ttk.Frame(lf)
        tv_frame.pack(fill="both", expand=True)
        self._tv_glossary = ttk.Treeview(tv_frame, columns=("src", "tgt"),
                                         show="headings", height=10)
        self._tv_glossary.heading("src", text="原文")
        self._tv_glossary.heading("tgt", text="譯文")
        self._tv_glossary.column("src", width=200)
        self._tv_glossary.column("tgt", width=200)
        sb = ttk.Scrollbar(tv_frame, orient="vertical", command=self._tv_glossary.yview)
        self._tv_glossary.configure(yscrollcommand=sb.set)
        self._tv_glossary.pack(side="left", fill="both", expand=True)
        sb.pack(side="right", fill="y")
        self._tv_glossary.bind("<Double-1>", self._gloss_dblclick)

        gb = ttk.Frame(lf)
        gb.pack(fill="x", pady=(6, 0))
        ttk.Label(gb, text="原文").pack(side="left")
        self._ent_gsrc = ttk.Entry(gb, width=14)
        self._ent_gsrc.pack(side="left", padx=(6, 0))
        self._ent_gsrc.bind("<Return>", lambda e: self._ent_gtgt.focus())
        ttk.Label(gb, text="→", style="Muted.TLabel").pack(side="left", padx=6)
        self._ent_gtgt = ttk.Entry(gb, width=14)
        self._ent_gtgt.pack(side="left")
        self._ent_gtgt.bind("<Return>", lambda e: self._gloss_add())
        ttk.Button(gb, text="新增", command=self._gloss_add).pack(side="left", padx=(6, 0))
        ttk.Button(gb, text="刪除選取", command=self._gloss_del).pack(side="left", padx=(4, 0))

        io_row = ttk.Frame(lf)
        io_row.pack(fill="x", pady=(6, 0))
        ttk.Button(io_row, text="匯入", command=self._gloss_import).pack(side="left")
        ttk.Button(io_row, text="儲存", command=self._gloss_save).pack(side="left", padx=(6, 0))
        ttk.Label(io_row, text="支援 TSV（原文\\t譯文）/ JSON",
                  style="Muted.TLabel").pack(side="left", padx=(10, 0))

    def _gloss_add(self):
        src = self._ent_gsrc.get().strip()
        tgt = self._ent_gtgt.get().strip()
        if src:
            self._tv_glossary.insert("", "end", values=(src, tgt))
            self._ent_gsrc.delete(0, "end")
            self._ent_gtgt.delete(0, "end")
            self._ent_gsrc.focus()

    def _gloss_del(self):
        sel = self._tv_glossary.selection()
        if sel:
            self._tv_glossary.delete(sel[0])

    def _gloss_import(self):
        path = filedialog.askopenfilename(
            title="匯入詞彙表",
            filetypes=[("TSV 檔案", "*.tsv *.txt"), ("JSON 檔案", "*.json"), ("所有檔案", "*.*")],
        )
        if not path:
            return
        try:
            text = Path(path).read_text(encoding="utf-8")
            if path.lower().endswith(".json"):
                entries = list(json.loads(text).items())
            else:
                entries = [
                    (a.strip(), b.strip())
                    for line in text.splitlines()
                    if "\t" in line
                    for a, b in [line.split("\t", 1)]
                ]
            for row in self._tv_glossary.get_children():
                self._tv_glossary.delete(row)
            for src, tgt in entries:
                if src:
                    self._tv_glossary.insert("", "end", values=(src, tgt))
            messagebox.showinfo("匯入完成", f"已匯入 {len(entries)} 筆詞彙")
        except Exception as e:
            messagebox.showerror("匯入失敗", str(e))

    def _gloss_save(self):
        path = filedialog.asksaveasfilename(
            title="儲存詞彙表",
            defaultextension=".tsv",
            filetypes=[("TSV 檔案", "*.tsv"), ("JSON 檔案", "*.json"), ("所有檔案", "*.*")],
        )
        if not path:
            return
        try:
            entries = [
                self._tv_glossary.item(iid, "values")
                for iid in self._tv_glossary.get_children()
                if self._tv_glossary.item(iid, "values")[0]
            ]
            if path.lower().endswith(".json"):
                content = json.dumps(dict(entries), ensure_ascii=False, indent=2)
            else:
                content = "\n".join(f"{s}\t{t}" for s, t in entries)
            Path(path).write_text(content, encoding="utf-8")
            messagebox.showinfo("儲存完成", f"已儲存 {len(entries)} 筆詞彙")
        except Exception as e:
            messagebox.showerror("儲存失敗", str(e))

    def _gloss_dblclick(self, event):
        item = self._tv_glossary.identify_row(event.y)
        col  = self._tv_glossary.identify_column(event.x)
        if not item or col not in ("#1", "#2"):
            return
        col_idx = int(col[1]) - 1
        bbox = self._tv_glossary.bbox(item, col)
        if not bbox:
            return
        x, y, w, h = bbox
        cur_vals = list(self._tv_glossary.item(item, "values"))

        var = tk.StringVar(value=cur_vals[col_idx])
        entry = ttk.Entry(self._tv_glossary, textvariable=var)
        entry.place(x=x, y=y, width=w, height=h)
        entry.focus()
        entry.select_range(0, "end")

        def _commit(_e=None):
            cur_vals[col_idx] = var.get().strip()
            self._tv_glossary.item(item, values=cur_vals)
            entry.destroy()

        entry.bind("<Return>",   _commit)
        entry.bind("<Tab>",      _commit)
        entry.bind("<Escape>",   lambda e: entry.destroy())
        entry.bind("<FocusOut>", _commit)
