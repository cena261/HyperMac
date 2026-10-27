import Foundation
import IOKit
import AppKit

// MARK: - Fan Model & Enums

public enum FanControlMode: String, CaseIterable, Codable, Sendable {
    case auto = "auto"
    case manual = "manual"
    case boost = "boost"
    case smartCurve = "smartCurve"

    public var title: String {
        switch self {
        case .auto: return "Tự động (Apple)"
        case .manual: return "Tùy chỉnh RPM"
        case .boost: return "Tối đa 100%"
        case .smartCurve: return "Tự động theo nhiệt"
        }
    }

    public var icon: String {
        switch self {
        case .auto: return "gearshape.2"
        case .manual: return "slider.horizontal.3"
        case .boost: return "bolt.fill"
        case .smartCurve: return "chart.xyaxis.line"
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
    @Published public var isCoolingTriggered: Bool = false
    @Published public var coolTimerMessage: String? = nil

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
    @Published public var smartCurveStartTemp: Double = 60.0
    @Published public var smartCurveMaxTemp: Double = 85.0

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
    }

    private func loadMachineHardwareInfo() {
        var size: size_t = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        let modelString = String(cString: model)

        if modelString.lowercased().contains("air") || modelString.hasPrefix("Mac14,2") || modelString.hasPrefix("Mac14,15") || modelString.hasPrefix("Mac15,12") {
            self.machineModelName = "MacBook Air (Apple Silicon)"
            self.isFanlessModel = true
        } else if modelString.lowercased().contains("pro") {
            self.machineModelName = "MacBook Pro"
            self.isFanlessModel = false
        } else if modelString.lowercased().contains("mini") {
            self.machineModelName = "Mac mini"
            self.isFanlessModel = false
        } else if modelString.lowercased().contains("studio") {
            self.machineModelName = "Mac Studio"
            self.isFanlessModel = false
        } else {
            self.machineModelName = modelString
            self.isFanlessModel = false
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
    }

    // MARK: - Detect Fan Hardware via SMC

    public func detectFans() {
        // Direct SMC query (requires zero sudo)
        let (output, status) = shell("\(smcBinaryPath) -k FNum -r 2>/dev/null || true")
        if status == 0 && output.contains("FNum") && !output.contains("no data") {
            let components = output.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
            for i in 0..<components.count {
                if components[i].hasPrefix("[") && i + 1 < components.count {
                    if let count = Int(components[i + 1]), count > 0 {
                        self.fanCount = count
                        self.hasFans = true
                        self.isFanlessModel = false
                        populateFanList(count: count)
                        return
                    }
                }
            }
            if let last = components.last, let count = Int(last), count > 0 {
                self.fanCount = count
                self.hasFans = true
                self.isFanlessModel = false
                populateFanList(count: count)
                return
            }
        }

        // Fanless machine (e.g. MacBook Air M1/M2/M3)
        self.fanCount = 0
        self.hasFans = false
        self.isFanlessModel = true
        self.fans = []
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
    }

    @objc private func thermalStateChanged() {
        refreshMetrics()
    }

    private func updateFanReadings() {
        guard hasFans else { return }
        for i in 0..<fans.count {
            let (outAct, _) = shell("\(smcBinaryPath) -k F\(i)Ac -r 2>/dev/null || true")
            let (outMin, _) = shell("\(smcBinaryPath) -k F\(i)Mn -r 2>/dev/null || true")
            let (outMax, _) = shell("\(smcBinaryPath) -k F\(i)Mx -r 2>/dev/null || true")

            if let val = parseRPM(outAct), val > 0 { fans[i].currentRPM = val }
            if let val = parseRPM(outMin), val > 0 { fans[i].minRPM = val }
            if let val = parseRPM(outMax), val > 0 { fans[i].maxRPM = val }
        }
    }

    // MARK: - Software Cooling for Fanless Macs
    public func triggerSoftwareCooling() {
        ProcessEnergyManager.shared.refreshProcesses()
        ProcessEnergyManager.shared.freezeTopConsumers()
        refreshMetrics()
    }

    private func parseRPM(_ line: String) -> Double? {
        let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        for part in parts.reversed() {
            if let num = Double(part) { return num }
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
            // Calculate target RPM proportionally based on CPU Temp
            let currentTemp = cpuAvgTemp > 0 ? cpuAvgTemp : 50.0
            for f in fans {
                let targetRPM: Double
                if currentTemp <= smartCurveStartTemp {
                    targetRPM = f.minRPM
                } else if currentTemp >= smartCurveMaxTemp {
                    targetRPM = f.maxRPM
                } else {
                    let ratio = (currentTemp - smartCurveStartTemp) / (smartCurveMaxTemp - smartCurveStartTemp)
                    targetRPM = f.minRPM + ratio * (f.maxRPM - f.minRPM)
                }
                _ = shell("sudo -n /usr/local/bin/displaycontrol-power fan-set \(f.id) \(Int(targetRPM)) 2>/dev/null || true")
            }
        }
    }
}
