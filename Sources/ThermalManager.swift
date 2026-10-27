import Foundation
import IOKit
import AppKit

// MARK: - Fan Model & Enums

public enum FanControlMode: String, CaseIterable, Codable, Sendable {
    case auto = "auto"
    case manual = "manual"
    case smartCurve = "smartCurve"
    case boost = "boost"

    public var title: String {
        switch self {
        case .auto: return "Tự động (Apple)"
        case .manual: return "Cố định RPM"
        case .smartCurve: return "Theo cảm biến"
        case .boost: return "Tối đa 100%"
        }
    }

    public var icon: String {
        switch self {
        case .auto: return "gearshape.2"
        case .manual: return "slider.horizontal.3"
        case .smartCurve: return "chart.xyaxis.line"
        case .boost: return "bolt.fill"
        }
    }
}

public enum ThermalSensorTarget: String, CaseIterable, Codable, Sendable {
    case cpuAvg = "cpu_avg"
    case cpuPeak = "cpu_peak"
    case gpu = "gpu"
    case hotspot = "hotspot"
    case ssd = "ssd"

    public var title: String {
        switch self {
        case .cpuAvg: return "CPU Trung bình"
        case .cpuPeak: return "CPU Nóng nhất"
        case .gpu: return "GPU Đồ họa"
        case .hotspot: return "Bo mạch (PMU)"
        case .ssd: return "Ổ cứng SSD"
        }
    }

    public var icon: String {
        switch self {
        case .cpuAvg: return "cpu"
        case .cpuPeak: return "flame.fill"
        case .gpu: return "gamecontroller.fill"
        case .hotspot: return "thermometer.medium"
        case .ssd: return "internaldrive.fill"
        }
    }
}

public struct FanModel: Identifiable, Equatable {
    public let id: Int
    public let name: String
    public var currentRPM: Double
    public var minRPM: Double
    public var maxRPM: Double
    public var targetRPM: Double
    public var isManual: Bool
}

public struct SensorReading: Identifiable, Equatable {
    public var id: String { name }
    public let name: String
    public let displayName: String
    public let temp: Double
    public let category: String
}

// MARK: - Native Apple Silicon IOHID Temperature Reader

private typealias ClientRef = OpaquePointer
private typealias ServiceRef = OpaquePointer
private typealias EventRef = OpaquePointer

private typealias FnCreateWithType = @convention(c) (CFAllocator?, UInt32, CFDictionary?) -> ClientRef?
private typealias FnCopyServices = @convention(c) (ClientRef) -> CFArray?
private typealias FnCopyProperty = @convention(c) (ServiceRef, CFString) -> CFTypeRef?
private typealias FnCopyEvent = @convention(c) (ServiceRef, Int64, Int32, Int64) -> EventRef?
private typealias FnGetFloat = @convention(c) (EventRef, UInt32) -> Double

private class AppleSiliconHIDReader {
    private var client: ClientRef?
    private var cachedServices: [ServiceRef] = []
    private var lastDiscoveryTime: TimeInterval = 0

    private var fnCreate: FnCreateWithType?
    private var fnCopyServices: FnCopyServices?
    private var fnCopyProperty: FnCopyProperty?
    private var fnCopyEvent: FnCopyEvent?
    private var fnGetFloat: FnGetFloat?

