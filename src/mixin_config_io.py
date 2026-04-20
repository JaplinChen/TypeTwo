from tkinter import messagebox

from config import load_cfg, save_cfg
from styles import C_ACCENT, C_SUCCESS


class ConfigIOMixin:
    """Config 序列化/反序列化 + 儲存/重載。"""

    def _load_to_ui(self):
        c = self._cfg
        self._var_provider.set(c.get("provider", "Ollama"))
        self._var_model.set(c.get("model", ""))
        self._var_endpoint.set(c.get("endpoint", ""))
        self._var_apikey.set(c.get("apiKey", ""))
        self._var_temp.set(float(c.get("temperature", 0.0)))
        self._var_src_lang.set(c.get("sourceLang", ""))
        self._var_tgt_lang.set(c.get("targetLang", ""))
        self._var_src_label.set(c.get("sourceLabel", ""))
        self._var_tgt_label.set(c.get("targetLabel", ""))
        self._txt_template.delete("1.0", "end")
        self._txt_template.insert("1.0", c.get("template", ""))
        self._txt_rules.delete("1.0", "end")
        self._txt_rules.insert("1.0", "\n".join(c.get("extraInstructions", [])))
        for row in self._tv_glossary.get_children():
            self._tv_glossary.delete(row)
        for src, tgt in c.get("glossary", {}).items():
            self._tv_glossary.insert("", "end", values=(src, tgt))
        self._lst_procs.delete(0, "end")
        for p in c.get("allowedProcesses", []):
            self._lst_procs.insert("end", p)
        self._update_apikey_visibility()

    def _collect_from_ui(self) -> dict:
        glossary = {}
        for iid in self._tv_glossary.get_children():
            src, tgt = self._tv_glossary.item(iid, "values")
            if src:
                glossary[src] = tgt
        return {
            "provider":          self._var_provider.get(),
            "model":             self._var_model.get().strip(),
            "endpoint":          self._var_endpoint.get().strip(),
            "apiKey":            self._var_apikey.get().strip(),
            "temperature":       round(self._var_temp.get(), 2),
            "sourceLang":        self._var_src_lang.get().strip(),
            "targetLang":        self._var_tgt_lang.get().strip(),
            "sourceLabel":       self._var_src_label.get().strip(),
            "targetLabel":       self._var_tgt_label.get().strip(),
            "template":          self._txt_template.get("1.0", "end-1c"),
            "extraInstructions": [r for r in self._txt_rules.get("1.0", "end-1c").splitlines() if r.strip()],
            "glossary":          glossary,
            "allowedProcesses":  list(self._lst_procs.get(0, "end")),
        }

    def _save(self):
        cfg = {**self._cfg, **self._collect_from_ui()}
        save_cfg(cfg)
        self._cfg = cfg
        self._lbl_save_status.config(text="✓ 已儲存", foreground=C_SUCCESS)
        self.after(3000, lambda: self._lbl_save_status.config(text=""))
        if self._bridge.is_running():
            if messagebox.askyesno("重啟 Bridge", "設定已儲存。\n需重啟 Bridge 才會生效，現在重啟？"):
                self._bridge.restart(after_ms=800, schedule_fn=self.after)

    def _reload(self):
        self._cfg = load_cfg()
        self._load_to_ui()
        self._lbl_save_status.config(text="已重新載入", foreground=C_ACCENT)
        self.after(2000, lambda: self._lbl_save_status.config(text=""))
