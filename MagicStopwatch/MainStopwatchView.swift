import SwiftUI

struct MainStopwatchView: View {
    @StateObject private var engine = StopwatchEngine()
    @State private var showSettings = false
    @State private var selectedTab = 2
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Color.black.tabItem {
                Label("World Clock", systemImage: "globe")
            }.tag(0)
            
            Color.black.tabItem {
                Label("Alarms", systemImage: "alarm.fill")
            }.tag(1)
            
            StopwatchContentView(engine: engine, showSettings: $showSettings)
                .tabItem {
                    Label("Stopwatch", systemImage: "stopwatch.fill")
                }
                .tag(2)
            
            Color.black.tabItem {
                Label("Timers", systemImage: "timer")
            }.tag(3)
        }
        .tint(.orange)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            SettingsView(engine: engine)
        }
    }
}

struct StopwatchContentView: View {
    @ObservedObject var engine: StopwatchEngine
    @Binding var showSettings: Bool
    
    @State private var tapCount = 0
    @State private var tapTimer: Timer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Timer Display
                Text(formatTime(engine.elapsedTime))
                    .font(.system(size: 88, weight: .thin, design: .default).monospacedDigit())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                    .contentShape(Rectangle()) // Make the whole area tappable
                    .onTapGesture {
                        handleTripleTap()
                    }
                
                // Pagination Dots
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 7, height: 7)
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 7, height: 7)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Controls
                HStack {
                    ControlButton(
                        title: engine.isRunning ? "Lap" : "Reset",
                        color: Color(white: 0.2),
                        textColor: .white,
                        action: {
                            if engine.isRunning {
                                engine.lap()
                            } else {
                                engine.reset()
                            }
                        }
                    )
                    
                    Spacer()
                    
                    ControlButton(
                        title: engine.isRunning ? "Stop" : "Start",
                        color: engine.isRunning ? Color(red: 0.2, green: 0.05, blue: 0.05) : Color(red: 0.05, green: 0.2, blue: 0.05),
                        textColor: engine.isRunning ? .red : .green,
                        action: {
                            if engine.isRunning {
                                engine.stop()
                            } else {
                                engine.start()
                            }
                        }
                    )
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
                
                // Lap List
                Divider()
                    .background(Color(white: 0.2))
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(engine.laps) { lap in
                            LapRow(lap: lap, engine: engine)
                            Divider()
                                .background(Color(white: 0.2))
                                .padding(.leading, 15)
                        }
                    }
                }
                .frame(height: 250)
            }
        }
    }
    
    private func handleTripleTap() {
        tapCount += 1
        tapTimer?.invalidate()
        tapTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { _ in
            if tapCount >= 3 {
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
                showSettings = true
            }
            tapCount = 0
        }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        let hundredths = Int((interval.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d,%02d", minutes, seconds, hundredths)
    }
}

struct ControlButton: View {
    let title: String
    let color: Color
    let textColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .stroke(color.opacity(0.5), lineWidth: 2)
                    .frame(width: 76, height: 76)
                
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(textColor)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LapRow: View {
    let lap: Lap
    let engine: StopwatchEngine
    
    var lapColor: Color {
        if lap.id == engine.shortestLapID {
            return .green
        } else if lap.id == engine.longestLapID {
            return .red
        }
        return .white
    }
    
    var body: some View {
        HStack {
            Text("Lap \(lap.lapNumber)")
            Spacer()
            Text(formatTime(lap.lapTime))
                .monospacedDigit()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .font(.system(size: 17))
        .foregroundColor(lapColor)
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        let hundredths = Int((interval.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d,%02d", minutes, seconds, hundredths)
    }
}

struct SettingsView: View {
    @ObservedObject var engine: StopwatchEngine
    @Environment(\.dismiss) var dismiss
    @State private var newLapValue: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Status") {
                    Toggle("Arm Magic", isOn: $engine.isArmed)
                }
                
                Section("Forced Stop Time") {
                    TextField("Format: MM:SS,hh (e.g. 01:23,45)", text: $engine.forcedStopTime)
                        .keyboardType(.numbersAndPunctuation)
                }
                
                Section("Forced Lap Sequence") {
                    ForEach(0..<engine.forcedLaps.count, id: \.self) { index in
                        Text(engine.forcedLaps[index])
                    }
                    .onDelete { indices in
                        engine.forcedLaps.remove(atOffsets: indices)
                    }
                    
                    HStack {
                        TextField("Add Lap (e.g. 10,00)", text: $newLapValue)
                            .keyboardType(.numbersAndPunctuation)
                        Button("Add") {
                            if !newLapValue.isEmpty {
                                engine.forcedLaps.append(newLapValue)
                                newLapValue = ""
                            }
                        }
                    }
                }
            }
            .navigationTitle("Magic Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