    init() {
        guard let handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW) else { return }
        if let s = dlsym(handle, "IOHIDEventSystemClientCreateWithType") { fnCreate = unsafeBitCast(s, to: FnCreateWithType.self) }
        if let s = dlsym(handle, "IOHIDEventSystemClientCopyServices") { fnCopyServices = unsafeBitCast(s, to: FnCopyServices.self) }
        if let s = dlsym(handle, "IOHIDServiceClientCopyProperty") { fnCopyProperty = unsafeBitCast(s, to: FnCopyProperty.self) }
        if let s = dlsym(handle, "IOHIDServiceClientCopyEvent") { fnCopyEvent = unsafeBitCast(s, to: FnCopyEvent.self) }
        if let s = dlsym(handle, "IOHIDEventGetFloatValue") { fnGetFloat = unsafeBitCast(s, to: FnGetFloat.self) }
    }

    func readTemperatures() -> (cpuAvg: Double, cpuPeak: Double, gpuAvg: Double, battery: Double, nand: Double, hotspot: Double, sensors: [SensorReading]) {
        guard let create = fnCreate, let copyServ = fnCopyServices, let copyProp = fnCopyProperty,
              let copyEvt = fnCopyEvent, let getFloat = fnGetFloat else {
            return (0, 0, 0, 0, 0, 0, [])
        }

        let now = ProcessInfo.processInfo.systemUptime
        if client == nil {
            client = create(kCFAllocatorDefault, 1, nil)
        }
        guard let c = client else { return (0, 0, 0, 0, 0, 0, []) }

        // Refresh services every 60s
        if cachedServices.isEmpty || (now - lastDiscoveryTime > 60) {
            cachedServices.removeAll(keepingCapacity: true)
            if let servCF = copyServ(c) {
                let count = CFArrayGetCount(servCF)
                for i in 0..<count {
                    let s = unsafeBitCast(CFArrayGetValueAtIndex(servCF, i), to: ServiceRef.self)
                    cachedServices.append(s)
                }
            }
            lastDiscoveryTime = now
        }

        var cpuTemps: [Double] = []
        var gpuTemps: [Double] = []
        var batteryTemps: [Double] = []
        var nandTemps: [Double] = []
        var hotspotTemps: [Double] = []
        var sensorList: [SensorReading] = []

        let kIOHIDEventTypeTemperature: Int64 = 15
        let kIOHIDEventFieldTemperatureValue: UInt32 = (15 << 16) | 0

        for s in cachedServices {
            guard let pRef = copyProp(s, "Product" as CFString),
                  let name = pRef as? String else { continue }

            guard let evt = copyEvt(s, kIOHIDEventTypeTemperature, 0, 0) else { continue }
            let temp = getFloat(evt, kIOHIDEventFieldTemperatureValue)
            guard temp > 15.0 && temp < 125.0 else { continue }

            if name.hasPrefix("PMU tdie") || name.hasPrefix("PMU2 tdie") {
                cpuTemps.append(temp)
                let coreIdx = name.replacingOccurrences(of: "PMU tdie", with: "").replacingOccurrences(of: "PMU2 tdie", with: " (P-Core ")
                let label = name.contains("PMU2") ? "CPU P-Core \(coreIdx.replacingOccurrences(of: " (P-Core ", with: ""))" : "CPU Core \(coreIdx)"
                sensorList.append(SensorReading(name: name, displayName: label, temp: temp, category: "CPU"))
            } else if name.hasPrefix("PMU tdev") || name.hasPrefix("PMU2 tdev") {
                gpuTemps.append(temp)
                let gpuIdx = name.replacingOccurrences(of: "PMU tdev", with: "").replacingOccurrences(of: "PMU2 tdev", with: " Cụm ")
                sensorList.append(SensorReading(name: name, displayName: "GPU Cụm \(gpuIdx)", temp: temp, category: "GPU"))
            } else if name.contains("battery") {
                batteryTemps.append(temp)
                sensorList.append(SensorReading(name: name, displayName: "Pin Cell (Gas Gauge)", temp: temp, category: "Pin"))
            } else if name.contains("NAND") {
                nandTemps.append(temp)
                sensorList.append(SensorReading(name: name, displayName: "SSD NVMe Flash", temp: temp, category: "Ổ cứng"))
            } else if name.contains("tcal") {
                hotspotTemps.append(temp)
                sensorList.append(SensorReading(name: name, displayName: "Hotspot Bo mạch", temp: temp, category: "Bo mạch"))
            }
        }

        let cpuAvg = cpuTemps.isEmpty ? 0.0 : (cpuTemps.reduce(0, +) / Double(cpuTemps.count))
        let cpuPeak = cpuTemps.max() ?? 0.0
        let gpuAvg = gpuTemps.isEmpty ? 0.0 : (gpuTemps.reduce(0, +) / Double(gpuTemps.count))
        let bat = batteryTemps.isEmpty ? 0.0 : (batteryTemps.reduce(0, +) / Double(batteryTemps.count))
        let nand = nandTemps.isEmpty ? 0.0 : (nandTemps.reduce(0, +) / Double(nandTemps.count))
        let hot = hotspotTemps.isEmpty ? 0.0 : (hotspotTemps.reduce(0, +) / Double(hotspotTemps.count))

        return (cpuAvg, cpuPeak, gpuAvg, bat, nand, hot, sensorList)
    }

    deinit {
        cachedServices.removeAll()
    }
}

