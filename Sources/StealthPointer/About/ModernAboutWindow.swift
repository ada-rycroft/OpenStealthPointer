import AppKit
import SwiftUI

@objc(ModernAboutWindowController)
final class ModernAboutWindowController: NSObject {
    @MainActor private static var window: NSWindow?

    @objc static func showWindow() {
        Task { @MainActor in
            if let window {
                window.setContentSize(NSSize(width: 520, height: 620))
                window.center()
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
            let hostingController = NSHostingController(rootView: StealthPointerAboutView())
            let newWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 620),
                                     styleMask: [.titled, .closable, .fullSizeContentView],
                                     backing: .buffered, defer: false)
            newWindow.title = "About StealthPointer"
            newWindow.titlebarAppearsTransparent = true
            newWindow.isMovableByWindowBackground = true
            newWindow.contentViewController = hostingController
            newWindow.isReleasedWhenClosed = false
            newWindow.center()
            newWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            window = newWindow
        }
    }
}

private struct StealthPointerAboutView: View {
    @State private var isPulsing = false
    private var version: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0" }
    private var build: String { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1" }

    var body: some View {
        ZStack {
            StealthVisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow).ignoresSafeArea()
            Color(red: 0.05, green: 0.07, blue: 0.06).opacity(0.86).ignoresSafeArea()
            StealthParticleField().opacity(0.46).blendMode(.screen)
            VStack(spacing: 22) {
                VStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(LinearGradient(colors: [.green.opacity(0.36), .mint.opacity(0.20), .black.opacity(0.18)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 130, height: 130)
                            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(.green.opacity(0.28), lineWidth: 1))
                            .shadow(color: .green.opacity(0.26), radius: 28, x: 0, y: 14)
                            .scaleEffect(isPulsing ? 1.02 : 0.98)
                        Image(systemName: "cursorarrow.motionlines")
                            .font(.system(size: 58, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.38), radius: 14, x: 0, y: 8)
                            .scaleEffect(isPulsing ? 1.0 : 0.94)
                    }
                    VStack(spacing: 5) {
                        Text("StealthPointer").font(.system(size: 40, weight: .bold)).foregroundStyle(.white)
                        Text("Game Cursor Hub").font(.headline).foregroundStyle(.white.opacity(0.78))
                        Text("v\(version)").font(.subheadline.weight(.medium)).foregroundStyle(.white.opacity(0.68))
                    }
                    Text("A macOS menu bar utility for keeping the game cursor hidden during gameplay and ready when menus, maps, or inventory need it.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.74))
                        .multilineTextAlignment(.center).lineLimit(4).frame(maxWidth: 410)
                }
                VStack(spacing: 10) {
                    AboutFeatureRow(icon: "cursorarrow.motionlines", title: "Stealth cursor control", subtitle: "Threaded hide and show engine tuned for Wine and game windows")
                    AboutFeatureRow(icon: "gamecontroller", title: "Game profiles", subtitle: "Action, Strategy, and saved Own Games profiles with custom key rules")
                    AboutFeatureRow(icon: "keyboard", title: "Hotkeys and virtual keyboard", subtitle: "Global F1/F2 controls plus profile switching for inventory and gameplay")
                }
                HStack(spacing: 10) {
                    AboutInfoPill(icon: "person.fill", text: "Alien4042x")
                    AboutInfoPill(icon: "number.circle.fill", text: "Build \(build)")
                    AboutInfoPill(icon: "gamecontroller.fill", text: "Profile Hub")
                }
                Spacer(minLength: 0)
                HStack(spacing: 12) {
                    Button {
                        if let url = URL(string: "https://github.com/alien4042x") { NSWorkspace.shared.open(url) }
                    } label: {
                        Label("GitHub", systemImage: "link").foregroundStyle(.white).frame(width: 128)
                    }.buttonStyle(.bordered)
                    Button {
                        NSApp.keyWindow?.performClose(nil)
                    } label: {
                        Text("Close").foregroundStyle(.white).frame(width: 128)
                    }.buttonStyle(.borderedProminent).keyboardShortcut(.return, modifiers: [])
                }
            }.foregroundStyle(.white).padding(.horizontal, 34).padding(.vertical, 30)
        }.frame(width: 520, height: 620).preferredColorScheme(.dark)
            .onAppear { withAnimation(.easeInOut(duration: 1.55).repeatForever(autoreverses: true)) { isPulsing = true } }
    }
}

private struct AboutInfoPill: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundStyle(.green)
            Text(text).font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.78))
        }.padding(.horizontal, 10).padding(.vertical, 7)
            .background(Capsule().fill(.white.opacity(0.075)))
            .overlay(Capsule().stroke(.white.opacity(0.10), lineWidth: 1))
    }
}

private struct AboutFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.white.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(.green.opacity(0.18), lineWidth: 1))
                Image(systemName: icon).font(.system(size: 17, weight: .semibold)).foregroundStyle(.green)
            }.frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.70))
            }
            Spacer(minLength: 0)
        }.padding(.horizontal, 14).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white.opacity(0.055)))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.white.opacity(0.09), lineWidth: 1))
    }
}

struct StealthVisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blendingMode
    }
}

struct StealthParticle: Identifiable {
    let id: Int
    let x: Double
    let y: Double
    let amplitudeX: Double
    let amplitudeY: Double
    let size: Double
    let blur: Double
    let speed: Double
    let phase: Double
    let opacity: Double
    let color: Color
}

struct StealthParticleField: View {
    var particles: [StealthParticle] = Self.defaultParticles
    static let defaultParticles: [StealthParticle] = [
        .init(id: 0, x: 0.18, y: 0.18, amplitudeX: 24, amplitudeY: 18, size: 24, blur: 9, speed: 0.32, phase: 0.10, opacity: 0.32, color: .green),
        .init(id: 1, x: 0.78, y: 0.16, amplitudeX: 30, amplitudeY: 22, size: 18, blur: 7, speed: 0.42, phase: 1.2, opacity: 0.28, color: .mint),
        .init(id: 2, x: 0.34, y: 0.38, amplitudeX: 18, amplitudeY: 28, size: 14, blur: 6, speed: 0.50, phase: 2.4, opacity: 0.22, color: .white),
        .init(id: 3, x: 0.88, y: 0.46, amplitudeX: 26, amplitudeY: 20, size: 30, blur: 11, speed: 0.26, phase: 3, opacity: 0.18, color: .green),
        .init(id: 4, x: 0.16, y: 0.72, amplitudeX: 28, amplitudeY: 24, size: 20, blur: 8, speed: 0.36, phase: 4.1, opacity: 0.24, color: .mint),
        .init(id: 5, x: 0.68, y: 0.76, amplitudeX: 22, amplitudeY: 16, size: 16, blur: 6, speed: 0.46, phase: 5, opacity: 0.20, color: .green)
    ]
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let phase = time * particle.speed + particle.phase
                    let x = size.width * particle.x + cos(phase) * particle.amplitudeX
                    let y = size.height * particle.y + sin(phase * 0.82) * particle.amplitudeY
                    let rect = CGRect(x: x - particle.size / 2, y: y - particle.size / 2, width: particle.size, height: particle.size)
                    context.drawLayer { layer in
                        layer.addFilter(.blur(radius: particle.blur))
                        layer.fill(Path(ellipseIn: rect), with: .color(particle.color.opacity(particle.opacity)))
                    }
                }
            }
        }.ignoresSafeArea().allowsHitTesting(false)
    }
}
