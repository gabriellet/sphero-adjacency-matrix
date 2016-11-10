//
//  ViewController.swift
//  Adjacency
//
//  Created by Gabrielle on 9/29/16.
//  Copyright © 2016 Gabrielle. All rights reserved.
//

import UIKit

class ViewController: UIViewController, RKResponseObserver {

    //MARK: Properties
    @IBOutlet weak var responseText: UILabel!
    @IBOutlet weak var connectionLabel: UILabel!
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    
    @IBOutlet weak var gridView: GridView!
    @IBOutlet weak var showTail: UIButton!
    @IBOutlet weak var sleepButton: UIButton!
    @IBOutlet var directionButtons: [UIButton]!
    
    var ledON = false

    var speed: Double = 0.0
    
    var robot: RKConvenienceRobot!
    var robotBase: RKRobotBase!
    
    var hdg: Float = 0.0
    var dst: Float = 0.0
    
    enum DriveDir {
        case North
        case NorthEast
        case East
        case SouthEast
        case South
        case SouthWest
        case West
        case NorthWest
    }
    
    var collisionTime: TimeInterval = TimeInterval(0.0)
    var collisionSpeed: Float = 0.0
    var collisionAxisX: Bool = false
    var collisionAxisY: Bool = false
    
    var locatorPositionX: Float = 0.0
    var locatorPositionY: Float = 0.0
    
    // adjacency matrix of 100x100, will map from (x,y)-coordinates (-150,-150) to (150,150)
    var arraySize = 1000
    var adjMapVal: Int = 1000 / 2
    