// MARK: - Thermal & Fan Manager Engine

@MainActor
public class ThermalManager: ObservableObject {
    public static let shared = ThermalManager()

    // Hardware Fan Capabilities
    @Published public var hasFans: Bool = false
    @Published public var fanCount: Int = 0
    @Published public var fans: [FanModel] = []
    @Published public var machineModelName: String = "Mac"
    @Published public var isFanlessModel: Bool = true

    // Real-Time Temperatures (°C)
    @Published public var cpuAvgTemp: Double = 0.0
    @Published public var cpuPeakTemp: Double = 0.0
    @Published public var gpuAvgTemp: Double = 0.0
    @Published public var batteryTemp: Double = 0.0
    @Published public var ssdTemp: Double = 0.0
    @Published public var hotspotTemp: Double = 0.0

    // Detailed Sensor Breakdown
    @Published public var detailedSensors: [SensorReading] = []
    @Published public var isDetailExpanded: Bool = false

    // UI View State (Stored here to prevent CommandLineTools SwiftUIMacros @State crash)
    @Published public var selectedSection: Int = 0 // 0: Pin & Nguồn SMC, 1: Tản nhiệt & Quạt
    @Published public var isRefreshing: Bool = false

    // Thermal Throttling & Status
    @Published public var thermalStateDescription: String = "Mát mẻ (Bình thường)"
    @Published public var isThrottling: Bool = false

    // Fan Control Preferences
    @Published public var selectedFanMode: FanControlMode = .auto {
        didSet { UserDefaults.standard.set(selectedFanMode.rawValue, forKey: "fan_control_mode") }
    }
    @Published public var manualRPM: Double = 3200 {
        didSet { UserDefaults.standard.set(manualRPM, forKey: "fan_manual_rpm") }
    }

    // Macs Fan Control Sensor-Based Curve Settings
    @Published public var sensorTarget: ThermalSensorTarget = .cpuAvg {
        didSet {
            UserDefaults.standard.set(sensorTarget.rawValue, forKey: "fan_sensor_target")
            if selectedFanMode == .smartCurve { applyActiveFanProfile() }
        }
    }
    @Published public var smartCurveStartTemp: Double = 50.0 {
        didSet {
            UserDefaults.standard.set(smartCurveStartTemp, forKey: "fan_curve_start_temp")
            if selectedFanMode == .smartCurve { applyActiveFanProfile() }
        }
    }
    @Published public var smartCurveMaxTemp: Double = 85.0 {
        didSet {
            UserDefaults.standard.set(smartCurveMaxTemp, forKey: "fan_curve_max_temp")
            if selectedFanMode == .smartCurve { applyActiveFanProfile() }
        }
    }

    // Menu Bar Live Telemetry (Macs Fan Control signature feature)
    @Published public var showMenuBarMetrics: Bool = UserDefaults.standard.bool(forKey: "show_menubar_thermal") {
        didSet {
            UserDefaults.standard.set(showMenuBarMetrics, forKey: "show_menubar_thermal")
            updateMenuBarDisplay()
        }
    }
    @Published public var menuBarDisplayMode: Int = UserDefaults.standard.integer(forKey: "menubar_thermal_mode") {
        didSet {
            UserDefaults.standard.set(menuBarDisplayMode, forKey: "menubar_thermal_mode")
            updateMenuBarDisplay()
        }
    }
    public var onMenuBarUpdate: ((String?) -> Void)?

    private var smcBinaryPath: String {
        if FileManager.default.isExecutableFile(atPath: "/usr/local/bin/displaycontrol-smc") {
            return "/usr/local/bin/displaycontrol-smc"
        }
        if let res = Bundle.main.resourcePath, FileManager.default.isExecutableFile(atPath: res + "/smc") {
            return res + "/smc"
        }
        if FileManager.default.isExecutableFile(atPath: "/usr/local/bin/smc") {
            return "/usr/local/bin/smc"
        }
        return "/Users/khacdai24/.gemini/antigravity-ide/scratch/DisplayControl/Resources/smc"
    }

