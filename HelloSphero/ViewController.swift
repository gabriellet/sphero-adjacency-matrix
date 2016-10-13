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
    var robotBase: RKRobotBase!
    
    var hdg: Float = 0.0
    var dst: Float = 0.0
    
    enum DriveDir {
        case left
        case right
        case forward
        case backward
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.applicationWillResignActive(_:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.applicationWillResignActive), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.applicationDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        startDiscovery()
        RKRobotDiscoveryAgent.shared().addNotificationObserver(self, selector: #selector(handleRobotStateChangeNotification))
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
            case 0:
                responseText.text = "Drive left \(leftStep)"
                directionControl(dir: .left)
            case 1: responseText.text = "Drive right \(rightStep)"
                directionControl(dir: .right)
            case 2: responseText.text = "Drive forward \(forwardStep)"
                directionControl(dir: .forward)
            case 3: responseText.text = "Drive backward \(backwardStep)"
                directionControl(dir: .backward)
            default: responseText.text = "-----"
        }
        //responseText.text = "Greetings mortals."
        
    }

    @IBAction func sayHello(_ sender: UIButton) {
        responseText.text = "Hello World!"
        toggleLED()
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
    
    func directionControl(dir: DriveDir) {
        NSLog("I believe I can drive")
        switch dir {
        case .left: hdg = 270.0
            dst = Float(leftStep)
        case .right: hdg = 90.0
            dst = Float(rightStep)
        case .backward: hdg = 180.0
            dst = Float(backwardStep)
        case .forward: hdg = 0.0
            dst = Float(forwardStep)
        }
        drive()
    }
    
    func drive() {
        if let robot = self.robot {
            robot.setLEDWithRed(0.7, green: 0.0, blue: 0.2)
            NSLog("heading: \(hdg), distance: \(dst)")
            //DispatchQueue.main.asyncAfter(deadline: .now()) {
                //robot.send(RKRollCommand(heading: self.hdg, velocity: 1.0, andDistance: self.dst))
            //}
            robot.drive(withHeading: hdg, andVelocity: dst)
            //self.robot.send(RKSetHeadingCommand(heading: 0.0))
            //self.robot.send(RKRollCommand(heading: hdg, velocity: 1.0, andDistance: dst))
            NSLog("One small step for Gabrielle, one large roll for me.")
        }
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
                //toggleLED()
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

