import Foundation

// MARK: - Pasta de dados

enum AppPaths {
    /// ~/Library/Application Support/Ipasty (ou IPASTY_DATA_DIR, usado para gerar os prints com dados de exemplo).
    static let dataDir: URL = {
        if let custom = ProcessInfo.processInfo.environment["IPASTY_DATA_DIR"], !custom.isEmpty {
            let u = URL(fileURLWithPath: custom, isDirectory: true)
            try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
            return u
        }
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Ipasty", isDirectory: true)
        // Migra o histórico das primeiras versões, quando o app se chamava "Copiado".
        let old = base.appendingPathComponent("Copiado", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path), FileManager.default.fileExists(atPath: old.path) {
            try? FileManager.default.moveItem(at: old, to: dir)
        }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    /// Migra as preferências (chave do GIPHY etc.) do identificador antigo.
    static func migrateDefaults() {
        let d = UserDefaults.standard
        guard !d.bool(forKey: "migratedFromCopiado"), let old = UserDefaults(suiteName: "local.copiado.app") else { return }
        for key in ["giphyKey", "autoPaste", "symbolCategory"] where d.object(forKey: key) == nil {
            if let v = old.object(forKey: key) { d.set(v, forKey: key) }
        }
        d.set(true, forKey: "migratedFromCopiado")
    }
}

// MARK: - Dados do sistema
//
// Os nomes dos emojis em português e as categorias de caracteres vêm do próprio macOS
// de quem usa o app (os mesmos do Visualizador de Caracteres). Nada disso é copiado para
// o repositório: tudo é lido do sistema na hora em que o app abre.
// A ordem e as categorias dos emojis vêm do arquivo emoji-test.txt do Unicode (veja THIRD_PARTY_NOTICES.md).

enum SystemData {
    static let coreEmoji = "/System/Library/PrivateFrameworks/CoreEmoji.framework/Versions/A/Resources"
    static let charPalette = "/System/Library/Input Methods/CharacterPalette.app/Contents/Resources"

    private static func dict(_ path: String) -> [String: Any] {
        (NSDictionary(contentsOfFile: path) as? [String: Any]) ?? [:]
    }

    private static func strings(_ path: String, locale: String? = nil) -> [String: String] {
        let d = dict(path)
        if let locale { return (d[locale] as? [String: String]) ?? [:] }
        return (d as? [String: String]) ?? [:]
    }

    // MARK: Emojis

    static func loadEmoji() -> [EmojiGroup] {
        guard let url = Bundle.main.url(forResource: "emoji-test", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }

        let lang = Locale.preferredLanguages.first ?? "pt-BR"
        let candidates = [lang.replacingOccurrences(of: "-", with: "_"), "pt_BR", "en"]
        var names: [String: String] = [:]
        for c in candidates {
            names = strings("\(coreEmoji)/\(c).lproj/AppleName.strings")
            if !names.isEmpty { break }
        }
        var normalized: [String: String] = [:]
        for (k, v) in names { normalized[k.replacingOccurrences(of: "\u{FE0F}", with: "")] = v }

        let groupInfo: [String: (String, String)] = [
            "Smileys & Emotion": ("Carinhas e emoções", "face.smiling"),
            "People & Body": ("Pessoas", "hand.wave"),
            "Animals & Nature": ("Animais e natureza", "leaf"),
            "Food & Drink": ("Comidas e bebidas", "fork.knife"),
            "Travel & Places": ("Viagens e lugares", "car"),
            "Activities": ("Atividades", "soccerball"),
            "Objects": ("Objetos", "lightbulb"),
            "Symbols": ("Símbolos", "heart"),
            "Flags": ("Bandeiras", "flag"),
        ]
        let skin: ClosedRange<UInt32> = 0x1F3FB...0x1F3FF

        var groups: [EmojiGroup] = []
        var current: (id: String, name: String, icon: String, items: [EmojiEntry])?
        func flush() {
            if let c = current { groups.append(EmojiGroup(id: c.id, name: c.name, icon: c.icon, emojis: c.items)) }
            current = nil
        }

        for raw in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(raw)
            if line.hasPrefix("# group:") {
                flush()
                let g = line.dropFirst("# group:".count).trimmingCharacters(in: .whitespaces)
                if let info = groupInfo[g] { current = (g, info.0, info.1, []) }
                continue
            }
            guard current != nil, !line.hasPrefix("#"), line.contains("; fully-qualified"),
                  let hash = line.firstIndex(of: "#") else { continue }
            let comment = line[line.index(after: hash)...].trimmingCharacters(in: .whitespaces)
            let parts = comment.split(separator: " ", maxSplits: 2)
            guard parts.count >= 1 else { continue }
            let emoji = String(parts[0])
            let english = parts.count > 2 ? String(parts[2]) : ""
            if emoji.unicodeScalars.contains(where: { skin.contains($0.value) }) { continue }
            let local = names[emoji] ?? normalized[emoji.replacingOccurrences(of: "\u{FE0F}", with: "")]
            // Sem nome no sistema = o macOS ainda não sabe desenhar esse emoji.
            if names.isEmpty == false && local == nil { continue }
            current?.items.append(EmojiEntry(e: emoji, n: local ?? english, k: english))
        }
        flush()
        return groups
    }

