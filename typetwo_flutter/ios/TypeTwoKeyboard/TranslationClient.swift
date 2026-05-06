import Foundation

enum TranslationError: LocalizedError {
    case noConfig
    case invalidURL
    case apiError(Int, String)
    case parseError

    var errorDescription: String? {
        switch self {
        case .noConfig:      return "尚未設定翻譯引擎，請先開啟 TypeTwo 完成設定。"
        case .invalidURL:    return "Endpoint URL 無效。"
        case .apiError(let code, let msg): return "API 錯誤 \(code): \(msg)"
        case .parseError:    return "無法解析 API 回應。"
        }
    }
}

enum TranslationClient {

    static func translate(text: String, config: KeyboardConfig) async throws -> String {
        let raw = try await config.provider == "Gemini"
            ? gemini(text: text, config: config)
            : openAICompatible(text: text, config: config)
        return buildOutput(source: text, translation: raw, template: config.template)
    }

    // MARK: - Output

    private static func buildOutput(source: String, translation: String, template: String) -> String {
        template
            .replacingOccurrences(of: "{source}", with: source)
            .replacingOccurrences(of: "{translation}", with: translation)
    }

    // MARK: - System prompt

    private static func systemPrompt(config: KeyboardConfig) -> String {
        let lang   = config.targetLang
        let second = config.secondTargetLang

        let task: String
        if config.sourceLang == "auto", let s = second, !s.isEmpty {
            task = "Detect the source language and choose exactly one target language. "
                + "If the source is \(lang), translate to \(s). "
                + "If the source is \(s), translate to \(lang). "
                + "Otherwise translate to \(lang)."
        } else if config.sourceLang == "auto" {
            task = "Detect the source language and translate to \(lang)."
        } else {
            task = "Translate \(config.sourceLang) to \(lang)."
        }

        var prompt = "You are a translation engine. \(task) "
            + "Output ONLY the translation — nothing else. "
            + "Preserve all formatting: bullet points, line breaks, punctuation."

        if !config.glossary.isEmpty {
            let terms = config.glossary.map { "\($0.key) → \($0.value)" }.joined(separator: "\n")
            prompt += "\n\nGlossary:\n\(terms)"
        }
        for instruction in config.extraInstructions {
            prompt += "\n\(instruction)"
        }
        return prompt
    }

    // MARK: - OpenAI-compatible (OpenAI, Groq, Azure, Ollama)

    private static func openAICompatible(text: String, config: KeyboardConfig) async throws -> String {
        let urlStr = config.endpoint.isEmpty
            ? "https://api.openai.com/v1/chat/completions"
            : config.endpoint
        guard let url = URL(string: urlStr) else { throw TranslationError.invalidURL }

        let body: [String: Any] = [
            "model": config.model,
            "temperature": config.temperature,
            "messages": [
                ["role": "system", "content": systemPrompt(config: config)],
                ["role": "user",   "content": text],
            ],
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !config.apiKey.isEmpty {
            req.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: req)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard code == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw TranslationError.apiError(code, String(msg.prefix(200)))
        }

        guard
            let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices  = json["choices"] as? [[String: Any]],
            let message  = choices.first?["message"] as? [String: Any],
            let content  = message["content"] as? String
        else { throw TranslationError.parseError }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Gemini

    private static func gemini(text: String, config: KeyboardConfig) async throws -> String {
        let base = "https://generativelanguage.googleapis.com/v1beta/models/\(config.model):generateContent"
        guard let url = URL(string: "\(base)?key=\(config.apiKey)") else {
            throw TranslationError.invalidURL
        }

        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": systemPrompt(config: config)]]],
            "contents": [["parts": [["text": text]]]],
            "generationConfig": ["temperature": config.temperature],
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: req)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard code == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw TranslationError.apiError(code, String(msg.prefix(200)))
        }

        guard
            let json       = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let content    = candidates.first?["content"] as? [String: Any],
            let parts      = content["parts"] as? [[String: Any]],
            let result     = parts.first?["text"] as? String
        else { throw TranslationError.parseError }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
