//
//  SaveTableViewController.swift
//  SyncManager
//
//  Created by Šimun on 08.02.2016..
//  Copyright © 2016. Manifest Media. All rights reserved.
//

import UIKit

class SaveTableViewController: UITableViewController {
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    var user: User?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        if let user = user {
            title = "Edit User"
            email.text = user.email!
            password.text = user.password!
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func saveData(sender: AnyObject) {
        
        let data = [
            "email": email.text!,
            "password": password.text!
        ]
        Sync.manager.saveRecord(forModel: User.self, withData: data, inRecord: user?.id, success: { (model) -> Void in
            let alert = UIAlertView(
                title: "Success",
                message: "Your data is saved",
                delegate: nil,
                cancelButtonTitle: "Dissmis"
            )
            alert.show()

        }) { (error) -> Void in
            self.displayMSG(error.description)
        }
    }
    
    func displayMSG(content: String){
        let alert = UIAlertView(
            title: "Can't save your data.",
            message: content,
            delegate: nil,
            cancelButtonTitle: "Dissmis"
        )
        alert.show()
    }
}