//
//  ViewController.swift
//  HelloSphero
//
//  Created by Gabrielle on 9/29/16.
//  Copyright © 2016 Gabrielle. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var responseText: UILabel!
    @IBOutlet weak var step5: UILabel!
    @IBOutlet weak var step6: UILabel!
    @IBOutlet weak var step7: UILabel!
    @IBOutlet weak var step8: UILabel!
    var leftStep: Double = 0.0
    var rightStep: Double = 0.0
    var forwardStep: Double = 0.0
    var backwardStep: Double = 0.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
   
}

