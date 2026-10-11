import SwiftUI

struct GameProfilesView: View {
    @Binding var profileEnabled: Bool
    @Binding var showKeys: String
    @Binding var hideKeys: String
    @Binding var selectedProfile: String
    @AppStorage("SavedGameProfiles") private var savedProfilesData = "[]"
    @State private var profileName = ""
    @State private var selectedMode = ProfileMode.action
    @State private var selectedSavedProfileID = ""
    private var savedProfiles: [SavedGameProfile] { GameProfileRules.decode(savedProfilesData) }

    var body: some View {
        HubPage(title: "Game Profile", subtitle: "Keyboard rules for switching cursor visibility while a game is active.", maxWidth: 1080) {
            SettingsPanel {
                Toggle("Game Profile", isOn: $profileEnabled).toggleStyle(.switch)
                Divider().overlay(HubStyle.line)
                Text("Preset").font(.system(size: 14, weight: .semibold))
                HStack(spacing: 10) {
                    ForEach(ProfileMode.allCases) { mode in
                        PresetButton(title: mode.rawValue) { select(mode) }
                    }
                }
                Divider().overlay(HubStyle.line)
                if selectedMode == .ownGames {
                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Templates").font(.system(size: 14, weight: .semibold))
                            HStack(spacing: 10) {
                                PresetButton(title: "Action Template") {
                                    selectedProfile = "Own Games"; showKeys = GameProfileRules.actionShow; hideKeys = GameProfileRules.actionHide
                                }
                                PresetButton(title: "Strategy Template") {
                                    selectedProfile = "Own Games"; showKeys = GameProfileRules.strategyShow; hideKeys = GameProfileRules.strategyHide
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Own Games").font(.system(size: 14, weight: .semibold))
                            HStack {
                                TextField("Game name", text: $profileName).textFieldStyle(.plain).padding(9)
                                    .background(Color.black.opacity(0.28)).clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                Button("Save Game", action: save)
                            }
                            if !savedProfiles.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Saved").font(.system(size: 12, weight: .semibold))
                                    HStack {
                                        Picker("Select saved game", selection: $selectedSavedProfileID) {
                                            Text("Select saved game").tag("")
                                            ForEach(savedProfiles) { profile in Text(profile.name).tag(profile.id.uuidString) }
                                        }.labelsHidden().frame(maxWidth: .infinity)
                                            .padding(.horizontal, 10).padding(.vertical, 6)
                                            .background(Color.black.opacity(0.24))
                                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(HubStyle.line))
                                            .onChange(of: selectedSavedProfileID) { value in load(value) }
                                        Button { deleteSelected() } label: { Image(systemName: "trash").font(.system(size: 12, weight: .semibold)) }
                                            .buttonStyle(.plain)
                                            .foregroundColor(savedProfiles.contains(where: { $0.id.uuidString == selectedSavedProfileID }) ? .secondary : .secondary.opacity(0.45))
                                            .disabled(!savedProfiles.contains(where: { $0.id.uuidString == selectedSavedProfileID }))
                                    }
                                }
                            }
                        }
                        RuleEditor(showKeys: $showKeys, hideKeys: $hideKeys, selectedProfile: $selectedProfile)
                    }
                } else {
                    FixedProfileSummary(showKeys: showKeys, hideKeys: hideKeys)
                }
            }
        }.onAppear(perform: synchronizeSelection)
    }

    private func select(_ mode: ProfileMode) {
        selectedMode = mode
        switch mode {
        case .action:
            selectedSavedProfileID = ""; selectedProfile = "Action"
            showKeys = GameProfileRules.actionShow; hideKeys = GameProfileRules.actionHide
        case .strategy:
            selectedSavedProfileID = ""; selectedProfile = "Strategy"
            showKeys = GameProfileRules.strategyShow; hideKeys = GameProfileRules.strategyHide
        case .ownGames:
            if selectedProfile == "Action" || selectedProfile == "Strategy" { selectedProfile = "Own Games" }
        }
    }
    private func synchronizeSelection() {
        selectedMode = ProfileMode(rawValue: selectedProfile) ?? .ownGames
        guard selectedMode == .ownGames else { return }
        profileName = selectedProfile == "Own Games" ? "" : selectedProfile
        selectedSavedProfileID = savedProfiles.first(where: { $0.name == selectedProfile })?.id.uuidString ?? ""
    }
    private func save() {
        let result = GameProfileRules.saving(name: profileName, selectedProfile: selectedProfile,
                                            showKeys: showKeys, hideKeys: hideKeys, in: savedProfiles)
        savedProfilesData = GameProfileRules.encode(result.profiles)
        selectedProfile = result.profile.name
        profileName = result.profile.name
        selectedSavedProfileID = result.profile.id.uuidString
    }
    private func load(_ id: String) {
        guard let profile = savedProfiles.first(where: { $0.id.uuidString == id }) else { return }
        selectedProfile = profile.name; profileName = profile.name
        showKeys = profile.showKeys; hideKeys = profile.hideKeys
    }
    private func deleteSelected() {
        guard let profile = savedProfiles.first(where: { $0.id.uuidString == selectedSavedProfileID }) else { return }
        savedProfilesData = GameProfileRules.encode(savedProfiles.filter { $0.id != profile.id })
        if selectedProfile == profile.name { selectedProfile = "Own Games" }
        selectedSavedProfileID = ""
    }
}

