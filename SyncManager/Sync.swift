
//  Sync.swift
//  Sync
//
//  Created by Šimun on 03.02.2016..
//  Copyright © 2016. Manifest Media. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import SwiftyJSON
import Alamofire
import Loggerithm

var LOGGER = Loggerithm()

protocol SyncProtocol {
    
    static func createRecord(fromJson json: JSON) -> NSManagedObject?
    static func saveRecord(fromJson json: JSON, forRecord id: NSNumber!) -> NSManagedObject?
    static func get(record id: NSNumber?) -> NSManagedObject?
    static func getAllRecords() -> [NSManagedObject]
    static func delete(record id: NSNumber?)
    static func getModelRecords(byLastSyncDate date: Bool, asJson jsonFromat: Bool) -> [String:String]?
    
}

enum Router: URLRequestConvertible {
    
    //    static let APIUrl = Config.manager?.apiServer
    static let APIUrl = "http://server.dev:3000/api/"

    static let requestType = ""
    static let URLEndpoints = ""
    
    case Login(Dictionary<String, String>)
    case Register(Dictionary<String, String>)
    case RecoverPassword(Dictionary<String, String>)
    case RecoverAccount(Dictionary<String, String>)
    case ChangePassword(Dictionary<String, String>)
    case Logout
    case Get(String, NSNumber)
    case GetAll(String)
    case Create(String, Dictionary<String, String>)
    case Save(String, Dictionary<String, String>, NSNumber?)
    case Delete(String, NSNumber)
    case Sync(String, Dictionary<String, String>)
    
    var method: Alamofire.Method {
        switch self {
        case Logout:
            return .PUT
        case Get:
            return .GET
        case GetAll:
            return .GET
        case Delete:
            return .DELETE
        default:
            return .POST
        }
    }
    
    var encoding: Alamofire.ParameterEncoding {
        if self.method.rawValue == "POST" {
            return .JSON
        }
        else {
            return .URL
        }
    }

    var URLRequest: NSMutableURLRequest {
        
        let (path, parameters): (String, [String: String]) = {
            
            switch self {
            case .Login(let data):
                let parameters: [String: String] = data
                return ("authenticate/login", parameters)
            case .Register(let data):
                let parameters: [String: String] = data
                return ("authenticate/register", parameters)
            case .RecoverPassword(let data):
                let parameters: [String: String] = data
                return ("authenticate/recover/password", parameters)
            case .RecoverAccount(let data):
                let parameters: [String: String] = data
                return ("authenticate/recover/account", parameters)
            case .ChangePassword(let data):
                let parameters: [String: String] = data
                return ("authenticate/change/password", parameters)
            case .Get(let model, let id):
                return ("records/\(model)/\(id)", [:])
            case .GetAll(let model):
                return ("records/all/\(model)", [:])
            case .Create(let model, let data):
                return ("records/create/\(model)", data)
            case .Save(let model, let data, let id):
                let parameters: [String: String] = data
                if let recordId = id {
                    return ("records/save/\(model)/\(recordId)", parameters)
                }
                else {
                    return ("records/save/\(model)", parameters)
                }
            case .Delete(let model, let id):
                return ("records/\(model)/\(id)", [:])
            case .Sync(let model, let data):
                let parameters: [String: String] = data
                return ("records/sync/\(model)", parameters)
            default:
                return ("", [:])
            }
        }()
        
        LOGGER.debug(path)
        LOGGER.debug(parameters)
        let URL = NSURL(string: Router.APIUrl)
        let URLRequest = NSMutableURLRequest(URL: URL!.URLByAppendingPathComponent(path))
        URLRequest.HTTPMethod = method.rawValue
        URLRequest.setValue("hash=16A4C184AED0", forHTTPHeaderField: "Authorization")
        URLRequest.setValue("application/json",  forHTTPHeaderField: "Content-Type")
        return encoding.encode(URLRequest, parameters: parameters).0
    }
}

class Sync {
    
