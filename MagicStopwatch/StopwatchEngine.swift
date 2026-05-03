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
    
    // Forcing Settings
    @Published var forcedStopTime: String = ""
    @Published var forcedLaps: [String] = []
    @Published var nextForcedLapIndex: Int = 0
    @Published var isArmed: Bool = false
    
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
        
        timer = Timer.publish(every: 0.01, on: .main, in: .common)
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
        if isArmed && !forcedStopTime.isEmpty {
            if let forcedInterval = parseTimeInterval(forcedStopTime) {
                elapsedTime = forcedInterval
            }
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
        
        // Handle Forced Laps
        if isArmed && nextForcedLapIndex < forcedLaps.count {
            let forcedStr = forcedLaps[nextForcedLapIndex]
            if let forcedInterval = parseTimeInterval(forcedStr) {
                lapTime = forcedInterval
                // Adjust total time if needed? Usually for magic we just want the lap row to show the forced value.
                // In a real stopwatch, lapTime + previousTotal = currentTotal.
                // We'll just force the lapTime display for now.
            }
            nextForcedLapIndex += 1
        }
        
        let newLap = Lap(
            lapNumber: laps.count + 1,
            lapTime: lapTime,
            totalTime: totalTime
        )
        laps.insert(newLap, at: 0)
        
        // Reset lap timer
        currentLapStartTime = Date()
        accumulatedLapTime = 0
    }
    
    private func updateTime() {
        if let startTime = startTime {
            elapsedTime = accumulatedTime + Date().timeIntervalSince(startTime)
        }
    }
    
    func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        let hundredths = Int((interval.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
    }
    
    private func parseTimeInterval(_ timeString: String) -> TimeInterval? {
        // Expected format: MM:SS.hh or SS.hh
        let components = timeString.split(separator: ":")
        if components.count == 2 {
            if let mins = Double(components[0]), let secsAndHuns = Double(components[1]) {
                return (mins * 60) + secsAndHuns
            }
        } else if components.count == 1 {
            return Double(components[0])
        }
        return nil
    }
}