    // MARK: Caracteres especiais

    private static func parse(_ data: String) -> (chars: [String], ranges: [[Int]]) {
        var chars: [String] = []
        var ranges: [[Int]] = []
        for tok in data.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespaces) }) where !tok.isEmpty {
            if tok.hasPrefix("0x"), tok.contains("-0x") {
                let p = tok.split(separator: "-")
                if p.count == 2, let a = Int(p[0].dropFirst(2), radix: 16), let b = Int(p[1].dropFirst(2), radix: 16) {
                    ranges.append([a, b])
                }
            } else if tok.hasPrefix("0x"), tok.count > 2, let v = UInt32(tok.dropFirst(2), radix: 16), let s = Unicode.Scalar(v) {
                chars.append(String(Character(s)))
            } else {
                chars.append(tok)
            }
        }
        return (chars, ranges)
    }

    static func loadSymbols() -> [SymbolGroup] {
        let lang = (Locale.preferredLanguages.first ?? "pt-BR").replacingOccurrences(of: "-", with: "_")
        let locAll = dict("\(charPalette)/Localizable.loctable")
        let loc = (locAll[lang] as? [String: String]) ?? (locAll["pt_BR"] as? [String: String]) ?? [:]
        let locEn = (locAll["en"] as? [String: String]) ?? [:]
        let blocksAll = dict("\(charPalette)/UnicodeBlocks_Title.loctable")
        let blocks = (blocksAll[lang] as? [String: String]) ?? (blocksAll["pt_BR"] as? [String: String]) ?? [:]
        func tr(_ key: String) -> String? { loc[key] ?? locEn[key] }

        guard let root = dict("\(charPalette)/Categories.plist")["CVAvailableCategories"] as? [[String: Any]] else { return [] }
        let fm = FileManager.default
        let skip: Set<String> = ["Category-Emoji", "Category-Favorites", "Category-Recents", "Category-Unicode"]

        var out: [SymbolGroup] = []
        for g in root {
            guard let gid = g["Group"] as? String, gid != "CategoryGroup-CodeTables",
                  let names = g["Categories"] as? [String] else { continue }
            var cats: [SymbolCategory] = []
            for c in names {
                let path = "\(charPalette)/\(c).plist"
                if skip.contains(c) || !fm.fileExists(atPath: path) { continue }
                if names.contains(c + "All"), fm.fileExists(atPath: "\(charPalette)/\(c)All.plist") { continue }
                if ["_ja", "_ko", "_zh_CN", "_zh_TW"].contains(where: { c.hasSuffix($0) }) { continue }
                guard let d = dict(path)["CVCategoryData"] as? [String: Any] else { continue }
                let base = String(c.dropFirst("Category-".count))
                let baseName = base.hasSuffix("All") ? String(base.dropLast(3)) : base
                let name = tr("CategoryName-\(base)") ?? tr("CategoryName-\(baseName)") ?? baseName
                let invisible = (d["CVInvisibleSectionTitles"] as? Bool) ?? false
                var sections: [SymbolSection] = []
                if let arr = d["DataArray"] as? [[String: Any]] {
                    for s in arr {
                        let p = parse(s["Data"] as? String ?? "")
                        let t = s["CVDataTitle"] as? String ?? ""
                        let title = invisible ? "" : (tr(t) ?? t.replacingOccurrences(of: "SectionTitle-", with: ""))
                        sections.append(SymbolSection(title: title, chars: p.chars, ranges: p.ranges))
                    }
                } else if let data = d["Data"] as? String {
                    let p = parse(data)
                    sections.append(SymbolSection(title: "", chars: p.chars, ranges: p.ranges))
                }
                if !sections.isEmpty { cats.append(SymbolCategory(id: base, name: name, sections: sections)) }
            }
            if !cats.isEmpty {
                out.append(SymbolGroup(name: tr(gid) ?? gid.replacingOccurrences(of: "CategoryGroup-", with: ""), categories: cats))
            }
        }

        if let uni = (dict("\(charPalette)/Category-Unicode.plist")["CVCategoryData"] as? [String: Any])?["DataArray"] as? [[String: Any]] {
            let sections = uni.map { b -> SymbolSection in
                let p = parse(b["Data"] as? String ?? "")
                let t = b["CVDataTitle"] as? String ?? ""
                return SymbolSection(title: blocks[t] ?? t, chars: p.chars, ranges: p.ranges)
            }
            out.append(SymbolGroup(name: "Tudo", categories: [SymbolCategory(id: "Unicode", name: "Unicode completo", sections: sections)]))
        }
        return out
    }
}