    struct SyncSupportData {
        static let initialSync = "isInitialSync"
        static let lastSyncDate = "lastSyncDate"
    }
    
    enum SyncError: ErrorType {
        case Server([String: AnyObject])
        case Connection(ErrorType)
        case CoreData(String)
        
        var code: Int {
            switch self {
            case .Server(let data):
                return data["code"] as! Int
            case .Connection(let error):
                let error = error as NSError
                return error.code
            default:
                return 0000
            }
        }
        
        var description: String {
            switch self {
            case .Server(let data):
                return data["msg"] as! String
            case .Connection(let error):
                let error = error as NSError
                return error.localizedDescription
            default:
                return "No Error is present."
            }
        }
        
        var originalError: AnyObject {
            switch self {
            case .Server(let data):
                return data
            case .Connection(let error):
                let error = error as NSError
                return error
            default:
                return "No Error is present."
            }
        }
    }
    
    static let manager = Sync()
    
    var authenticate: Auth?
    var registeredModels: [String: SyncProtocol.Type]
    var inProgress: Bool = false
    var initialSync: Bool = true
    var lastSyncDate: NSDate?
    var authModel: AnyClass?
    
    
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
    
    func registerModelForSync(model: String){
        if registeredModels[model] == nil {
            registeredModels[model] = NSClassFromString(model) as? SyncProtocol.Type
            LOGGER.info("\(model) registered for Sync")
        }
    }
    
    func setup() {
        let objectModel = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectModel
        for entitiy in objectModel.entities {
            registerModelForSync(entitiy.name!)
            LOGGER.info("Sync manager ready.")
        }
        if let model = authModel {
            authenticate = Auth(modelClass: model)
        }
        else {
            authenticate = Auth(modelClass: User.self)
        }
    }
    
    func createRecord(forModel model: AnyClass, withData data: [String: String], success: (model: NSManagedObject) -> Void, failure: (error: SyncError) -> Void) {
        let modelName: String = NSStringFromClass(model).stringByReplacingOccurrencesOfString("SyncManager.", withString: "")
        let modelObject = registeredModels[modelName]!
        
        Alamofire.request(Router.Create(modelName.lowercaseString, data)).responseJSON { (request, response, result) -> Void in
            switch result {
            case .Success(let json):
                let record = JSON(json)
                if let errors = record["errors"].dictionaryObject {
                    failure(error: .Server(errors))
                }
                else {
                    if let createdModel = modelObject.createRecord(fromJson: record) {
                        LOGGER.info("\(modelName) was synced successfully.")
                        success(model: createdModel)
                    }
                    else {
                        failure(error: .CoreData("There was an error while saving \(modelName) data."))
                    }
                }
            case .Failure(let data, let errorResponse):
                LOGGER.debug(errorResponse as NSError)
                LOGGER.debug(NSString(data: data!, encoding: NSUTF8StringEncoding))
                failure(error: .Connection(errorResponse))
            }
        }
    }
    
    func saveRecord(forModel model: AnyClass, withData data: [String: String], inRecord id: NSNumber?, success: (model: NSManagedObject) -> Void, failure: (error: SyncError) -> Void) {
        let modelName: String = NSStringFromClass(model).stringByReplacingOccurrencesOfString("SyncManager.", withString: "")
        let modelObject = registeredModels[modelName]!
    
        Alamofire.request(Router.Save(modelName.lowercaseString, data, id)).responseJSON { (request, response, result) -> Void in
            switch result {
            case .Success(let json):
                let record = JSON(json)
                LOGGER.debug(record)
                if let errors = record["errors"].dictionaryObject {
                    failure(error: .Server(errors))
                }
                else {
                    if let savedModel = modelObject.saveRecord(fromJson: record, forRecord: record["id"].numberValue) {
                        LOGGER.info("\(modelName) was synced successfully.")
                        success(model: savedModel)
                    }
                    else {
                        failure(error: .CoreData("There was an error while saving \(modelName) data."))
                    }
                }
            case .Failure(let data, let errorResponse):
                LOGGER.debug(errorResponse as NSError)
                LOGGER.debug(NSString(data: data!, encoding: NSUTF8StringEncoding))
                failure(error: .Connection(errorResponse))
            }
        }
    }
    
