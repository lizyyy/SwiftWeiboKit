//
//  ViewController.swift
//  Example
//
//  Created by Ruoyu Fu on 14-6-14.
//  Copyright (c) 2014年 Ruoyu Fu. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {
    let client = SWKClient(clientID:"", clientSecret:"", redirectURI:"")

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func login(sender : UIButton) {
        client.presentAuthorizeView(fromViewController: self){
            isSuccess in
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

