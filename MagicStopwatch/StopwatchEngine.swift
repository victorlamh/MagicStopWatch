import SwiftUI
import Combine

struct Lap: Identifiable, Equatable {
    let id = UUID()
    let lapNumber: Int
    let lapTime: TimeInterval
    let totalTime: TimeInterval
}

class StopwatchEngine: ObservableObject {
    @Published var elapsedTime: TimeInterval = 0
    @Published var isRunning = false
    @Published var laps: [Lap] = []
    
    // Forcing Settings (Only forcing the last 2 digits)
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
        
        // Refreshing every 0.03 seconds (~33fps) for a smoother, more "real" feel
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
        
        // Handle Forcing on Stop (Replace last 2 digits)
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
        
        // Handle Forced Laps (Replace last 2 digits)
        if isArmed && nextForcedLapIndex < forcedLapDigits.count {
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
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        // New interval: (mins*60) + secs + (forced/100)
        return TimeInterval((minutes * 60) + seconds) + (forcedVal / 100.0)
    }
}
