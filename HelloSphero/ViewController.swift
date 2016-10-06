//
//  ViewController.swift
//  HelloSphero
//
//  Created by Gabrielle on 9/29/16.
//  Copyright © 2016 Gabrielle. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    //MARK: Properties
    @IBOutlet weak var responseText: UILabel!
    @IBOutlet weak var step5: UILabel!
    @IBOutlet weak var step6: UILabel!
    @IBOutlet weak var step7: UILabel!
    @IBOutlet weak var step8: UILabel!
    @IBOutlet var connectionLabel: UILabel!
    
    var ledON = false
    
    var leftStep: Double = 0.0
    var rightStep: Double = 0.0
    var forwardStep: Double = 0.0
    var backwardStep: Double = 0.0
    
    var robot: RKConvenienceRobot!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.applicationWillResignActive(_:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        
        //Original line that worked in swift 2
        //RKRobotDiscoveryAgent.sharedAgent().addNotificationObserver(self, selector: #selector(ViewController.handleRobotStateChangeNotification(_:)))
        
        //Broken line
        //RKRobotDiscoveryAgent.shared().addNotificationObserver(self, selector: #selector(ViewController.handleRobotStateChangeNotification(_:)))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Actions
    
    @IBAction func sleepButtonPress(_ sender: UIButton) {
        //if let robot = self.robot {
            responseText.text = "Goodnight"
            connectionLabel.text = "Sleeping"
            robot!.sleep()
        //}
    }

    @IBAction func buttonPress(_ sender: UIButton) {
        switch (sender.tag) {
            case 0: responseText.text = "Drive left \(leftStep)"
            case 1: responseText.text = "Drive right \(rightStep)"
            case 2: responseText.text = "Drive forward \(forwardStep)"
            case 3: responseText.text = "Drive backward \(backwardStep)"
            default: responseText.text = "-----"
        }
        //responseText.text = "Greetings mortals."
        
    }

    @IBAction func sayHello(_ sender: UIButton) {
        responseText.text = "Hello World!"
    }
    
    @IBAction func stepperPress(_ sender: UIStepper) {
        switch (sender.tag) {
        case 5: step5.text = String(sender.value)
            leftStep = sender.value
        case 6: step6.text = String(sender.value)
            rightStep = sender.value
        case 7: step7.text = String(sender.value)
            forwardStep = sender.value
        case 8: step8.text = String(sender.value)
            backwardStep = sender.value
        default: break
        }
    }
    
    //MARK: - Robot Specific Functions
    
    func startDiscovery() {
        connectionLabel.text = "Discovering Robots"
        RKRobotDiscoveryAgent.startDiscovery()
    }
    
    func stopDiscovery() {
        RKRobotDiscoveryAgent.stopDiscovery()
    }
    
    func toggleLED() {
        if let robot = self.robot {
            if (ledON) {
                robot.setLEDWithRed(0.0, green: 0.0, blue: 0.0)
            } else {
                robot.setLEDWithRed(0.0, green: 0.8, blue: 0.0)
            }
            ledON = !ledON
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.toggleLED()
            }
        }
    }
    
    func directionControl() {
        
    }
    
    
    func handleRobotStateChangeNotification(notification: RKRobotChangedStateNotification) {
        guard let noteRobot = notification.robot else {return}
        
        switch (notification.type) {
        case .connecting:
            connectionLabel.text = "\(notification.robot.name()) Connecting"
            break
        case .online:
            guard let conveniencerobot = RKConvenienceRobot(robot: noteRobot) else {return}
            if (UIApplication.shared.applicationState != .active) {
                conveniencerobot.disconnect()
            } else {
                self.robot = RKConvenienceRobot(robot: noteRobot);
                connectionLabel.text = noteRobot.name()
                //directionControl()
                toggleLED()
            }
            break
        case .disconnected:
            connectionLabel.text = "Disconnected"
            startDiscovery()
            robot = nil;
            
            break
        default:
            NSLog("State change with state: \(notification.type)")
        }
    }
   
}

