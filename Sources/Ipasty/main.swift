// Ipasty — área de transferência, emojis, GIFs e caracteres especiais na barra de menus do macOS.
// Atalho padrão: ⇧⌘V abre o histórico. ↑/↓ navega, Enter cola, ⌘1–9 escolhe rápido,
// ⌘P fixa/desafixa, ⌘⌫ apaga o item, Esc fecha.

import AppKit
import SwiftUI
import Carbon
import CryptoKit
import ServiceManagement

// MARK: - Painel

final class KeyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate {
    static var shared: AppDelegate!
    let store = Store()
    let picker = PickerStore()
    let gifs = GifStore()
    lazy var watcher = ClipboardWatcher(store: store)
    var statusItem: NSStatusItem!
    var panel: KeyPanel!
    var hotKeyRef: EventHotKeyRef?
    var keyMonitor: Any?

    var autoPaste: Bool {
        get { UserDefaults.standard.object(forKey: "autoPaste") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "autoPaste") }
    }

    func applicationDidFinishLaunching(_ note: Notification) {
        AppDelegate.shared = self
        AppPaths.migrateDefaults()
        setupStatusItem()
        setupPanel()
        registerHotKey()
        watcher.start()
        // Modo de teste: Ipasty --snapshot arquivo.png → salva uma imagem do painel e sai
        if let i = CommandLine.arguments.firstIndex(of: "--snapshot"), i + 1 < CommandLine.arguments.count {
            let path = CommandLine.arguments[i + 1]
            if let a = CommandLine.arguments.firstIndex(of: "--appearance"), a + 1 < CommandLine.arguments.count {
                NSApp.appearance = NSAppearance(named: CommandLine.arguments[a + 1] == "light" ? .aqua : .darkAqua)
            }
            showPanel()
            if let t = CommandLine.arguments.firstIndex(of: "--tab"), t + 1 < CommandLine.arguments.count,
               let n = Int(CommandLine.arguments[t + 1]), let tab = Tab(rawValue: n) {
                picker.tab = tab
                if tab == .gif { gifs.loadIfNeeded() }
            }
            if let q = CommandLine.arguments.firstIndex(of: "--query"), q + 1 < CommandLine.arguments.count {
                let text = CommandLine.arguments[q + 1]
                switch picker.tab {
                case .emoji: picker.emojiQuery = text
                case .symbols: picker.symbolQuery = text
                default: store.query = text
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                if let v = self.panel.contentView, let rep = v.bitmapImageRepForCachingDisplay(in: v.bounds) {
                    v.cacheDisplay(in: v.bounds, to: rep)
                    try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
                }
                NSApp.terminate(nil)
            }
            return
        }
        if autoPaste && !AXIsProcessTrusted() { requestAccessibility() }
    }

    // Barra de menus
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Ipasty")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        menu.addItem(withTitle: "Abrir área de transferência", action: #selector(showPanelFromMenu), keyEquivalent: "v")
            .keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(withTitle: "Emojis", action: #selector(showEmoji), keyEquivalent: "")
        menu.addItem(withTitle: "GIFs", action: #selector(showGif), keyEquivalent: "")
        menu.addItem(withTitle: "Caracteres especiais", action: #selector(showSymbols), keyEquivalent: "")
        menu.addItem(withTitle: "Favoritos", action: #selector(showFavorites), keyEquivalent: "")
        menu.addItem(.separator())

        let ap = menu.addItem(withTitle: "Colar automaticamente", action: #selector(toggleAutoPaste), keyEquivalent: "")
        ap.state = autoPaste ? .on : .off
        if autoPaste && !AXIsProcessTrusted() {
            menu.addItem(withTitle: "⚠︎ Permitir Acessibilidade…", action: #selector(requestAccessibility), keyEquivalent: "")
        }
        let login = menu.addItem(withTitle: "Abrir ao iniciar o Mac", action: #selector(toggleLogin), keyEquivalent: "")
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off

        menu.addItem(.separator())
        menu.addItem(withTitle: "Limpar histórico (mantém fixados)", action: #selector(clearHistory), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Sair do Ipasty", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        for item in menu.items where item.action != #selector(NSApplication.terminate(_:)) { item.target = self }
    }

    @objc func showPanelFromMenu() { showPanel() }
    @objc func showEmoji() { showPanel(tab: .emoji) }
    @objc func showGif() { showPanel(tab: .gif) }
    @objc func showSymbols() { showPanel(tab: .symbols) }
    @objc func showFavorites() { showPanel(tab: .favorites) }

    @objc func toggleAutoPaste() {
        autoPaste.toggle()
        if autoPaste && !AXIsProcessTrusted() { requestAccessibility() }
    }

    @objc func requestAccessibility() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }

    @objc func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
        } catch {
            let a = NSAlert()
            a.messageText = "Não foi possível alterar a abertura automática"
            a.informativeText = error.localizedDescription
            a.runModal()
        }
    }

    @objc func clearHistory() { store.clearUnpinned() }

    // Painel flutuante
    func setupPanel() {
        panel = KeyPanel(contentRect: NSRect(x: 0, y: 0, width: 410, height: 560),
                         styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
                         backing: .buffered, defer: false)
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton].forEach {
            panel.standardWindowButton($0)?.isHidden = true
        }
        let host = NSHostingView(rootView: RootView(picker: picker, clips: store, gifs: gifs, app: self))
        host.sizingOptions = []
        panel.contentView = host
        panel.setContentSize(NSSize(width: 410, height: 560))

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            guard let self, self.panel.isKeyWindow else { return e }
            return self.handleKey(e) ? nil : e
        }
    }

    func handleKey(_ e: NSEvent) -> Bool {
        let list = store.filtered
        let cmd = e.modifierFlags.contains(.command)
        let flags = e.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if Int(e.keyCode) == kVK_Escape { hidePanel(); return true }

        // ⌃Tab / ⌃⇧Tab troca de aba
        if Int(e.keyCode) == kVK_Tab && flags.contains(.control) {
            let all = Tab.allCases
            let i = all.firstIndex(of: picker.tab) ?? 0
            let next = flags.contains(.shift) ? (i - 1 + all.count) % all.count : (i + 1) % all.count
            picker.tab = all[next]
            picker.focusTick += 1
            if picker.tab == .gif { gifs.loadIfNeeded() }
            return true
        }

        // Sem menu "Editar", os atalhos de texto precisam ser repassados à mão
        if cmd, let c = e.charactersIgnoringModifiers?.lowercased() {
            let edit: [String: Selector] = ["v": #selector(NSText.paste(_:)), "c": #selector(NSText.copy(_:)),
                                            "x": #selector(NSText.cut(_:)), "a": #selector(NSText.selectAll(_:)),
                                            "z": Selector(("undo:"))]
            if let sel = edit[c], !flags.contains(.shift) {
                NSApp.sendAction(sel, to: nil, from: nil)
                return true
            }
        }

        guard picker.tab == .clipboard else { return false }

        switch Int(e.keyCode) {
        case kVK_DownArrow:
            if !list.isEmpty { store.selected = min(store.selected + 1, list.count - 1) }
            return true
        case kVK_UpArrow:
            store.selected = max(store.selected - 1, 0); return true
        case kVK_Return, kVK_ANSI_KeypadEnter:
            if store.selected < list.count { pick(list[store.selected]) }
            return true
        case kVK_Delete where cmd:
            if store.selected < list.count { store.delete(list[store.selected].id) }
            return true
        case kVK_ANSI_P where cmd:
            if store.selected < list.count { store.togglePin(list[store.selected].id) }
            return true
        default: break
        }
        if cmd, let c = e.charactersIgnoringModifiers, let n = Int(c), (1...9).contains(n) {
            if n - 1 < list.count { pick(list[n - 1]) }
            return true
        }
        return false
    }

    func togglePanel() { panel.isVisible ? hidePanel() : showPanel() }

    func showPanel(tab: Tab = .clipboard) {
        store.query = ""
        store.selected = 0
        picker.tab = tab
        if tab == .gif { gifs.loadIfNeeded() }
        // Posiciona perto do cursor, sem sair da tela
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main!
        let vf = screen.visibleFrame
        let size = panel.frame.size
        var origin = NSPoint(x: mouse.x - 20, y: mouse.y - size.height + 20)
        origin.x = min(max(origin.x, vf.minX + 8), vf.maxX - size.width - 8)
        origin.y = min(max(origin.y, vf.minY + 8), vf.maxY - size.height - 8)
        panel.setFrameOrigin(origin)
        panel.makeKeyAndOrderFront(nil)
        picker.focusTick += 1
    }

    func hidePanel() { panel.orderOut(nil) }

    func windowDidResignKey(_ notification: Notification) { hidePanel() }

    func pick(_ item: ClipItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.kind {
        case .text: pb.setString(item.text ?? "", forType: .string)
        case .image:
            if let d = store.imageData(item) {
                pb.setData(d, forType: .png)
                if let tiff = NSImage(data: d)?.tiffRepresentation { pb.setData(tiff, forType: .tiff) }
            }
        }
        watcher.markOwnWrite()
        store.moveToTop(item.id)
        hidePanel()
        if autoPaste && AXIsProcessTrusted() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { Self.sendCmdV() }
        }
    }

    /// Cola um texto (emoji, símbolo, kaomoji) no app em que você estava.
    func pasteText(_ text: String, fav: FavItem?) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        watcher.markOwnWrite()
        if let fav { picker.addRecent(fav) }
        finishPaste()
    }

    /// Só copia, sem colar e sem fechar o painel.
    func copyOnly(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        watcher.markOwnWrite()
    }

    /// Baixa o GIF e coloca na área de transferência como imagem animada + arquivo .gif.
    func pasteGif(_ fav: FavItem) {
        guard let s = fav.full ?? fav.preview, let url = URL(string: s) else { return }
        picker.addRecent(fav)
        GifLoader.shared.data(url) { [weak self] data in
            guard let self, let data else { NSSound.beep(); return }
            let dir = FileManager.default.temporaryDirectory.appendingPathComponent("Ipasty-GIFs", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let file = dir.appendingPathComponent("\(fav.value).gif")
            try? data.write(to: file)
            let item = NSPasteboardItem()
            item.setData(data, forType: NSPasteboard.PasteboardType("com.compuserve.gif"))
            item.setString(file.absoluteString, forType: .fileURL)
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.writeObjects([item])
            self.watcher.markOwnWrite()
            self.finishPaste()
        }
    }

    private func finishPaste() {
        hidePanel()
        if autoPaste && AXIsProcessTrusted() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { Self.sendCmdV() }
        }
    }

    static func sendCmdV() {
        let src = CGEventSource(stateID: .combinedSessionState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        let up = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    // Atalho global ⇧⌘V (Carbon — não precisa de permissão)
    func registerHotKey() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            DispatchQueue.main.async { AppDelegate.shared.togglePanel() }
            return noErr
        }, 1, &spec, nil, nil)
        let id = EventHotKeyID(signature: OSType(0x43505944), id: 1) // 'CPYD'
        RegisterEventHotKey(UInt32(kVK_ANSI_V), UInt32(cmdKey | shiftKey), id,
                            GetApplicationEventTarget(), 0, &hotKeyRef)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
