import AppKit
import SwiftUI


struct HotkeySettingsView: View {
    private enum CaptureTarget { case hide, show }
    @State private var captureTarget: CaptureTarget?
    @State private var keyMonitor: Any?
    @State private var hideKeyCode: Int
    @State private var showKeyCode: Int
    @State private var hideKeyModifiers: Int
    @State private var showKeyModifiers: Int
    @State private var autoHideEnabled: Bool
    @State private var autoHideDelaySeconds: Double

    init() {
        let defaults = UserDefaults.standard
        let hasSaved = defaults.object(forKey: "HideKeyCode") != nil
        _hideKeyCode = State(initialValue: hasSaved ? defaults.integer(forKey: "HideKeyCode") : 122)
        _showKeyCode = State(initialValue: hasSaved ? defaults.integer(forKey: "ShowKeyCode") : 120)
        _hideKeyModifiers = State(initialValue: hasSaved ? defaults.integer(forKey: "HideKeyModifiers") : 0)
        _showKeyModifiers = State(initialValue: hasSaved ? defaults.integer(forKey: "ShowKeyModifiers") : 0)
        _autoHideEnabled = State(initialValue: defaults.bool(forKey: "AutoHideEnabled"))
        let delay = defaults.double(forKey: "AutoHideDelaySeconds")
        _autoHideDelaySeconds = State(initialValue: delay > 0 ? min(max(delay, 1), 60) : 5)
    }

    var body: some View {
        HubPage(title: "Settings", subtitle: "Keyboard shortcuts and manual cursor controls.") {
            SettingsPanel {
                HotkeyRow(title: "Hide Cursor Key", value: hideKeyText, isCapturing: captureTarget == .hide) { capture(.hide) }
                HotkeyRow(title: "Show Cursor Key", value: showKeyText, isCapturing: captureTarget == .show) { capture(.show) }
                Divider().overlay(HubStyle.line)
                Toggle("Auto-hide cursor", isOn: $autoHideEnabled).toggleStyle(.switch)
                Text("Hides the cursor automatically after the selected time. Press \(showKeyText) to show it temporarily for \(Int(autoHideDelaySeconds)) seconds.")
                    .font(.system(size: 12)).foregroundColor(.secondary)
                HStack {
                    Slider(value: $autoHideDelaySeconds, in: 1...60, step: 1).disabled(!autoHideEnabled)
                    Text("\(Int(autoHideDelaySeconds))s").font(.system(size: 13, weight: .semibold, design: .monospaced)).frame(width: 42, alignment: .trailing)
                }
                Divider().overlay(HubStyle.line)
                Text("Click a hotkey field and press the key combination you want to use. Supported modifiers: Cmd, Ctrl, Alt, Shift.")
                    .font(.system(size: 12)).foregroundColor(.secondary)
                HStack(spacing: 10) {
                    Button("Reset", action: reset)
                    Button("Save", action: save)
                }.padding(.top, 6)
            }
        }.onDisappear(perform: stopCapture)
    }
    private var hideKeyText: String { SettingsHotkeyFormatter.string(keyCode: hideKeyCode, modifiers: hideKeyModifiers) }
    private var showKeyText: String { SettingsHotkeyFormatter.string(keyCode: showKeyCode, modifiers: showKeyModifiers) }
    private func capture(_ target: CaptureTarget) {
        stopCapture()
        captureTarget = target
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode != 53 {
                let modifiers = SettingsHotkeyFormatter.carbonModifiers(event.modifierFlags)
                if target == .hide { hideKeyCode = Int(event.keyCode); hideKeyModifiers = modifiers }
                else { showKeyCode = Int(event.keyCode); showKeyModifiers = modifiers }
            }
            stopCapture()
            return nil
        }
    }
    private func stopCapture() {
        if let monitor = keyMonitor { NSEvent.removeMonitor(monitor) }
        keyMonitor = nil
        captureTarget = nil
    }
    private func reset() {
        stopCapture()
        hideKeyCode = 122; showKeyCode = 120; hideKeyModifiers = 0; showKeyModifiers = 0
        autoHideEnabled = false; autoHideDelaySeconds = 5
    }
    private func save() {
        stopCapture()
        let defaults = UserDefaults.standard
        defaults.set(hideKeyCode, forKey: "HideKeyCode")
        defaults.set(showKeyCode, forKey: "ShowKeyCode")
        defaults.set(hideKeyModifiers, forKey: "HideKeyModifiers")
        defaults.set(showKeyModifiers, forKey: "ShowKeyModifiers")
        defaults.set(autoHideEnabled, forKey: "AutoHideEnabled")
        defaults.set(Int(autoHideDelaySeconds), forKey: "AutoHideDelaySeconds")
        defaults.synchronize()
        let selector = NSSelectorFromString("reloadHotkeySettingsFromUserDefaults")
        if let delegate = NSApp.delegate as? NSObject, delegate.responds(to: selector) { delegate.perform(selector) }
    }
}

struct HotkeyRow: View {
    let title: String
    let value: String
    let isCapturing: Bool
    let action: () -> Void
    var body: some View {
        HStack {
            Text(title).font(.system(size: 13, weight: .medium)).frame(width: 150, alignment: .leading)
            Button(action: action) {
                Text(isCapturing ? "Press a key..." : value).font(.system(size: 13, weight: .medium))
                    .foregroundColor(isCapturing ? .green : .primary)
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                    .background(Color.black.opacity(isCapturing ? 0.42 : 0.28))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(isCapturing ? Color.green.opacity(0.7) : HubStyle.line))
            }.buttonStyle(.plain)
        }
    }
}