    func get(record id: NSNumber!, forModel model: AnyClass, success: (model: NSManagedObject) -> Void, failure: (error: SyncError) -> Void) {
        let modelName: String = NSStringFromClass(model).stringByReplacingOccurrencesOfString("SyncManager.", withString: "")
        let modelObject = registeredModels[modelName]!

        Alamofire.request(Router.Get(modelName.lowercaseString, id!)).responseJSON { (request, response, result) -> Void in
            switch result {
            case .Success(let json):
                let record = JSON(json)
                if let errors = record["errors"].dictionaryObject {
                   failure(error:.Server(errors))
                }
                else {
                    if let savedModel = modelObject.saveRecord(fromJson: record, forRecord: id) {
                        LOGGER.info("\(modelName) was synced successfully.")
                        success(model: savedModel)
                    }
                    else {
                        failure(error: .CoreData("There was an error while saving \(modelName) data."))
                    }
                }
            case .Failure(let data, let errorResponse):
                LOGGER.debug(errorResponse as NSError)
                LOGGER.debug(NSString(data: data!, encoding: NSUTF8StringEncoding))
                failure(error: .Connection(errorResponse))
            }
        }
    }
    
    func allRecords(forModel model: AnyClass, success: (models: [NSManagedObject]) -> Void, failure: (error: SyncError) -> Void) {
        let modelName: String = NSStringFromClass(model).stringByReplacingOccurrencesOfString("SyncManager.", withString: "")
        let modelObject = registeredModels[modelName]!
        Alamofire.request(Router.GetAll(modelName.lowercaseString)).responseJSON { (request, response, result) -> Void in
            switch result {
            case .Success(let json):
                let record = JSON(json)
                if let errors = record["errors"].dictionaryObject {
                    failure(error: .Server(errors))
                }
                else {
                    var models: [NSManagedObject] = []
                    for modelRecord in record.array! {
                        if let savedModel = modelObject.saveRecord(fromJson: modelRecord, forRecord: modelRecord["id"].numberValue) {
                            LOGGER.info("\(modelName) was synced successfully.")
                            models.append(savedModel)
                        }
                        else {
                            failure(error: .CoreData("There was an error while saving \(modelName) data."))
                        }
                    }
                    success(models: models)
                }
                
            case .Failure(let data, let errorResponse):
                LOGGER.debug(errorResponse as NSError)
                LOGGER.debug(NSString(data: data!, encoding: NSUTF8StringEncoding))
                failure(error: .Connection(errorResponse))
            }
        }
    }
    
    func delete(record id: NSNumber, forModel model: AnyClass, success: () -> Void, failure: (error: SyncError) -> Void) {
        let modelName: String = NSStringFromClass(model).stringByReplacingOccurrencesOfString("SyncManager.", withString: "")
        Alamofire.request(Router.Delete(modelName.lowercaseString, id)).responseJSON { (request, response, result) -> Void in
            switch result {
            case .Success(let json):
                let record = JSON(json)
                if record["deleted"].boolValue {
                    success()
                }
                else {
                    failure(error: .Server(record["errors"].dictionaryObject!))
                }
                
            case .Failure(let data, let errorResponse):
                LOGGER.debug(errorResponse as NSError)
                LOGGER.debug(NSString(data: data!, encoding: NSUTF8StringEncoding))
                failure(error: .Connection(errorResponse))
            }
        }
    }
    
