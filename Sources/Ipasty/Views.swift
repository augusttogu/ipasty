import AppKit
import SwiftUI

// MARK: - Raiz com abas

struct RootView: View {
    @ObservedObject var picker: PickerStore
    @ObservedObject var clips: Store
    @ObservedObject var gifs: GifStore
    var app: AppDelegate

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text("Ipasty").font(.system(size: 12)).foregroundStyle(.secondary)
                Spacer()
                Button(action: { app.hidePanel() }) {
                    Image(systemName: "xmark").font(.system(size: 12))
                        .frame(width: 24, height: 24).contentShape(Rectangle())
                }
                .buttonStyle(.plain).foregroundStyle(.secondary).help("Fechar (Esc)")
            }
            .padding(.horizontal, 14).padding(.top, 10)

            HStack(spacing: 4) {
                ForEach(Tab.allCases, id: \.self) { t in
                    TabButton(tab: t, selected: picker.tab == t) {
                        picker.tab = t
                        picker.focusTick += 1
                        if t == .gif { gifs.loadIfNeeded() }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 10).padding(.top, 4)

            Group {
                switch picker.tab {
                case .favorites: FavoritesTab(picker: picker, app: app)
                case .emoji: EmojiTab(picker: picker, app: app)
                case .gif: GifTab(gifs: gifs, picker: picker, app: app)
                case .kaomoji: KaomojiTab(picker: picker, app: app)
                case .symbols: SymbolsTab(picker: picker, app: app)
                case .clipboard: ClipboardTab(store: clips, picker: picker, app: app)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VisualEffect())
        .ignoresSafeArea()
    }
}

struct TabButton: View {
    let tab: Tab
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                icon
                    .frame(width: 44, height: 26)
                    .foregroundStyle(selected ? Color.primary : Color.secondary)
                Capsule()
                    .fill(selected ? Color.accentColor : Color.clear)
                    .frame(width: 18, height: 3)
            }
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(selected ? 0.06 : 0)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(tab.title)
    }

    @ViewBuilder var icon: some View {
        switch tab {
        case .favorites: Image(systemName: "heart").font(.system(size: 17))
        case .emoji: Image(systemName: "face.smiling").font(.system(size: 18))
        case .gif:
            Text("GIF").font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 3).padding(.vertical, 1)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(lineWidth: 1.4))
        case .kaomoji: Text(";-)").font(.system(size: 15, weight: .semibold))
        case .symbols: Text("Ω%").font(.system(size: 14, weight: .semibold))
        case .clipboard: Image(systemName: "list.clipboard").font(.system(size: 17))
        }
    }
}

struct TabHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: () -> Trailing
    var body: some View {
        HStack {
            Text(title).font(.system(size: 16, weight: .semibold))
            Spacer()
            trailing()
        }
        .padding(.horizontal, 14).padding(.top, 10)
    }
}

struct SearchField: View {
    let placeholder: String
    @Binding var text: String
    let focusTick: Int
    @FocusState private var focused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.roundedBorder)
            .focused($focused)
            .padding(.horizontal, 14).padding(.top, 8).padding(.bottom, 6)
            .onAppear { DispatchQueue.main.async { focused = true } }
            .onChange(of: focusTick) { _, _ in focused = true }
    }
}

struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4).padding(.vertical, 5)
            .background(VisualEffect())
    }
}

struct EmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 30)).foregroundStyle(.tertiary)
            Text(title).font(.system(size: 13, weight: .medium))
            Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Célula de um caractere/emoji, com destaque ao passar o mouse.
struct GlyphCell: View {
    let glyph: String
    let size: CGFloat
    let fontSize: CGFloat
    let hovered: Bool
    let favorite: Bool
    let onTap: () -> Void
    let onHover: (Bool) -> Void
    let onFavorite: () -> Void

    var body: some View {
        Text(glyph)
            .font(.system(size: fontSize))
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(hovered ? 0.1 : 0)))
            .overlay(alignment: .topTrailing) {
                if favorite {
                    Image(systemName: "heart.fill").font(.system(size: 7)).foregroundStyle(.pink).padding(2)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            .onHover(perform: onHover)
            .contextMenu {
                Button(favorite ? "Remover dos favoritos" : "Adicionar aos favoritos", action: onFavorite)
                Button("Copiar sem colar") { AppDelegate.shared.copyOnly(glyph) }
            }
    }
}

// MARK: - Emojis

struct EmojiTab: View {
    @ObservedObject var picker: PickerStore
    var app: AppDelegate
    let columns = Array(repeating: GridItem(.fixed(42), spacing: 2), count: 8)

