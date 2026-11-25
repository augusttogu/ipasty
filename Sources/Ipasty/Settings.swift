// Ipasty — preferências do app e janela de Ajustes.

import AppKit
import SwiftUI
import Carbon
import ServiceManagement

// MARK: - Atalho global

enum HotKeyChoice: String, CaseIterable, Identifiable {
    case shiftCmdV, optCmdV, ctrlCmdV, ctrlOptV

    var id: String { rawValue }

    var label: String {
        switch self {
        case .shiftCmdV: return "⇧⌘V"
        case .optCmdV: return "⌥⌘V"
        case .ctrlCmdV: return "⌃⌘V"
        case .ctrlOptV: return "⌃⌥V"
        }
    }

    var carbonModifiers: UInt32 {
        switch self {
        case .shiftCmdV: return UInt32(cmdKey | shiftKey)
        case .optCmdV: return UInt32(cmdKey | optionKey)
        case .ctrlCmdV: return UInt32(cmdKey | controlKey)
        case .ctrlOptV: return UInt32(controlKey | optionKey)
        }
    }

    var menuModifiers: NSEvent.ModifierFlags {
        switch self {
        case .shiftCmdV: return [.command, .shift]
        case .optCmdV: return [.command, .option]
        case .ctrlCmdV: return [.command, .control]
        case .ctrlOptV: return [.control, .option]
        }
    }
}

// MARK: - Preferências

final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    private let d = UserDefaults.standard

    /// Abas que podem ser desligadas (a Área de Transferência fica sempre ligada).
    static let optionalTabs: [Tab] = [.favorites, .emoji, .gif, .kaomoji, .symbols]
    static let historyLimits = [50, 100, 300, 500, 1000]

    @Published var autoPaste: Bool { didSet { d.set(autoPaste, forKey: "autoPaste") } }
    @Published var saveImages: Bool { didSet { d.set(saveImages, forKey: "saveImages") } }
    @Published var maxItems: Int { didSet { d.set(maxItems, forKey: "maxItems") } }
    @Published var hotKey: HotKeyChoice {
        didSet { d.set(hotKey.rawValue, forKey: "hotKey"); AppDelegate.shared?.registerHotKey() }
    }
    @Published var disabledTabs: Set<Int> {
        didSet { d.set(Array(disabledTabs), forKey: "disabledTabs") }
    }

    /// Estado real do sistema (lido de novo a cada poucos segundos enquanto os Ajustes estão abertos).
    @Published private(set) var accessibilityGranted = AXIsProcessTrusted()
    @Published private(set) var launchAtLogin = SMAppService.mainApp.status == .enabled
    @Published var loginError: String?
    @Published var confirmClear = false

    private init() {
        autoPaste = d.object(forKey: "autoPaste") as? Bool ?? true
        saveImages = d.object(forKey: "saveImages") as? Bool ?? true
        maxItems = d.object(forKey: "maxItems") as? Int ?? 300
        hotKey = HotKeyChoice(rawValue: d.string(forKey: "hotKey") ?? "") ?? .shiftCmdV
        disabledTabs = Set(d.array(forKey: "disabledTabs") as? [Int] ?? [])
    }

    var visibleTabs: [Tab] { Tab.allCases.filter { !disabledTabs.contains($0.rawValue) } }

    func isTabEnabled(_ t: Tab) -> Bool { !disabledTabs.contains(t.rawValue) }

    func setTab(_ t: Tab, enabled: Bool) {
        guard t != .clipboard else { return }
        if enabled { disabledTabs.remove(t.rawValue) } else { disabledTabs.insert(t.rawValue) }
    }

    func refresh() {
        let ax = AXIsProcessTrusted()
        if ax != accessibilityGranted { accessibilityGranted = ax }
        let login = SMAppService.mainApp.status == .enabled
        if login != launchAtLogin { launchAtLogin = login }
    }

    // MARK: Abrir ao iniciar o Mac

    func setLaunchAtLogin(_ on: Bool) {
        loginError = nil
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            loginError = error.localizedDescription
        }
        refresh()
    }

    /// Na primeira execução liga a abertura automática (o usuário pode desligar nos Ajustes).
    func configureLoginOnFirstRun() {
        guard !d.bool(forKey: "loginConfigured") else { return }
        d.set(true, forKey: "loginConfigured")
        if SMAppService.mainApp.status != .enabled { setLaunchAtLogin(true) }
    }

    // MARK: Acessibilidade

    /// Mostra o aviso do sistema uma única vez. Depois disso o Ipasty só pede de novo
    /// quando o usuário clica em "Permitir" nos Ajustes ou no menu.
    func requestAccessibilityIfFirstTime() {
        guard autoPaste, !AXIsProcessTrusted(), !d.bool(forKey: "axPrompted") else { return }
        requestAccessibility()
    }

    func requestAccessibility() {
        d.set(true, forKey: "axPrompted")
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
        watchAccessibility()
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
        watchAccessibility()
    }

    /// Apaga a entrada antiga do Ipasty na lista de Acessibilidade (útil quando ela aparece
    /// ligada mas não funciona, por exemplo depois de atualizar de uma versão antiga) e pede de novo.
    func resetAccessibility() {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        p.arguments = ["reset", "Accessibility", Bundle.main.bundleIdentifier ?? "io.github.augusttogu.ipasty"]
        try? p.run()
        p.waitUntilExit()
        refresh()
        requestAccessibility()
    }

    private var axTimer: Timer?

    /// Confere a permissão por até 2 minutos depois de pedir, para a interface atualizar sozinha.
    private func watchAccessibility() {
        axTimer?.invalidate()
        var ticks = 0
        axTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            ticks += 1
            self?.refresh()
            if self?.accessibilityGranted == true || ticks > 120 { t.invalidate() }
        }
    }
}

