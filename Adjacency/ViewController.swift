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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // possibly do clean up if open connection exists i.e. from force quit
        //RKRobotDiscoveryAgent.disconnectAll()
        //stopDiscovery()
        startDiscovery()
        RKRobotDiscoveryAgent.shared().addNotificationObserver(self, selector: #selector(handleRobotStateChangeNotification))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        RKRobotDiscoveryAgent.disconnectAll()
        stopDiscovery()
        startDiscovery()
        RKRobotDiscoveryAgent.shared().addNotificationObserver(self, selector: #selector(handleRobotStateChangeNotification))
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

    @IBAction func buttonPress(_ sender: UIButton) {
        switch (sender.tag) {
            case 0: responseText.text = "Drive North"
                directionControl(dir: .North)
            case 1: responseText.text = "Drive North East"
                directionControl(dir: .NorthEast)
            case 2: responseText.text = "Drive East"
                directionControl(dir: .East)
            case 3: responseText.text = "Drive South East"
                directionControl(dir: .SouthEast)
            case 4: responseText.text = "Drive South"
                directionControl(dir: .South)
            case 5: responseText.text = "Drive South West"
                directionControl(dir: .SouthWest)
            case 6: responseText.text = "Drive West"
                directionControl(dir: .West)
            case 7: responseText.text = "Drive North West"
                directionControl(dir: .NorthWest)
            default: responseText.text = "-----"
        }
        
    }
    
    // TODO: make press and hold action work
    /*
    var timer: Timer = Timer.init()
    
    func driveButtonHold() {
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(driveButtonHold), userInfo: nil, repeats: true)
    }
    
    func driveButtonStop() {
        
    }
    
    @IBAction func buttonHold(_ sender: UIButton) {
        switch (sender.tag) {
        case 0: responseText.text = "Drive North"
        directionControl(dir: .North)
        case 1: responseText.text = "Drive North East"
        directionControl(dir: .NorthEast)
        case 2: responseText.text = "Drive East"
        directionControl(dir: .East)
        case 3: responseText.text = "Drive South East"
        directionControl(dir: .SouthEast)
        case 4: responseText.text = "Drive South"
        directionControl(dir: .South)
        case 5: responseText.text = "Drive South West"
        directionControl(dir: .SouthWest)
        case 6: responseText.text = "Drive West"
        directionControl(dir: .West)
        case 7: responseText.text = "Drive North West"
        directionControl(dir: .NorthWest)
        default: responseText.text = "-----"
        }
    } */
    
    
    
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
    
    func drive() {
        if let robot = self.robot {
            robot.setLEDWithRed(0.7, green: 0.0, blue: 0.2)
            //NSLog("heading: \(hdg), distance: \(dst)")
            robot.drive(withHeading: hdg, andVelocity: dst)
            //self.robot.send(RKSetHeadingCommand(heading: 0.0))
            //self.robot.send(RKRollCommand(heading: hdg, velocity: 1.0, andDistance: dst))
            //NSLog("One small step for Gabrielle, one large roll for me.")
        }
    }
    
    func handle(_ message: RKAsyncMessage!, forRobot robot: RKRobotBase!) {
        //NSLog("Async Message")
        if let sensorMessage = message as? RKDeviceSensorsAsyncData {
            let sensorData = sensorMessage.dataFrames.last as? RKDeviceSensorsData
            let locator = sensorData?.locatorData
            locatorPositionX = locator!.position.x
            locatorPositionY = locator!.position.y
            positionLabel.text = "(\(locatorPositionX), \(locatorPositionY))"
            //NSLog("Current Position:(\(locatorPositionX), \(locatorPositionY))")
            
        }
        else if let sensorMessage = message as? RKCollisionDetectedAsyncData {
            
            //get data from sphero on collision
            collisionTime = sensorMessage.impactTimeStamp
            collisionSpeed = sensorMessage.impactSpeed
            collisionAxisX = sensorMessage.impactAxis.x
            collisionAxisY = sensorMessage.impactAxis.y
            
            //change sphero color on collision, print message to app
            self.robot.setLEDWithRed(0.1, green: 0.8, blue: 0.2)
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
                robot = RKConvenienceRobot(robot: noteRobot)
                connectionLabel.text = noteRobot.name()
                responseText.text = "Greetings mortals."
                robot.add(self) //get responses from sphero
                robot.enableStabilization(true)
                robot.enableCollisions(true)
                robot.enableLocator(true)
                let sensorMask = RKDataStreamingMask.locatorAll
                robot.enableSensors(sensorMask, at: RKStreamingRate.dataStreamingRate10)
                robot.setZeroHeading() //current position is (0,0)
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

var occupancy: [[Int]] = [[Int]](repeating:[Int](repeating:0, count:1000), count:1000)

