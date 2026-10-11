import SwiftUI
import Combine
import CoreGraphics

@MainActor
struct DisplayProfilesView: View {
    @State private var displays: [DisplayTarget] = []
    @State private var selectedDisplayID: CGDirectDisplayID = 0
    @State private var selectedModeID = ""
    @State private var safeAspectOnly = true
    @State private var statusMessage = "Pick a game resolution. Apply saves your current macOS mode first, so Restore can return to it."
    @State private var restorePointLabel = "Saved automatically on Apply"
    @State private var showDisplayConfirmation = false
    @State private var confirmationCountdown = 15
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var selectedDisplay: DisplayTarget? { displays.first { $0.id == selectedDisplayID } }
    private var visibleModes: [DisplayModeChoice] {
        guard let display = selectedDisplay else { return [] }
        return safeAspectOnly ? display.modes.filter(\.isSafeAspect) : display.modes
    }
    private var selectedMode: DisplayModeChoice? { visibleModes.first { $0.id == selectedModeID } }

    var body: some View {
        HubPage(title: "Setup Display (Experimental)",
                subtitle: "Switch macOS display mode before launching a game, then restore it after playing.", maxWidth: 920) {
            if displays.isEmpty {
                displayStatus(symbol: "display.trianglebadge.exclamationmark", title: "Displays", value: "No active displays found")
            } else {
                VStack(alignment: .leading, spacing: 18) {
                    displayPicker
                    if let display = selectedDisplay {
                        VStack(alignment: .leading, spacing: 8) {
                            displayStatus(symbol: "rectangle.on.rectangle", title: "Current macOS mode", value: display.currentModeLabel)
                            displayStatus(symbol: "arrow.uturn.backward", title: "Restore point", value: restorePointLabel)
                            displayStatus(symbol: "aspectratio", title: "Native aspect", value: "\(display.nativeWidth) x \(display.nativeHeight)")
                        }
                        divider
                        Toggle("Show safe aspect-ratio modes only", isOn: $safeAspectOnly)
                            .toggleStyle(.switch)
                            .onChange(of: safeAspectOnly) { _ in ensureSelection() }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target Resolution").font(.system(size: 13, weight: .semibold))
                            Picker("", selection: $selectedModeID) {
                                ForEach(visibleModes) { mode in Text(mode.label).tag(mode.id) }
                            }
                            .labelsHidden().pickerStyle(.menu)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08)))
                            Text("Use Apply before launching the game, then choose the same resolution inside the game. Save Current stores the macOS mode that Restore will return to.")
                                .font(.system(size: 12)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        }
                        if let mode = selectedMode {
                            VStack(alignment: .leading, spacing: 8) {
                                displayStatus(symbol: mode.isSafeAspect ? "checkmark.circle" : "exclamationmark.triangle", title: "Aspect",
                                    value: String(format: "%.2f vs %.2f - %@", Double(mode.width) / Double(mode.height), display.nativeAspect, mode.isSafeAspect ? "safe" : "stretch risk"))
                                displayStatus(symbol: "textformat.size", title: "Clarity", value: mode.clarity.rawValue)
                            }
                        }
                        divider
                        HStack(spacing: 10) {
                            Button("Save Current", action: saveCurrent)
                            Button("Apply", action: apply)
                            Button("Restore", action: restore)
                        }
                        Text(statusMessage).font(.system(size: 12)).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .onAppear(perform: reload)
        .onDisappear(perform: autoRestore)
        .onReceive(timer) { _ in
            guard showDisplayConfirmation else { return }
            if confirmationCountdown <= 1 { autoRestore() } else { confirmationCountdown -= 1 }
        }
        .sheet(isPresented: $showDisplayConfirmation) {
            DisplayConfirmationSheet(countdown: confirmationCountdown, onKeep: keep, onRestore: restore)
        }
    }

    private var divider: some View { Divider().overlay(Color.white.opacity(0.08)) }

    private var displayPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Display").font(.system(size: 13, weight: .semibold))
            Picker("", selection: $selectedDisplayID) {
                ForEach(displays) { display in Text("\(display.name) - \(display.currentModeLabel)").tag(display.id) }
            }
            .labelsHidden().pickerStyle(.menu)
            .onChange(of: selectedDisplayID) { _ in
                if let display = selectedDisplay {
                    selectMode(width: display.currentWidth, height: display.currentHeight, refreshRate: display.currentRefreshRate)
                } else {
                    selectedModeID = ""
                }
                if selectedModeID.isEmpty { ensureSelection() }
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08)))
        }
    }

    private func displayStatus(symbol: String, title: String, value: String) -> some View {
        StatusRow(symbol: symbol, title: title, value: value)
    }

    private func reload() {
        displays = DisplayModeStore.displays()
        guard !displays.isEmpty else {
            selectedDisplayID = 0
            selectedModeID = ""
            statusMessage = "No active displays found."
            return
        }
        if let profile = DisplayModeStore.gameProfile(), displays.contains(where: { $0.id == profile.displayID }) {
            selectedDisplayID = profile.displayID
            safeAspectOnly = profile.safeAspectOnly
            selectMode(width: profile.width, height: profile.height, refreshRate: profile.refreshRate)
        } else if selectedDisplay == nil {
            selectedDisplayID = displays[0].id
        }
        ensureSelection()
        updateRestorePointLabel()
    }

    private func ensureSelection() {
        guard !visibleModes.contains(where: { $0.id == selectedModeID }) else { return }
        selectedModeID = visibleModes.first?.id ?? selectedDisplay?.modes.first?.id ?? ""
    }

    private func selectMode(width: Int, height: Int, refreshRate: Double) {
        selectedModeID = visibleModes.filter { $0.width == width && $0.height == height }
            .min { abs($0.refreshRate - refreshRate) < abs($1.refreshRate - refreshRate) }?.id ?? ""
    }

    private func updateRestorePointLabel() {
        guard let saved = DisplayModeStore.restorePoint() else {
            restorePointLabel = "Saved automatically on Apply"
            return
        }
        restorePointLabel = saved.displayID == selectedDisplayID
            ? DisplayModeFormatting.label(width: saved.width, height: saved.height, refreshRate: saved.refreshRate)
            : "Saved for another display"
    }

    private func saveCurrent() {
        guard let display = selectedDisplay else { return }
        selectMode(width: display.currentWidth, height: display.currentHeight, refreshRate: display.currentRefreshRate)
        safeAspectOnly = true
        DisplayModeStore.saveRestorePoint(StoredDisplayMode(displayID: display.id, width: display.currentWidth,
            height: display.currentHeight, refreshRate: display.currentRefreshRate))
        updateRestorePointLabel()
        statusMessage = "Saved the current macOS mode for \(display.name). Restore will return to it."
    }

    private func apply() {
        guard let display = selectedDisplay, let choice = selectedMode else {
            statusMessage = "Select a display mode before applying."
            return
        }
        DisplayModeStore.saveGameProfile(SavedDisplayProfile(displayID: display.id, displayName: display.name,
            width: choice.width, height: choice.height, refreshRate: choice.refreshRate, safeAspectOnly: safeAspectOnly))
        var succeeded = false
        if let current = CGDisplayCopyDisplayMode(display.id) {
            DisplayModeStore.saveRestorePoint(StoredDisplayMode(displayID: display.id, width: current.width,
                height: current.height, refreshRate: current.refreshRate))
            if let mode = DisplayModeStore.matchingMode(displayID: display.id, width: choice.width,
                    height: choice.height, refreshRate: choice.refreshRate) {
                succeeded = CGDisplaySetDisplayMode(display.id, mode, nil) == .success
            }
        }
        statusMessage = succeeded ? "Applied \(choice.label). Your previous macOS mode was saved for Restore."
            : "Could not apply this display mode."
        reload()
        if succeeded {
            confirmationCountdown = 15
            showDisplayConfirmation = true
            statusMessage = "Applied \(choice.label). Confirm within 15 seconds or macOS will return to the restore point."
        }
    }

    private func restore() {
        showDisplayConfirmation = false
        statusMessage = DisplayModeStore.restore() ? "Restored the saved macOS display mode."
            : "No restore point saved. Use Save Current or Apply first."
        reload()
    }

    private func autoRestore() {
        guard showDisplayConfirmation else { return }
        showDisplayConfirmation = false
        statusMessage = DisplayModeStore.restore() ? "Auto-restored the saved macOS display mode."
            : "Auto-restore failed. Use macOS Display Settings."
        reload()
    }

    private func keep() {
        showDisplayConfirmation = false
        statusMessage = "Kept the applied display mode. Use Restore to return to the saved macOS mode."
        reload()
    }
}

struct DisplayConfirmationSheet: View {
    let countdown: Int
    let onKeep: () -> Void
    let onRestore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "display").font(.system(size: 22, weight: .semibold)).foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Keep this display mode?").font(.system(size: 18, weight: .semibold))
                    Text("Auto-restore in \(countdown)s").font(.system(size: 13, weight: .medium, design: .monospaced)).foregroundStyle(.secondary)
                }
            }
            Text("If the screen looks wrong or you cannot use the app, wait. macOS will return to the saved restore point automatically.")
                .font(.system(size: 13)).foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Button("Restore Now", action: onRestore).keyboardShortcut(.cancelAction)
                Spacer()
                Button("Keep", action: onKeep).keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 420)
        .preferredColorScheme(.dark)
    }
}
