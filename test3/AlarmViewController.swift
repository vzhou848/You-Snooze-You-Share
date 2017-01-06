//
//  AlarmViewController.swift
//  test3
//
//  Created by Vivian Zhou on 11/29/16.
//  Copyright © 2016 viv. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI //framework to customize the notification

class AlarmViewController: UIViewController, UINavigationControllerDelegate {

    // MARK: Properties
    
    // value for storing onoff value of passed alarm
    var onoffStore = true
    // This value is either passed by 'AlarmTableViewController' in 'prepareForSegue(_:sender:)' or constructed as part of adding a new alarm.
    var alarm: Alarm?
    // value for setting the new id of an alarm
    var id = 0
    // value for receiving the value of the last alarm created, used as a counter for the next alarm's id
    var counter: Int?
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var alarmTime: UIDatePicker!
    
    
    // function that is called whenever AlarmViewController loads
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up views if editing an existing Alarm.
        if let alarm = alarm {
            
            // format the date received from the alarm being edited
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "h:mm a"
            let time = dateFormatter.date(from: alarm.time)
            
            // set the date of the scroller, the onoff status of the alarm, and the alarm id
            alarmTime.date = time!
            onoffStore = true
            id = alarm.id
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Navigation
    
    // function for cancelling the edit of an alarm or the creation of a new alarm
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        
        //Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        let isPresentingInAddAlarmMode = presentingViewController is UINavigationController
        
        if isPresentingInAddAlarmMode {
            dismiss(animated: true, completion: nil)
        }
        else {
            navigationController!.popViewController(animated: true)
        }
    }
    
    //This method lets you configure a view controller before it's presented
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // if the save button is pressed, create new alarm object to be passed to AlarmTableViewController
        if saveButton === sender as AnyObject? {
            
            // format the date to be set in the alarms array
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "h:mm a"
            let time = dateFormatter.string(from: alarmTime.date)
            
            // set new ID of the alarm if an alarm isnt being edited
            if id == 0 {
                if let counter = counter {
                    id = counter + 1
                }
                else {
                    id = -1
                }
            }
            
            // delete any existing notification requests with the given id
            stopNotification(identifier: id)
            
            // set the values of the newly created/edited alarm
            alarm = Alarm(time: time, onoff: onoffStore, id: id)
            
            // schedule the new notification
            scheduleNotification(alarm: alarm!, identifier: id)
            
        }
    }
    
    // variable to store the identifier for each alarm
    var requestIdentifier = "DefaultIdentifier"
    
    
    // function for scheduling a notification
    func scheduleNotification(alarm: Alarm, identifier: Int) {
        
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
        date.minute = minute
        
        // set trigger and request identifier for notification request
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        requestIdentifier = String(identifier)
        
        // request notification
        let request = UNNotificationRequest(identifier:requestIdentifier, content: content, trigger: trigger)
        
        // set the delegate of the UNUserNotificationCenter
        UNUserNotificationCenter.current().delegate = self
        // log if an error occurs
        UNUserNotificationCenter.current().add(request){(error) in
            if (error != nil){
                print(error?.localizedDescription as Any)
            }
        }
        
    }
    
    // function for removing notifications
    func stopNotification(identifier: Int) {
        
        // set the requestIdentifier label equal to the identifier given
        requestIdentifier = String(identifier)
        
        // remove the pending notifications with the given requestIdentifier
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [requestIdentifier])
    }
    
}

// extension to AlarmViewController to allow for scheduling of notifications
extension AlarmViewController:UNUserNotificationCenterDelegate{
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Tapped in notification")
    }
    
    //This is key callback to present notification while the app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // default setting of notifications is alert, sound, and badge
        if notification.request.identifier == requestIdentifier {
            completionHandler( [.alert,.sound,.badge])
            
        }
    }
}







