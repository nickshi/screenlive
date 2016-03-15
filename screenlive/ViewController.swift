//
//  ViewController.swift
//  screenlive
//
//  Created by nick.shi on 16/2/27.
//  Copyright © 2016年 nick.shi. All rights reserved.
//

import Cocoa


class ViewController: NSViewController {

    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var imageView: NSImageView!
    
    @IBOutlet weak var screenPlayer: ScreenPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    
    }
    
    override func viewWillLayout() {
        print("viewWillLayout")
    }
    
    override func viewDidLayout() {
        print("viewDidLayout")
        self.screenPlayer.frame = self.view.bounds
    }
    
}
