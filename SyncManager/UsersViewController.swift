//
//  ViewController.swift
//  SyncManager
//
//  Created by Šimun on 03.02.2016..
//  Copyright © 2016. Manifest Media. All rights reserved.
//

import UIKit

class UsersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var usersTable: UITableView!
    var users: [User] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        usersTable.delegate = self
        usersTable.dataSource = self
    }
    
    override func viewWillAppear(animated: Bool) {
        loadTable()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadTable() {
        Sync.manager.allRecords(forModel: User.self, success: { (models) -> Void in
            self.users = models as! [User]
            self.usersTable.reloadData()
        }) { (error) -> Void in
            let alert = UIAlertView(
                title: "Whooopsie, We can't load your data",
                message: error.description,
                delegate: nil,
                cancelButtonTitle: "Dissmis"
            )
            alert.show()
        }
    }
    
    @IBAction func logout(sender: AnyObject) {
        let userId = Sync.manager.authenticate?.userSession!.valueForKey("userId") as! NSNumber
        let user = User.find("id == %@", args: userId) as! User
        user.token = nil
        user.save()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("UserCell", forIndexPath: indexPath) as UITableViewCell
        let user = users[indexPath.row]
        cell.textLabel?.text = user.email
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let user = users[indexPath.row]
            Sync.manager.delete(record: user.id!, forModel: User.self, success: { () -> Void in
                self.users.removeAtIndex(indexPath.row)
                self.usersTable.reloadData()
            }, failure: { (error) -> Void in
                let alert = UIAlertView(
                    title: "Whooopsie, something went wrong",
                    message: error.description,
                    delegate: nil,
                    cancelButtonTitle: "Dissmis"
                )
                alert.show()
            })
            
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("EditUser", sender: indexPath.row)
    }
    
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EditUser" {
            let saveController = segue.destinationViewController as! SaveTableViewController
            let index = sender as! Int
            saveController.user = users[index]
        }
    }

}

