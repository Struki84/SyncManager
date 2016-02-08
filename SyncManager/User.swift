//
//  User+CoreDataProperties.swift
//  SyncManager
//
//  Created by Šimun on 03.02.2016..
//  Copyright © 2016. Manifest Media. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData
import SwiftyJSON
import SwiftRecord

@objc(User)
class User: NSManagedObject, SyncProtocol {

    @NSManaged var id: NSNumber?
    @NSManaged var email: String?
    @NSManaged var password: String?
    @NSManaged var token: String?
    @NSManaged var recoverCode: String?
    @NSManaged var registeredOn: NSDate?
    
    static func createRecord(fromJson json: JSON) -> NSManagedObject? {
        let properties = clean(json.dictionaryObject!)
        let user = User.create(properties: properties) as! User
        user.save()
        return user
    }
    
    static func saveRecord(fromJson json: JSON, forRecord id: NSNumber!) -> NSManagedObject? {
        let properties = clean(json.dictionaryObject!)
        if let user = User.findOrCreate(["id" : id!]) as? User {
            user.update(properties)
            user.save()
            return user
        }
        return nil
    }
    
    static func get(record id: NSNumber?) -> NSManagedObject? {
        if let user = User.find("id == %@", args: id!) {
            return user
        }
        return nil
    }
    
    static func getAllRecords() -> [NSManagedObject] {
        return User.all() as! [User]
    }
    
    static func delete(record id: NSNumber?) {
        User.find("id == %@", args: id!)?.delete()
    }
    
    static func getModelRecords(byLastSyncDate date: Bool, asJson jsonFromat: Bool) -> [String:String]? {
        return nil
    }
}



