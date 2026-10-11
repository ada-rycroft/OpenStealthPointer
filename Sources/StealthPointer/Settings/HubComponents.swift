import SwiftUI

enum HubStyle {
    static let background = Color(red: 0.07, green: 0.08, blue: 0.08)
    static let panel = Color(red: 0.12, green: 0.13, blue: 0.13)
    static let line = Color.white.opacity(0.08)
}

struct HubPage<Content: View>: View {
    let title: String
    let subtitle: String
    var maxWidth: CGFloat = 780
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.system(size: 30, weight: .semibold))
                    Text(subtitle).font(.system(size: 13)).foregroundColor(.secondary)
                }
                content
            }
            .padding(32).frame(maxWidth: maxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

struct SettingsPanel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 18) { content }
            .padding(20)
            .background(HubStyle.panel)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(HubStyle.line))
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: symbol).font(.system(size: 20, weight: .semibold)).foregroundColor(.green)
            Text(value).font(.system(size: 22, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.72)
            Text(title).font(.system(size: 12)).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).frame(height: 116, alignment: .leading)
            .padding(18).background(HubStyle.panel)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(HubStyle.line))
    }
}

struct StatusRow: View {
    let symbol: String
    let title: String
    let value: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).frame(width: 22).foregroundColor(.green)
            Text(title)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }.font(.system(size: 13)).padding(.vertical, 6)
    }
}

struct PresetButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 12).padding(.vertical, 7)
        }.buttonStyle(.bordered)
    }
}
