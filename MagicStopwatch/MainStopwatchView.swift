import SwiftUI

struct MainStopwatchView: View {
    @StateObject private var engine = StopwatchEngine()
    @State private var showSettings = false
    @State private var selectedTab = 2
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WorldClockView()
                .tabItem { Label("World Clock", systemImage: "globe") }
                .tag(0)
            
            AlarmsView()
                .tabItem { Label("Alarms", systemImage: "alarm.fill") }
                .tag(1)
            
            StopwatchContentView(engine: engine, showSettings: $showSettings)
                .tabItem { Label("Stopwatch", systemImage: "stopwatch.fill") }
                .tag(2)
            
            TimersView()
                .tabItem { Label("Timers", systemImage: "timer") }
                .tag(3)
        }
        .tint(.orange)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            SettingsView(engine: engine)
        }
    }
}

// MARK: - Dummy Pages for Fidelity
struct WorldClockView: View {
    var body: some View {
        NavigationStack {
            List {
                ClockRow(city: "Cupertino", time: "04:11", offset: "Today, -9HRS")
                ClockRow(city: "Paris", time: "13:11", offset: "Today, +0HRS")
                ClockRow(city: "Tokyo", time: "21:11", offset: "Today, +8HRS")
            }
            .listStyle(.plain)
            .navigationTitle("World Clock")
        }
    }
}

struct ClockRow: View {
    let city: String
    let time: String
    let offset: String
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(offset).font(.caption).foregroundColor(.secondary)
                Text(city).font(.title3)
            }
            Spacer()
            Text(time).font(.system(size: 48, weight: .light))
        }
        .padding(.vertical, 8)
    }
}

struct AlarmsView: View {
    var body: some View {
        NavigationStack {
            List {
                AlarmRow(time: "07:00", label: "Work", isOn: false)
                AlarmRow(time: "08:30", label: "Gym", isOn: false)
            }
            .navigationTitle("Alarms")
        }
    }
}

struct AlarmRow: View {
    let time: String
    let label: String
    @State var isOn: Bool
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(time).font(.system(size: 48, weight: .light)).foregroundColor(isOn ? .white : .secondary)
                Text(label).font(.caption)
            }
            Spacer()
            Toggle("", isOn: $isOn)
        }
    }
}

struct TimersView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                ZStack {
                    Circle().stroke(Color(white: 0.1), lineWidth: 8)
                    Text("00:00:00").font(.system(size: 64, weight: .thin, design: .default).monospacedDigit())
                }
                .frame(width: 300, height: 300)
                Spacer()
                HStack {
                    Circle().fill(Color(white: 0.1)).frame(width: 80, height: 80).overlay(Text("Cancel").foregroundColor(.secondary))
                    Spacer()
                    Circle().fill(Color(red: 0.05, green: 0.2, blue: 0.05)).frame(width: 80, height: 80).overlay(Text("Start").foregroundColor(.green))
                }
                .padding(40)
            }
            .navigationTitle("Timer")
        }
    }
}

// MARK: - Stopwatch Content
struct StopwatchContentView: View {
    @ObservedObject var engine: StopwatchEngine
    @Binding var showSettings: Bool
    
    @State private var tapCount = 0
    @State private var tapTimer: Timer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Text(formatTime(engine.elapsedTime))
                    .font(.system(size: 88, weight: .thin, design: .default).monospacedDigit())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                    .contentShape(Rectangle())
                    .onTapGesture { handleTripleTap() }
                
                HStack(spacing: 8) {
                    Circle().fill(Color.white).frame(width: 7, height: 7)
                    Circle().fill(Color.gray).frame(width: 7, height: 7)
                }
                .padding(.top, 20)
                
                Spacer()
                
                HStack {
                    ControlButton(title: engine.isRunning ? "Lap" : "Reset", color: Color(white: 0.2), textColor: .white) {
                        if engine.isRunning { engine.lap() } else { engine.reset() }
                    }
                    Spacer()
                    ControlButton(title: engine.isRunning ? "Stop" : "Start", color: engine.isRunning ? Color(red: 0.2, green: 0.05, blue: 0.05) : Color(red: 0.05, green: 0.2, blue: 0.05), textColor: engine.isRunning ? .red : .green) {
                        if engine.isRunning { engine.stop() } else { engine.start() }
                    }
                }
                .padding(.horizontal, 30).padding(.bottom, 20)
                
                Divider().background(Color(white: 0.2))
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(engine.laps) { lap in
                            LapRow(lap: lap, engine: engine)
                            Divider().background(Color(white: 0.2)).padding(.leading, 15)
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
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
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

// MARK: - Components
struct ControlButton: View {
    let title: String; let color: Color; let textColor: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(color).frame(width: 80, height: 80)
                Circle().stroke(color.opacity(0.5), lineWidth: 2).frame(width: 76, height: 76)
                Text(title).font(.system(size: 17)).foregroundColor(textColor)
            }
        }.buttonStyle(PlainButtonStyle())
    }
}

struct LapRow: View {
    let lap: Lap; let engine: StopwatchEngine
    var lapColor: Color {
        if lap.id == engine.shortestLapID { return .green }
        if lap.id == engine.longestLapID { return .red }
        return .white
    }
    var body: some View {
        HStack {
            Text("Lap \(lap.lapNumber)")
            Spacer()
            Text(formatTime(lap.lapTime)).monospacedDigit()
        }
        .padding(.vertical, 12).padding(.horizontal, 20).font(.system(size: 17)).foregroundColor(lapColor)
    }
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        let hundredths = Int((interval.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d,%02d", minutes, seconds, hundredths)
    }
}

// MARK: - Simplified Settings
struct SettingsView: View {
    @ObservedObject var engine: StopwatchEngine
    @Environment(\.dismiss) var dismiss
    @State private var newLapValue: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Arm Magic", isOn: $engine.isArmed)
                } header: { Text("Status") } footer: { Text("When armed, only the last 2 digits (hundredths) will be forced. The minutes and seconds will remain real.") }
                
                Section("Final Stop Force") {
                    TextField("2 digits (e.g. 42)", text: $engine.forcedStopDigits)
                        .keyboardType(.numberPad)
                        .onChange(of: engine.forcedStopDigits) { newValue in
                            engine.forcedStopDigits = String(newValue.prefix(2)).filter { $0.isNumber }
                        }
                }
                
                Section("Lap Sequence Force") {
                    ForEach(0..<engine.forcedLapDigits.count, id: \.self) { index in
                        Text("Lap \(index + 1): .\(engine.forcedLapDigits[index])")
                    }
                    .onDelete { engine.forcedLapDigits.remove(atOffsets: $0) }
                    
                    HStack {
                        TextField("2 digits", text: $newLapValue)
                            .keyboardType(.numberPad)
                            .onChange(of: newLapValue) { newValue in
                                newLapValue = String(newValue.prefix(2)).filter { $0.isNumber }
                            }
                        Button("Add") {
                            if !newLapValue.isEmpty {
                                engine.forcedLapDigits.append(newLapValue)
                                newLapValue = ""
                            }
                        }
                    }
                }
            }
            .navigationTitle("Magic Settings")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}
