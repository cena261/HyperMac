import Foundation
import IOKit
import Combine
import AppKit

// MARK: - Battery Manager

@MainActor
public class BatteryManager: ObservableObject {
    public static let shared = BatteryManager()

    // MARK: - Published State
    @Published public var currentLevel: Int = 0
    @Published public var maxCapacityPercent: Int = 100
    @Published public var nominalCapacity: Int = 0
    @Published public var designCapacity: Int = 0
    @Published public var healthPercent: Int = 100
    @Published public var cycleCount: Int = 0
    @Published public var temperature: Double = 0.0      // in °C
    @Published public var voltage: Double = 0.0          // in Volts
    @Published public var amperage: Int = 0              // in mA
    @Published public var isPluggedIn: Bool = false
    @Published public var isCharging: Bool = false
    @Published public var isFullyCharged: Bool = false
    @Published public var timeRemaining: Int = 0         // in minutes
    @Published public var isBypassActive: Bool = false    // SMC CHTE = 1 (Running direct from AC)
    @Published public var isHelperInstalled: Bool = false
    @Published public var isInstallingHelper: Bool = false
    @Published public var statusMessage: String = "Đang kiểm tra..."
    @Published public var lastUpdated: Date = Date()

    // User Settings (Stored in UserDefaults)
    @Published public var isProtectionEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isProtectionEnabled, forKey: "battery_protection_enabled")
            evaluatePowerManagement()
        }
    }

    @Published public var chargeLimit: Int = 80 {
        didSet {
            UserDefaults.standard.set(chargeLimit, forKey: "battery_charge_limit")
            evaluatePowerManagement()
        }
    }

    @Published public var isTopUpActive: Bool = false {
        didSet {
            UserDefaults.standard.set(isTopUpActive, forKey: "battery_top_up_active")
            evaluatePowerManagement()
        }
    }

    @Published public var isTempAlertEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isTempAlertEnabled, forKey: "battery_temp_alert_enabled")
        }
    }

    @Published public var isSmartAlertsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isSmartAlertsEnabled, forKey: "battery_smart_alerts_enabled")
        }
    }

    public var tempAlertThreshold: Double = 38.0 // Warning at 38°C
    private var lastTempAlertDate: Date? = nil
    private var lastExtDisplayAlertDate: Date? = nil
    private var lastLowBatteryAlertLevel: Int? = nil
    private var hasAlertedBypassThisSession: Bool = false

    private var timer: Timer?

    private init() {
        // Load preferences
        if UserDefaults.standard.object(forKey: "battery_protection_enabled") != nil {
            self.isProtectionEnabled = UserDefaults.standard.bool(forKey: "battery_protection_enabled")
        } else {
            self.isProtectionEnabled = true
        }

        if UserDefaults.standard.object(forKey: "battery_temp_alert_enabled") != nil {
            self.isTempAlertEnabled = UserDefaults.standard.bool(forKey: "battery_temp_alert_enabled")
        } else {
            self.isTempAlertEnabled = true
        }

        if UserDefaults.standard.object(forKey: "battery_smart_alerts_enabled") != nil {
            self.isSmartAlertsEnabled = UserDefaults.standard.bool(forKey: "battery_smart_alerts_enabled")
        } else {
            self.isSmartAlertsEnabled = true
        }

        let savedLimit = UserDefaults.standard.integer(forKey: "battery_charge_limit")
        if savedLimit >= 50 && savedLimit <= 100 {
            self.chargeLimit = savedLimit
        } else {
            self.chargeLimit = 80
        }

        self.isTopUpActive = UserDefaults.standard.bool(forKey: "battery_top_up_active")

        // Initial check
        checkHelperStatus()
        refreshBatteryInfo()
        checkSMCBypassStatus()
        evaluatePowerManagement()

        // Start background polling timer
        startPolling()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Polling Timer

    public func startPolling() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.refreshBatteryInfo()
                self.checkSMCBypassStatus()
                self.evaluatePowerManagement()
            }
        }
    }

    // MARK: - IOKit Battery Status Query

    public func refreshBatteryInfo() {
        let matching = IOServiceMatching("AppleSmartBattery")
        let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
        guard service != 0 else {
            return
        }
        defer { IOObjectRelease(service) }

        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == kIOReturnSuccess,
              let dict = props?.takeRetainedValue() as? [String: Any] else {
            return
        }

        self.currentLevel = dict["CurrentCapacity"] as? Int ?? self.currentLevel
        self.maxCapacityPercent = dict["MaxCapacity"] as? Int ?? 100
        self.nominalCapacity = dict["NominalChargeCapacity"] as? Int ?? self.nominalCapacity
        self.designCapacity = dict["DesignCapacity"] as? Int ?? self.designCapacity
        self.cycleCount = dict["CycleCount"] as? Int ?? self.cycleCount
        self.isCharging = dict["IsCharging"] as? Bool ?? false
        self.isPluggedIn = dict["ExternalConnected"] as? Bool ?? false
        self.isFullyCharged = dict["FullyCharged"] as? Bool ?? false
        self.timeRemaining = dict["TimeRemaining"] as? Int ?? 0

        if let rawTemp = dict["Temperature"] as? Double {
            self.temperature = rawTemp / 100.0
        } else if let rawTempInt = dict["Temperature"] as? Int {
            self.temperature = Double(rawTempInt) / 100.0
        }

        if let rawVolt = dict["Voltage"] as? Double {
            self.voltage = rawVolt / 1000.0
        } else if let rawVoltInt = dict["Voltage"] as? Int {
            self.voltage = Double(rawVoltInt) / 1000.0
        }

        if let rawAmp = dict["Amperage"] as? Int64 {
            // Signed 64-bit: negative = discharging, positive = charging
            self.amperage = Int(rawAmp)
        }

        if self.designCapacity > 0 && self.nominalCapacity > 0 {
            let ratio = Double(self.nominalCapacity) / Double(self.designCapacity) * 100.0
            self.healthPercent = min(100, Int(round(ratio)))
        }

        self.lastUpdated = Date()
        checkTemperatureAlert()
        checkSmartSafetyAlerts()
    }

    // MARK: - Smart Safety & Anti-Wear Alerts

    private func checkSmartSafetyAlerts() {
        guard isSmartAlertsEnabled else { return }

        // 1. Alert: External display active but running on battery (not plugged in)
        let hasExtDisplay = DisplayManager.shared.monitors.contains(where: { !$0.isBuiltIn && $0.isConnected })
        if hasExtDisplay && !isPluggedIn {
            let now = Date()
            if lastExtDisplayAlertDate == nil || now.timeIntervalSince(lastExtDisplayAlertDate!) > 900 { // 15 mins
                lastExtDisplayAlertDate = now
                sendNotification(
                    title: "⚠️ Đang dùng màn ngoài nhưng chưa cắm sạc!",
                    body: "Màn hình ngoài đang làm GPU xả pin rất nặng và nóng máy. Hãy cắm sạc để máy chạy điện trực tiếp và bảo vệ pin!"
                )
            }
        } else if isPluggedIn {
            lastExtDisplayAlertDate = nil
        }

        // 2. Alert: Low battery warning to prevent deep discharge (<20% and <10%)
        if !isPluggedIn {
            if currentLevel <= 10 {
                if lastLowBatteryAlertLevel != 10 {
                    lastLowBatteryAlertLevel = 10
                    sendNotification(
                        title: "🚨 KHẨN CẤP: Pin còn 10%!",
                        body: "Tuyệt đối không để máy dùng cạn đáy sập nguồn (gây hại cell pin vĩnh viễn). Hãy cắm sạc ngay!"
                    )
                }
            } else if currentLevel <= 20 {
                if lastLowBatteryAlertLevel != 20 {
                    lastLowBatteryAlertLevel = 20
                    sendNotification(
                        title: "⚠️ Pin yếu (20%) - Hãy cắm sạc!",
                        body: "Để tránh hiện tượng tụt áp sâu (Deep Discharge) làm chai pin, hãy cắm sạc ngay bây giờ."
                    )
                }
            } else {
                lastLowBatteryAlertLevel = nil
            }
        } else {
            lastLowBatteryAlertLevel = nil
        }

        // 3. Informational Alert: Reached limit with AC Bypass active
        if isPluggedIn && isBypassActive && currentLevel >= chargeLimit {
            if !hasAlertedBypassThisSession {
                hasAlertedBypassThisSession = true
                sendNotification(
                    title: "🛡️ Đã khóa \(chargeLimit)% - Chuyển sang nguồn AC trực tiếp",
                    body: "Pin đã được ngắt sạc an toàn. MacBook đang dùng điện trực tiếp từ củ sạc để chống chai pin tối đa!"
                )
            }
        } else if !isPluggedIn || currentLevel < (chargeLimit - 4) {
            hasAlertedBypassThisSession = false
        }
    }

    // MARK: - Temperature Safety Alerts

    private func checkTemperatureAlert() {
        guard isTempAlertEnabled && temperature >= tempAlertThreshold else { return }

        let now = Date()
        if let last = lastTempAlertDate, now.timeIntervalSince(last) < 600 {
            return // Wait at least 10 minutes between alerts
        }
        lastTempAlertDate = now

        let tempStr = String(format: "%.1f°C", temperature)
        sendNotification(
            title: "⚠️ Cảnh báo nhiệt độ pin (\(tempStr))",
            body: "Nhiệt độ pin MacBook đã lên tới \(tempStr)! Hãy kê thoáng máy hoặc giảm tải tác vụ nặng để bảo vệ tuổi thọ cell pin."
        )
    }

    private func sendNotification(title: String, body: String) {
        let escapedTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedBody = body.replacingOccurrences(of: "\"", with: "\\\"")
        let script = "display notification \"\(escapedBody)\" with title \"\(escapedTitle)\" sound name \"Submarine\""
        DispatchQueue.global(qos: .utility).async {
            _ = shell("osascript -e '\(script)'")
        }
    }

    public func checkSMCBypassStatus() {
        guard isHelperInstalled else { return }
        DispatchQueue.global(qos: .utility).async {
            let (out, code) = shell("sudo -n /usr/local/bin/displaycontrol-power status 2>/dev/null")
            DispatchQueue.main.async {
                if code == 0 {
                    // Check if CHTE is 1
                    let isBypassed = out.contains("01 00 00 00") || out.contains("1 (bytes 01 00 00 00)")
                    self.isBypassActive = isBypassed
                }
            }
        }
    }

    // MARK: - Power & Limiter Evaluation

    public func evaluatePowerManagement() {
        guard isHelperInstalled else {
            statusMessage = "Cần cấp quyền để kích hoạt bảo vệ nguồn SMC"
            return
        }

        if !isPluggedIn {
            statusMessage = "Đang dùng pin (\(currentLevel)%)"
            return
        }

        // Plugged in
        if isTopUpActive {
            setChargingInhibited(false)
            if currentLevel >= 100 {
                isTopUpActive = false
                statusMessage = "Đã sạc đầy 100%"
            } else {
                statusMessage = "⚡️ Đang sạc đầy tạm thời (\(currentLevel)%)"
            }
            return
        }

        if isProtectionEnabled {
            if currentLevel >= chargeLimit {
                setChargingInhibited(true)
                statusMessage = "🛡️ Nguồn AC trực tiếp (Đã khóa \(chargeLimit)% chống chai pin)"
            } else if currentLevel <= max(10, chargeLimit - 3) {
                setChargingInhibited(false)
                statusMessage = "⚡️ Đang sạc bù lên \(chargeLimit)% (\(currentLevel)%)"
            } else {
                if isBypassActive {
                    statusMessage = "🛡️ Nguồn AC trực tiếp (\(currentLevel)%)"
                } else {
                    statusMessage = "⚡️ Đang sạc (\(currentLevel)%)"
                }
            }
        } else {
            setChargingInhibited(false)
            statusMessage = isFullyCharged ? "Đã sạc đầy 100%" : "Đang sạc thường (\(currentLevel)%)"
        }
    }

    // MARK: - SMC Charging Inhibit Control

    public func setChargingInhibited(_ inhibit: Bool) {
        guard isHelperInstalled else { return }
        let action = inhibit ? "charge-off" : "charge-on"
        DispatchQueue.global(qos: .utility).async {
            let (_, code) = shell("sudo -n /usr/local/bin/displaycontrol-power \(action)")
            DispatchQueue.main.async {
                if code == 0 {
                    self.isBypassActive = inhibit
                }
            }
        }
    }

    // MARK: - Helper Installation Check & Prompt

    public func checkHelperStatus() {
        let exists = FileManager.default.fileExists(atPath: "/usr/local/bin/displaycontrol-power")
        if !exists {
            self.isHelperInstalled = false
            return
        }
        DispatchQueue.global(qos: .utility).async {
            let (_, code) = shell("sudo -n /usr/local/bin/displaycontrol-power status 2>/dev/null")
            DispatchQueue.main.async {
                self.isHelperInstalled = (code == 0)
            }
        }
    }

    public func installHelper(completion: ((Bool) -> Void)? = nil) {
        guard !isInstallingHelper else { return }
        isInstallingHelper = true

        DispatchQueue.global(qos: .userInitiated).async {
            var smcSrc = Bundle.main.path(forResource: "smc", ofType: nil)
            var helperSrc = Bundle.main.path(forResource: "displaycontrol-power", ofType: nil)
            var installScript = Bundle.main.path(forResource: "install-helper", ofType: "sh")

            if smcSrc == nil {
                smcSrc = "/Users/khacdai24/.gemini/antigravity-ide/scratch/DisplayControl/Resources/smc"
            }
            if helperSrc == nil {
                helperSrc = "/Users/khacdai24/.gemini/antigravity-ide/scratch/DisplayControl/Resources/displaycontrol-power"
            }
            if installScript == nil {
                installScript = "/Users/khacdai24/.gemini/antigravity-ide/scratch/DisplayControl/Resources/install-helper.sh"
            }

            guard let sSMC = smcSrc, let sHelper = helperSrc, let sInstall = installScript else {
                DispatchQueue.main.async {
                    self.isInstallingHelper = false
                    completion?(false)
                }
                return
            }

            let appleScriptCmd = """
            do shell script "/bin/bash '\(sInstall)' '\(sSMC)' '\(sHelper)'" with administrator privileges
            """

            var errorDict: NSDictionary?
            if let scriptObj = NSAppleScript(source: appleScriptCmd) {
                _ = scriptObj.executeAndReturnError(&errorDict)
            }

            // Verify installation
            let (_, code) = shell("sudo -n /usr/local/bin/displaycontrol-power status 2>/dev/null")
            let success = (code == 0)

            DispatchQueue.main.async {
                self.isInstallingHelper = false
                self.isHelperInstalled = success
                if success {
                    self.evaluatePowerManagement()
                }
                completion?(success)
            }
        }
    }
}