    var body: some View {
        VStack(spacing: 0) {
            SearchField(placeholder: "Buscar emoji (ex.: coração, gato, festa)", text: $picker.emojiQuery, focusTick: picker.focusTick)

            if picker.emojiQuery.isEmpty {
                HStack(spacing: 0) {
                    ForEach(picker.emojiGroups) { g in
                        Button { picker.emojiScrollTarget = g.id } label: {
                            Image(systemName: g.icon).font(.system(size: 14))
                                .frame(maxWidth: .infinity).frame(height: 24).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain).foregroundStyle(.secondary).help(g.name)
                    }
                }
                .padding(.horizontal, 12).padding(.bottom, 4)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    if picker.emojiQuery.isEmpty {
                        LazyVGrid(columns: columns, spacing: 2, pinnedViews: [.sectionHeaders]) {
                            ForEach(picker.emojiGroups) { g in
                                Section(header: SectionTitle(text: g.name).id(g.id)) {
                                    ForEach(g.emojis, id: \.e) { e in cell(e) }
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                    } else {
                        let res = picker.emojiResults
                        if res.isEmpty {
                            EmptyState(icon: "magnifyingglass", title: "Nenhum emoji encontrado", subtitle: "Tente outra palavra, em português ou inglês.")
                        } else {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(res, id: \.e) { e in cell(e) }
                            }
                            .padding(.horizontal, 14)
                        }
                    }
                }
                .onChange(of: picker.emojiScrollTarget) { _, t in
                    if let t { proxy.scrollTo(t, anchor: .top); picker.emojiScrollTarget = nil }
                }
            }

            InfoBar(glyph: picker.hoveredEmoji?.e, name: picker.hoveredEmoji?.n.capitalizedFirst, detail: nil,
                    hint: "Clique para colar · botão direito para favoritar")
        }
    }

    func cell(_ e: EmojiEntry) -> some View {
        let fav = FavItem(kind: .emoji, value: e.e, title: e.n)
        return GlyphCell(glyph: e.e, size: 42, fontSize: 26, hovered: picker.hoveredEmoji == e,
                         favorite: picker.isFavorite(fav),
                         onTap: { app.pasteText(e.e, fav: fav) },
                         onHover: { inside in
                             if inside { picker.hoveredEmoji = e } else if picker.hoveredEmoji == e { picker.hoveredEmoji = nil }
                         },
                         onFavorite: { picker.toggleFavorite(fav) })
    }
}

struct InfoBar: View {
    let glyph: String?
    let name: String?
    let detail: String?
    let hint: String

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                if let glyph {
                    Text(glyph).font(.system(size: 24)).frame(minWidth: 32)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(name ?? "").font(.system(size: 12, weight: .medium)).lineLimit(1)
                        if let detail { Text(detail).font(.system(size: 10.5, design: .monospaced)).foregroundStyle(.secondary) }
                    }
                } else {
                    Text(hint).font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .frame(height: 40)
            .padding(.horizontal, 14)
        }
    }
}

extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

// MARK: - Caracteres especiais

struct SymbolsTab: View {
    @ObservedObject var picker: PickerStore
    var app: AppDelegate
    let columns = Array(repeating: GridItem(.fixed(38), spacing: 2), count: 9)

    var body: some View {
        VStack(spacing: 0) {
            SearchField(placeholder: "Buscar pelo nome em inglês (ex.: arrow, euro, degree)", text: $picker.symbolQuery, focusTick: picker.focusTick)

            if picker.symbolQuery.isEmpty {
                HStack(spacing: 8) {
                    Menu {
                        ForEach(Array(picker.symbolGroups.enumerated()), id: \.offset) { _, g in
                            Section(g.name) {
                                ForEach(g.categories) { c in
                                    Button(c.name) { picker.symbolCategoryID = c.id }
                                }
                            }
                        }
                    } label: {
                        Text(picker.currentSymbolCategory?.name ?? "Categoria")
                    }
                    .fixedSize()

                    if picker.isBlockMode, let cat = picker.currentSymbolCategory {
                        Menu {
                            ForEach(Array(cat.sections.enumerated()), id: \.offset) { i, s in
                                Button(s.title) { picker.blockIndex = i }
                            }
                        } label: {
                            Text(cat.sections.indices.contains(picker.blockIndex) ? cat.sections[picker.blockIndex].title : "Bloco")
                        }
                        .frame(maxWidth: 190)
                    }
                    Spacer()
                }
                .padding(.horizontal, 14).padding(.bottom, 4)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(picker.symbolGroups.first?.categories ?? []) { c in
                            Chip(text: c.name.replacingOccurrences(of: " - Todos", with: "").replacingOccurrences(of: " - Tudo", with: ""),
                                 selected: c.id == picker.symbolCategoryID) { picker.symbolCategoryID = c.id }
                        }
                        ForEach(["Latin", "Greek", "Unicode"], id: \.self) { id in
                            if let c = picker.allSymbolCategories.first(where: { $0.id == id }) {
                                Chip(text: c.name, selected: c.id == picker.symbolCategoryID) { picker.symbolCategoryID = c.id }
                            }
                        }
                    }
                    .padding(.horizontal, 14).padding(.bottom, 6)
                }
            }

