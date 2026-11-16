import AppKit
import SwiftUI

// GIFs via API do GIPHY (chave gratuita "beta": 100 chamadas por hora).
// Documentação: https://developers.giphy.com/docs/api/endpoint

struct GifItem: Identifiable, Hashable {
    let id: String
    let title: String
    let previewURL: URL   // fixed_width (200px)
    let fullURL: URL      // downsized (até ~2 MB), usado para colar
    let pageURL: String
    let aspect: CGFloat   // largura / altura
}

private struct GiphyResponse: Decodable {
    struct Img: Decodable { let url: String?; let width: String?; let height: String? }
    struct Images: Decodable {
        let fixed_width: Img?
        let downsized: Img?
        let original: Img?
    }
    struct GIF: Decodable { let id: String; let title: String?; let url: String?; let images: Images }
    struct Pagination: Decodable { let offset: Int?; let count: Int?; let total_count: Int? }
    struct Meta: Decodable { let status: Int?; let msg: String? }
    let data: [GIF]?
    let pagination: Pagination?
    let meta: Meta?
}

final class GifStore: ObservableObject {
    // Ao gerar os prints com dados de exemplo (IPASTY_DATA_DIR), ignora a chave salva.
    @Published var apiKey: String = ProcessInfo.processInfo.environment["IPASTY_DATA_DIR"] != nil
        ? "" : (UserDefaults.standard.string(forKey: "giphyKey") ?? "")
    @Published var keyDraft = ""
    @Published var query = "" { didSet { scheduleSearch() } }
    @Published private(set) var results: [GifItem] = []
    @Published private(set) var loading = false
    @Published private(set) var error: String?
    @Published var hoveredID: String?
    private var offset = 0
    private var canLoadMore = true
    private var work: DispatchWorkItem?
    private var generation = 0

    var hasKey: Bool { !apiKey.isEmpty }

    func saveKey() {
        let k = keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !k.isEmpty else { return }
        apiKey = k
        keyDraft = ""
        UserDefaults.standard.set(k, forKey: "giphyKey")
        reload()
    }

    func removeKey() {
        apiKey = ""
        UserDefaults.standard.removeObject(forKey: "giphyKey")
        results = []
    }

    /// Chamado ao abrir a aba GIF.
    func loadIfNeeded() { if results.isEmpty && hasKey && !loading { reload() } }

    private func scheduleSearch() {
        work?.cancel()
        let w = DispatchWorkItem { [weak self] in self?.reload() }
        work = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: w) // economiza a cota de 100/hora
    }

    func reload() {
        offset = 0
        canLoadMore = true
        results = []
        fetch()
    }

    func loadMore() {
        guard canLoadMore, !loading, !results.isEmpty else { return }
        fetch()
    }

    private func fetch() {
        guard hasKey else { return }
        generation += 1
        let gen = generation
        let q = query.trimmingCharacters(in: .whitespaces)
        var c = URLComponents(string: q.isEmpty ? "https://api.giphy.com/v1/gifs/trending"
                                                : "https://api.giphy.com/v1/gifs/search")!
        var items = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "limit", value: "24"),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "rating", value: "pg-13"),
            URLQueryItem(name: "bundle", value: "messaging_non_clips"),
        ]
        if !q.isEmpty {
            items.append(URLQueryItem(name: "q", value: String(q.prefix(50))))
            items.append(URLQueryItem(name: "lang", value: "pt"))
        }
        c.queryItems = items
        loading = true
        error = nil
        URLSession.shared.dataTask(with: c.url!) { [weak self] data, resp, err in
            DispatchQueue.main.async {
                guard let self, gen == self.generation else { return }
                self.loading = false
                let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
                if let err { self.error = "Sem conexão: \(err.localizedDescription)"; return }
                if status == 401 || status == 403 { self.error = "Chave do GIPHY inválida. Confira a chave nas opções abaixo."; return }
                if status == 429 { self.error = "Limite do GIPHY atingido (100 buscas por hora). Tente daqui a pouco."; return }
                guard let data, let r = try? JSONDecoder().decode(GiphyResponse.self, from: data) else {
                    self.error = "Resposta inesperada do GIPHY (HTTP \(status))."; return
                }
                let new: [GifItem] = (r.data ?? []).compactMap { g in
                    guard let p = g.images.fixed_width?.url, let pu = URL(string: p),
                          let f = g.images.downsized?.url ?? g.images.original?.url ?? g.images.fixed_width?.url,
                          let fu = URL(string: f) else { return nil }
                    let w = Double(g.images.fixed_width?.width ?? "") ?? 200
                    let h = Double(g.images.fixed_width?.height ?? "") ?? 200
                    return GifItem(id: g.id, title: g.title ?? "", previewURL: pu, fullURL: fu,
                                   pageURL: g.url ?? "", aspect: CGFloat(w / max(h, 1)))
                }
                let existing = Set(self.results.map(\.id))
                self.results += new.filter { !existing.contains($0.id) }
                self.offset += r.pagination?.count ?? new.count
                if new.isEmpty || self.offset > 480 { self.canLoadMore = false }
            }
        }.resume()
    }
}

// MARK: - Carregamento e exibição de GIF animado

final class GifLoader {
    static let shared = GifLoader()
    private let cache = NSCache<NSURL, NSData>()   // só em memória, enquanto o app está aberto
    init() { cache.totalCostLimit = 80 * 1024 * 1024 }

    func data(_ url: URL, _ done: @escaping (Data?) -> Void) {
        if let d = cache.object(forKey: url as NSURL) { done(d as Data); return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            if let data { self?.cache.setObject(data as NSData, forKey: url as NSURL, cost: data.count) }
            DispatchQueue.main.async { done(data) }
        }.resume()
    }
}

struct AnimatedGifView: NSViewRepresentable {
    let url: URL

    final class Coordinator { var url: URL? }
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSImageView {
        let v = NSImageView()
        v.animates = true
        v.imageScaling = .scaleProportionallyUpOrDown
        v.canDrawSubviewsIntoLayer = true
        v.wantsLayer = true
        v.layer?.cornerRadius = 6
        v.layer?.masksToBounds = true
        v.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        v.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        load(into: v, context: context)
        return v
    }

    func updateNSView(_ v: NSImageView, context: Context) {
        if context.coordinator.url != url { load(into: v, context: context) }
    }

    private func load(into v: NSImageView, context: Context) {
        context.coordinator.url = url
        v.image = nil
        let u = url
        GifLoader.shared.data(u) { data in
            guard context.coordinator.url == u, let data, let img = NSImage(data: data) else { return }
            v.image = img
        }
    }
}
