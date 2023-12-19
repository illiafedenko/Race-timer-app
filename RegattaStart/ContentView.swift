//
//  ContentView.swift
//  RegattaStart
//
//  Created by Patrick Flanagan on 12/13/23.
//

import SwiftUI
import AVFoundation
import UserNotifications

//var bombSoundEffect: AVAudioPlayer?

struct ContentView: View {
    
    @State private var hours = Calendar.current.component(.hour, from: Date()) % 12
    @State private var minutes = Calendar.current.component(.minute, from: Date())
    @State private var seconds = Calendar.current.component(.second, from: Date())
    @State private var period = Calendar.current.component(.hour, from: Date()) >= 12 ? "PM" : "AM"
    
    @State private var totalSeconds: Int?
    @State private var isActive = false
    @State private var showAlert = false
    let calendar = Calendar.current
    
    init() {
        // Request notification permissions from the user
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permissions granted")
                

            } else if let error = error {
                print("Notification permissions error:", error)
            }
        }
        
    }
    
    
    var body: some View {
        ZStack{
            Color(red: 0.12, green: 0.12, blue: 0.13)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Text("Set Race Time").foregroundColor(.white)
                    .font(.largeTitle)
                    
                HStack(spacing: 5) {
                    // Hours picker for 12-hour format
                    Picker("Hours", selection: $hours) {
                        ForEach(1..<13, id: \.self) { hour in
                            Text("\(hour)").foregroundColor(.white)
                        }
                    }
                    .frame(width: 80, height: 150)
                    .clipped()
                    .compositingGroup()
                    
                    // Minutes picker
                    Picker("Minutes", selection: $minutes) {
                        ForEach(0..<60, id: \.self) { minute in
                            Text("\(minute)").foregroundColor(.white)
                        }
                    }
                    .frame(width: 80, height: 150)
                    .clipped()
                    .compositingGroup()
                    
                    // Seconds picker
                    Picker("Seconds", selection: $seconds) {
                        ForEach(0..<60, id: \.self) { second in
                            Text("\(second)").foregroundColor(.white)
                        }
                    }
                    .frame(width: 80, height: 150)
                    .clipped()
                    .compositingGroup()
                    
                    // AM/PM picker
                    Picker("Period", selection: $period) {
                            Text("AM").foregroundColor(.white).tag("AM")
                            Text("PM").foregroundColor(.white).tag("PM")
                        }
                        .frame(width: 80, height: 150)
                        .clipped()
                }.pickerStyle(WheelPickerStyle())
                
                Button(action: isActive ? stopRace : startRace) {
                    Text(isActive ? "Stop" : "Start Race")
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        .background(Color(red: 0.2, green: 0.2, blue: 0.23))
                        .cornerRadius(20)
                        .alert(isPresented: $showAlert) {
                            Alert(
                                title: Text("Invalid Start Time"),
                                message: Text("The selected start time is in the past."),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                }
                
                if isActive, let totalSeconds = totalSeconds {
                    TimerView(initialTime: totalSeconds)
                        .padding()
                }
            }
        }
    }
    
    func startRace() {
        let currentTime = Date()
        let currentHour = calendar.component(.hour, from: currentTime)
        let currentMinute = calendar.component(.minute, from: currentTime)
        let currentSecond = calendar.component(.second, from: currentTime)
        let currentTotalSeconds = currentHour * 3600 + currentMinute * 60 + currentSecond
        
        // Convert 12-hour formatted time to 24-hour format for calculation
        let raceHour = period == "AM" ? (hours % 12) : ((hours % 12) + 12)
        let totalSecond = raceHour * 3600 + minutes * 60 + seconds
        
        if totalSecond <= currentTotalSeconds {
            showAlert = true
        } else {
            isActive = true
            totalSeconds = totalSecond - currentTotalSeconds
        }
    }
    
    func stopRace() {
        isActive = false
        totalSeconds = nil
    }
    
    
}

func playSound(title: String, subtitle: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.subtitle = subtitle
    content.sound = UNNotificationSound.default
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

    // choose a random identifier
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

    // add our notification request
    UNUserNotificationCenter.current().add(request)
}

struct TimerView: View {
    @State private var timeRemaining: Int
    @State private var timer: Timer?
    
    init(initialTime: Int) {
        _timeRemaining = State(initialValue: initialTime)
    }
    
    var body: some View {
        Text(timeString(time: TimeInterval(timeRemaining)))
            .font(.largeTitle)
            .onAppear(perform: setupTimer)
            .onDisappear(perform: { timer?.invalidate() })
            .foregroundColor(.white)
    }
    
    func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                print(timeRemaining)
            // Trigger specific alerts based on the remaining time
                if timeRemaining % 60 == 0 {
                    // Vibrate every minute until the final minute
                    playSound(title: "One Minute Passed", subtitle: "Next check in 60 seconds")
                    // Optionally play a sound here
                } else if timeRemaining % 10 == 0 && timeRemaining < 60 {
                    // More frantic alert every 10 seconds in the final minute
                    playSound(title: "Final Countdown", subtitle: "\(timeRemaining) seconds!")
                    // Optionally implement different vibration here
                } else if timeRemaining <= 5 {
                    // Final 5 seconds, alert every second
                    playSound(title: "Get Ready!", subtitle: "Starting in \(timeRemaining)...")
                    // Optionally implement more intense vibration here
                }
                
                timeRemaining -= 1
            } else {
                // Very prominent final alert
                playSound(title: "Race Start", subtitle: "Go!")
                // Optionally implement most intense vibration here
                self.timer?.invalidate()
            }
        }
    }
    
    func timeString(time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
