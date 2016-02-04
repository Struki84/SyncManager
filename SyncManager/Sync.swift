//
//  SyncManager.swift
//  SyncManager
//
//  Created by Šimun on 03.02.2016..
//  Copyright © 2016. Manifest Media. All rights reserved.
//

import UIKit

//
//  Sync.swift
//  TeacherBox
//
//  Created by Šimun on 08.10.2015..
//  Copyright © 2015. Manifest Media ltd. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON
import Alamofire

protocol SyncProtocol {
    
    static func saveModelData(fromJson json: JSON) -> NSManagedObject?
    static func getModelData(byLastSyncDate date: Bool, asJson jsonFromat: Bool) -> [String:String]?
    
}

class Sync {
    
    struct SyncSupportData {
        static let initialSync = "isInitialSync"
        static let lastSyncDate = "lastSyncDate"
    }
    
    static let manager = Sync()
    
    var registeredModels: [String: SyncProtocol.Type]
    var inProgress: Bool = false
    var initialSync: Bool = true
    var lastSyncDate: NSDate?
    
    init(){
        registeredModels = Dictionary()
        let defaults = NSUserDefaults.standardUserDefaults()
        initialSync = defaults.boolForKey(SyncSupportData.initialSync)
        lastSyncDate = defaults.objectForKey(SyncSupportData.lastSyncDate) as? NSDate
    }
    
    func start(completed: () -> Void) {
        let defaults = NSUserDefaults.standardUserDefaults()
        if (inProgress){
            LOGGER.info("Start Sync")
            inProgress = true
            syncAllModels({ () -> Void in
                self.inProgress = false
                defaults.setObject(NSDate(), forKey: SyncSupportData.lastSyncDate)
                defaults.synchronize()
                completed()
            })
        }
    }
    
    func start(){
        self.start(())
    }
    
    func registerModelForSync(model: AnyClass){
        if model.isSubclassOfClass(NSManagedObject) {
            let modelString: String = NSStringFromClass(model).stringByReplacingOccurrencesOfString("SyncManager.", withString: "")
            if registeredModels[modelString] == nil { 
                registeredModels[modelString] = model as? SyncProtocol.Type
            }
        }
    }
    
    func setup() {
        let objectModel = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectModel
        for entitiy in objectModel.entities {
            LOGGER.info(entitiy)
        }
    }
    
    func createRecord(forModel model: AnyClass) {
        let modelName: String = NSStringFromClass(model).stringByReplacingOccurrencesOfString("SyncManager.", withString: "")
        let modelObject = registeredModels[modelName]!
        let modelData = modelObject.getModelData(byLastSyncDate: false, asJson: false)
        
        
        Alamofire.request(Router.Create(modelName, modelData!)).responseJSON { (request, response, result) -> Void in
            switch result {
            case .Success(let json):
                let record = JSON(json)
                if let _ = modelObject.saveModelData(fromJson: record) {
                    LOGGER.info("\(modelName) was synced successfully.")
                }
                else {
                    LOGGER.error("There was an error while saving \(modelName) data.")
                }
            case .Failure(let data, let errorResponse):
                LOGGER.error("\(errorResponse)")
                LOGGER.error("\(JSON(data!))")
            }
        }
    }
    
    func createRecord(forModel model: NSManagedObject, success: (model: NSManagedObject) -> Void, failure: (error: ErrorType) -> Void) {
        
    }
    
    func saveRecord(forModel model: AnyClass, withData data: [String: String], inRecord id: NSNumber? ) {
    }
    
    func saveRecord(forModel model: AnyClass, withData data: [String: String], inRecord id: NSNumber?, success: (model: NSManagedObject) -> Void, failure: (error: ErrorType) -> Void) {
        let modelName: String = NSStringFromClass(model).stringByReplacingOccurrencesOfString("SyncManager.", withString: "")
        let modelObject = registeredModels[modelName]!
        let modelData = modelObject.getModelData(byLastSyncDate: false, asJson: false)
        
        
        Alamofire.request(Router.Save(modelName, modelData!, id)).responseJSON { (request, response, result) -> Void in
            switch result {
            case .Success(let json):
                let record = JSON(json)
                if let savedModel = modelObject.saveModelData(fromJson: record) {
                    success(model: savedModel)
                    LOGGER.info("\(modelName) was synced successfully.")
                }
                else {
                    LOGGER.error("There was an error while saving \(modelName) data.")
                }
            case .Failure(let data, let errorResponse):
                failure(error: errorResponse)
                LOGGER.error("There was an error while saving \(modelName) data.")
                LOGGER.error("\(errorResponse)")
                LOGGER.error("\(JSON(data!))")
            }
        }

    }
    
    func getRecord(forModel model: NSManagedObject, success: (model: NSManagedObject) -> Void, failure: (error: ErrorType) -> Void) {
    
    }
    
    func getRecords(forModel model: NSManagedObject, success: (model: NSManagedObject) -> Void, failure: (error: ErrorType) -> Void) {
        
    }
    
    func syncModel(modelName: String, completed: () -> Void) {
        let modelInSync = registeredModels[modelName]
        let modelData = modelInSync!.getModelData(byLastSyncDate: true, asJson: true)
        Alamofire.request(Router.Sync(modelName, modelData!)).responseJSON { (request, response, result) -> Void in
            switch result {
            case .Success(let json):
                let record = JSON(json)
                if let _ = modelInSync?.saveModelData(fromJson: record) {
                    LOGGER.info("\(modelName) was synced successfully.")
                }
                else {
                    LOGGER.error("There was an error while saving \(modelName) data.")
                }
            case .Failure(let data, let errorResponse):
                LOGGER.error("\(errorResponse)")
                LOGGER.error("\(JSON(data!))")
            }
        }
            
    }
    
    func syncAllModels(completed: () -> Void){
        let dispatchGroup: dispatch_group_t = dispatch_group_create()
        var modelData: [String: String]?
        var responseObjects: [String: JSON]?
        
        for (modelName, modelClass) in registeredModels {
            dispatch_group_enter(dispatchGroup)
            modelData = modelClass.getModelData(byLastSyncDate: true, asJson: true)
            LOGGER.info("Send Sync Request")
            Alamofire.request(Router.Sync(modelName, modelData!)).responseJSON { (request, response, result) -> Void in
                switch result {
                case .Success(let json):
                    let record = JSON(json)
                    responseObjects![modelName] = record
                    dispatch_group_leave(dispatchGroup)
                case .Failure(let data, let errorResponse):
                    LOGGER.error("Fail \(errorResponse)")
                    LOGGER.error("Fail \(JSON(data!))")
                }
            }
        }
        
        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), {
            LOGGER.info("Send Sync Request Ended")
            for(key, value) in responseObjects! {
                LOGGER.info("-==\(key)==-")
                let modelClass = self.registeredModels[key]
                for record in value[self.getJsonObj(key)].array! {
                    if let _ = modelClass?.saveModelData(fromJson: record) {
                        LOGGER.info("\(key) was synced successfully.")
                    }
                    else {
                        LOGGER.error("There was an error while saving \(key) data.")
                    }
                }
            }
            completed()
        })
    }
    
    func getJsonObj(modelName: String) -> String {
        if modelName == "Country" {
            return "countries"
        }
        else if modelName == "Currency" {
            return "currencies"
        }
        else {
            return "\(modelName.lowercaseString)s"
        }
    }
}