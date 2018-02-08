//
//  ViewController.swift
//  demo
//
//  Created by deploy on 25/01/2018.
//  Copyright © 2018 holaspark. All rights reserved.
//

import UIKit
import UserNotifications
import MobileCoreServices

class ViewController: UIViewController {

    // MARK: Properties
    @IBOutlet weak var generateNotificationButton: UIButton!
    
    // MARK: Actions
    @IBAction func onGenerateNotification(sender: UIButton){
        let url = URL(string: "https://video.h-cdn.com/static/mp4/preview_sample.mp4")!
        let category = UNNotificationCategory(identifier: "spark-preview", actions: [], intentIdentifiers: [], options: [])
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = "spark-preview"
        content.title = "Watch"
        content.body = "Dani Alves gets kicked out after shouting at referee in PSG defeat at Lyon"
        content.sound = UNNotificationSound.default()
        content.addRemoteAttachment(url) {
            if content.attachments.count==0 {
                // download of remote attachment failed, use in-app resource
                let backup = Bundle.main.url(forResource: "preview", withExtension: "mp4")!
                let attachment = try! UNNotificationAttachment(identifier: "preview", url: backup, options: [:])
                content.attachments = [attachment]
            }
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            let request = UNNotificationRequest(identifier: "demo", content: content, trigger: trigger)
            let center = UNUserNotificationCenter.current()
            center.setNotificationCategories([category])
            center.add(request, withCompletionHandler: { (error) in
                if let error = error {
                    print("notification failed", error)
                } else {
                    print("notification sent, close the app and wait 10 sec")
                }
            });
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

}



