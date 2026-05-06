import Foundation

struct KeyboardConfig {
    let provider: String
    let model: String
    let endpoint: String
    let apiKey: String
    let temperature: Double
    let sourceLang: String
    let targetLang: String
    let secondTargetLang: String?
    let template: String
    let glossary: [String: String]
    let extraInstructions: [String]
    let thinkingMode: String
}

enum ConfigReader {
    static let appGroupId = "group.com.typetwo.typetwo"
    static let configFileName = "translator_config.json"
    static let glossaryFileName = "glossary.json"

    static func load() -> KeyboardConfig? {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
        else { return nil }

        let configURL = containerURL.appendingPathComponent(configFileName)
        let glossaryURL = containerURL.appendingPathComponent(glossaryFileName)

        guard
            let configData = try? Data(contentsOf: configURL),
            let raw = try? JSONSerialization.jsonObject(with: configData) as? [String: Any]
        else { return nil }

        let glossary: [String: String]
        if let gData = try? Data(contentsOf: glossaryURL),
           let g = try? JSONSerialization.jsonObject(with: gData) as? [String: String] {
            glossary = g
        } else {
            glossary = [:]
        }

        let provider = raw["provider"] as? String ?? "OpenAI"
        let providerConfigs = raw["providerConfigs"] as? [String: [String: Any]] ?? [:]
        let pc = providerConfigs[provider]

        let apiKey   = pc?["apiKey"]   as? String ?? raw["apiKey"]   as? String ?? ""
        let endpoint = pc?["endpoint"] as? String ?? raw["endpoint"] as? String ?? ""
        let model    = pc?["model"]    as? String ?? raw["model"]    as? String ?? ""

        return KeyboardConfig(
            provider: provider,
            model: model,
            endpoint: endpoint,
            apiKey: apiKey,
            temperature: (raw["temperature"] as? Double) ?? 0.0,
            sourceLang: raw["sourceLang"] as? String ?? "auto",
            targetLang: raw["targetLang"] as? String ?? "繁體中文",
            secondTargetLang: raw["secondTargetLang"] as? String,
            template: raw["template"] as? String ?? "{source}\n{translation}",
            glossary: glossary,
            extraInstructions: raw["extraInstructions"] as? [String] ?? [],
            thinkingMode: raw["thinkingMode"] as? String ?? "quick"
        )
    }
}
