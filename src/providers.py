from urllib.parse import urlparse

import requests

PROVIDERS = ["Ollama", "OpenAI", "Azure OpenAI", "Gemini"]

PROVIDER_DEFAULTS = {
    "Ollama":       {"endpoint": "http://127.0.0.1:11434/api/chat",           "model": "translategemma"},
    "OpenAI":       {"endpoint": "https://api.openai.com/v1/chat/completions", "model": "gpt-4o"},
    "Azure OpenAI": {"endpoint": "https://<resource>.openai.azure.com/openai/deployments/<deployment>/chat/completions?api-version=2024-02-01",
                                                                               "model": "gpt-4o"},
    "Gemini":       {"endpoint": "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent",
                                                                               "model": "gemini-2.5-flash"},
}

NEEDS_APIKEY = {"OpenAI", "Azure OpenAI", "Gemini"}

_OLLAMA_MODELS_PATH  = "/api/tags"
_OPENAI_MODELS_URL   = "https://api.openai.com/v1/models"
_GEMINI_MODELS_URL   = "https://generativelanguage.googleapis.com/v1beta/models"


def _ollama_base(endpoint: str) -> str:
    p = urlparse(endpoint)
    return f"{p.scheme}://{p.netloc}"


def _get(url: str, *, headers: dict | None = None, timeout: int) -> requests.Response:
    r = requests.get(url, headers=headers, timeout=timeout)
    r.raise_for_status()
    return r


def get_models(provider: str, endpoint: str, apikey: str) -> list[str]:
    if provider == "Ollama":
        r = _get(f"{_ollama_base(endpoint)}{_OLLAMA_MODELS_PATH}", timeout=10)
        return [m["name"] for m in r.json().get("models", []) if isinstance(m, dict) and "name" in m]

    if provider == "OpenAI":
        r = _get(_OPENAI_MODELS_URL,
                 headers={"Authorization": f"Bearer {apikey}"}, timeout=10)
        return sorted(m["id"] for m in r.json().get("data", []) if isinstance(m, dict) and "gpt" in m.get("id", ""))

    if provider == "Azure OpenAI":
        raise RuntimeError("Azure OpenAI 不支援自動列出模型，請手動輸入部署名稱。")

    if provider == "Gemini":
        r = _get(_GEMINI_MODELS_URL, headers={"x-goog-api-key": apikey}, timeout=10)
        return [
            m["name"].split("/")[-1]
            for m in r.json().get("models", [])
            if isinstance(m, dict) and "generateContent" in m.get("supportedGenerationMethods", [])
        ]

    return []


def check_connection(provider: str, endpoint: str, apikey: str) -> tuple[bool, str]:
    try:
        if provider == "Ollama":
            _get(f"{_ollama_base(endpoint)}{_OLLAMA_MODELS_PATH}", timeout=5)
            return True, ""

        if provider == "OpenAI":
            _get(_OPENAI_MODELS_URL,
                 headers={"Authorization": f"Bearer {apikey}"}, timeout=5)
            return True, ""

        if provider == "Azure OpenAI":
            r = requests.post(
                endpoint,
                headers={
                    "api-key": apikey,
                    "Content-Type": "application/json",
                },
                json={
                    "messages": [{"role": "user", "content": "Reply with OK."}],
                    "max_tokens": 1,
                    "temperature": 0,
                },
                timeout=5,
            )
            if r.status_code == 200:
                return True, ""
            return False, f"HTTP {r.status_code}: {r.text[:200]}"

        if provider == "Gemini":
            _get(_GEMINI_MODELS_URL, headers={"x-goog-api-key": apikey}, timeout=5)
            return True, ""

        return False, f"未知 provider: {provider}"
    except Exception as e:
        return False, str(e)
