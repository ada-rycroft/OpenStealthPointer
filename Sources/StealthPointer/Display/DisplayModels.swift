import AppKit
import CoreGraphics
import Foundation

struct StoredDisplayMode: Codable, Equatable {
    let displayID: CGDirectDisplayID
    let width: Int
    let height: Int
    let refreshRate: Double
}

struct SavedDisplayProfile: Codable, Equatable {
    let displayID: CGDirectDisplayID
    let displayName: String
    let width: Int
    let height: Int
    let refreshRate: Double
    let safeAspectOnly: Bool
}

struct DisplayModeChoice: Identifiable, Equatable {
    enum Clarity: String {
        case native = "Native"
        case good = "Good"
        case low = "Low clarity"
    }

    let id: String
    let width: Int
    let height: Int
    let pixelWidth: Int
    let pixelHeight: Int
    let refreshRate: Double
    let isHiDPI: Bool
    let aspectDelta: Double
    let clarity: Clarity

    var label: String {
        DisplayModeFormatting.label(width: width, height: height, refreshRate: refreshRate)
            + (isHiDPI ? " HiDPI" : "")
    }

    var isSafeAspect: Bool { aspectDelta <= 0.04 }
}

struct DisplayTarget: Identifiable, Equatable {
    let id: CGDirectDisplayID
    let name: String
    let nativeWidth: Int
    let nativeHeight: Int
    let currentWidth: Int
    let currentHeight: Int
    let currentRefreshRate: Double
    let modes: [DisplayModeChoice]

    var currentModeLabel: String {
        DisplayModeFormatting.label(width: currentWidth, height: currentHeight, refreshRate: currentRefreshRate)
    }

    var nativeAspect: Double { nativeHeight > 0 ? Double(nativeWidth) / Double(nativeHeight) : 1 }
}

enum DisplayModeFormatting {
    static func label(width: Int, height: Int, refreshRate: Double) -> String {
        "\(width) x \(height)" + (refreshRate > 0 ? " @ \(Int(refreshRate.rounded()))Hz" : "")
    }
}

@MainActor
enum DisplayModeStore {
    static let restoreKey = "PreviousDisplayMode"
    static let profileKey = "GameDisplayProfile"

    static func restorePoint(defaults: UserDefaults = .standard) -> StoredDisplayMode? {
        guard let data = defaults.data(forKey: restoreKey) else { return nil }
        return try? JSONDecoder().decode(StoredDisplayMode.self, from: data)
    }

    static func gameProfile(defaults: UserDefaults = .standard) -> SavedDisplayProfile? {
        guard let data = defaults.data(forKey: profileKey) else { return nil }
        return try? JSONDecoder().decode(SavedDisplayProfile.self, from: data)
    }

    static func saveRestorePoint(_ mode: StoredDisplayMode, defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(mode) { defaults.set(data, forKey: restoreKey) }
    }

    static func saveGameProfile(_ profile: SavedDisplayProfile, defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(profile) { defaults.set(data, forKey: profileKey) }
    }

    static func allModes(for displayID: CGDirectDisplayID) -> [CGDisplayMode] {
        let options = [kCGDisplayShowDuplicateLowResolutionModes as String: true] as CFDictionary
        return CGDisplayCopyAllDisplayModes(displayID, options) as? [CGDisplayMode] ?? []
    }

    static func matchingMode(displayID: CGDirectDisplayID, width: Int, height: Int, refreshRate: Double) -> CGDisplayMode? {
        let matches = allModes(for: displayID).filter { $0.width == width && $0.height == height }
        if refreshRate <= 0 { return matches.first }
        return matches.min { abs($0.refreshRate - refreshRate) < abs($1.refreshRate - refreshRate) }
    }

    static func restore(defaults: UserDefaults = .standard) -> Bool {
        guard let saved = restorePoint(defaults: defaults),
              let mode = matchingMode(displayID: saved.displayID, width: saved.width, height: saved.height, refreshRate: saved.refreshRate),
              CGDisplaySetDisplayMode(saved.displayID, mode, nil) == .success else { return false }
        defaults.removeObject(forKey: restoreKey)
        return true
    }

    static func displays() -> [DisplayTarget] {
        var count: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &count)
        guard count > 0 else { return [] }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        CGGetActiveDisplayList(count, &ids, &count)
        return ids.compactMap { id in
            let modes = allModes(for: id)
            guard let native = modes.max(by: { $0.pixelWidth * $0.pixelHeight < $1.pixelWidth * $1.pixelHeight }) else { return nil }
            let nativeWidth = native.pixelWidth
            let nativeHeight = native.pixelHeight
            let nativeAspect = nativeHeight > 0 ? Double(nativeWidth) / Double(nativeHeight) : 1
            var choices: [String: DisplayModeChoice] = [:]
            for mode in modes where mode.width > 0 && mode.height > 0 {
                let hiDPI = mode.pixelWidth != mode.width || mode.pixelHeight != mode.height
                let key = "\(mode.width)x\(mode.height)@\(Int(mode.refreshRate.rounded()))-\(hiDPI ? "hidpi" : "std")"
                let clarity: DisplayModeChoice.Clarity = mode.width == nativeWidth && mode.height == nativeHeight
                    ? .native : (Double(mode.width) >= Double(nativeWidth) * 0.74 && Double(mode.height) >= Double(nativeHeight) * 0.74 ? .good : .low)
                choices[key] = DisplayModeChoice(id: key, width: mode.width, height: mode.height,
                    pixelWidth: mode.pixelWidth, pixelHeight: mode.pixelHeight, refreshRate: mode.refreshRate,
                    isHiDPI: hiDPI, aspectDelta: abs(Double(mode.width) / Double(mode.height) - nativeAspect) / nativeAspect, clarity: clarity)
            }
            let sorted = choices.values.sorted {
                if $0.aspectDelta != $1.aspectDelta { return $0.aspectDelta < $1.aspectDelta }
                if $0.width * $0.height != $1.width * $1.height { return $0.width * $0.height > $1.width * $1.height }
                return $0.refreshRate > $1.refreshRate
            }
            let screen = NSScreen.screens.first { ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value == id }
            let current = CGDisplayCopyDisplayMode(id)
            return DisplayTarget(id: id, name: screen?.localizedName ?? "Display \(id)",
                nativeWidth: nativeWidth, nativeHeight: nativeHeight,
                currentWidth: current?.width ?? CGDisplayPixelsWide(id), currentHeight: current?.height ?? CGDisplayPixelsHigh(id),
                currentRefreshRate: current?.refreshRate ?? 0, modes: sorted)
        }
    }
}