            ScrollView {
                if picker.symbolQuery.isEmpty {
                    LazyVGrid(columns: columns, spacing: 2, pinnedViews: [.sectionHeaders]) {
                        ForEach(picker.symbolSections) { s in
                            Section(header: Group { if !s.title.isEmpty { SectionTitle(text: s.title) } }) {
                                ForEach(Array(s.chars.enumerated()), id: \.offset) { _, ch in cell(ch) }
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                } else if picker.symbolResults.isEmpty {
                    EmptyState(icon: "magnifyingglass", title: "Nada encontrado",
                               subtitle: "A busca usa os nomes oficiais do Unicode, em inglês.")
                } else {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(Array(picker.symbolResults.enumerated()), id: \.offset) { _, ch in cell(ch) }
                    }
                    .padding(.horizontal, 14)
                }
            }
            .id(picker.symbolCategoryID + "#\(picker.blockIndex)")

            let h = picker.hoveredChar
            InfoBar(glyph: h, name: h.flatMap { CharNames.shared.name($0) }?.capitalized,
                    detail: h.map { $0.unicodeScalars.map { String(format: "U+%04X", $0.value) }.joined(separator: " ") },
                    hint: "Clique para colar · botão direito para favoritar")
        }
    }

    func cell(_ ch: String) -> some View {
        let fav = FavItem(kind: .symbol, value: ch, title: nil)
        return GlyphCell(glyph: ch, size: 38, fontSize: 20, hovered: picker.hoveredChar == ch,
                         favorite: picker.isFavorite(fav),
                         onTap: { app.pasteText(ch, fav: fav) },
                         onHover: { inside in
                             if inside { picker.hoveredChar = ch } else if picker.hoveredChar == ch { picker.hoveredChar = nil }
                         },
                         onFavorite: { picker.toggleFavorite(fav) })
    }
}

struct Chip: View {
    let text: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(text).font(.system(size: 11.5, weight: selected ? .semibold : .regular))
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Capsule().fill(selected ? Color.accentColor.opacity(0.9) : Color.primary.opacity(0.07)))
                .foregroundStyle(selected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Kaomojis

struct KaomojiTab: View {
    @ObservedObject var picker: PickerStore
    var app: AppDelegate

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4, pinnedViews: [.sectionHeaders]) {
                ForEach(kaomojiGroups) { g in
                    Section(header: SectionTitle(text: g.id)) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 6)], spacing: 6) {
                            ForEach(g.items, id: \.self) { k in TextChip(text: k, picker: picker, kind: .kaomoji, app: app) }
                        }
                    }
                }
            }
            .padding(.horizontal, 14).padding(.top, 8).padding(.bottom, 14)
        }
    }
}

struct TextChip: View {
    let text: String
    @ObservedObject var picker: PickerStore
    let kind: FavItem.Kind
    var app: AppDelegate

    var body: some View {
        let fav = FavItem(kind: kind, value: text)
        let isFav = picker.isFavorite(fav)
        Text(text)
            .font(.system(size: 13))
            .lineLimit(1).minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity).frame(height: 34)
            .padding(.horizontal, 6)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.07)))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.primary.opacity(0.08)))
            .overlay(alignment: .topTrailing) {
                if isFav { Image(systemName: "heart.fill").font(.system(size: 7)).foregroundStyle(.pink).padding(3) }
            }
            .contentShape(Rectangle())
            .onTapGesture { app.pasteText(text, fav: fav) }
            .contextMenu {
                Button(isFav ? "Remover dos favoritos" : "Adicionar aos favoritos") { picker.toggleFavorite(fav) }
                Button("Copiar sem colar") { app.copyOnly(text) }
            }
            .help(text)
    }
}

// MARK: - GIFs

struct GifTab: View {
    @ObservedObject var gifs: GifStore
    @ObservedObject var picker: PickerStore
    var app: AppDelegate