// MARK: - Janela de Ajustes

final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()
    private var window: NSWindow?
    private var timer: Timer?

    func show(clips: Store) {
        if window == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 620),
                             styleMask: [.titled, .closable, .miniaturizable],
                             backing: .buffered, defer: false)
            w.title = "Ajustes do Ipasty"
            w.isReleasedWhenClosed = false
            w.delegate = self
            w.contentView = NSHostingView(rootView: SettingsView(settings: .shared, clips: clips))
            w.center()
            window = w
        }
        AppSettings.shared.refresh()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in AppSettings.shared.refresh() }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        timer?.invalidate()
        timer = nil
    }
}

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var clips: Store

    var body: some View {
        Form {
            Section("Geral") {
                Toggle("Abrir ao iniciar o Mac", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { settings.setLaunchAtLogin($0) }))
                if let err = settings.loginError {
                    Text("Não foi possível alterar: \(err)").font(.caption).foregroundStyle(.red)
                }
                Picker("Atalho para abrir", selection: $settings.hotKey) {
                    ForEach(HotKeyChoice.allCases) { Text($0.label).tag($0) }
                }
                Toggle("Colar automaticamente no app em que você estava", isOn: $settings.autoPaste)
            }

            Section {
                HStack(spacing: 10) {
                    Image(systemName: settings.accessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(settings.accessibilityGranted ? .green : .orange)
                        .font(.system(size: 18))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(settings.accessibilityGranted ? "Acessibilidade permitida" : "Acessibilidade não permitida")
                            .font(.system(size: 13, weight: .medium))
                        Text(settings.accessibilityGranted
                             ? "O Ipasty consegue colar com um clique."
                             : "Sem ela o item só é copiado; aí é só apertar ⌘V.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                if !settings.accessibilityGranted {
                    HStack {
                        Button("Permitir…") { settings.requestAccessibility() }
                        Button("Abrir Ajustes do Sistema") { settings.openAccessibilitySettings() }
                    }
                    Text("Se o Ipasty já aparece ligado na lista e mesmo assim não funciona, redefina a permissão: o macOS apaga a entrada antiga e pede de novo.")
                        .font(.caption).foregroundStyle(.secondary)
                    Button("Redefinir permissão") { settings.resetAccessibility() }
                }
            } header: {
                Text("Permissões")
            }

            Section("Abas do painel") {
                ForEach(AppSettings.optionalTabs, id: \.self) { t in
                    Toggle(t.title, isOn: Binding(
                        get: { settings.isTabEnabled(t) },
                        set: { settings.setTab(t, enabled: $0) }))
                }
                Text("A Área de Transferência fica sempre ligada.").font(.caption).foregroundStyle(.secondary)
            }

            Section("Histórico") {
                Picker("Guardar até", selection: $settings.maxItems) {
                    ForEach(AppSettings.historyLimits, id: \.self) { Text("\($0) itens").tag($0) }
                }
                Toggle("Guardar imagens copiadas", isOn: $settings.saveImages)
                Text("Senhas copiadas de gerenciadores (1Password, Bitwarden etc.) nunca são salvas.")
                    .font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button("Limpar histórico…") { settings.confirmClear = true }
                    Spacer()
                    Button("Mostrar dados no Finder") { NSWorkspace.shared.open(AppPaths.dataDir) }
                }
            }

            Section {
                HStack {
                    Text("Ipasty \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Link("GitHub", destination: URL(string: "https://github.com/augusttogu/ipasty")!)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 620)
        .alert("Limpar o histórico?", isPresented: $settings.confirmClear) {
            Button("Limpar", role: .destructive) { clips.clearUnpinned() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Os itens fixados continuam guardados.")
        }
    }
}
