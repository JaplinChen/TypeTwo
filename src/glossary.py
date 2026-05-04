import re

_GLOSSARY_MAX_ENTRIES = 50
_KNOWN_GLOSSARY_LANGUAGES = (
    "繁體中文",
    "簡體中文",
    "越南文",
    "日文",
    "韓文",
    "泰文",
)


def glossary_rules(glossary: dict) -> str:
    items = sorted(glossary.items(), key=lambda x: len(x[0]), reverse=True)
    return "\n".join(f"- {src} → {tgt}" for src, tgt in items)


def resolve_glossary(cfg: dict, original_cfg: dict | None = None) -> dict:
    def add_pair(result: dict, source: str, target: str):
        entries = lang_glossary.get(f"{source}-{target}", {})
        if isinstance(entries, dict):
            result.update(entries)

    global_g = cfg.get("glossary", {})
    lang_glossary = cfg.get("langGlossary", {})
    result = dict(global_g) if isinstance(global_g, dict) else {}
    source = str(cfg.get("sourceLang", "auto"))
    target = str(cfg.get("targetLang", ""))
    add_pair(result, source, target)
    add_pair(result, target, source)

    auto_cfg = original_cfg or cfg
    second = str(auto_cfg.get("secondTargetLang") or "")
    if auto_cfg.get("sourceLang") == "auto" and second:
        primary = str(auto_cfg.get("targetLang", ""))
        add_pair(result, primary, second)
        add_pair(result, second, primary)
    return result


def glossary_matches(term: str, text: str) -> bool:
    if term.isascii():
        return bool(re.search(r'\b' + re.escape(term) + r'\b', text, re.IGNORECASE))
    return term.casefold() in text.casefold()


def looks_like_language(text: str, lang: str) -> bool:
    if lang in {"繁體中文", "簡體中文"}:
        return bool(re.search(r"[一-鿿]", text))
    if lang == "越南文":
        return bool(re.search(r"[ÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚÝàáâãèéêìíòóôõùúýĂăĐđĨĩŨũƠơƯưẠ-ỹ]", text))
    if lang == "日文":
        return bool(re.search(r"[぀-ヿ]", text))
    if lang == "韓文":
        return bool(re.search(r"[가-힯]", text))
    if lang == "泰文":
        return bool(re.search(r"[฀-๿]", text))
    return False


def looks_like_known_language(text: str) -> bool:
    return any(looks_like_language(text, lang) for lang in _KNOWN_GLOSSARY_LANGUAGES)


def direction_matches_target(input_term: str, output_term: str, target_lang: str) -> bool:
    if not target_lang:
        return True
    if looks_like_language(output_term, target_lang):
        return True
    if looks_like_language(input_term, target_lang):
        return False
    if looks_like_known_language(output_term):
        return False
    if looks_like_known_language(input_term):
        return True
    return True


def pick_relevant_glossary(
    text: str,
    cfg: dict,
    original_cfg: dict | None = None,
) -> dict:
    import logging
    target_lang = str(cfg.get("targetLang", ""))
    matched: dict = {}
    for src, tgt in resolve_glossary(cfg, original_cfg).items():
        src_text = str(src)
        tgt_text = str(tgt)
        if src_text and tgt_text and glossary_matches(src_text, text):
            if direction_matches_target(src_text, tgt_text, target_lang):
                matched[src_text] = tgt_text
        if tgt_text and src_text and glossary_matches(tgt_text, text):
            if direction_matches_target(tgt_text, src_text, target_lang):
                matched[tgt_text] = src_text
    if len(matched) <= _GLOSSARY_MAX_ENTRIES:
        return matched
    logging.warning("Glossary truncated to %d entries", _GLOSSARY_MAX_ENTRIES)
    return dict(sorted(matched.items(), key=lambda x: len(x[0]), reverse=True)[:_GLOSSARY_MAX_ENTRIES])


def target_from_glossary(text: str, cfg: dict) -> str | None:
    second = str(cfg.get("secondTargetLang") or "")
    if cfg.get("sourceLang") != "auto" or not second:
        return None
    primary = str(cfg.get("targetLang", ""))
    for src, tgt in resolve_glossary(cfg).items():
        src_text = str(src)
        tgt_text = str(tgt)
        if src_text and glossary_matches(src_text, text):
            if direction_matches_target(src_text, tgt_text, second):
                return second
            if direction_matches_target(src_text, tgt_text, primary):
                return primary
        if tgt_text and glossary_matches(tgt_text, text):
            if direction_matches_target(tgt_text, src_text, primary):
                return primary
            if direction_matches_target(tgt_text, src_text, second):
                return second
    return None


def apply_glossary_post(text: str, glossary: dict) -> str:
    ascii_entries = sorted(
        [(src, tgt) for src, tgt in glossary.items() if src.isascii()],
        key=lambda x: len(x[0]),
        reverse=True,
    )
    if not ascii_entries:
        return text
    pattern = re.compile(
        '|'.join(r'\b' + re.escape(src) + r'\b' for src, _ in ascii_entries),
        flags=re.IGNORECASE,
    )
    lookup = {src.lower(): tgt for src, tgt in ascii_entries}
    return pattern.sub(lambda m: lookup[m.group().lower()], text)


def effective_cfg(text: str, cfg: dict) -> dict:
    second = str(cfg.get("secondTargetLang") or "")
    if cfg.get("sourceLang") != "auto" or not second:
        return cfg
    primary = str(cfg.get("targetLang", ""))
    looks_primary = looks_like_language(text, primary)
    looks_second = looks_like_language(text, second)
    if looks_primary and not looks_second:
        resolved = second
    elif looks_second and not looks_primary:
        resolved = primary
    else:
        resolved = target_from_glossary(text, cfg)
    if not resolved:
        return cfg
    return {**cfg, "sourceLang": "auto", "targetLang": resolved, "secondTargetLang": None}
