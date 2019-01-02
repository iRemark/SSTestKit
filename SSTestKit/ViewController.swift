//
//  ViewController.swift
//  SSTestKit
//
//  Created by lichao on 2019/1/2.
//  Copyright © 2019 charles. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func tapButton(_ sender: Any) {
        VPNManager.shared()?.startVPN(options: ["type":"ss","domin":""], complete: nil)
    }
    
}

