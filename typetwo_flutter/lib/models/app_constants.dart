const kAutoDetectLang = 'auto';

const kProviders = ['Ollama', 'OpenAI', 'Azure OpenAI', 'Gemini', 'Groq', 'LM Studio'];

const kNeedsApiKey = {'OpenAI', 'Azure OpenAI', 'Gemini', 'Groq', 'LM Studio'};

/// Providers that don't use a configurable server endpoint.
const kNoEndpoint = {'Gemini', 'Groq'};

const kApiKeyUrls = {
  'OpenAI': 'https://platform.openai.com/api-keys',
  'Azure OpenAI':
      'https://portal.azure.com/#create/Microsoft.CognitiveServicesOpenAI',
  'Gemini': 'https://aistudio.google.com/app/apikey',
  'Groq': 'https://console.groq.com/keys',
};

const kProviderDefaults = <String, ({String endpoint, String model})>{
  'Ollama': (
    endpoint: 'http://127.0.0.1:11434/api/chat',
    model: 'qwen3:14b',
  ),
  'OpenAI': (
    endpoint: 'https://api.openai.com/v1/chat/completions',
    model: 'gpt-4o',
  ),
  'Azure OpenAI': (
    endpoint:
        'https://<resource>.openai.azure.com/openai/deployments/<deployment>/chat/completions?api-version=2024-02-01',
    model: 'gpt-4o',
  ),
  'Gemini': (
    endpoint:
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
    model: 'gemini-2.0-flash',
  ),
  'Groq': (
    endpoint: 'https://api.groq.com/openai/v1/chat/completions',
    model: 'llama-3.3-70b-versatile',
  ),
  'LM Studio': (
    endpoint: 'http://127.0.0.1:1234/v1/chat/completions',
    model: 'local-model',
  ),
};

const kProviderFallbackDefaults = <String, List<String>>{
  'Ollama': [
    'translategemma:4b',
    'translategemma:12b',
    'qwen3:8b',
  ],
  'Gemini': [
    'gemini-1.5-flash',
  ],
  'Groq': [
    'gemma2-9b-it',
    'llama-3.1-8b-instant',
  ],
  'LM Studio': [
    'gemma-3-12b-it',
    'qwen3-8b',
  ],
};

const kBaseLanguages = <(String, String)>[
  ('繁體中文', '繁體中文'),
  ('簡體中文', '簡體中文'),
  ('越南文', '越南文'),
  ('英文', '英文'),
  ('日文', '日文'),
  ('韓文', '韓文'),
  ('泰文', '泰文'),
  ('印尼文', '印尼文'),
  ('馬來文', '馬來文'),
  ('法文', '法文'),
  ('德文', '德文'),
  ('西班牙文', '西班牙文'),
  ('葡萄牙文', '葡萄牙文'),
];

const kSrcLanguages = <(String, String)>[
  (kAutoDetectLang, '自動偵測'),
  ...kBaseLanguages,
];

const kTgtLanguages = kBaseLanguages;
