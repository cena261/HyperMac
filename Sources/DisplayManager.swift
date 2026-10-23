import Foundation
import CoreGraphics
import IOKit
import AppKit
import Combine

// MARK: - Display Model

public struct DisplayInfo: Identifiable, Equatable, Sendable {
    public let id: CGDirectDisplayID
    public var name: String
    public let isBuiltIn: Bool
    public var brightness: Double   // 0.0 ... 1.0
    public var isConnected: Bool   // true = active in WindowServer, false = soft-disconnected
    public var resolution: String
    public var externalIndex: Int?

    public static func == (lhs: DisplayInfo, rhs: DisplayInfo) -> Bool {
        lhs.id == rhs.id &&
        abs(lhs.brightness - rhs.brightness) < 0.001 &&
        lhs.isConnected == rhs.isConnected &&
        lhs.name == rhs.name &&
        lhs.resolution == rhs.resolution
    }
}

// MARK: - Private DisplayServices Function Signatures (Apple Silicon Native)

private typealias GetBrightnessFunc = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
private typealias SetBrightnessFunc = @convention(c) (CGDirectDisplayID, Float) -> Int32

// MARK: - Display Manager

@MainActor
public class DisplayManager: ObservableObject {
    public static let shared = DisplayManager()

    @Published public var monitors: [DisplayInfo] = []
    @Published public var selectedID: CGDirectDisplayID? = nil
    @Published public var isCursorBased: Bool = true
    @Published public var isMouseChordEnabled: Bool = true {
        didSet {
            gIsMouseChordEnabled = isMouseChordEnabled
        }
    }
    @Published public var isRefreshing: Bool = false
    @Published public var hasAccessibility: Bool = false
    @Published public var selectedMainTab: Int = 0
    @Published public var alertMessage: String? = nil
    @Published public var showAlert: Bool = false

    private var brightnessCache: [CGDirectDisplayID: Double] = [:]
    private var dsGetBrightness: GetBrightnessFunc?
    private var dsSetBrightness: SetBrightnessFunc?
    private var permCheckTimer: Timer?

    private init() {
        appLog("🚀 DisplayManager: Initializing...")
        // Load DisplayServices for Apple Silicon Built-in display brightness
        if let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW) {
            if let symGet = dlsym(handle, "DisplayServicesGetBrightness") {
                self.dsGetBrightness = unsafeBitCast(symGet, to: GetBrightnessFunc.self)
            }
            if let symSet = dlsym(handle, "DisplayServicesSetBrightness") {
                self.dsSetBrightness = unsafeBitCast(symSet, to: SetBrightnessFunc.self)
            }
        }

        if let savedChord = UserDefaults.standard.object(forKey: "mouse_chord_enabled") as? Bool {
            self.isMouseChordEnabled = savedChord
        }

        refreshDisplays()

        if let first = monitors.first {
            self.selectedID = first.id
        }

        self.hasAccessibility = AXIsProcessTrusted()
        if !hasAccessibility {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
        }

        permCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkAccessibility()
            }
        }
    }

    deinit {
        permCheckTimer?.invalidate()
    }

    // MARK: - Accessibility Check

    public func checkAccessibility() {
        let trusted = AXIsProcessTrusted()
        if self.hasAccessibility != trusted {
            self.hasAccessibility = trusted
            appLog("🔐 Accessibility status changed to: \(trusted)")
        }
        if trusted && KeyInterceptor.shared.currentTap == nil {
            KeyInterceptor.shared.start()
        }
    }

    public func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Refresh Displays

    public func refresh() {
        isRefreshing = true
        refreshDisplays()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isRefreshing = false
        }
    }

    public func refreshDisplays() {
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: 16)
        var count: UInt32 = 0
        // SLSGetDisplayList lists ALL monitors including soft-disconnected ones
        _ = SLSGetDisplayList(16, &displayIDs, &count)

        var externalIdx = 1
        var updatedList: [DisplayInfo] = []

        for i in 0..<Int(count) {
            let id = displayIDs[i]
            let isBuiltIn = CGDisplayIsBuiltin(id) != 0
            let isOnline = (CGDisplayIsOnline(id) != 0)
            let bounds = CGDisplayBounds(id)

            // Filter out offline phantom/unplugged display descriptors (e.g. 1x1 offline ports)
            if !isBuiltIn && (!isOnline || (bounds.width <= 10 && bounds.height <= 10)) {
                continue
            }

            let name = getDisplayName(for: id, isBuiltIn: isBuiltIn)
            let resolution = "\(Int(bounds.width)) × \(Int(bounds.height))"
            let isActive = (CGDisplayIsActive(id) != 0)

            // Load cached brightness from UserDefaults or in-memory cache
            if brightnessCache[id] == nil {
                if let saved = UserDefaults.standard.object(forKey: "brightness_\(id)") as? Double {
                    brightnessCache[id] = saved
                }
            }

            let currentBrightness: Double
            if isBuiltIn {
                currentBrightness = isActive ? getBuiltInBrightness(displayID: id) : (brightnessCache[id] ?? 0.8)
            } else {
                currentBrightness = brightnessCache[id] ?? 0.8
            }

            var idx: Int? = nil
            if !isBuiltIn {
                idx = externalIdx
                externalIdx += 1
            }

            updatedList.append(DisplayInfo(
                id: id,
                name: name,
                isBuiltIn: isBuiltIn,
                brightness: currentBrightness,
                isConnected: isActive,
                resolution: resolution,
                externalIndex: idx
            ))
        }

        updatedList.sort { a, b in
            if a.isBuiltIn != b.isBuiltIn { return a.isBuiltIn }
            return a.id < b.id
        }

        self.monitors = updatedList
        appLog("🖥 Display list refreshed. Total: \(updatedList.count) (Active: \(updatedList.filter { $0.isConnected }.count))")

        if selectedID == nil || !updatedList.contains(where: { $0.id == selectedID }) {
            selectedID = updatedList.first?.id
        }
    }

    // MARK: - Selection

    public func selectMonitor(_ monitor: DisplayInfo) {
        selectedID = monitor.id
    }

    public var selectedMonitor: DisplayInfo? {
        monitors.first { $0.id == selectedID } ?? monitors.first
    }

    // MARK: - Display Name Lookup via IOKit

    private func getDisplayName(for displayID: CGDirectDisplayID, isBuiltIn: Bool) -> String {
        if isBuiltIn { return "Built-in Retina Display" }

        let targetVendor = CGDisplayVendorNumber(displayID)
        let targetModel  = CGDisplayModelNumber(displayID)

        var iter = io_iterator_t()
        guard IOServiceGetMatchingServices(
            kIOMainPort,
            IOServiceMatching("IODisplayConnect"),
            &iter
        ) == kIOReturnSuccess else {
            return "External Display"
        }
        defer { IOObjectRelease(iter) }

        var service = IOIteratorNext(iter)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iter)
            }

            guard let infoRef = IODisplayCreateInfoDictionary(service, kIODisplayOnlyPreferredName) else {
                continue
            }
            let info = infoRef.takeRetainedValue() as NSDictionary

            guard let vendor = info[kDisplayVendorIDKey] as? UInt32,
                  let model  = info[kDisplayProductIDKey] as? UInt32,
                  vendor == targetVendor, model == targetModel else {
                continue
            }

            if let names = info[kDisplayProductNameKey] as? [String: String],
               let name = names.values.first, !name.isEmpty {
                return name
            }
        }

        return "External Display"
    }

    // MARK: - Built-in Brightness via DisplayServices (Apple Silicon Native)

    private func getBuiltInBrightness(displayID: CGDirectDisplayID) -> Double {
        if let getFn = dsGetBrightness {
            var val: Float = 0.5
            if getFn(displayID, &val) == 0 {
                return Double(val)
            }
        }
        return 0.5
    }

    private func setBuiltInBrightness(displayID: CGDirectDisplayID, value: Float) {
        if let setFn = dsSetBrightness {
            _ = setFn(displayID, max(0.0, min(1.0, value)))
        }
    }

    // MARK: - External Brightness via CoreGraphics Hardware Gamma LUT

    private func setHardwareGamma(displayID: CGDirectDisplayID, brightness: Double) {
        let tableSize: UInt32 = 256
        var red = [Float](repeating: 0, count: Int(tableSize))
        var green = [Float](repeating: 0, count: Int(tableSize))
        var blue = [Float](repeating: 0, count: Int(tableSize))

        let b = Float(max(0.0, min(1.0, brightness)))
        for i in 0..<Int(tableSize) {
            let val = (Float(i) / Float(tableSize - 1)) * b
            red[i] = val
            green[i] = val
            blue[i] = val
        }

        _ = CGSetDisplayTransferByTable(displayID, tableSize, &red, &green, &blue)
    }

    // MARK: - Unified Brightness Setter

    public func setBrightness(_ value: Double, for monitor: DisplayInfo) {
        let clamped = max(0.0, min(1.0, value))
        guard let idx = monitors.firstIndex(where: { $0.id == monitor.id }) else { return }
        monitors[idx].brightness = clamped
        brightnessCache[monitor.id] = clamped
        UserDefaults.standard.set(clamped, forKey: "brightness_\(monitor.id)")

        // Only apply hardware changes if monitor is active
        guard monitors[idx].isConnected else { return }

        appLog("💡 Setting brightness to \(Int(clamped * 100))% for '\(monitor.name)' (isBuiltIn: \(monitor.isBuiltIn))")

        if monitor.isBuiltIn {
            setBuiltInBrightness(displayID: monitor.id, value: Float(clamped))
        } else {
            setHardwareGamma(displayID: monitor.id, brightness: clamped)
        }
    }

    // MARK: - Keyboard F1 / F2 Brightness Handler

    /// Called by KeyInterceptor when F1 (isUp == false, brightness down) or F2 (isUp == true, brightness up) is pressed.
    /// Returns true if handled and swallowed (external display), or false to let macOS handle natively (built-in screen).
    public func handleBrightnessKey(isUp: Bool) -> Bool {
        let targetMonitor: DisplayInfo?
        let mouseLoc = NSEvent.mouseLocation

        if isCursorBased {
            let screenUnderMouse = NSScreen.screens.first { NSMouseInRect(mouseLoc, $0.frame, false) }
            let screenDisplayID = screenUnderMouse?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID

            if let did = screenDisplayID, let m = monitors.first(where: { $0.id == did }) {
                targetMonitor = m
            } else {
                targetMonitor = selectedMonitor
            }
        } else {
            targetMonitor = selectedMonitor
        }

        guard let monitor = targetMonitor, monitor.isConnected else {
            appLog("⚠️ handleBrightnessKey: Target monitor is nil or disconnected.")
            return false
        }

        appLog("🎯 handleBrightnessKey: isUp=\(isUp) | target='\(monitor.name)' (builtin=\(monitor.isBuiltIn)) | mouse=\(mouseLoc)")

        // Step brightness by 1/16 (6.25% - standard Apple block)
        let step = 0.0625
        let current = monitor.brightness
        // F2 = isUp (increase), F1 = !isUp (decrease)
        let newBrightness = max(0.0, min(1.0, isUp ? (current + step) : (current - step)))

        setBrightness(newBrightness, for: monitor)

        let targetScreen = NSScreen.screens.first { s in
            let did = s.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
            return did == monitor.id
        } ?? NSScreen.main
        OSDManager.shared.show(title: monitor.name, brightness: newBrightness, on: targetScreen)

        return true
    }

    // MARK: - True BetterDisplay-Style Display Connection Management

    public func canDisconnect(_ monitor: DisplayInfo) -> Bool {
        let activeCount = monitors.filter { $0.isConnected }.count
        return activeCount > 1
    }

    public func toggleConnection(for monitor: DisplayInfo) {
        guard let idx = monitors.firstIndex(where: { $0.id == monitor.id }) else { return }
        let currentlyActive = monitors[idx].isConnected

        if currentlyActive && !canDisconnect(monitor) {
            alertMessage = "Không thể ngắt tất cả màn hình! macOS cần giữ lại ít nhất 1 màn hình hoạt động để bạn tiếp tục sử dụng."
            showAlert = true
            return
        }

        let targetID = monitor.id
        let shouldEnable = !currentlyActive

        if shouldEnable && !monitor.isBuiltIn && CGDisplayIsOnline(targetID) == 0 {
            alertMessage = "Màn hình ngoài hiện không có tín hiệu cáp kết nối vật lý với máy."
            showAlert = true
            refreshDisplays()
            return
        }

        appLog("⚡️ toggleConnection: target='\(monitor.name)' (id=\(targetID)) -> willEnable=\(shouldEnable)")

        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success, let cfg = config else {
            alertMessage = "Không thể khởi tạo phiên thay đổi cấu hình màn hình."
            showAlert = true
            return
        }

        // Use WindowServer private SkyLight API to cleanly soft-disconnect or connect
        let confResult = SLSConfigureDisplayEnabled(cfg, targetID, shouldEnable)
        guard confResult == .success else {
            _ = CGCancelDisplayConfiguration(config)
            alertMessage = "Lỗi thiết lập trạng thái màn hình (Mã lỗi: \(confResult.rawValue))."
            showAlert = true
            return
        }

        let commitResult = CGCompleteDisplayConfiguration(config, .permanently)
        guard commitResult == .success else {
            CGRestorePermanentDisplayConfiguration()
            if shouldEnable {
                alertMessage = "Không thể bật màn hình ngoài do thiếu tín hiệu cáp hoặc nguồn điện. Vui lòng kiểm tra lại kết nối vật lý."
            } else {
                alertMessage = "Lỗi áp dụng cấu hình màn hình vào WindowServer (Mã lỗi: \(commitResult.rawValue))."
            }
            showAlert = true
            refreshDisplays()
            return
        }

        appLog("✅ toggleConnection committed to WindowServer successfully.")

        // Update local state immediately
        monitors[idx].isConnected = shouldEnable

        if shouldEnable {
            // Restore brightness on reconnect
            let saved = brightnessCache[targetID] ?? 0.8
            if monitor.isBuiltIn {
                setBuiltInBrightness(displayID: targetID, value: Float(saved))
            } else {
                setHardwareGamma(displayID: targetID, brightness: saved)
            }
        }

        // Refresh displays to sync with WindowServer desktop layout consolidation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refreshDisplays()
        }
    }

    // MARK: - Quick Presets

    public func setQuickBrightness(_ percent: Double, for monitor: DisplayInfo) {
        setBrightness(percent, for: monitor)
    }

    public func connectAllDisplays() {
        for monitor in monitors where !monitor.isConnected {
            toggleConnection(for: monitor)
        }
    }
}