    func syncModel(modelName: String, completed: () -> Void) {
        let modelInSync = registeredModels[modelName]
        let modelData = modelInSync!.getModelRecords(byLastSyncDate: true, asJson: true)
        Alamofire.request(Router.Sync(modelName, modelData!)).responseJSON { (request, response, result) -> Void in
            switch result {
            case .Success(let json):
                let record = JSON(json)
                if let _ = modelInSync?.saveRecord(fromJson: record, forRecord: record["id"].numberValue) {
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
            modelData = modelClass.getModelRecords(byLastSyncDate: true, asJson: true)
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
                    if let _ = modelClass?.saveRecord(fromJson: record, forRecord: nil) {
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

class Auth {
    
   
    let userSession: NSUserDefaults?
    let model: SyncProtocol.Type?
    
    init(modelClass: AnyClass){
        userSession = NSUserDefaults.standardUserDefaults()
        let modelName: String = NSStringFromClass(modelClass).stringByReplacingOccurrencesOfString("SyncManager.", withString: "")
        model = Sync.manager.registeredModels[modelName]
    }
    
    func register(withUserData data: [String: String], valid:(model: NSManagedObject) -> Void, inValid:(error: Sync.SyncError ) -> Void){
        Alamofire.request(Router.Register(data)).responseJSON { (request, response, result) -> Void in
            switch result {
            case .Success(let json):
                let record = JSON(json)
                if let errors = record["errors"].dictionaryObject {
                    inValid(error: .Server(errors))
                }
                else {
                    if let createdModel = self.model?.createRecord(fromJson: record) {
                        self.userSession?.setValuesForKeysWithDictionary([
                            "userValid" : true,
                            "userId"    : record["id"].numberValue,
                            "userToken" : record["token"].stringValue
                        ])
                        valid(model: createdModel)
                    }
                    else {
                        inValid(error: .CoreData("There was an error while saving data."))
                    }
                }
            case .Failure(let data, let errorResponse):
                LOGGER.debug(errorResponse as NSError)
                LOGGER.debug(NSString(data: data!, encoding: NSUTF8StringEncoding))
                inValid(error: .Connection(errorResponse))
            }
        }
    }
    
    func login(username: String, password: String, valid:(model: NSManagedObject) -> Void, inValid:(error: Sync.SyncError) -> Void){
        Alamofire.request(Router.Login(["email": username, "password": password])).responseJSON { (request, response, result) -> Void in
            switch result {
            case .Success(let json):
                let record = JSON(json)
                LOGGER.debug(record)
                if record["logged_in"].boolValue {
                    if let savedModel = self.model?.saveRecord(fromJson: record, forRecord: record["user_id"].numberValue) {
                        self.userSession?.setValuesForKeysWithDictionary([
                            "userValid" : true,
                            "userId"    : record["user_id"].numberValue,
                            "userToken" : record["token"].stringValue
                        ])
                        valid(model: savedModel)
                    }
                    else {
                        inValid(error: .CoreData("There was an error while saving data."))
                    }
                }
                else {
                    inValid(error: .Server(record["errors"].dictionaryObject!))
                }
            case .Failure(let data, let errorResponse):
                LOGGER.debug(errorResponse as NSError)
                LOGGER.debug(NSString(data: data!, encoding: NSUTF8StringEncoding))
                inValid(error: .Connection(errorResponse))
            }
        }
    }
    
    func recoverPassword(email: String, success:(model: NSManagedObject) -> Void, failure:(error: Sync.SyncError) -> Void){
        
    }
    
    func recoverAccout(recoveryCode: String, success:(model: NSManagedObject) -> Void, failure:(error: Sync.SyncError) -> Void){
        
    }
    
    func changePassword(newData data: [String: String], success:(model: NSManagedObject) -> Void, failure:(error: Sync.SyncError) -> Void){
        
    }
    
    func logout(user: NSManagedObject, success:(model: NSManagedObject) -> Void, failure:(error: Sync.SyncError) -> Void){
        
    }
}

extension NSManagedObject {
    
    public static func clean(data: [String:AnyObject]) -> [String:AnyObject] {
        var properties = data
        for (key, value) in properties {
            if let _ = value as? NSNull {
                properties.removeValueForKey(key)
            }
        }
        return properties
    }
}