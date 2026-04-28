from urllib.parse import urlparse

import requests

PROVIDERS = ["Ollama", "OpenAI", "Azure OpenAI", "Gemini", "Groq", "LM Studio"]

PROVIDER_DEFAULTS = {
    "Ollama":       {"endpoint": "http://127.0.0.1:11434/api/chat",           "model": "translategemma:4b"},
    "OpenAI":       {"endpoint": "https://api.openai.com/v1/chat/completions", "model": "gpt-4o"},
    "Azure OpenAI": {"endpoint": "https://<resource>.openai.azure.com/openai/deployments/<deployment>/chat/completions?api-version=2024-02-01",
                                                                               "model": "gpt-4o"},
    "Gemini":       {"endpoint": "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent",
                                                                               "model": "gemini-2.0-flash"},
    "Groq":         {"endpoint": "https://api.groq.com/openai/v1/chat/completions",
                                                                               "model": "llama-3.3-70b-versatile"},
    "LM Studio":    {"endpoint": "http://127.0.0.1:1234/v1/chat/completions", "model": "local-model"},
}

NEEDS_APIKEY = {"OpenAI", "Azure OpenAI", "Gemini", "Groq", "LM Studio"}

_OLLAMA_MODELS_PATH  = "/api/tags"
_OPENAI_MODELS_URL   = "https://api.openai.com/v1/models"
_GEMINI_MODELS_URL   = "https://generativelanguage.googleapis.com/v1beta/models"
_GROQ_MODELS_URL     = "https://api.groq.com/openai/v1/models"


def _openai_compatible_headers(apikey: str) -> dict[str, str]:
    headers = {"Content-Type": "application/json"}
    if apikey.strip():
        headers["Authorization"] = f"Bearer {apikey}"
    return headers


def _openai_compatible_models_url(endpoint: str) -> str:
    p = urlparse(endpoint)
    normalized_path = p.path.rstrip("/")
    suffix = "/chat/completions"
    if normalized_path.endswith(suffix):
        model_path = f"{normalized_path[:-len(suffix)]}/models"
    elif normalized_path.endswith("/models"):
        model_path = normalized_path
    else:
        model_path = f"{normalized_path}/models"
    return f"{p.scheme}://{p.netloc}{model_path}"


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

    if provider == "LM Studio":
        r = _get(
            _openai_compatible_models_url(endpoint),
            headers=_openai_compatible_headers(apikey),
            timeout=10,
        )
        return sorted(
            m["id"]
            for m in r.json().get("data", [])
            if isinstance(m, dict) and m.get("id")
        )

    if provider == "Azure OpenAI":
        raise RuntimeError("Azure OpenAI 不支援自動列出模型，請手動輸入部署名稱。")

    if provider == "Gemini":
        r = _get(_GEMINI_MODELS_URL, headers={"x-goog-api-key": apikey}, timeout=10)
        return [
            m["name"].split("/")[-1]
            for m in r.json().get("models", [])
            if isinstance(m, dict) and "generateContent" in m.get("supportedGenerationMethods", [])
        ]

    if provider == "Groq":
        r = _get(_GROQ_MODELS_URL, headers=_openai_compatible_headers(apikey), timeout=10)
        blocked = {"whisper", "tts", "embed", "vision", "guard", "tool"}
        return sorted(
            m["id"] for m in r.json().get("data", [])
            if isinstance(m, dict) and not any(k in m.get("id", "").lower() for k in blocked)
        )

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

        if provider == "LM Studio":
            _get(
                _openai_compatible_models_url(endpoint),
                headers=_openai_compatible_headers(apikey),
                timeout=5,
            )
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

        if provider == "Groq":
            _get(_GROQ_MODELS_URL, headers=_openai_compatible_headers(apikey), timeout=5)
            return True, ""

        return False, f"未知 provider: {provider}"
    except Exception as e:
        return False, str(e)