    var driveTimer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // possibly do clean up if open connection exists i.e. from force quit
        //RKRobotDiscoveryAgent.disconnectAll()
        //stopDiscovery()
        NSLog("viewDidLoad")
        //NSLog("starting discovery")
        //startDiscovery()
        //RKRobotDiscoveryAgent.shared().addNotificationObserver(self, selector: #selector(handleRobotStateChangeNotification))
        showTail.layer.cornerRadius = 10
        sleepButton.layer.cornerRadius = 10
        for button in directionButtons {
            button.layer.cornerRadius = 5
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NSLog("viewWillAppear")
        RKRobotDiscoveryAgent.disconnectAll()
        //NSLog("stop discovery")
        //stopDiscovery()
        NSLog("start discovery")
        startDiscovery()
        RKRobotDiscoveryAgent.shared().addNotificationObserver(self, selector: #selector(handleRobotStateChangeNotification))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        NSLog("viewDidAppear")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    //MARK: Actions
    
    @IBAction func sleepButtonPress(_ sender: UIButton) {
        if let robot = self.robot {
            responseText.text = "Goodnight"
            connectionLabel.text = "Sleeping"
            robot.sleep()
        }
    }
    
    /* @IBAction func clearGrid(_ sender: UIButton) {
        occupancy = [[Int]](repeating:[Int](repeating:0, count:1000), count:1000)
        gridView.setNeedsDisplay()
    } */
    
    @IBAction func showTail(_ sender: UIButton) {
        if let robot = self.robot {
            robot.setLEDWithRed(0.0, green: 0.0, blue: 0.0)
            robot.setBackLEDBrightness(1.0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.tailOff()
        }
    }
    
    func tailOff() {
        if let robot = self.robot {
            robot.setBackLEDBrightness(0.0)
            robot.setLEDWithRed(0.1, green: 0.8, blue: 0.2)
        }
    }
    
    @IBAction func driveButtonDown(_ sender: UIButton) {
        var dir: DriveDir = .North
        switch (sender.tag) {
            case 0: responseText.text = "Drive North"
                dir = .North
            case 1: responseText.text = "Drive North East"
                dir = .NorthEast
            case 2: responseText.text = "Drive East"
                dir = .East
            case 3: responseText.text = "Drive South East"
                dir = .SouthEast
            case 4: responseText.text = "Drive South"
                dir = .South
            case 5: responseText.text = "Drive South West"
                dir = .SouthWest
            case 6: responseText.text = "Drive West"
                dir = .West
            case 7: responseText.text = "Drive North West"
                dir = .NorthWest
            default: responseText.text = "-----"
        }
        directionControl(dir: dir)
        driveTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(repeatDirectionControl), userInfo: dir, repeats: true)
    }
    
    @IBAction func driveButtonUp(_ sender: UIButton) {
        if let robot = self.robot {
            robot.stop()
        }
        driveTimer.invalidate()
    }
    
    
    @IBAction func stepperPress(_ sender: UIStepper) {
        speedLabel.text = String(sender.value)
        speed = sender.value
    }
    
    //MARK: - Robot Specific Functions
    
    func startDiscovery() {
        connectionLabel.text = "Discovering Robots"
        RKRobotDiscoveryAgent.startDiscovery()
    }
    
    func stopDiscovery() {
        RKRobotDiscoveryAgent.stopDiscovery()
    }
    
    func directionControl(dir: DriveDir) {
        //NSLog("I believe I can drive")
        switch dir {
            case .North: hdg = 0.0
            case .NorthEast: hdg = 45.0
            case .East: hdg = 90.0
            case .SouthEast: hdg = 135.0
            case .South: hdg = 180.0
            case .SouthWest: hdg = 225.0
            case .West: hdg = 270.0
            case .NorthWest: hdg = 315.0
        }
        dst = Float(speed)
        drive()
    }
    
    func repeatDirectionControl(driveTimer: Timer) {
        //NSLog("I believe I can drive")
        switch driveTimer.userInfo as! DriveDir {
        case .North: hdg = 0.0
        case .NorthEast: hdg = 45.0
        case .East: hdg = 90.0
        case .SouthEast: hdg = 135.0
        case .South: hdg = 180.0
        case .SouthWest: hdg = 225.0
        case .West: hdg = 270.0
        case .NorthWest: hdg = 315.0
        }
        dst = Float(speed)
        drive()
        // directionControl(dir: driveTimer.userInfo as! DriveDir)
    }
    
    func drive() {
        if let robot = self.robot {
            robot.setLEDWithRed(0.1, green: 0.8, blue: 0.2)
            //NSLog("heading: \(hdg), distance: \(dst)")
            robot.drive(withHeading: hdg, andVelocity: dst)
            //NSLog("One small step for Gabrielle, one large roll for me.")
        }
    }
    
    func handle(_ message: RKAsyncMessage!, forRobot robot: RKRobotBase!) {
        //NSLog("Async Message")
        if let sensorMessage = message as? RKDeviceSensorsAsyncData {
            if let sensorData = sensorMessage.dataFrames.last as? RKDeviceSensorsData {
                if let locator = sensorData.locatorData {
                    locatorPositionX = locator.position.x
                    locatorPositionY = locator.position.y
                    positionLabel.text = "(\(locatorPositionX), \(locatorPositionY))"
                    //NSLog("Current Position:(\(locatorPositionX), \(locatorPositionY))")
                }
            }
            
        }
        else if let sensorMessage = message as? RKCollisionDetectedAsyncData {
            
            //get data from sphero on collision
            collisionTime = sensorMessage.impactTimeStamp
            collisionSpeed = sensorMessage.impactSpeed
            
            //change sphero color on collision, print message to app
            self.robot.setLEDWithRed(0.7, green: 0.0, blue: 0.2)
            responseText.text = "OUCH!"
            gridView.setNeedsDisplay()
            
            //stop driving
            self.robot.stop()
            NSLog("Colllision detected: time=\(collisionTime), speed=\(collisionSpeed)")
            NSLog("Current Position:(\(locatorPositionX), \(locatorPositionY))")
            
            //translate to array indices, add if within boundaries
            let adjPosX = Int(locatorPositionX) + adjMapVal
            let adjPosY = Int(locatorPositionY) + adjMapVal
            let withinXBound = (adjPosX >= 0) && (adjPosX < arraySize)
            let withinYBound = (adjPosY >= 0) && (adjPosY < arraySize)
            if (withinXBound  && withinYBound) {
                occupancy[adjPosX][adjPosY] =  1
                NSLog("occupancy[\(adjPosX)][\(adjPosY)]=\(occupancy[adjPosX][adjPosY])")
            }
            else {
                NSLog("position outside current adjacency matrix size")
            }
        }
    }
    
    func handleRobotStateChangeNotification(notification: RKRobotChangedStateNotification) {
        if let noteRobot = notification.robot {
            switch (notification.type) {
            case .connecting:
                NSLog("Connecting Sphero")
                connectionLabel.text = "\(notification.robot.name()) Connecting"
                break
            case .online:
                NSLog("Sphero Online")
                if let conveniencerobot = RKConvenienceRobot(robot: noteRobot) {
                    if (UIApplication.shared.applicationState != .active) {
                        conveniencerobot.disconnect()
                    } else {
                        robot = RKConvenienceRobot(robot: noteRobot)
                        connectionLabel.text = noteRobot.name()
                        responseText.text = "Greetings mortals."
                        robot.add(self) //get responses from sphero
                        robot.enableStabilization(true)
                        robot.enableCollisions(true)
                        robot.enableLocator(true)
                        let sensorMask = RKDataStreamingMask.locatorAll
                        robot.enableSensors(sensorMask, at: RKStreamingRate.dataStreamingRate100)
                        robot.setZeroHeading() //current position is (0,0)
                        robot.setLEDWithRed(0.1, green: 0.8, blue: 0.2)
                    }
                    break
                }
            case .disconnected:
                NSLog("Sphero Disconnected")
                connectionLabel.text = "Disconnected"
                robot = nil;
                // eventually will have to redraw empty grid
                // gridView.setNeedsDisplay()
                startDiscovery()
                break
            default:
                NSLog("State change with state: \(notification)")
            }
        }
    }
   
}

var occupancy: [[Int]] = [[Int]](repeating:[Int](repeating:0, count:1000), count:1000)

