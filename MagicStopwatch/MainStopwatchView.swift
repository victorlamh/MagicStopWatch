import SwiftUI

struct MainStopwatchView: View {
    @StateObject private var engine = StopwatchEngine()
    @State private var showSettings = false
    @State private var timerTapCount = 0
    @State private var timerTapTimer: Timer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Timer Display
                Text(engine.timeString(from: engine.elapsedTime))
                    .font(.system(size: 88, weight: .thin, design: .default).monospacedDigit())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                    .onTapGesture {
                        handleTimerTap()
                    }
                
                Spacer()
                
                // Controls
                HStack {
                    // Left Button: Lap / Reset
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
                    
                    // Right Button: Start / Stop
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
                .padding(.bottom, 30)
                
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
                .frame(height: 300)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(engine: engine)
        }
    }
    
    private func handleTimerTap() {
        timerTapCount += 1
        timerTapTimer?.invalidate()
        timerTapTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            if timerTapCount >= 3 {
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
                showSettings = true
            }
            timerTapCount = 0
        }
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
    
    var body: some View {
        HStack {
            Text("Lap \(lap.lapNumber)")
                .foregroundColor(.white)
            Spacer()
            Text(engine.timeString(from: lap.lapTime))
                .monospacedDigit()
                .foregroundColor(.white)
            Spacer()
            Text(engine.timeString(from: lap.totalTime))
                .monospacedDigit()
                .foregroundColor(.white)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .font(.system(size: 17))
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
                    TextField("Format: MM:SS.hh (e.g. 01:23.45)", text: $engine.forcedStopTime)
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
                        TextField("Add Lap (e.g. 10.00)", text: $newLapValue)
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
