//
//  RegisterTableViewController.swift
//  SyncManager
//
//  Created by Šimun on 07.02.2016..
//  Copyright © 2016. Manifest Media. All rights reserved.
//

import UIKit

class RegisterTableViewController: UITableViewController {

    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func saveData(sender: AnyObject) {
        Sync.manager.authenticate?.register(withUserData: ["email": email.text!, "password": password.text!], valid: { (model) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
            }, inValid: { (error) -> Void in
                self.displayMSG(error.description)
        })
    }

    @IBAction func cancelRegistration(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func displayMSG(content: String){
        let alert = UIAlertView(
            title: "Can't saveyout data.",
            message: content,
            delegate: nil,
            cancelButtonTitle: "Dissmis"
        )
        alert.show()
    }
}