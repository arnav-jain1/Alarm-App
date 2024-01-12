//
//  ContentView.swift
//  Alarm
//
//  Created by Arnav on 12/29/23.
//
import SwiftUI
import Foundation
import UserNotifications

// MARK: ContentView
struct ContentView: View {
    @StateObject private var notificationManager = NotificationManager()
    @State private var currentTime: Date = Date()
    let wordleAnswers: [String] = [
        "mural", "aging", "twirl", "scant", "lunge",
        "cable", "stony", "final", "liner", "threw",
        "brief", "route", "heard", "doing", "lunch",
        "blond", "court", "stole", "thing", "large",
        "north", "tweak", "still", "relic", "block",
        "aloof", "snake", "ember"
    ]
    
    @State private var secretWord: String = ""
    @State private var wordle: String = ""
    @State private var feedbackMessage: String = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    let checkTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    
    var body: some View {
        VStack {
            Text("\(formatTime(currentTime))")
                .font(.largeTitle)
                .onReceive(timer) { _ in
                    self.currentTime = Date()
                }
                .onAppear {
                    
                    notificationManager.scheduleNotification()
                    wordle = wordleAnswers[getCurrentDayIndex()]
                }
            
            TextField("Enter wordle", text: $secretWord)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Submit") {
                if secretWord.lowercased() == wordle.lowercased() {
                    feedbackMessage = "Correct! 😀 Alarm stopped"
                    notificationManager.word = true
                } else {
                    feedbackMessage = "Try again!"
                }
                secretWord = "" // Reset the text field
            }
            .padding()
            
            Text(feedbackMessage)
                .padding()
            
            
        }
    }
    
    func formatTime(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        return dateFormatter.string(from: date)
    }
    
    func getCurrentDayIndex() -> Int {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: Date())
        return (day - 1)
    }
}


// MARK: NotificationManager
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var hr = 16
    @Published var min = 41
    @Published var second = 30
    @Published var word = false

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                let content = UNMutableNotificationContent()
                content.title = "Wake Up"
                content.body = "It's time!"
                content.sound = UNNotificationSound(named: UNNotificationSoundName("wakeup.wav"))
                
                var dateComponents = DateComponents()
                dateComponents.hour = self.hr
                dateComponents.minute = self.min
                dateComponents.second = self.second
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                
                center.add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error)")
                    } else {
                        print("Notification scheduled for \(self.hr):\(self.min)")
                    }
                }
            } else {
                print("Permission denied for notifications.")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // Check if self.word is false
        if !self.word {
            // Increment self.min
            self.min += 1
            
            // Call scheduleNotification() to set the next notification
            self.scheduleNotification()
        }
        
        completionHandler()
    }
    
    
    func checkAndUpdateSettings() {
        let currentHour = Calendar.current.component(.hour, from: Date())
        if currentHour >= 20 { // 20 represents 8 PM in 24-hour format
            self.hr = 8  // Set to 8 AM
            self.word = false
            scheduleNotification()
        }
    }
}

// MARK: Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