    var body: some View {
        if !gifs.hasKey {
            GifSetupView(gifs: gifs)
        } else {
            VStack(spacing: 0) {
                SearchField(placeholder: "Pesquisar no GIPHY", text: $gifs.query, focusTick: picker.focusTick)
                if let err = gifs.error {
                    Text(err).font(.system(size: 11)).foregroundStyle(.orange)
                        .padding(.horizontal, 14).padding(.bottom, 4)
                }
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                        ForEach(gifs.results) { g in
                            GifCell(gif: g, picker: picker, gifs: gifs, app: app)
                                .onAppear { if g.id == gifs.results.last?.id { gifs.loadMore() } }
                        }
                    }
                    .padding(.horizontal, 14).padding(.bottom, 8)
                    if gifs.loading { ProgressView().controlSize(.small).padding(10) }
                    if !gifs.loading && gifs.results.isEmpty && gifs.error == nil {
                        EmptyState(icon: "photo.on.rectangle", title: "Nenhum GIF", subtitle: "Tente outra busca.")
                    }
                }
                Divider()
                HStack {
                    Text("Powered by GIPHY").font(.system(size: 10.5, weight: .semibold)).foregroundStyle(.secondary)
                    Spacer()
                    Menu {
                        Button("Trocar chave do GIPHY") { gifs.removeKey() }
                    } label: { Image(systemName: "gearshape") }
                    .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
                }
                .padding(.horizontal, 14).frame(height: 30)
            }
        }
    }
}

struct GifCell: View {
    let gif: GifItem
    @ObservedObject var picker: PickerStore
    @ObservedObject var gifs: GifStore
    var app: AppDelegate

    var fav: FavItem {
        FavItem(kind: .gif, value: gif.id, title: gif.title, preview: gif.previewURL.absoluteString, full: gif.fullURL.absoluteString)
    }

    var body: some View {
        let isFav = picker.isFavorite(fav)
        let hovered = gifs.hoveredID == gif.id
        AnimatedGifView(url: gif.previewURL)
            .frame(height: 112)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.primary.opacity(hovered ? 0.6 : 0), lineWidth: 2))
            .overlay(alignment: .topTrailing) {
                if hovered || isFav {
                    Button { picker.toggleFavorite(fav) } label: {
                        Image(systemName: isFav ? "heart.fill" : "heart")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(isFav ? Color.pink : Color.white)
                            .padding(6)
                            .background(Circle().fill(Color.black.opacity(0.45)))
                    }
                    .buttonStyle(.plain).padding(5)
                    .help(isFav ? "Remover dos favoritos" : "Adicionar aos favoritos")
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { app.pasteGif(fav) }
            .onHover { inside in
                if inside { gifs.hoveredID = gif.id } else if gifs.hoveredID == gif.id { gifs.hoveredID = nil }
            }
            .contextMenu {
                Button("Colar GIF") { app.pasteGif(fav) }
                Button("Copiar link do GIF") { app.copyOnly(gif.fullURL.absoluteString) }
                Button(isFav ? "Remover dos favoritos" : "Adicionar aos favoritos") { picker.toggleFavorite(fav) }
            }
            .help(gif.title)
    }
}

struct GifSetupView: View {
    @ObservedObject var gifs: GifStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Ativar GIFs").font(.system(size: 16, weight: .semibold))
                Text("Os GIFs vêm do GIPHY, que é gratuito para uso pessoal (até 100 buscas por hora). Você só precisa criar uma chave uma vez:")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                step(1, "Entre ou crie uma conta grátis no site de desenvolvedores do GIPHY.")
                Button("Abrir developers.giphy.com") {
                    NSWorkspace.shared.open(URL(string: "https://developers.giphy.com/dashboard/?create=true")!)
                }
                .padding(.leading, 26)
                step(2, "Clique em \"Create an API Key\", escolha \"API\" e dê o nome \"Ipasty\".")
                step(3, "Copie a chave gerada e cole aqui:")

                HStack {
                    TextField("Chave do GIPHY", text: $gifs.keyDraft)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { gifs.saveKey() }
                    Button("Salvar") { gifs.saveKey() }
                        .keyboardShortcut(.defaultAction)
                        .disabled(gifs.keyDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.leading, 26)

                Text("A chave fica guardada só neste Mac.")
                    .font(.system(size: 11)).foregroundStyle(.secondary).padding(.leading, 26)
            }
            .padding(16)
        }
    }

    func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(n)").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                .frame(width: 18, height: 18).background(Circle().fill(Color.accentColor))
            Text(text).font(.system(size: 12.5)).fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Favoritos e recentes

struct FavoritesTab: View {
    @ObservedObject var picker: PickerStore
    var app: AppDelegate

