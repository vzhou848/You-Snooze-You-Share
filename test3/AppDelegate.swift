//
//  AppDelegate.swift
//  test3
//
//  Created by Vivian Zhou on 11/29/16.
//  Copyright © 2016 viv. All rights reserved.
//

import UIKit
import UserNotifications
import Fabric
import TwitterKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // window is for allowing the views to exist
    var window: UIWindow?
    
    // player is for playing audio when the alarm goes off
    var player: AVAudioPlayer?
    
    // function that is called when the app is openned for the first time or whenever the app is openned after terminating
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        //Requesting Authorization for notifications
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if granted {
                print("Authorization granted!")
            } else {
                print("Authorization denied :(")
            }
        }
        
        // check that user is logged into twitter
        Fabric.with([Twitter.self])

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // reference the AlarmTableViewController so that information from that view controller can be accessed
        let currentNavigationController = self.window?.rootViewController as! UINavigationController
        let currentViewController = currentNavigationController.viewControllers[0] as! AlarmTableViewController
        
        // access the length of the alarms array from AlarmTableViewController
        if currentViewController.alarms.count == 0 {
            // load any saved alarms if the length of the alarms array is zero
            if let savedAlarms = currentViewController.loadAlarms() {
                currentViewController.alarms += savedAlarms
            }
        }
        
        // check if any notifications have just gone off
        checkNotifications(array: currentViewController.alarms)
        
        // delete any alarms that were created through snoozing and have already gone off
        deleteSnoozeAlarms(array: currentViewController.alarms)
    }
    
    // function for checking if any notifications went off less than a minute ago
    func checkNotifications(array: Array<Alarm>) {
        let array = array
        
        // if any alarms exist, do the following if block
        if array.count > 0 {
            
            // obtain actual current hour and minute
            let date = NSDate()
            let calendar = NSCalendar.current
            let hour = calendar.component(.hour, from: date as Date)
            let minutes = calendar.component(.minute, from: date as Date)
            
            // access AlarmTableViewController
            var currentViewController: AlarmTableViewController
            let currentNavigationController = self.window?.rootViewController as! UINavigationController
            currentViewController = currentNavigationController.viewControllers[0] as! AlarmTableViewController
            
            // check all alarms in the alarms array to see if any are both on and went off less than a minute ago
            for alarm in array {
                // if alarm is on, do the following
                if alarm.onoff == true {
                    
                    // obtain the hour and minute that the alarm went off
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "h:mm a"
                    let alarmdate = dateFormatter.date(from: alarm.time)
                    
                    // convert the alarm's hour and minute into sightly different values to compare later
                    dateFormatter.dateFormat = "h"
                    var alarmhour = dateFormatter.string(from: alarmdate!)
                    dateFormatter.dateFormat = "a"
                    let alarmAmpm = dateFormatter.string(from: alarmdate!)
                    dateFormatter.dateFormat = "mm"
                    let alarmminute = dateFormatter.string(from: alarmdate!)
                    
                    
                    var afternoon: Int?
                    var checkered = 0
                    
                    // convert hour based on AM or PM
                    if alarmAmpm == "PM" {
                        if alarmhour == "12" {
                            afternoon = Int(alarmhour)! - 12
                            checkered = 1
                            print("afternoon is \(afternoon)")
                        }
                        if checkered == 1 {
                            afternoon = afternoon! + 12
                            print("2 afternoon is \(afternoon)")
                        }
                        else {
                            afternoon = Int(alarmhour)! + 12
                            print("3 afternoon is \(afternoon)")
                        }
                        alarmhour = String(describing: afternoon)
                        print("4 alarmhour is \(alarmhour)")
                    }
                    else if alarmAmpm == "AM" {
                        print("11111 it is AM")
                        if alarmhour == "12" {
                            alarmhour = String(Int(alarmhour)! - 12)
                        }
                    }
                    else {
                        print(alarmAmpm)
                    }
                    
                    // remove excess characters and such from the alarmhour variable
                    alarmhour = alarmhour.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range:nil)
                    alarmhour = alarmhour.replacingOccurrences(of: "Optional", with: "", options: NSString.CompareOptions.literal, range:nil)
                    alarmhour = alarmhour.replacingOccurrences(of: "(", with: "", options: NSString.CompareOptions.literal, range:nil)
                    alarmhour = alarmhour.replacingOccurrences(of: ")", with: "", options: NSString.CompareOptions.literal, range:nil)
                    
                    // check if current time is same as the alarm time. If so, trigger alarm popup
                    if Int(alarmhour) == hour && Int(alarmminute) == minutes {
                        // play sound of the alarm
                        playSound()
                        
                        // trigger twitter posting popup
                        ShowTwitterPopup(viewController: currentViewController, alarm: alarm)
                    }
                }
            }
        }
    }
    
    // function for allowing the twitter popup, which allows users to either post and snooze, or cancel the alarm
    func ShowTwitterPopup(viewController: UIViewController, alarm: Alarm) {
        
        // generate a random number to be appended onto the tweet, as twitter doesn't allow the same tweet to be posted mutliple times
        let counter = Int(arc4random())
        
        // compose tweet with set text and set image
        let composer = TWTRComposer()
    
        composer.setText("On a scale from 1 to \(counter), my laziness is a \(counter)")
        composer.setImage(UIImage(named: "fabric"))
    
        // Called from a UIViewController
        composer.show(from: viewController) { result in
            if (result == TWTRComposerResult.cancelled) {
                print("Tweet composition cancelled")
                
                // stop the sound
                if let player = self.player {
                    player.stop()
                }
            }
            else {
                print("Sending tweet!")
                
                // stop the sound
                if let player = self.player {
                    player.stop()
                }
                self.rescheduleNotification(alarm: alarm)
            }
        }
    }
    
    // function to reschedule a notification of snooze/post is pressed
    func rescheduleNotification(alarm: Alarm) {
        
        // set content in the notification
        let content = UNMutableNotificationContent()
        content.title = "Alarm"
        content.subtitle = "Wake up! Open the app to turn off the sounds."
        content.body = "ALARM ALARM ALARM"
        content.sound = UNNotificationSound.init(named: "alarmsound.mp3")
        
        
        // convert time to a Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        let time = dateFormatter.date(from: alarm.time)
        
        // get hour and minute components and set as a DateComponent()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time!)
        let minute = calendar.component(.minute, from: time!)
        
        var date = DateComponents()
        date.hour = hour
        date.minute = minute + 5
        
        // check if the added 5 minutes changes the minutes or hours of the new alarm
        if date.minute! > 59 {
            if let datehour = date.hour {
                date.hour = 1 + datehour
            }
            date.minute = date.minute! - 60
            if date.hour == 24 {
                date.hour = date.hour! - 24
            }
        }
        
        // remove excess characters from the new Alarm's hour
        var stringDateHour = String(describing: date.hour)
        stringDateHour = stringDateHour.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range:nil)
        stringDateHour = stringDateHour.replacingOccurrences(of: "Optional(", with: "", options: NSString.CompareOptions.literal, range:nil)
        stringDateHour = stringDateHour.replacingOccurrences(of: ")", with: "", options: NSString.CompareOptions.literal, range:nil)
        date.hour = Int(stringDateHour)
        
        // remove excess characters from the new Alarm's minutes
        var stringDateMinute = String(describing: date.minute)
        stringDateMinute = stringDateMinute.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range:nil)
        stringDateMinute = stringDateMinute.replacingOccurrences(of: "Optional(", with: "", options: NSString.CompareOptions.literal, range:nil)
        stringDateMinute = stringDateMinute.replacingOccurrences(of: ")", with: "", options: NSString.CompareOptions.literal, range:nil)
        if Int(stringDateMinute)! < 10 {
            stringDateMinute = "0" + stringDateMinute
        }
        date.minute = Int(stringDateMinute)
        
        // set trigger and request identifier for notification
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
        
        // request notification
        let request = UNNotificationRequest(identifier: "-1", content: content, trigger: trigger)
        
        // set the delegate of the UNUserNotificationCenter
        let currentNavigationController = self.window?.rootViewController as! UINavigationController
        let currentViewController = currentNavigationController.viewControllers[0] as! AlarmTableViewController
        UNUserNotificationCenter.current().delegate = currentViewController
        
        // log if an error occurs
        UNUserNotificationCenter.current().add(request){(error) in
            if (error != nil){
                print(error?.localizedDescription as Any)
            }
        }
        
        print("stringDateHour is \(stringDateHour)")
        // reconvert the alarm's hour back into am and pm terms
        var ampm = "AM"
        if Int(stringDateHour)! > 12 {
            stringDateHour = String(Int(stringDateHour)! - 12)
            ampm = "PM"
        }
        print("2 stringDateHour is \(stringDateHour)")
        
        stringDateHour = stringDateHour.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range:nil)
        stringDateHour = stringDateHour.replacingOccurrences(of: "Optional(", with: "", options: NSString.CompareOptions.literal, range:nil)
        stringDateHour = stringDateHour.replacingOccurrences(of: ")", with: "", options: NSString.CompareOptions.literal, range:nil)
        
        print("3 stringDateHour is \(stringDateHour)")
        
        // concatenate together the string version of the alarm time to be used when setting hte alarm
        let alarmtime = stringDateHour + ":" + stringDateMinute + " " + ampm
        
        // set the values of the newly created/edited alarm. all snooze-created alarms have id: -1
        let newalarm = Alarm(time: alarmtime, onoff: true, id: -1)
        
        // add the new alarm to the alarms array
        currentViewController.alarms.append(newalarm!)
        currentViewController.saveAlarms()
        
        // insert a new row into the AlarmTableViewController
        let newIndexPath = NSIndexPath(row: currentViewController.alarms.count - 1, section: 0)
        currentViewController.tableView.insertRows(at: [newIndexPath as IndexPath], with: .bottom)
    }
    
    // function for deleting alarms created by the snooze button that have also already gone off
    func deleteSnoozeAlarms(array: Array<Alarm>) {
        var array = array
        // only do this if there are actually alarms
        if array.count > 0 {
            var b = 0
            // go through each alarm and check if it is a snooze alarm
            for i in 0..<array.count {
                // if the alarm is a snooze alarm, check if it already went off
                if array[i - b].id == -1 {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "h:mm a"
                    let time = dateFormatter.date(from: array[i - b].time)
                    
                    let calendar = Calendar.current
                    let hour = calendar.component(.hour, from: time!)
                    let minute = calendar.component(.minute, from: time!)
                    
                    let date = NSDate()
                    let currentCalendar = NSCalendar.current
                    let currentHour = currentCalendar.component(.hour, from: date as Date)
                    let currentMinute = currentCalendar.component(.minute, from: date as Date)
                    
                    // check if the alarm already went off. if so, remove it from the alarms array
                    if hour < currentHour {
                        if hour + 23 > currentHour {
                            array.remove(at: i - b)
                            b += 1
                        }
                    }
                    else if hour == currentHour && minute < currentMinute {
                        array.remove(at: i - b)
                        b += 1
                    }
                    else if hour > currentHour + 1 {
                        array.remove(at: i - b)
                        b += 1
                    }
                }
            }
        }
        
        // update the alarms array
        let currentNavigationController = self.window?.rootViewController as! UINavigationController
        let currentViewController = currentNavigationController.viewControllers[0] as! AlarmTableViewController
        currentViewController.alarms = array
        currentViewController.saveAlarms()
        
        // reload the alarms array
        currentViewController.tableView.reloadData()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("applicationWillTerminate called")
    }
    
    // function for playing sound when needed
    func playSound() {
        // define url for the alarm sound
        let url = Bundle.main.url(forResource: "alarmsound", withExtension: "mp3")!
        
        // prepare and play audio using AVAudioPlayer
        do {
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else {return}
            
            player.prepareToPlay()
            player.play()
        }
        
        catch let error {
            print(error.localizedDescription)
        }
    }


}

