import AppKit
import SwiftUI

@objc(ModernSettingsWindowController)
final class ModernSettingsWindowController: NSObject {
    @MainActor private static var settingsWindow: NSWindow?
    @MainActor private static let visibilityDelegate = SettingsWindowVisibilityDelegate()

    @objc static func showWindow() {
        Task { @MainActor in
            let frame = windowFrame()
            if let window = settingsWindow {
                window.title = "StealthPointer Hub"
                window.titleVisibility = .hidden
                window.setFrame(frame, display: true, animate: false)
                window.center()
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                SettingsWindowVisibilityDelegate.update(true)
                return
            }
            let window = NSWindow(contentRect: frame, styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
            window.title = "StealthPointer Hub"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            window.contentViewController = NSHostingController(rootView: StealthPointerHubView())
            window.minSize = NSSize(width: 760, height: 520)
            window.isReleasedWhenClosed = false
            window.delegate = visibilityDelegate
            window.setFrame(frame, display: true, animate: false)
            window.center()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            settingsWindow = window
            SettingsWindowVisibilityDelegate.update(true)
        }
    }

    @MainActor private static func windowFrame() -> NSRect {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let width = min(max(screen.width * 0.52, 900), screen.width - 180)
        let height = min(max(screen.height * 0.64, 580), screen.height - 140)
        return NSRect(x: screen.midX - width / 2, y: screen.midY - height / 2, width: width, height: height)
    }
}

@MainActor
private final class SettingsWindowVisibilityDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) { Task { @MainActor in Self.update(false) } }
    func windowDidMiniaturize(_ notification: Notification) { Task { @MainActor in Self.update(false) } }
    func windowDidDeminiaturize(_ notification: Notification) { Task { @MainActor in Self.update(true) } }
    static func update(_ visible: Bool) {
        let selector = NSSelectorFromString("setSettingsHubVisibleFromNumber:")
        if let delegate = NSApp.delegate as? NSObject, delegate.responds(to: selector) {
            delegate.perform(selector, with: NSNumber(value: visible))
        }
    }
}

enum HubSection: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case profiles = "Game Profiles"
    case display = "Setup Display (Experimental)"
    case settings = "Settings"
    case system = "System"
    case premium = "Premium"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.bottom.50percent"
        case .profiles: return "gamecontroller"
        case .display: return "display"
        case .settings: return "slider.horizontal.3"
        case .system: return "gearshape"
        case .premium: return "sparkles"
        }
    }
}

struct StealthPointerHubView: View {
    @State private var selectedSection = HubSection.dashboard
    @AppStorage("GameProfileEnabled") private var profileEnabled = true
    @AppStorage("ProfileShowKeys") private var showKeys = GameProfileRules.actionShow
    @AppStorage("ProfileHideKeys") private var hideKeys = GameProfileRules.actionHide
    @AppStorage("SelectedProfilePreset") private var selectedProfile = "Action"
    @AppStorage("HideKeyCode") private var hideKeyCode = 122
    @AppStorage("ShowKeyCode") private var showKeyCode = 120
    @AppStorage("HideKeyModifiers") private var hideKeyModifiers = 0
    @AppStorage("ShowKeyModifiers") private var showKeyModifiers = 0
    @AppStorage("AutoHideEnabled") private var autoHideEnabled = false
    @AppStorage("AutoHideDelaySeconds") private var autoHideDelaySeconds = 5

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    Image(systemName: "cursorarrow.motionlines").font(.system(size: 22, weight: .semibold)).foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("StealthPointer").font(.system(size: 16, weight: .semibold))
                        Text("Game cursor hub").font(.system(size: 11)).foregroundColor(.secondary)
                    }
                }.padding(.horizontal, 18).padding(.top, 44)
                VStack(spacing: 4) {
                    ForEach(HubSection.allCases) { section in
                        Button { selectedSection = section } label: {
                            HStack(spacing: 10) {
                                Image(systemName: section.symbol).frame(width: 20)
                                Text(section.rawValue)
                                Spacer(minLength: 0)
                            }.font(.system(size: 13, weight: selectedSection == section ? .semibold : .regular))
                                .foregroundColor(selectedSection == section ? .green : .secondary)
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .background(selectedSection == section ? Color.green.opacity(0.12) : Color.clear)
                                .overlay(alignment: .leading) {
                                    if selectedSection == section { Color.green.frame(width: 3) }
                                }
                        }.buttonStyle(.plain)
                    }
                }.padding(.top, 12)
                Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    Text(profileEnabled ? "Profile active" : "Profile disabled").font(.system(size: 12, weight: .medium))
                    Text("\(SettingsHotkeyFormatter.string(keyCode: hideKeyCode, modifiers: hideKeyModifiers)) arms the selected rules")
                        .font(.system(size: 11)).foregroundColor(.secondary)
                }.padding(.horizontal, 18).padding(.bottom, 18)
            }.frame(width: 300).frame(maxHeight: .infinity)
                .background(Color(red: 0.11, green: 0.12, blue: 0.12))
            content.frame(maxWidth: .infinity, maxHeight: .infinity).background(HubStyle.background)
        }.background(HubStyle.background).preferredColorScheme(.dark)
    }

    @ViewBuilder private var content: some View {
        switch selectedSection {
        case .dashboard:
            DashboardView(profileEnabled: profileEnabled, selectedProfile: selectedProfile,
                          manualKeys: "\(SettingsHotkeyFormatter.string(keyCode: hideKeyCode, modifiers: hideKeyModifiers)) / \(SettingsHotkeyFormatter.string(keyCode: showKeyCode, modifiers: showKeyModifiers))",
                          autoHideEnabled: autoHideEnabled, autoHideDelaySeconds: autoHideDelaySeconds)
        case .profiles:
            GameProfilesView(profileEnabled: $profileEnabled, showKeys: $showKeys, hideKeys: $hideKeys, selectedProfile: $selectedProfile)
        case .display: DisplayProfilesView()
        case .settings: HotkeySettingsView()
        case .system: SystemView()
        case .premium: PremiumView()
        }
    }
}