    private let hidReader = AppleSiliconHIDReader()
    private var pollTimer: Timer?

    private init() {
        loadMachineHardwareInfo()
        loadSavedSettings()
        detectFans()
        refreshMetrics()
        startPolling()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(thermalStateChanged),
            name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil
        )

        // Safety: Restore fans to Apple Auto on Sleep, re-apply on Wake
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSystemSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSystemWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    private func loadMachineHardwareInfo() {
        var size: size_t = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        let modelString = String(cString: model)
        let modelLower = modelString.lowercased()

        // Fanless Mac hardware in Apple history:
        // 1. MacBook Air: MacBookAir*, Mac14,2 (M2 13"), Mac14,15 (M2 15"), Mac15,12 (M3 13"), Mac15,13 (M3 15")
        // 2. MacBook 12" Retina: MacBook8,1, MacBook9,1, MacBook10,1
        let isAir = modelLower.contains("air") ||
                    modelString.hasPrefix("Mac14,2") ||
                    modelString.hasPrefix("Mac14,15") ||
                    modelString.hasPrefix("Mac15,12") ||
                    modelString.hasPrefix("Mac15,13")
        let is12Inch = modelString.hasPrefix("MacBook8,") ||
                       modelString.hasPrefix("MacBook9,") ||
                       modelString.hasPrefix("MacBook10,")

        if isAir {
            self.machineModelName = "MacBook Air"
            self.isFanlessModel = true
            self.hasFans = false
            self.fanCount = 0
        } else if is12Inch {
            self.machineModelName = "MacBook (12-inch)"
            self.isFanlessModel = true
            self.hasFans = false
            self.fanCount = 0
        } else if modelLower.contains("mini") || modelString == "Mac14,3" || modelString == "Mac14,12" || modelString.hasPrefix("Mac16,10") || modelString.hasPrefix("Mac16,11") || modelString.hasPrefix("Mac16,15") {
            self.machineModelName = "Mac mini"
            self.isFanlessModel = false
            self.hasFans = true
            self.fanCount = 1
        } else if modelLower.contains("studio") || modelString.hasPrefix("Mac13,") || modelString == "Mac14,13" || modelString == "Mac14,14" {
            self.machineModelName = "Mac Studio"
            self.isFanlessModel = false
            self.hasFans = true
            self.fanCount = 2
        } else if modelLower.contains("imac") || modelString == "Mac15,4" || modelString == "Mac15,5" || modelString == "Mac16,2" || modelString == "Mac16,3" {
            self.machineModelName = "iMac"
            self.isFanlessModel = false
            self.hasFans = true
            self.fanCount = 2
        } else if modelLower.contains("pro") ||
                  modelString.hasPrefix("MacBookPro") ||
                  modelString.hasPrefix("Mac14,5") || modelString.hasPrefix("Mac14,6") ||
                  modelString.hasPrefix("Mac14,7") || modelString.hasPrefix("Mac14,9") ||
                  modelString.hasPrefix("Mac14,10") || modelString.hasPrefix("Mac15,") ||
                  modelString.hasPrefix("Mac16,") {
            self.machineModelName = "MacBook Pro"
            self.isFanlessModel = false
            self.hasFans = true
            let is13Inch = modelString.contains("13") || modelString.hasPrefix("Mac14,7") || modelString.hasPrefix("MacBookPro17,1")
            self.fanCount = is13Inch ? 1 : 2
        } else {
            self.machineModelName = modelString.isEmpty ? "Mac" : modelString
            self.isFanlessModel = false
            self.hasFans = true
            self.fanCount = 2
        }
    }

