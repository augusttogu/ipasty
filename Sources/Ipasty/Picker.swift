import AppKit
import SwiftUI
import SQLite3
import CoreText

// MARK: - Abas

enum Tab: Int, CaseIterable {
    case favorites, emoji, gif, kaomoji, symbols, clipboard

    var title: String {
        switch self {
        case .favorites: return "Favoritos e recentes"
        case .emoji: return "Emojis"
        case .gif: return "GIFs"
        case .kaomoji: return "Kaomojis"
        case .symbols: return "Caracteres especiais"
        case .clipboard: return "Área de Transferência"
        }
    }
}

// MARK: - Favoritos e recentes

struct FavItem: Codable, Identifiable, Hashable {
    enum Kind: String, Codable { case emoji, symbol, kaomoji, gif, text }
    var kind: Kind
    var value: String          // o texto/caractere, ou o id do GIF
    var title: String? = nil   // nome do emoji/caractere ou título do GIF
    var preview: String? = nil // GIF: URL da miniatura
    var full: String? = nil    // GIF: URL do GIF para colar
    var id: String { kind.rawValue + ":" + value }
}

// MARK: - Dados de emoji e caracteres

struct EmojiEntry: Codable, Hashable { let e: String; let n: String; let k: String }
struct EmojiGroup: Codable, Identifiable { let id: String; let name: String; let icon: String; let emojis: [EmojiEntry] }

struct SymbolSection: Codable { let title: String; let chars: [String]; let ranges: [[Int]] }
struct SymbolCategory: Codable, Identifiable { let id: String; let name: String; let sections: [SymbolSection] }
struct SymbolGroup: Codable { let name: String; let categories: [SymbolCategory] }

struct CharSection: Identifiable { let id: Int; let title: String; let chars: [String] }

/// Nomes oficiais dos caracteres, do banco do Visualizador de Caracteres do macOS (somente leitura).
final class CharNames {
    static let shared = CharNames()
    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "ipasty.charnames")
    private var cache: [String: String] = [:]

    init() {
        let path = "/System/Library/Input Methods/CharacterPalette.app/Contents/Resources/CharacterDB.sqlite3"
        if sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) != SQLITE_OK { db = nil }
    }

    func name(_ ch: String) -> String? {
        queue.sync {
            if let c = cache[ch] { return c }
            guard let db else { return nil }
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, "SELECT info FROM unihan_dict WHERE uchr = ?1 LIMIT 1", -1, &stmt, nil) == SQLITE_OK else { return nil }
            sqlite3_bind_text(stmt, 1, ch, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            var result: String?
            if sqlite3_step(stmt) == SQLITE_ROW, let c = sqlite3_column_text(stmt, 0) {
                let info = String(cString: c)
                result = info.split(separator: "|", omittingEmptySubsequences: false).first.map(String.init)
            }
            if result == nil, let s = ch.unicodeScalars.first, ch.unicodeScalars.count == 1 {
                result = s.properties.name
            }
            cache[ch] = result ?? ""
            return result
        }
    }

    /// Busca por nome (em inglês, como no Visualizador de Caracteres).
    func search(_ term: String, limit: Int = 600) -> [String] {
        queue.sync {
            guard let db else { return [] }
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            let sql = "SELECT uchr FROM unihan_dict WHERE info LIKE ?1 AND length(uchr) > 0 LIMIT ?2"
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
            let pattern = "%" + term + "%|%"
            sqlite3_bind_text(stmt, 1, pattern, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            sqlite3_bind_int(stmt, 2, Int32(limit))
            var out: [String] = []
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let c = sqlite3_column_text(stmt, 0) {
                    let s = String(cString: c)
                    if let sc = s.unicodeScalars.first, isPrintable(sc) { out.append(s) }
                }
            }
            return out
        }
    }
}

/// Esconde caracteres que nenhuma fonte do Mac sabe desenhar (apareceriam como "?").
enum GlyphCheck {
    private static let base = CTFontCreateUIFontForLanguage(.system, 20, nil)!
    private static var cache: [String: Bool] = [:]
    private static let lock = NSLock()

    static func hasGlyph(_ s: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        if let c = cache[s] { return c }
        let ns = s as NSString
        let font = CTFontCreateForString(base, ns, CFRange(location: 0, length: ns.length))
        var chars = Array(s.utf16)
        var glyphs = [CGGlyph](repeating: 0, count: chars.count)
        let ok = CTFontGetGlyphsForCharacters(font, &chars, &glyphs, chars.count)
        let name = CTFontCopyPostScriptName(font) as String
        let result = ok && name != "LastResort"
        cache[s] = result
        return result
    }
}

func isPrintable(_ s: Unicode.Scalar) -> Bool {
    switch s.properties.generalCategory {
    case .unassigned, .control, .surrogate, .privateUse, .format, .lineSeparator, .paragraphSeparator: return false
    default: return true
    }
}

// MARK: - Kaomojis

struct KaomojiGroup: Identifiable { let id: String; let items: [String] }

