const kAutoDetectLang = 'auto';

const kProviders = ['Ollama', 'OpenAI', 'Azure OpenAI', 'Gemini'];

const kNeedsApiKey = {'OpenAI', 'Azure OpenAI', 'Gemini'};

/// Providers that don't use a configurable server endpoint.
const kNoEndpoint = {'Gemini'};

const kApiKeyUrls = {
  'OpenAI': 'https://platform.openai.com/api-keys',
  'Azure OpenAI':
      'https://portal.azure.com/#create/Microsoft.CognitiveServicesOpenAI',
  'Gemini': 'https://aistudio.google.com/app/apikey',
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
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
    model: 'gemini-2.5-flash',
  ),
};

const kProviderFallbackDefaults = <String, List<String>>{
  'Ollama': [
    'translategemma:4b',
    'translategemma:12b',
    'qwen3:8b',
  ],
  'Gemini': [
    'gemini-2.0-flash',
    'gemini-1.5-flash',
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

const kDefaultLabels = <String, String>{
  kAutoDetectLang: '來源',
  '繁體中文': '中文',
  '簡體中文': '簡中',
  '越南文': 'Tiếng Việt',
  '英文': 'English',
  '日文': '日本語',
  '韓文': '한국어',
  '泰文': 'ภาษาไทย',
  '印尼文': 'Bahasa Indonesia',
  '馬來文': 'Bahasa Melayu',
  '法文': 'Français',
  '德文': 'Deutsch',
  '西班牙文': 'Español',
  '葡萄牙文': 'Português',
};