struct FixedProfileSummary: View {
    let showKeys: String
    let hideKeys: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RuleSummaryRow(title: "Show Cursor Keys", value: showKeys)
            RuleSummaryRow(title: "Hide Cursor Keys", value: hideKeys)
        }
    }
}

struct RuleSummaryRow: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
            Text(value.isEmpty ? "-" : value).font(.system(size: 13, design: .monospaced)).lineLimit(2)
                .padding(9).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RuleEditor: View {
    enum KeyboardTarget { case show, hide }
    struct KeySpec {
        let title: String
        var units: CGFloat = 1
    }
    @Binding var showKeys: String
    @Binding var hideKeys: String
    @Binding var selectedProfile: String
    @State private var keyboardTarget = KeyboardTarget.show
    private let keyUnit: CGFloat = 36
    private let keyHeight: CGFloat = 34
    private let keySpacing: CGFloat = 4
    private var currentRules: String { keyboardTarget == .show ? showKeys : hideKeys }

    private let rows: [[KeySpec]] = [
        ["Esc", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"].map { KeySpec(title: $0) },
        [KeySpec(title: "`"), KeySpec(title: "1"), KeySpec(title: "2"), KeySpec(title: "3"), KeySpec(title: "4"), KeySpec(title: "5"), KeySpec(title: "6"), KeySpec(title: "7"), KeySpec(title: "8"), KeySpec(title: "9"), KeySpec(title: "0"), KeySpec(title: "-"), KeySpec(title: "="), KeySpec(title: "Backspace", units: 2)],
        [KeySpec(title: "Tab", units: 1.5), KeySpec(title: "Q"), KeySpec(title: "W"), KeySpec(title: "E"), KeySpec(title: "R"), KeySpec(title: "T"), KeySpec(title: "Z"), KeySpec(title: "U"), KeySpec(title: "I"), KeySpec(title: "O"), KeySpec(title: "P"), KeySpec(title: "["), KeySpec(title: "]"), KeySpec(title: "\\", units: 1.5)],
        [KeySpec(title: "Caps", units: 1.75), KeySpec(title: "A"), KeySpec(title: "S"), KeySpec(title: "D"), KeySpec(title: "F"), KeySpec(title: "G"), KeySpec(title: "H"), KeySpec(title: "J"), KeySpec(title: "K"), KeySpec(title: "L"), KeySpec(title: ";"), KeySpec(title: "'"), KeySpec(title: "Enter", units: 2.25)],
        [KeySpec(title: "Shift", units: 2.25), KeySpec(title: "Y"), KeySpec(title: "X"), KeySpec(title: "C"), KeySpec(title: "V"), KeySpec(title: "B"), KeySpec(title: "N"), KeySpec(title: "M"), KeySpec(title: ","), KeySpec(title: "."), KeySpec(title: "/"), KeySpec(title: "Shift", units: 2.75)],
        [KeySpec(title: "Ctrl", units: 1.25), KeySpec(title: "Alt", units: 1.25), KeySpec(title: "Cmd", units: 1.25), KeySpec(title: "Space", units: 5), KeySpec(title: "Cmd", units: 1.25), KeySpec(title: "AltGr", units: 1.25), KeySpec(title: "Ctrl", units: 1.25)]
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            field(title: "Show Cursor Keys", binding: $showKeys)
            field(title: "Hide Cursor Keys", binding: $hideKeys)
            Divider().overlay(HubStyle.line)
            HStack {
                Text("Virtual Keyboard").font(.system(size: 13, weight: .semibold))
                Spacer()
                HStack(spacing: 8) {
                KeyboardTargetButton(title: "Show Cursor", isSelected: keyboardTarget == .show) { keyboardTarget = .show }
                KeyboardTargetButton(title: "Hide Cursor", isSelected: keyboardTarget == .hide) { keyboardTarget = .hide }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: keySpacing) {
                        ForEach(rows.indices, id: \.self) { row in keyRow(rows[row]) }
                    }
                    VStack(spacing: keySpacing) {
                        keyRow(["PrtScr", "ScrLk", "Pause"].map { KeySpec(title: $0) })
                        keyRow(["Insert", "Home", "PageUp"].map { KeySpec(title: $0) })
                        keyRow(["Del", "End", "PageDown"].map { KeySpec(title: $0) })
                        Spacer().frame(height: keyHeight + keySpacing)
                        keyRow([KeySpec(title: "", units: 1), KeySpec(title: "Up"), KeySpec(title: "", units: 1)])
                        keyRow(["Left", "Down", "Right"].map { KeySpec(title: $0) })
                    }
                    numpad
                }.padding(8).background(Color.black.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(HubStyle.line))
            }
        }
    }
    private func field(title: String, binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 13, weight: .semibold))
            TextField("", text: Binding(get: { binding.wrappedValue }, set: {
                binding.wrappedValue = $0; selectedProfile = "Own Games"
            })).textFieldStyle(.plain).padding(10).background(Color.black.opacity(0.28))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous)).font(.system(size: 13, design: .monospaced))
        }
    }
    private func keyRow(_ specs: [KeySpec]) -> some View {
        HStack(spacing: keySpacing) {
            ForEach(specs.indices, id: \.self) { index in
                if specs[index].title.isEmpty { Color.clear.frame(width: keyUnit, height: keyHeight) }
                else { key(specs[index]) }
            }
        }
    }
    private func key(_ spec: KeySpec) -> some View {
        VirtualKeyButton(title: spec.title, width: keyUnit * spec.units + keySpacing * max(spec.units - 1, 0), height: keyHeight, isSelected: ProfileKeyboardTokens.contains(spec.title, in: currentRules)) {
            let rules = ProfileKeyboardTokens.toggle(spec.title, in: currentRules)
            if keyboardTarget == .show { showKeys = rules } else { hideKeys = rules }
            selectedProfile = "Own Games"
        }
    }
    private var numpad: some View {
        VStack(alignment: .leading, spacing: keySpacing) {
            keyRow(["Clear", "Num/", "Num*", "Num-"].map { KeySpec(title: $0) })
            keyRow(["Num7", "Num8", "Num9", "Num+"].map { KeySpec(title: $0) })
            keyRow(["Num4", "Num5", "Num6", "NumEnter"].map { KeySpec(title: $0) })
            keyRow(["Num1", "Num2", "Num3", "Num."].map { KeySpec(title: $0) })
            keyRow([KeySpec(title: "Num0", units: 2), KeySpec(title: "Num.")])
        }
    }
}

struct KeyboardTargetButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .black : .white.opacity(0.82))
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(isSelected ? Color.green : Color.black.opacity(0.26))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(isSelected ? Color.green.opacity(0.85) : Color.white.opacity(0.1)))
        }.buttonStyle(.plain)
    }
}

struct VirtualKeyButton: View {
    let title: String
    let width: CGFloat
    let height: CGFloat
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.system(size: 11, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.72)
                .frame(width: width, height: height)
                .background(isSelected ? Color.green.opacity(0.24) : Color.black.opacity(0.24))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(isSelected ? Color.green.opacity(0.65) : HubStyle.line))
        }.buttonStyle(.plain)
    }
}