let kaomojiGroups: [KaomojiGroup] = [
    KaomojiGroup(id: "Clássicos", items: [":-)", ";-)", ":-D", ":-P", ":-(", ":'(", ":-O", "<3", "xD", "^_^", "^^", "-_-", "o_O", "O_o", "T_T", ">_<", "¬_¬", "*-*", "=)", ":3"]),
    KaomojiGroup(id: "Feliz", items: ["(＾▽＾)", "(◕‿◕)", "(✿◠‿◠)", "(ﾉ◕ヮ◕)ﾉ*:･ﾟ✧", "ヽ(•‿•)ノ", "(＾ｖ＾)", "(•‿•)", "(¬‿¬)", "(ᵔᴥᵔ)", "(◠‿◠)", "＼(^o^)／", "(^_^)v", "(*^▽^*)", "ヽ(´▽`)/", "(≧◡≦)", "(o^▽^o)"]),
    KaomojiGroup(id: "Amor", items: ["(♥‿♥)", "(｡♥‿♥｡)", "(づ｡◕‿‿◕｡)づ", "(っ˘з(˘⌣˘ )", "♡(｡- ω -)", "(´∀｀)♡", "(*˘︶˘*).｡.:*♡", "(ღ˘⌣˘ღ)", "( ˘ ³˘)♥", "(◍•ᴗ•◍)❤", "♡＾▽＾♡", "(灬º‿º灬)♡"]),
    KaomojiGroup(id: "Triste", items: ["(╥﹏╥)", "(ಥ﹏ಥ)", "(T⌓T)", "(；︵；)", "(っ- ‸ – ς)", "(｡•́︿•̀｡)", "( ͡ಥ ͜ʖ ͡ಥ)", "(´；ω；`)", "ಥ_ಥ", "(-_-;)", "(◞‸◟；)", "(ノ_<。)"]),
    KaomojiGroup(id: "Bravo", items: ["(╬ Ò﹏Ó)", "(ノಠ益ಠ)ノ", "ಠ_ಠ", "(¬_¬\")", "(｀ε´)", "(＃`Д´)", "ლ(ಠ益ಠლ)", "(ง'̀-'́)ง", "(눈_눈)", "(•̀ᴗ•́)و", "凸(｀⌒´メ)凸", "(╯°□°)╯"]),
    KaomojiGroup(id: "Mesa e caos", items: ["(╯°□°)╯︵ ┻━┻", "┬─┬ノ( º _ ºノ)", "(ノಠ益ಠ)ノ彡┻━┻", "┻━┻ ︵ヽ(`Д´)ﾉ︵ ┻━┻", "(┛◉Д◉)┛彡┻━┻", "┬─┬ ¯\\_(ツ)", "(ﾉ´ヮ`)ﾉ*: ･ﾟ"]),
    KaomojiGroup(id: "Surpreso", items: ["(⊙_⊙)", "(°ロ°)", "(ﾟДﾟ;)", "(O_O)", "Σ(°△°|||)", "(⊙０⊙)", "w(°ｏ°)w", "(・□・;)", "(*゜ロ゜)ノ", "щ(゜ロ゜щ)"]),
    KaomojiGroup(id: "Dar de ombros", items: ["¯\\_(ツ)_/¯", "┐(´ー｀)┌", "╮(╯▽╰)╭", "┐( ˘_˘ )┌", "ヽ(ー_ー )ノ", "¯\\_(⊙_ʖ⊙)_/¯", "┐(￣ヘ￣)┌", "(￣ω￣;)"]),
    KaomojiGroup(id: "Acenando", items: ["(＾▽＾)/", "ヾ(＾∇＾)", "(°▽°)/", "( ´ ▽ ` )ﾉ", "(＾-＾)ノ", "ヾ(・ω・*)", "(・ω・)ノ", "ヾ(☆▽☆)", "(*・ω・)ﾉ", "( ゜ω ゜)ノ"]),
    KaomojiGroup(id: "Abraço", items: ["(っ´▽｀)っ", "(つ≧▽≦)つ", "⊂(・▽・⊂)", "(づ￣ ³￣)づ", "(っ˘̩╭╮˘̩)っ", "⊂(´・ω・｀⊂)", "(⊃｡•́‿•̀｡)⊃", "༼ つ ◕_◕ ༽つ"]),
    KaomojiGroup(id: "Animais", items: ["ʕ•ᴥ•ʔ", "ʕ￫ᴥ￩ʔ", "(=^･ω･^=)", "(=①ω①=)", "ฅ^•ﻌ•^ฅ", "U・ᴥ・U", "(ᵔᴥᵔ)", "( ・ω・)", "<コ:彡", "~>°)～～～", "(・θ・)", "ᘛ⁐̤ᕐᐷ", "(°)#))<<", "/ᐠ｡ꞈ｡ᐟ\\"]),
    KaomojiGroup(id: "Outros", items: ["( ͡° ͜ʖ ͡°)", "(•_•) ( •_•)>⌐■-■ (⌐■_■)", "(☞ﾟヮﾟ)☞", "☜(ﾟヮﾟ☜)", "(ง •̀_•́)ง", "ᕦ(ò_óˇ)ᕤ", "(－‸ლ)", "(￣o￣) zzZZ", "(◔_◔)", "(ಠ‿ಠ)", "✌(-‿-)✌", "(｡◕‿◕｡)", "( ˘▽˘)っ♨", "♪~ ᕕ(ᐛ)ᕗ"]),
]