    private func loadSavedSettings() {
        if let savedMode = UserDefaults.standard.string(forKey: "fan_control_mode"),
           let mode = FanControlMode(rawValue: savedMode) {
            self.selectedFanMode = mode
        }
        let savedRPM = UserDefaults.standard.double(forKey: "fan_manual_rpm")
        if savedRPM > 1000 {
            self.manualRPM = savedRPM
        }
        if let savedTarget = UserDefaults.standard.string(forKey: "fan_sensor_target"),
           let target = ThermalSensorTarget(rawValue: savedTarget) {
            self.sensorTarget = target
        }
        let savedStart = UserDefaults.standard.double(forKey: "fan_curve_start_temp")
        if savedStart >= 35.0 && savedStart <= 75.0 {
            self.smartCurveStartTemp = savedStart
        }
        let savedMax = UserDefaults.standard.double(forKey: "fan_curve_max_temp")
        if savedMax >= 65.0 && savedMax <= 100.0 {
            self.smartCurveMaxTemp = savedMax
        }
    }

    // MARK: - Detect Fan Hardware via SMC

    public func detectFans() {
        // If known to be fanless (MacBook Air), do not probe
        if self.isFanlessModel {
            self.fanCount = 0
            self.hasFans = false
            self.fans = []
            return
        }

        // 1. Try smc -f first (returns total fans, fan IDs, current and max RPM)
        let (outputF, statusF) = shell("\(smcBinaryPath) -f 2>/dev/null || true")
        if statusF == 0, let count = parseTotalFans(outputF) {
            if count > 0 {
                self.fanCount = count
                self.hasFans = true
                self.isFanlessModel = false
                populateFanList(count: count)
                updateFanReadingsWithSMCF(outputF)
                return
            } else if count == 0 && (self.machineModelName.contains("Air") || self.machineModelName.contains("12-inch")) {
                self.fanCount = 0
                self.hasFans = false
                self.isFanlessModel = true
                self.fans = []
                return
            }
        }

        // 2. Try smc -k FNum -r
        let (outputK, statusK) = shell("\(smcBinaryPath) -k FNum -r 2>/dev/null || true")
        if statusK == 0 && outputK.contains("FNum") && !outputK.contains("no data") {
            if let count = parseFNumValue(outputK), count > 0 {
                self.fanCount = count
                self.hasFans = true
                self.isFanlessModel = false
                populateFanList(count: count)
                return
            }
        }

        // 3. Fallback for hardware known to have fans (MacBook Pro, Mac Studio, Mac mini)
        if !self.isFanlessModel {
            if self.fanCount <= 0 {
                self.fanCount = (self.machineModelName.contains("mini") || self.machineModelName.contains("13")) ? 1 : 2
            }
            self.hasFans = true
            populateFanList(count: self.fanCount)
            return
        }

        self.fanCount = 0
        self.hasFans = false
        self.isFanlessModel = true
        self.fans = []
    }

    private func parseTotalFans(_ text: String) -> Int? {
        let pattern = #"Total fans in system:\s*(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return Int(text[range])
    }

    private func parseFNumValue(_ text: String) -> Int? {
        // Matches digit following closing bracket ']' e.g. "FNum [ui8 ] 2 (bytes 02)"
        let pattern = #"\]\s*(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return Int(text[range])
    }

    private func populateFanList(count: Int) {
        var list: [FanModel] = []
        for i in 0..<count {
            let name = count == 1 ? "Quạt chính" : (i == 0 ? "Quạt trái (Left)" : "Quạt phải (Right)")
            let minR = 1200.0
            let maxR = 6500.0
            list.append(FanModel(id: i, name: name, currentRPM: 0.0, minRPM: minR, maxRPM: maxR, targetRPM: 0.0, isManual: false))
        }
        self.fans = list
    }

