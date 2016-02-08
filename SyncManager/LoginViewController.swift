//
//  LoginViewController.swift
//  SyncManager
//
//  Created by Šimun on 07.02.2016..
//  Copyright © 2016. Manifest Media. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginUser(sender: AnyObject) {
        if email.text!.isEmpty {
            displayMSG("Please fill in all the fields.")
            return
        }
        
        if password.text!.isEmpty{
            displayMSG("Please fill in all the fields.")
            return
        }
        
        
        LOGGER.debug(email.text!)
        LOGGER.debug(password.text!)
        
        Sync.manager.authenticate!.login(email.text!, password: password.text!, valid: { (model) -> Void in
            self.performSegueWithIdentifier("LoginUser", sender: nil)
        }) { (error) -> Void in
            self.displayMSG(error.description)
        }
    }
    
    func displayMSG(content: String){
        let alert = UIAlertView(
            title: "Can't Log you in.",
            message: content,
            delegate: nil,
            cancelButtonTitle: "Dissmis"
        )
        alert.show()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
