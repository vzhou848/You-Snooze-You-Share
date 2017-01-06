//
//  AlarmTableViewController.swift
//  test3
//
//  Created by Vivian Zhou on 11/30/16.
//  Copyright © 2016 viv. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI //framework to customize the notification
import AVFoundation
import TwitterKit


// controls the view controller which contains the table of alarms
class AlarmTableViewController: UITableViewController {
    
    // MARK: Properties
    var alarms = [Alarm]()
    var player: AVAudioPlayer?
    
    // function that is run when teh page is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // check if user is logged into twitter
        Twitter.sharedInstance().logIn { session, error in
            // if user is logged in, proceed with rest of the view
            if (session != nil) {
                print("signed in as \(session?.userName)");
            } else {
                // if not logged in, redirect to login page
                print("error: \(error?.localizedDescription)");
                
                // instantiate the LoginViewController where users log in, as well as the AlarmTableViewController itself
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
                _ = storyboard.instantiateViewController(withIdentifier: "AlarmTableViewController")
                
                // present the login page to users
                self.present(controller, animated: true, completion: nil)
            }
        }
        
        // Use the edit button item provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Table view data source
    
    // function to determine number of sections for the table
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    // function to determine how many rows the table should have
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alarms.count
    }

    // function for setting the properties of the alarm cell based on an alarm object
    let cellIdentifier = "AlarmTableViewCell"
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! AlarmTableViewCell
        
        // fetch the appropriate alarm for the cell
        let alarm = alarms[indexPath.row]
        
        // set the switch's state based on the onoff property of the alarm
        if alarm.onoff {
            cell.onoffSwitch.setOn(true, animated: true)
        }
        else {
            cell.onoffSwitch.setOn(false, animated: true)
        }
        
        // set the alarm's text based on the alarm's time property
        cell.timeLabel.text = alarm.time
        
        return cell
    }

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            // Delete the row from the data source
            alarms.remove(at: indexPath.row)
            saveAlarms()
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    
    // MARK: - Navigation

    // function that prepares information to be passed to AlarmViewController right before the segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // if editing an alarm, run this part of the if clause
        if segue.identifier == "ShowDetail" {
            
            let alarmDetailViewController = segue.destination as! AlarmViewController
            
            // Get the cell that generated this segue.
            if let selectedAlarmCell = sender as? AlarmTableViewCell {
                
                // retrieve information about the "selectedAlarmCell"
                let indexPath = tableView.indexPath(for: selectedAlarmCell)!
                
                // retrieve the actual cell to be edited
                let selectedAlarm = alarms[indexPath.row]
                
                // set the "alarm" variable within AlarmViewController as the "selected alarm" variable
                alarmDetailViewController.alarm = selectedAlarm
            }
        }
        // if adding a new alarm, run this part of the if clause
        else if segue.identifier == "AddItem" {
            
            // create "counter" variable to set ID for new alarm
            var counter = 0
            
            // if there already exists an alarm, take the id of the last alarm and set it equal to counter
            if alarms.count > 0 {
                for i in 0..<alarms.count {
                    // if the previous alarm has id of -1, then go to the next previous alarm
                    if alarms[alarms.count - 1 - i].id != -1 {
                        counter = alarms[alarms.count - 1 - i].id
                    }
                }
            }
            
            // if counter is too big, re-ID the counters starting from 1
            if counter > 1000000 {
                var i = 1
                for alarm in alarms {
                    alarm.id = i
                    i += 1
                }
                counter = alarms[alarms.count - 1].id
                
                // if counter is still too big, alert user to delete alarms and do not segue
                if counter > 1000000 {
                    let alertController = UIAlertController(title: "Too Many Alarms", message: "Please delete some alarms. You have too many.", preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    present(alertController, animated: true, completion: nil)
                }
            }
            
            // set "counter" in AlarmViewController equal to "counter" defined above
            // must go through the navigation controller to get to the "counter" variable of AlarmViewController
            let navController = segue.destination as! UINavigationController
            let alarmDetailViewController = navController.topViewController as! AlarmViewController
            alarmDetailViewController.counter = counter
        
        }
    }
    
    // function run after AlarmViewController segues back to AlarmTableViewController
    @IBAction func unwindToAlarmList(sender: UIStoryboardSegue) {
        
        // run this clause if the sender is AlarmViewController
        if let sourceViewController = sender.source as? AlarmViewController, let alarm = sourceViewController.alarm {
            
            // run this part of the if clause if you are editing an existing cell
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                
                // Update an existing meal
                alarms[selectedIndexPath.row] = alarm
                
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
            }
            // run this part of the if clause if you are adding a new alarm
            else {
                
                // Add a new alarm to the alarms array
                let newIndexPath = NSIndexPath(row: alarms.count, section: 0)
                alarms.append(alarm)
                
                tableView.insertRows(at: [newIndexPath as IndexPath], with: .bottom)
            }
            
            //Save the alarms
            saveAlarms()
        
        }
    }
    
    
    
    
    // variable to store the identifier for each alarm
    var requestIdentifier = "DefaultIdentifier"
    
    // function for scheduling a notification
    func scheduleNotification(alarm: Alarm, identifier: Int) {
        
        // set content in the notification
        let content = UNMutableNotificationContent()
        content.title = "Alarm"
        content.subtitle = ""
        content.body = "Open Alarm App and click 'Post' to Snooze. Click 'Cancel' to dismiss alarm."
        content.sound = UNNotificationSound.init(named: "alarmsound.mp3")
        
        
        // convert time to a Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        let time = dateFormatter.date(from: alarm.time)
        
        // get hour and minute components and set as a DateComponent()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time!)
        let minute = calendar.component(.minute, from: time!)
        let ampm = calendar.component(.era, from: time!)
        print("era is: \(ampm)")
        
        /*
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
        
        */
        
        var date = DateComponents()
        date.hour = hour
        date.minute = minute
        
        // set trigger and request identifier for notification
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
    
    
    
    
    //MARK: NSCoding
    
    // function for saving the alarms to persist data
    func saveAlarms() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(alarms, toFile: Alarm.ArchiveURL.path)
        
        if !isSuccessfulSave {
            print("Failed to save alarms...")
        }
        else {
            print("Alarms saved!")
        }
    }
    
    // function for loading the alarms from persisted data
    func loadAlarms () ->[Alarm]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Alarm.ArchiveURL.path) as? [Alarm]
    }
    
    
    
    
    // MARK: Actions
    
    // function that is called whenever an onoff switch is pressed in the Table View Controller
    @IBAction func switchOnoff(_ sender: Any) {
        
        var indexPath: NSIndexPath!
        
        // Get the cell that generated this action.
        if let singleswitch = sender as? UISwitch {
            
            // get the index path of the Alarms table
            if let cell = singleswitch.superview {
                if let table = cell.superview as? AlarmTableViewCell {
                    indexPath = tableView.indexPath(for: table)! as NSIndexPath!
                }
            }
            
            // retrieve the alarm whose switch was clicked
            let selectedAlarm = alarms[indexPath.row]
            
            // change the state of the selected alarm's onoff property, and request or delete notification
            if selectedAlarm.onoff == false {
                selectedAlarm.onoff = true
                
                // if switch is set from off to on, request a notification
                scheduleNotification(alarm: selectedAlarm, identifier: selectedAlarm.id)
                
                // Save Alarms
                saveAlarms()
            }
            else {
                selectedAlarm.onoff = false
                
                // if switch is set from on to off, stop any requested notifications
                stopNotification(identifier: selectedAlarm.id)

                // Save Alarms
                saveAlarms()
            }
        }
    }
}

// extension of the AlarmTableViewController that allows notifications to be scheduled
extension AlarmTableViewController:UNUserNotificationCenterDelegate{
    
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
    
    // function to play a sound when an alarm goes off
    func playSound() {
        // retrieve url of mp3 file
        let url = Bundle.main.url(forResource: "alarmsound", withExtension: "mp3")!
        
        // prepare audio and play it using AVAudioPlayer
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





