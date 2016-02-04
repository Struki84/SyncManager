//
//  Router.swift
//  SyncManager
//
//  Created by Šimun on 04.02.2016..
//  Copyright © 2016. Manifest Media. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

enum Router: URLRequestConvertible {
    
//    static let APIUrl = Config.manager?.apiServer
    static let APIUrl = "server.dev:3000/api/"
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
    case Model(String, Dictionary<String, String>)
    
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
                let parameters: [String: String] = [:]
                return ("records/all/\(model)", parameters)
            case .Create(let model, let data):
                let parameters: [String: String] = data
                return ("records/create/\(model)", parameters)
            case .Save(let model, let data, let id):
                let parameters: [String: String] = data
                return ("records/save/\(model)/\(id)", parameters)
            case .Delete(let model, let id):
                return ("records/\(model)/\(id)", [:])
            case .Sync(let model, let data):
                let parameters: [String: String] = data
                return ("records/sync/\(model)", parameters)
            default:
                return ("", [:])
            }
        }()
        
        let URL = NSURL(string: Router.APIUrl)
        let URLRequest = NSMutableURLRequest(URL: URL!.URLByAppendingPathComponent(path))
        URLRequest.HTTPMethod = method.rawValue
        URLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        let defaults = NSUserDefaults.standardUserDefaults()
        
//        if let currentUserId = defualts.objectForKey("currentUserId") as? NSNumber {
//            let currentUser: User = User.get(currentUserId)!
//            URLRequest.setValue("Bearer \(currentUser.accessToken!)", forHTTPHeaderField: "authenticate")
//        }
        
        let encoding = Alamofire.ParameterEncoding.URL
        LOGGER.debug(URLRequest)
        return encoding.encode(URLRequest, parameters: parameters).0
        
    }
}
