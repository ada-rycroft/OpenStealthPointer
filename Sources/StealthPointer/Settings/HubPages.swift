import SwiftUI

struct DashboardView: View {
    let profileEnabled: Bool
    let selectedProfile: String
    let manualKeys: String
    let autoHideEnabled: Bool
    let autoHideDelaySeconds: Int
    var body: some View {
        HubPage(title: "Dashboard", subtitle: "Current runtime state and quick actions.") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], alignment: .leading, spacing: 12) {
                MetricTile(title: "Game Profile", value: profileEnabled ? "Enabled" : "Disabled", symbol: "gamecontroller")
                MetricTile(title: "Active Profile", value: selectedProfile, symbol: "slider.horizontal.3")
                MetricTile(title: "Manual Keys", value: manualKeys, symbol: "keyboard")
                MetricTile(title: "Auto-hide", value: autoHideEnabled ? "On (\(autoHideDelaySeconds)s)" : "Off", symbol: autoHideEnabled ? "timer" : "timer.circle")
            }
        }
    }
}

struct SystemView: View {
    var body: some View {
        HubPage(title: "System", subtitle: "Permissions needed for global keyboard monitoring.") {
            SettingsPanel {
                StatusRow(symbol: "accessibility", title: "Accessibility", value: "Required")
                StatusRow(symbol: "keyboard", title: "Input Monitoring", value: "Recommended")
                StatusRow(symbol: "lock.shield", title: "Engine", value: "Objective-C")
                StatusRow(symbol: "paintpalette", title: "Interface", value: "SwiftUI")
            }
        }
    }
}

struct PremiumView: View {
    var body: some View {
        HubPage(title: "Premium", subtitle: "A placeholder for future profile packs and automation.") {
            SettingsPanel {
                StatusRow(symbol: "person.crop.circle.badge.checkmark", title: "Account", value: "Not required")
                StatusRow(symbol: "square.stack.3d.up", title: "Multiple game profiles", value: "Planned")
                StatusRow(symbol: "wand.and.stars", title: "Auto profile switching", value: "Planned")
            }
        }
    }
}
