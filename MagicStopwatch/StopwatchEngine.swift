import SwiftUI
import Combine

struct Lap: Identifiable, Equatable {
    let id = UUID()
    let lapNumber: Int
    let lapTime: TimeInterval
    let totalTime: TimeInterval
}

class StopwatchEngine: ObservableObject {
    enum ForceMode: String, CaseIterable {
        case finalOnly = "Final Stop Only"
        case sequence = "Full Sequence"
    }
    
    @Published var elapsedTime: TimeInterval = 0
    @Published var isRunning = false
    @Published var laps: [Lap] = []
    
    // Forcing Settings
    @Published var forceMode: ForceMode = .finalOnly
    @Published var sequenceInput: String = "" {
        didSet { parseSequence() }
    }
    @Published var forcedStopDigits: String = ""
    @Published var forcedLapDigits: [String] = []
    @Published var nextForcedLapIndex: Int = 0
    @Published var isArmed: Bool = false
    
    // Lap Colors
    var shortestLapID: UUID? {
        guard laps.count >= 2 else { return nil }
        return laps.min(by: { $0.lapTime < $1.lapTime })?.id
    }
    
    var longestLapID: UUID? {
        guard laps.count >= 2 else { return nil }
        return laps.max(by: { $0.lapTime < $1.lapTime })?.id
    }
    
    private var timer: AnyCancellable?
    private var startTime: Date?
    private var accumulatedTime: TimeInterval = 0
    private var currentLapStartTime: Date?
    private var accumulatedLapTime: TimeInterval = 0
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        startTime = Date()
        currentLapStartTime = Date()
        
        timer = Timer.publish(every: 0.03, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTime()
            }
    }
    
    func stop() {
        guard isRunning else { return }
        isRunning = false
        timer?.cancel()
        timer = nil
        
        if let startTime = startTime {
            accumulatedTime += Date().timeIntervalSince(startTime)
        }
        if let currentLapStartTime = currentLapStartTime {
            accumulatedLapTime += Date().timeIntervalSince(currentLapStartTime)
        }
        
        // Handle Forcing on Stop
        if isArmed && !forcedStopDigits.isEmpty {
            elapsedTime = forceHundredths(on: elapsedTime, forced: forcedStopDigits)
        }
    }
    
    func reset() {
        stop()
        elapsedTime = 0
        accumulatedTime = 0
        accumulatedLapTime = 0
        laps = []
        nextForcedLapIndex = 0
    }
    
    func lap() {
        let totalTime = elapsedTime
        var lapTime: TimeInterval
        
        if let currentLapStartTime = currentLapStartTime {
            lapTime = accumulatedLapTime + Date().timeIntervalSince(currentLapStartTime)
        } else {
            lapTime = accumulatedLapTime
        }
        
        // Handle Forced Laps (Only in Sequence mode)
        if isArmed && forceMode == .sequence && nextForcedLapIndex < forcedLapDigits.count {
            let forcedStr = forcedLapDigits[nextForcedLapIndex]
            lapTime = forceHundredths(on: lapTime, forced: forcedStr)
            nextForcedLapIndex += 1
        }
        
        let newLap = Lap(
            lapNumber: laps.count + 1,
            lapTime: lapTime,
            totalTime: totalTime
        )
        laps.insert(newLap, at: 0)
        
        currentLapStartTime = Date()
        accumulatedLapTime = 0
    }
    
    private func updateTime() {
        if let startTime = startTime {
            elapsedTime = accumulatedTime + Date().timeIntervalSince(startTime)
        }
    }
    
    private func forceHundredths(on time: TimeInterval, forced: String) -> TimeInterval {
        guard let forcedVal = Double(forced) else { return time }
        let baseSeconds = floor(time)
        return baseSeconds + (forcedVal / 100.0) + 0.001
    }
    
    private func parseSequence() {
        var digits = sequenceInput.filter { $0.isNumber }
        guard !digits.isEmpty else {
            forcedStopDigits = ""
            forcedLapDigits = []
            return
        }
        
        if digits.count % 2 != 0 {
            digits = "0" + digits
        }
        
        var pairs: [String] = []
        for i in stride(from: 0, to: digits.count, by: 2) {
            let start = digits.index(digits.startIndex, offsetBy: i)
            let end = digits.index(start, offsetBy: 2)
            pairs.append(String(digits[start..<end]))
        }
        
        if let last = pairs.popLast() {
            forcedStopDigits = last
        }
        forcedLapDigits = pairs
        nextForcedLapIndex = 0
    }
}

