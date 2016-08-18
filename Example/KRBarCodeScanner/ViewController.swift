//
//  ViewController.swift
//  KRBarCodeScanner
//
//  Created by khetaram on 08/18/2016.
//  Copyright (c) 2016 khetaram. All rights reserved.
//

import UIKit
import KRBarCodeScanner

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let vi = KRBarCodeScannerView(frame:CGRectMake(100,100,200,200))
        self.view.addSubview(vi)
        vi.startScanning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