    // MARK: - Polling & Refresh Metrics

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshMetrics()
            }
        }
    }

    public func refreshMetrics() {
        // 1. Read Apple Silicon HID Temperatures
        let (cpu, peak, gpu, bat, nand, hot, sensors) = hidReader.readTemperatures()
        if cpu > 0 { self.cpuAvgTemp = cpu }
        if peak > 0 { self.cpuPeakTemp = peak }
        if gpu > 0 { self.gpuAvgTemp = gpu }
        if bat > 0 { self.batteryTemp = bat }
        if nand > 0 { self.ssdTemp = nand }
        if hot > 0 { self.hotspotTemp = hot }
        if !sensors.isEmpty { self.detailedSensors = sensors }

        // 2. Read System Thermal Pressure
        let state = ProcessInfo.processInfo.thermalState
        switch state {
        case .nominal:
            self.thermalStateDescription = "Mát mẻ (Bình thường)"
            self.isThrottling = false
        case .fair:
            self.thermalStateDescription = "Ấm nhẹ (Tải vừa)"
            self.isThrottling = false
        case .serious:
            self.thermalStateDescription = "Nóng (Đang giảm xung nhẹ)"
            self.isThrottling = true
        case .critical:
            self.thermalStateDescription = "Rất nóng (Thermal Throttling tối đa!)"
            self.isThrottling = true
        @unknown default:
            self.thermalStateDescription = "Bình thường"
            self.isThrottling = false
        }

        // 3. Update Fans (if present)
        if hasFans {
            updateFanReadings()
            applyActiveFanProfile()
        }

        // 4. Update Menu Bar Live Telemetry
        updateMenuBarDisplay()
    }

    @objc private func thermalStateChanged() {
        refreshMetrics()
    }

    private func updateFanReadings() {
        guard hasFans else { return }

        let (out, status) = shell("\(smcBinaryPath) -f 2>/dev/null || true")
        if status == 0 && out.contains("Total fans in system:") && updateFanReadingsWithSMCF(out) {
            return
        }

        // Fallback key-by-key
        for i in 0..<fans.count {
            let (outAct, _) = shell("\(smcBinaryPath) -k F\(i)Ac -r 2>/dev/null || true")
            let (outMin, _) = shell("\(smcBinaryPath) -k F\(i)Mn -r 2>/dev/null || true")
            let (outMax, _) = shell("\(smcBinaryPath) -k F\(i)Mx -r 2>/dev/null || true")

            if let val = parseSMCKeyFloat(outAct), val > 0 { fans[i].currentRPM = val }
            if let val = parseSMCKeyFloat(outMin), val > 0 { fans[i].minRPM = val }
            if let val = parseSMCKeyFloat(outMax), val > 0 { fans[i].maxRPM = val }
        }
    }

    @discardableResult
    private func updateFanReadingsWithSMCF(_ text: String) -> Bool {
        let blocks = text.components(separatedBy: "Fan #")
        guard blocks.count > 1 else { return false }

        var updated = false
        for block in blocks.dropFirst() {
            guard let firstLine = block.components(separatedBy: .newlines).first?.trimmingCharacters(in: .whitespaces),
                  let colonIdx = firstLine.firstIndex(of: ":"),
                  let fanIdx = Int(firstLine[..<colonIdx].trimmingCharacters(in: .whitespaces)),
                  fanIdx < fans.count else {
                continue
            }

            if let name = extractValue(pattern: #"Fan ID\s*:\s*([^\n\r]+)"#, from: block) {
                let trimmed = name.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    fans[fanIdx] = FanModel(
                        id: fans[fanIdx].id,
                        name: trimmed,
                        currentRPM: fans[fanIdx].currentRPM,
                        minRPM: fans[fanIdx].minRPM,
                        maxRPM: fans[fanIdx].maxRPM,
                        targetRPM: fans[fanIdx].targetRPM,
                        isManual: fans[fanIdx].isManual
                    )
                }
            }

            if let curStr = extractValue(pattern: #"Current speed\s*:\s*([\d.]+)"#, from: block),
               let cur = Double(curStr) {
                fans[fanIdx].currentRPM = cur
                updated = true
            }

            if let minStr = extractValue(pattern: #"Minimum speed\s*:\s*([\d.]+)"#, from: block),
               let minVal = Double(minStr), minVal > 0 {
                fans[fanIdx].minRPM = minVal
            }

            if let maxStr = extractValue(pattern: #"Maximum speed\s*:\s*([\d.]+)"#, from: block),
               let maxVal = Double(maxStr), maxVal > 0 {
                fans[fanIdx].maxRPM = maxVal
            }
        }
        return updated
    }

    private func extractValue(pattern: String, from text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[range])
    }

    private func parseSMCKeyFloat(_ line: String) -> Double? {
        // Matches digits after closing bracket ']' e.g. "F0Ac [fpe2] 1498 (bytes 05 dc)"
        let pattern = #"\]\s*([\d.]+)"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)),
           let range = Range(match.range(at: 1), in: line) {
            return Double(line[range])
        }
        return nil
    }

    // MARK: - Fan Speed Control Execution

    public func setFanMode(_ mode: FanControlMode) {
        self.selectedFanMode = mode
        applyActiveFanProfile()
    }

    public func setManualSpeed(rpm: Double) {
        self.manualRPM = rpm
        if selectedFanMode == .manual {
            applyActiveFanProfile()
        }
    }

    private func applyActiveFanProfile() {
        guard hasFans else { return }

        switch selectedFanMode {
        case .auto:
            for f in fans {
                _ = shell("sudo -n /usr/local/bin/displaycontrol-power fan-auto \(f.id) 2>/dev/null || true")
            }

        case .manual:
            for f in fans {
                let clamped = min(max(manualRPM, f.minRPM), f.maxRPM)
                _ = shell("sudo -n /usr/local/bin/displaycontrol-power fan-set \(f.id) \(Int(clamped)) 2>/dev/null || true")
            }

        case .boost:
            for f in fans {
                _ = shell("sudo -n /usr/local/bin/displaycontrol-power fan-set \(f.id) \(Int(f.maxRPM)) 2>/dev/null || true")
            }

        case .smartCurve:
            // Calculate target RPM proportionally based on chosen sensor (Macs Fan Control curve)
            let currentTemp: Double
            switch sensorTarget {
            case .cpuAvg:
                currentTemp = cpuAvgTemp > 0 ? cpuAvgTemp : 50.0
            case .cpuPeak:
                currentTemp = cpuPeakTemp > 0 ? cpuPeakTemp : 50.0
            case .gpu:
                currentTemp = gpuAvgTemp > 0 ? gpuAvgTemp : 50.0
            case .hotspot:
                currentTemp = hotspotTemp > 0 ? hotspotTemp : 50.0
            case .ssd:
                currentTemp = ssdTemp > 0 ? ssdTemp : 45.0
            }

            for f in fans {
                let targetRPM: Double
                if currentTemp <= smartCurveStartTemp {
                    targetRPM = f.minRPM
                } else if currentTemp >= smartCurveMaxTemp {
                    targetRPM = f.maxRPM
                } else {
                    let denom = max(1.0, smartCurveMaxTemp - smartCurveStartTemp)
                    let ratio = (currentTemp - smartCurveStartTemp) / denom
                    targetRPM = f.minRPM + ratio * (f.maxRPM - f.minRPM)
                }
                let clamped = min(max(targetRPM, f.minRPM), f.maxRPM)
                _ = shell("sudo -n /usr/local/bin/displaycontrol-power fan-set \(f.id) \(Int(clamped)) 2>/dev/null || true")
            }
        }
    }

    // MARK: - Safe SMC Restoration & Power Management

    public func restoreFansToAuto() {
        guard hasFans else { return }
        for f in fans {
            _ = shell("sudo -n /usr/local/bin/displaycontrol-power fan-auto \(f.id) 2>/dev/null || true")
        }
    }

    @objc private func handleSystemSleep() {
        restoreFansToAuto()
    }

    @objc private func handleSystemWake() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.refreshMetrics()
            self?.applyActiveFanProfile()
        }
    }

    public func updateMenuBarDisplay() {
        guard showMenuBarMetrics else {
            onMenuBarUpdate?(nil)
            return
        }
        let temp = cpuAvgTemp > 0 ? Int(cpuAvgTemp) : (cpuPeakTemp > 0 ? Int(cpuPeakTemp) : 0)
        guard temp > 0 else {
            onMenuBarUpdate?(nil)
            return
        }

        if hasFans && menuBarDisplayMode == 1 {
            let maxCurrentRPM = fans.map(\.currentRPM).max() ?? 0
            let rpmFormatted = maxCurrentRPM > 999 ? String(format: "%.1fk", maxCurrentRPM / 1000.0) : "\(Int(maxCurrentRPM))"
            onMenuBarUpdate?("\(temp)°C • \(rpmFormatted)")
        } else {
            onMenuBarUpdate?("\(temp)°C")
        }
    }
}