    var body: some View {
        if picker.favorites.isEmpty && picker.recents.isEmpty {
            EmptyState(icon: "heart", title: "Nenhum favorito ainda",
                       subtitle: "Clique com o botão direito em um emoji, símbolo ou kaomoji, ou no ♡ de um GIF, para guardar aqui.")
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if !picker.favorites.isEmpty {
                        TabHeader(title: "Favoritos") { EmptyView() }.padding(.horizontal, -14)
                        FavCollection(items: picker.favorites, picker: picker, app: app)
                    }
                    if !picker.recents.isEmpty {
                        TabHeader(title: "Usados recentemente") {
                            Button("Limpar") { picker.clearRecents() }.controlSize(.small)
                        }
                        .padding(.horizontal, -14)
                        FavCollection(items: picker.recents, picker: picker, app: app)
                    }
                }
                .padding(.horizontal, 14).padding(.bottom, 14)
            }
        }
    }
}

struct FavCollection: View {
    let items: [FavItem]
    @ObservedObject var picker: PickerStore
    var app: AppDelegate

    var body: some View {
        let glyphs = items.filter { $0.kind == .emoji || $0.kind == .symbol }
        let texts = items.filter { $0.kind == .kaomoji || $0.kind == .text }
        let gifs = items.filter { $0.kind == .gif }
        VStack(alignment: .leading, spacing: 8) {
            if !glyphs.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(42), spacing: 2), count: 8), alignment: .leading, spacing: 2) {
                    ForEach(glyphs) { f in
                        GlyphCell(glyph: f.value, size: 42, fontSize: f.kind == .emoji ? 26 : 20, hovered: false,
                                  favorite: false,
                                  onTap: { app.pasteText(f.value, fav: f) },
                                  onHover: { _ in },
                                  onFavorite: { picker.toggleFavorite(f) })
                        .help(f.title?.capitalizedFirst ?? f.value)
                    }
                }
            }
            if !texts.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 6)], spacing: 6) {
                    ForEach(texts) { f in TextChip(text: f.value, picker: picker, kind: f.kind, app: app) }
                }
            }
            if !gifs.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                    ForEach(gifs) { f in
                        if let p = f.preview.flatMap(URL.init(string:)) {
                            AnimatedGifView(url: p)
                                .frame(height: 100).frame(maxWidth: .infinity)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.06)))
                                .contentShape(Rectangle())
                                .onTapGesture { app.pasteGif(f) }
                                .contextMenu {
                                    Button("Colar GIF") { app.pasteGif(f) }
                                    Button(picker.isFavorite(f) ? "Remover dos favoritos" : "Adicionar aos favoritos") { picker.toggleFavorite(f) }
                                }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Área de transferência

struct ClipboardTab: View {
    @ObservedObject var store: Store
    @ObservedObject var picker: PickerStore
    var app: AppDelegate

    var body: some View {
        let list = store.filtered
        VStack(alignment: .leading, spacing: 0) {
            TabHeader(title: "Área de Transferência") {
                Button("Limpar tudo") { store.clearUnpinned() }
                    .help("Apaga tudo, menos os itens fixados")
            }

            SearchField(placeholder: "Buscar…", text: $store.query, focusTick: picker.focusTick)

            if list.isEmpty {
                EmptyState(icon: "doc.on.clipboard",
                           title: store.query.isEmpty ? "Nada copiado ainda" : "Nenhum resultado",
                           subtitle: store.query.isEmpty ? "Copie algo com ⌘C e aparece aqui." : "")
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(list.enumerated()), id: \.element.id) { i, item in
                                let fav = FavItem(kind: .text, value: item.text ?? "")
                                CardView(
                                    item: item,
                                    isSelected: i == store.selected,
                                    hovering: store.hoveredID == item.id,
                                    thumb: item.kind == .image ? store.thumbnail(item) : nil,
                                    isFavorite: item.kind == .text && picker.isFavorite(fav),
                                    onPick: { app.pick(item) },
                                    onTogglePin: { store.togglePin(item.id) },
                                    onDelete: { store.delete(item.id) },
                                    onFavorite: item.kind == .text ? { picker.toggleFavorite(fav) } : nil,
                                    onHover: { inside in
                                        if inside { store.hoveredID = item.id }
                                        else if store.hoveredID == item.id { store.hoveredID = nil }
                                    })
                                .id(item.id)
                                .onTapGesture { app.pick(item) }
                            }
                        }
                        .padding(.horizontal, 14).padding(.top, 4).padding(.bottom, 14)
                    }
                    .onChange(of: store.selected) { _, new in
                        if new < list.count {
                            withAnimation(.easeOut(duration: 0.12)) { proxy.scrollTo(list[new].id) }
                        }
                    }
                }
            }
        }
    }
}
