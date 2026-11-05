import Foundation

enum PublicPlanLanguage {
    /// Language preferences are independent for each built-in or imported template.
    static func key(for plan: PublicPlanInfo.Plan) -> String? {
        let identifier: String
        switch plan {
        case .app(let plan):
            identifier = "app.\(plan.file.rawValue)"
        case .custom(let plan):
            guard let id = plan.id else { return nil }
            identifier = "custom.\(id)"
        }
        return "com.zizicici.common.settings.PublicPlanLanguage.\(identifier)"
    }

    static func saved(for plan: PublicPlanInfo.Plan, defaults: UserDefaults = .standard) -> String? {
        key(for: plan).flatMap { defaults.string(forKey: $0) }.map(identifier)
    }

    static func save(_ language: String?, for plan: PublicPlanInfo.Plan, defaults: UserDefaults = .standard) {
        guard let key = key(for: plan) else { return }
        if let language {
            defaults.set(identifier(language), forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    static func title(for language: String?) -> String {
        guard let language else { return String(localized: "publicPlan.language.original") }
        // Autonyms keep the options recognizable regardless of the app's language.
        return Locale(identifier: language).localizedString(forIdentifier: language) ?? language
    }

    static func identifier(_ language: String) -> String {
        Locale.canonicalLanguageIdentifier(from: language.replacingOccurrences(of: "_", with: "-"))
    }

    static func fallbacks(for language: String) -> [String] {
        let identifier = identifier(language)
        var parts = identifier.split(separator: "-")
        guard let base = parts.first else { return [language] }

        var candidates = [language, identifier]
        // Keep explicit scripts and intermediate tags before falling back to the language.
        while parts.count > 2 {
            parts.removeLast()
            candidates.append(parts.joined(separator: "-"))
        }
        if let script = Locale(identifier: identifier).language.script?.identifier {
            candidates.append("\(base)-\(script)")
        }
        candidates.append(String(base))
        var seen = Set<String>()
        return candidates.filter { seen.insert($0).inserted }
    }
}
