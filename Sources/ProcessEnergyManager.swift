import Foundation
import Combine

// MARK: - Process Energy & Thermal Monitor

public struct HeavyProcess: Identifiable, Equatable {
    public var id: Int32 { pid }
    public let pid: Int32
    public let name: String
    public let cpu: Double
    public var isFrozen: Bool

    public static func == (lhs: HeavyProcess, rhs: HeavyProcess) -> Bool {
        lhs.pid == rhs.pid && lhs.cpu == rhs.cpu && lhs.isFrozen == rhs.isFrozen
    }
}

@MainActor
public class ProcessEnergyManager: ObservableObject {
    public static let shared = ProcessEnergyManager()

    @Published public var processes: [HeavyProcess] = []
    @Published public var frozenPIDs: Set<Int32> = []
    @Published public var isScanning: Bool = false
    @Published public var lastRefreshed: Date = Date()

    private var timer: Timer?

    private let ignoredNames: Set<String> = [
        "kernel_task", "launchd", "WindowServer", "sysmond", "HyperMac",
        "Activity Monitor", "coreaudiod", "loginwindow", "fseventsd",
        "distnoted", "powerd", "opendirectoryd", "trustd", "UserEventAgent",
        "sandboxd", "diskarbitrationd", "mds", "mds_stores", "mdworker",
        "notifyd", "cfprefsd", "logd", "symptomsd", "containermanagerd"
    ]

    private init() {
        refreshProcesses()
    }

    public func startAutoRefresh() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshProcesses()
            }
        }
    }

    public func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }

    public func refreshProcesses() {
        guard !isScanning else { return }
        isScanning = true

        let currentFrozen = self.frozenPIDs
        let ignored = self.ignoredNames

        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }

            let pipe = Pipe()
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/ps")
            task.arguments = ["-Aceo", "%cpu,pid,comm", "-r"]
            task.standardOutput = pipe

            do {
                try task.run()
                task.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let text = String(data: data, encoding: .utf8) ?? ""
                let lines = text.components(separatedBy: .newlines)

                var found: [HeavyProcess] = []

                for line in lines.dropFirst() {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { continue }
                    let parts = trimmed.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
                    guard parts.count == 3,
                          let cpu = Double(parts[0]),
                          let pid = Int32(parts[1]) else { continue }

                    let rawName = String(parts[2])
                    let shortName = (rawName as NSString).lastPathComponent

                    if !ignored.contains(shortName) && !ignored.contains(rawName) {
                        // Check if frozen
                        let isFrozen = ProcessEnergyManager.isPIDStopped(pid) || currentFrozen.contains(pid)
                        found.append(HeavyProcess(pid: pid, name: shortName, cpu: cpu, isFrozen: isFrozen))
                    }

                    if found.count >= 6 { break }
                }

                DispatchQueue.main.async {
                    self.processes = found
                    self.isScanning = false
                    self.lastRefreshed = Date()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isScanning = false
                }
            }
        }
    }

    nonisolated private static func isPIDStopped(_ pid: Int32) -> Bool {
        let pipe = Pipe()
        let ps = Process()
        ps.executableURL = URL(fileURLWithPath: "/bin/ps")
        ps.arguments = ["-o", "state=", "-p", "\(pid)"]
        ps.standardOutput = pipe
        do {
            try ps.run()
            ps.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let out = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return out.hasPrefix("T")
        } catch {
            return false
        }
    }

    // MARK: - Actions: Freeze (SIGSTOP) and Resume (SIGCONT)

    public func freezeProcess(pid: Int32) {
        kill(pid, SIGSTOP)
        frozenPIDs.insert(pid)
        updateLocalState(pid: pid, isFrozen: true)
    }

    public func resumeProcess(pid: Int32) {
        kill(pid, SIGCONT)
        frozenPIDs.remove(pid)
        updateLocalState(pid: pid, isFrozen: false)
    }

    public func terminateProcess(pid: Int32) {
        kill(pid, SIGTERM)
        frozenPIDs.remove(pid)
        processes.removeAll { $0.pid == pid }
    }

    private func updateLocalState(pid: Int32, isFrozen: Bool) {
        if let idx = processes.firstIndex(where: { $0.pid == pid }) {
            let p = processes[idx]
            processes[idx] = HeavyProcess(pid: p.pid, name: p.name, cpu: isFrozen ? 0.0 : p.cpu, isFrozen: isFrozen)
        }
    }
}