// MARK: - Estado do seletor

final class PickerStore: ObservableObject {
    @Published var tab: Tab = .clipboard
    @Published var favorites: [FavItem] = []
    @Published var recents: [FavItem] = []

    // Emoji
    let emojiGroups: [EmojiGroup] = SystemData.loadEmoji()
    @Published var emojiQuery = ""
    @Published var emojiScrollTarget: String?
    @Published var hoveredEmoji: EmojiEntry?

    // Caracteres
    let symbolGroups: [SymbolGroup] = SystemData.loadSymbols()
    @Published var symbolQuery = "" { didSet { scheduleSymbolSearch() } }
    @Published var symbolCategoryID = "PunctuationAll" { didSet { blockIndex = 0; rebuildSymbolSections() } }
    @Published var blockIndex = 0 { didSet { rebuildSymbolSections() } }
    @Published private(set) var symbolSections: [CharSection] = []
    @Published private(set) var symbolResults: [String] = []
    @Published var hoveredChar: String?
    private var searchWork: DispatchWorkItem?

    @Published var focusTick = 0

    private let dir: URL

    init() {
        dir = AppPaths.dataDir
        favorites = (try? JSONDecoder().decode([FavItem].self, from: Data(contentsOf: dir.appendingPathComponent("favorites.json")))) ?? []
        recents = (try? JSONDecoder().decode([FavItem].self, from: Data(contentsOf: dir.appendingPathComponent("recents.json")))) ?? []
        if let t = UserDefaults.standard.object(forKey: "symbolCategory") as? String { symbolCategoryID = t }
        rebuildSymbolSections()
    }

    // Favoritos
    func isFavorite(_ f: FavItem) -> Bool { favorites.contains { $0.id == f.id } }

    func toggleFavorite(_ f: FavItem) {
        if let i = favorites.firstIndex(where: { $0.id == f.id }) { favorites.remove(at: i) }
        else { favorites.insert(f, at: 0) }
        save()
    }

    func addRecent(_ f: FavItem) {
        recents.removeAll { $0.id == f.id }
        recents.insert(f, at: 0)
        if recents.count > 48 { recents.removeLast(recents.count - 48) }
        save()
    }

    func clearRecents() { recents = []; save() }

    private func save() {
        let enc = JSONEncoder()
        try? enc.encode(favorites).write(to: dir.appendingPathComponent("favorites.json"), options: .atomic)
        try? enc.encode(recents).write(to: dir.appendingPathComponent("recents.json"), options: .atomic)
    }

    // Emoji
    var emojiResults: [EmojiEntry] {
        let q = emojiQuery.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        let folded = q.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        var out: [EmojiEntry] = []
        for g in emojiGroups {
            for e in g.emojis where e.n.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).contains(folded)
                || e.k.localizedCaseInsensitiveContains(q) || e.e == q {
                out.append(e)
            }
        }
        return out
    }

    // Caracteres
    var allSymbolCategories: [SymbolCategory] { symbolGroups.flatMap { $0.categories } }
    var currentSymbolCategory: SymbolCategory? { allSymbolCategories.first { $0.id == symbolCategoryID } }

    /// Unicode completo tem centenas de blocos: mostra um bloco por vez.
    var isBlockMode: Bool { (currentSymbolCategory?.sections.count ?? 0) > 40 }

    private func rebuildSymbolSections() {
        UserDefaults.standard.set(symbolCategoryID, forKey: "symbolCategory")
        guard let cat = currentSymbolCategory else { symbolSections = []; return }
        let sections: [(Int, SymbolSection)] = isBlockMode
            ? (cat.sections.indices.contains(blockIndex) ? [(blockIndex, cat.sections[blockIndex])] : [])
            : Array(cat.sections.enumerated())
        symbolSections = sections.map { idx, s in
            var chars = s.chars
            for r in s.ranges where r.count == 2 {
                let upper = min(r[1], r[0] + 20000)
                for v in r[0]...upper {
                    if let sc = Unicode.Scalar(UInt32(v)), isPrintable(sc) { chars.append(String(Character(sc))) }
                }
            }
            return CharSection(id: idx, title: s.title, chars: chars.filter(GlyphCheck.hasGlyph))
        }
        .filter { !$0.chars.isEmpty }
    }

    private func scheduleSymbolSearch() {
        searchWork?.cancel()
        let q = symbolQuery.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { symbolResults = []; return }
        let work = DispatchWorkItem { [weak self] in
            var res: [String] = []
            // Um único caractere digitado também aparece no resultado
            if q.count == 1 { res.append(q) }
            res += CharNames.shared.search(q).filter(GlyphCheck.hasGlyph)
            DispatchQueue.main.async {
                guard let self, self.symbolQuery.trimmingCharacters(in: .whitespaces) == q else { return }
                self.symbolResults = res
            }
        }
        searchWork = work
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.2, execute: work)
    }
}
