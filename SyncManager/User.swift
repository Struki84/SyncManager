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

@objc(User)
class User: NSManagedObject, SyncProtocol {

    @NSManaged var name: String?
    
    static func saveModelData(fromJson json: JSON) -> NSManagedObject? {
        return nil
    }
    
    static func getModelData(byLastSyncDate date: Bool, asJson jsonFromat: Bool) -> [String:String]? {
        return nil
    }
}



