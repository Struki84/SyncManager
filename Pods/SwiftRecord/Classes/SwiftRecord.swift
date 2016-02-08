//
//  SwiftRecord.swift
//  
//  ark - http://www.arkverse.com
//  Created by Zaid on 5/7/15.
//
//

import Foundation
import CoreData
#if os(iOS)
import UIKit
#endif

public class SwiftRecord {
    
    public static var generateRelationships = false
    
    public static func setUpEntities(entities: [String:NSManagedObject.Type]) {
        nameToEntities = entities
    }
    
    private static var nameToEntities: [String:NSManagedObject.Type] = [String:NSManagedObject.Type]()
    
    public let appName = NSBundle.mainBundle().infoDictionary!["CFBundleName"] as! String
    
    public var databaseName: String {
        get {
            if let db = self._databaseName {
                return db
            } else {
                return self.appName + ".sqlite"
            }
        }
        set {
            _databaseName = newValue
            if _managedObjectContext != nil {
                _managedObjectContext = nil
            }
            if _persistentStoreCoordinator != nil {
                _persistentStoreCoordinator = nil
            }
        }
    }
    private var _databaseName: String?
    
    public var modelName: String {
        get {
            if let model = _modelName {
                return model
            } else {
                return appName
            }
        }
        set {
            _modelName = newValue
            if _managedObjectContext != nil {
                _managedObjectContext = nil
            }
            if _persistentStoreCoordinator != nil {
                _persistentStoreCoordinator = nil
            }
        }
    }
    private var _modelName: String?
    
    public var managedObjectContext: NSManagedObjectContext {
        get {
            if let context = _managedObjectContext {
                return context
            } else {
                let c = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
                c.persistentStoreCoordinator = persistentStoreCoordinator
                _managedObjectContext = c
                return c
            }
        }
        set {
            _managedObjectContext = newValue
        }
    }
    private var _managedObjectContext: NSManagedObjectContext?
    
    public var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        if let store = _persistentStoreCoordinator {
            return store
        } else {
            let p = self.persistentStoreCoordinator(NSSQLiteStoreType, storeURL: self.sqliteStoreURL)
            _persistentStoreCoordinator = p
            return p
        }
    }
    private var _persistentStoreCoordinator: NSPersistentStoreCoordinator?
    
    public var managedObjectModel: NSManagedObjectModel {
        get {
            if let m = _managedObjectModel {
                return m
            } else {
                let modelURL = NSBundle.mainBundle().URLForResource(self.modelName, withExtension: "momd")
                _managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL!)
                return _managedObjectModel!
            }
        }
        set {
            _managedObjectModel = newValue
        }
    }
    private var _managedObjectModel: NSManagedObjectModel?
    
    public func useInMemoryStore() {
        _persistentStoreCoordinator = self.persistentStoreCoordinator(NSInMemoryStoreType, storeURL: nil)
    }
    
    public func saveContext() -> Bool {
        if !self.managedObjectContext.hasChanges {
            return false
        }

        do {
            try self.managedObjectContext.save()
        } catch let error as NSError {
            print("Unresolved error in saving context! " + error.debugDescription)
            return false
        }
        
        return true
    }
    
    public func applicationDocumentsDirectory() -> NSURL {
        return NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).last!
    }
    
    public func applicationSupportDirectory() -> NSURL {
        return (NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.ApplicationSupportDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).last!).URLByAppendingPathComponent(self.appName)
    }
    
    public var sqliteStoreURL: NSURL {
        #if os(iOS)
            let dir = self.applicationDocumentsDirectory()
        #else
            let dir = self.applicationSupportDirectory()
            self.createApplicationSupportDirIfNeeded(dir)
        #endif
        return dir.URLByAppendingPathComponent(self.databaseName)
        
    }
    
    private func persistentStoreCoordinator(storeType: String, storeURL: NSURL?) -> NSPersistentStoreCoordinator {
        let c = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        do {
            try c.addPersistentStoreWithType(storeType, configuration: nil, URL: storeURL, options: [NSMigratePersistentStoresAutomaticallyOption:true, NSInferMappingModelAutomaticallyOption:true])
        } catch let error as NSError {
            print("ERROR WHILE CREATING PERSISTENT STORE COORDINATOR! " + error.debugDescription)
        }
        return c
    }
    
    private func createApplicationSupportDirIfNeeded(dir: NSURL) {
        if NSFileManager.defaultManager().fileExistsAtPath(dir.absoluteString) {
            return
        }
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(dir, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("ERROR WHILE CREATING APPLICATION SUPPORT DIRECTORY! " + error.debugDescription)
        }
    }
    private init() {
        #if os(iOS)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillTerminate", name: UIApplicationWillTerminateNotification, object: nil)
        #endif
    }
    public func applicationWillTerminate() {
    #if os(iOS)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        saveContext()
    #endif
    }
    // singleton
    public static let sharedRecord = SwiftRecord()
}

public extension NSManagedObjectContext {
    public static var defaultContext: NSManagedObjectContext {
        return SwiftRecord.sharedRecord.managedObjectContext
    }
}

public extension NSManagedObject {
    
    //Querying
    
    public static func all() -> [NSManagedObject] {
        return self.all(context: NSManagedObjectContext.defaultContext)
    }
    
    public static func all(sort sort: AnyObject) -> [NSManagedObject] {
        return self.all(context: NSManagedObjectContext.defaultContext, withSort:sort)
    }
    
    public static func all(context context: NSManagedObjectContext) -> [NSManagedObject] {
        return self.all(context: context, withSort: nil)
    }
    
    public static func all(context context: NSManagedObjectContext, withSort sort: AnyObject?) -> [NSManagedObject] {
        return self.fetch(nil, context: context, sort: sort, limit: nil)
    }
    
    public static func findOrCreate(properties: [String:AnyObject]) -> NSManagedObject {
        return self.findOrCreate(properties, context: NSManagedObjectContext.defaultContext)
    }
    
    public static func findOrCreate(properties: [String:AnyObject], context: NSManagedObjectContext) -> NSManagedObject {
        let transformed = self.transformProperties(properties, context: context)
        let existing: NSManagedObject? = self.query(transformed, context: context).first
        return existing ?? self.create(transformed, context:context)
    }
    
    public static func find(condition: AnyObject, args: AnyObject...) -> NSManagedObject? {
        let predicate: NSPredicate = self.predicate(condition, args: args);
        return self.find(predicate, context: NSManagedObjectContext.defaultContext)
    }
    
    public static func find(condition: AnyObject, context: NSManagedObjectContext) -> NSManagedObject? {
        return self.query(condition, context: context, sort:nil, limit:1).first
    }
    
    public static func query(condition: AnyObject, args: AnyObject...) -> [NSManagedObject] {
        let predicate: NSPredicate = self.predicate(condition, args: args)
        return self.query(predicate, context:NSManagedObjectContext.defaultContext)
    }
    
    public static func query(condition: AnyObject, sort: AnyObject) -> [NSManagedObject] {
        return self.query(condition, context: NSManagedObjectContext.defaultContext, sort: sort)
    }
    
    public static func query(condition: AnyObject, limit: Int) -> [NSManagedObject] {
        return self.query(condition, context: NSManagedObjectContext.defaultContext, sort:nil, limit: limit)
    }
    
    public static func query(condition: AnyObject, sort: AnyObject, limit: Int) -> [NSManagedObject] {
        return self.query(condition, context: NSManagedObjectContext.defaultContext, sort: sort, limit: limit)
    }
    
    public static func query(condition: AnyObject, context: NSManagedObjectContext) -> [NSManagedObject] {
        return self.query(condition, context: context, sort: nil, limit: nil)
    }
    
    public static func query(condition: AnyObject, context: NSManagedObjectContext, sort: AnyObject) -> [NSManagedObject] {
        return self.query(condition, context: context, sort: sort, limit: nil)
    }
    
    public static func query(condition: AnyObject, context: NSManagedObjectContext, sort: AnyObject?, limit: Int?) -> [NSManagedObject] {
        return self.fetch(condition, context: context, sort: sort, limit: limit)
    }
    
    // Aggregation
    
    public static func count() -> Int {
        return self.count(NSManagedObjectContext.defaultContext)
    }
    
    public static func count(query query: AnyObject, args: AnyObject...) -> Int {
        let predicate = self.predicate(query, args: args)
        return self.count(query: predicate, context:NSManagedObjectContext.defaultContext)
    }
    
    public static func count(context: NSManagedObjectContext) -> Int {
        return self.countForFetch(nil, context: context)
    }
    
    public static func count(query query: AnyObject, context: NSManagedObjectContext) -> Int {
        return self.countForFetch(self.predicate(query), context: context)
    }
    
    // Creation / Deletion
    public static func create() -> NSManagedObject {
        return self.create(context: NSManagedObjectContext.defaultContext)
    }
    
    public static func create(context context: NSManagedObjectContext) -> NSManagedObject {
        let o = NSEntityDescription.insertNewObjectForEntityForName(self.entityName(), inManagedObjectContext: context) as NSManagedObject
        if let idprop = self.autoIncrementingId() {
            o.setPrimitiveValue(NSNumber(integer: self.nextId()), forKey: idprop)
        }
        return o
    }
    
    public static func create(properties properties: [String:AnyObject]) -> NSManagedObject {
        return self.create(properties, context: NSManagedObjectContext.defaultContext)
    }
    
    public static func create(properties: [String:AnyObject], context: NSManagedObjectContext) -> NSManagedObject {
        let newEntity: NSManagedObject = self.create(context: context)
        newEntity.update(properties)
        if let idprop = self.autoIncrementingId() {
            if newEntity.primitiveValueForKey(idprop) == nil {
                newEntity.setPrimitiveValue(NSNumber(integer: self.nextId()), forKey: idprop)
            }
        }
        return newEntity
    }
    
    public static func autoIncrements() -> Bool {
        return self.autoIncrementingId() != nil
    }
    
    public static func nextId() -> Int {
        let key = "SwiftRecord-" + self.entityName() + "-ID"
        if let _ = self.autoIncrementingId() {
            let id = NSUserDefaults.standardUserDefaults().integerForKey(key)
            NSUserDefaults.standardUserDefaults().setInteger(id + 1, forKey: key)
            return id
        }
        return 0
    }
    
    public func update(properties: [String:AnyObject]) {
        if (properties.count == 0) {
            return
        }
        let context = self.managedObjectContext ?? NSManagedObjectContext.defaultContext
        let transformed = self.dynamicType.transformProperties(properties, context: context)
        //Finish
        for (key, value) in transformed {
            self.willChangeValueForKey(key)
            self.setSafeValue(value, forKey: key)
            self.didChangeValueForKey(key)
        }
    }
    
    public static func save() -> Bool {
        do {
            try NSManagedObjectContext.defaultContext.save()
            return true
        } catch let e as NSError {
            print("Save Error: \(e)")
            return false
        }
    }
    
    public func save() -> Bool {
        return self.saveTheContext()
    }
    
    public func delete() {
        self.managedObjectContext!.deleteObject(self)
    }
    
    public static func deleteAll() {
        self.deleteAll(NSManagedObjectContext.defaultContext)
    }
    
    public static func deleteAll(context: NSManagedObjectContext) {
        for o in self.all(context: context) {
            o.delete()
        }
    }
    
    public class func autoIncrementingId() -> String? {
        return nil
    }
    
    public static func entityName() -> String {
        var name = NSStringFromClass(self)
        if name.rangeOfString(".") != nil {
            
            let comp = name.characters.split {$0 == "."}.map { String($0) }
            if comp.count > 1 {
                name = comp.last!
            }
        }
        if name.rangeOfString("_") != nil {
            var comp = name.characters.split {$0 == "_"}.map { String($0) }
            var last: String = ""
            var remove = -1
            for (i,s) in comp.reverse().enumerate() {
                if last == s {
                    remove = i
                }
                last = s
            }
            if remove > -1 {
                comp.removeAtIndex(remove)
                name = comp.joinWithSeparator("_")
            }
        }
        return name
    }
    
    //Private
    
    private static func transformProperties(properties: [String:AnyObject], context: NSManagedObjectContext) -> [String:AnyObject]{
        let entity = NSEntityDescription.entityForName(self.entityName(), inManagedObjectContext: context)!
        let attrs = entity.attributesByName
        let rels = entity.relationshipsByName
        
        var transformed = [String:AnyObject]()
        for (key, value) in properties {
            let localKey = self.keyForRemoteKey(key, context: context)
            if attrs[localKey] != nil {
                transformed[localKey] = value
            } else if let rel = rels[localKey] {
                if SwiftRecord.generateRelationships {
                    if rel.toMany {
                        if let array = value as? [[String:AnyObject]] {
                            transformed[localKey] = self.generateSet(rel, array: array, context: context)
                        } else {
                            #if DEBUG
                                print("Invalid value for relationship generation in \(NSStringFromClass(self)).\(localKey)")
                                print(value)
                            #endif
                        }
                    } else if let dict = value as? [String:AnyObject] {
                        transformed[localKey] = self.generateObject(rel, dict: dict, context: context)
                    } else {
                        #if DEBUG
                            print("Invalid value for relationship generation in \(NSStringFromClass(self)).\(localKey)")
                            print(value)
                        #endif
                    }
                }
            }
        }
        return transformed
    }
    
    private static func predicate(properties: [String:AnyObject]) -> NSPredicate {
        var preds = [NSPredicate]()
        for (key, value) in properties {
            preds.append(NSPredicate(format: "%K = %@", argumentArray: [key, value]))
        }
        return NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: preds)
    }
    
    private static func predicate(condition: AnyObject) -> NSPredicate {
        return self.predicate(condition, args: nil)
    }
    
    private static func predicate(condition: AnyObject, args: [AnyObject]?) -> NSPredicate {
        if condition is NSPredicate {
            return condition as! NSPredicate
        }
        if condition is String {
            return NSPredicate(format: condition as! String, argumentArray: args)
        }
        if let d = condition as? [String:AnyObject] {
            return self.predicate(d)
        }
        return NSPredicate()
    }
    
    private static func sortDescriptor(o: AnyObject) -> NSSortDescriptor {
        if let _ = o as? String {
            return self.sortDescriptor(o)
        }
        if let d = o as? NSSortDescriptor {
            return d
        }
        if let d = o as? [String:AnyObject] {
            return self.sortDescriptor(d)
        }
        return NSSortDescriptor()
    }
    
    private static func sortDescriptor(dict: [String:AnyObject]) -> NSSortDescriptor {
        let isAscending = (dict.values.first as! String).uppercaseString != "DESC"
        return NSSortDescriptor(key: dict.keys.first!, ascending: isAscending)
    }
    
    private static func sortDescriptor(string: String) -> NSSortDescriptor {
        var key = string
        let components = string.characters.split {$0 == " "}.map { String($0) }
        var isAscending = true
        if (components.count > 1) {
            key = components[0]
            isAscending = components[1] == "ASC"
        }
        return NSSortDescriptor(key: key, ascending: isAscending)
    }
    
    private static func sortDescriptors(d: AnyObject) -> [NSSortDescriptor] {
        if let ds = d as? [NSSortDescriptor] {
            return ds
        }
        if let s = d as? String {
            return self.sortDescriptors(s)
        }
        if let dicts = d as? [[String:AnyObject]] {
            return self.sortDescriptors(dicts)
        }
        return [self.sortDescriptor(d)]
    }
    
    private static func sortDescriptors(s: String) -> [NSSortDescriptor]{
        let components = s.characters.split {$0 == ","}.map { String($0) }
        var ds = [NSSortDescriptor]()
        for sub in components {
            ds.append(self.sortDescriptor(sub))
        }
        return ds
    }
    
    private static func sortDescriptors(ds: [NSSortDescriptor]) -> [NSSortDescriptor] {
        return ds
    }
    
    private static func sortDescriptors(ds: [[String:AnyObject]]) -> [NSSortDescriptor] {
        var ret = [NSSortDescriptor]()
        for d in ds {
            ret.append(self.sortDescriptor(d))
        }
        return ret
    }
    
    private static func createFetchRequest(context: NSManagedObjectContext) -> NSFetchRequest {
        let request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName(self.entityName(), inManagedObjectContext: context)
        return request
    }
    
    private static func fetch(condition: AnyObject?, context: NSManagedObjectContext, sort: AnyObject?, limit: Int?) -> [NSManagedObject] {
        let request = self.createFetchRequest(context)
        
        if let cond: AnyObject = condition {
            request.predicate = self.predicate(cond)
        }
        
        if let ord: AnyObject = sort {
            request.sortDescriptors = self.sortDescriptors(ord)
        }
        
        if let lim = limit {
            request.fetchLimit = lim
        }

        var result : [NSManagedObject]
        
        do {
            var fetchResult : [AnyObject]
            try fetchResult = context.executeFetchRequest(request)
            
            if let fetchResultTyped = fetchResult as? [NSManagedObject] {
                result = fetchResultTyped
            } else {
                throw NSError(domain: "Fetch results unable to be casted to [NSManagedObject]", code: 0, userInfo: nil)
            }
        } catch let error as NSError {
            print("Error executing fetch request \(request): " + error.description)
            result = [NSManagedObject]()
        }
        
        return result
    }
    
    private static func countForFetch(predicate: NSPredicate?, context: NSManagedObjectContext) -> Int {
        let request = self.createFetchRequest(context)
        request.predicate = predicate
        
        return context.countForFetchRequest(request, error: nil)
    }
    
    private static func count(predicate: NSPredicate, context: NSManagedObjectContext) -> Int {
        let request = self.createFetchRequest(context)
        request.predicate = predicate
        return context.countForFetchRequest(request, error: nil)
    }
    
    private func saveTheContext() -> Bool {
        if self.managedObjectContext == nil || !self.managedObjectContext!.hasChanges {
            return true
        }
        
        do {
            try self.managedObjectContext!.save()
        } catch let error as NSError {
            print("Unresolved error in saving context for entity:")
            print(self)
            print("!\nError: " + error.debugDescription)
            return false
        }
        
        return true
    }
    
    private func setSafeValue(value: AnyObject?, forKey key: String) {
        if (value == nil) {
            self.setNilValueForKey(key)
            return
        }
        let val: AnyObject = value!
        if let attr = self.entity.attributesByName[key] {
            let attrType = attr.attributeType
            if attrType == NSAttributeType.StringAttributeType && value is NSNumber {
                self.setPrimitiveValue((val as! NSNumber).stringValue, forKey: key)
            } else if let s = val as? String {
                if self.isIntegerAttributeType(attrType) {
                    self.setPrimitiveValue(NSNumber(integer: val.integerValue), forKey: key)
                    return
                } else if attrType == NSAttributeType.BooleanAttributeType {
                    self.setPrimitiveValue(NSNumber(bool: val.boolValue), forKey: key)
                    return
                } else if (attrType == NSAttributeType.FloatAttributeType) {
                    self.setPrimitiveValue(NSNumber(floatLiteral: val.doubleValue), forKey: key)
                    return
                } else if (attrType == NSAttributeType.DateAttributeType) {
                    self.setPrimitiveValue(self.dynamicType.dateFormatter.dateFromString(s), forKey: key)
                    return
                }
            }
        }
        self.setPrimitiveValue(value, forKey: key)
    }
    
    private func isIntegerAttributeType(attrType: NSAttributeType) -> Bool {
        return attrType == NSAttributeType.Integer16AttributeType || attrType == NSAttributeType.Integer32AttributeType || attrType == NSAttributeType.Integer64AttributeType
    }
    
    private static var dateFormatter: NSDateFormatter {
        if _dateFormatter == nil {
            _dateFormatter = NSDateFormatter()
            _dateFormatter!.dateFormat = "yyyy-MM-dd HH:mm:ss z"
        }
        return _dateFormatter!
    }
    private static var _dateFormatter: NSDateFormatter?
}

public extension NSManagedObject {
    public class func mappings() -> [String:String] {
        return [String:String]()
    }
    
    public static func keyForRemoteKey(remote: String, context: NSManagedObjectContext) -> String {
        if let s = cachedMappings[remote] {
            return s
        }
        let entity = NSEntityDescription.entityForName(self.entityName(), inManagedObjectContext: context)!
        let properties = entity.propertiesByName
        if properties[remote] != nil {
            _cachedMappings![remote] = remote
            return remote
        }
        
        let camelCased = remote.camelCase
        if properties[camelCased] != nil {
            _cachedMappings![remote] = camelCased
            return camelCased
        }
        _cachedMappings![remote] = remote
        return remote
    }
    private static var cachedMappings: [String:String] {
        if let m = _cachedMappings {
            return m
        } else {
            var m = [String:String]()
            for (key, value) in mappings() {
                m[value] = key
            }
            _cachedMappings = m
            return m
        }
    }
    private static var _cachedMappings: [String:String]?
    
    private static func generateSet(rel: NSRelationshipDescription, array: [[String:AnyObject]], context: NSManagedObjectContext) -> NSSet {
        var cls: NSManagedObject.Type?
        if SwiftRecord.nameToEntities.count > 0 {
            cls = SwiftRecord.nameToEntities[rel.destinationEntity!.managedObjectClassName]
        }
        if cls == nil {
            cls = (NSClassFromString(rel.destinationEntity!.managedObjectClassName) as! NSManagedObject.Type)
        } else {
            print("Got class name from entity setup")
        }
        let set = NSMutableSet()
        for d in array {
            set.addObject(cls!.findOrCreate(d, context: context))
        }
        return set
    }
    
    private static func generateObject(rel: NSRelationshipDescription, dict: [String:AnyObject], context: NSManagedObjectContext) -> NSManagedObject {
        let entity = rel.destinationEntity!
        
        let cls: NSManagedObject.Type = NSClassFromString(entity.managedObjectClassName) as! NSManagedObject.Type
        return cls.findOrCreate(dict, context: context)
    }
    
    public static func primaryKey() -> String {
        NSException(name: "Primary key undefined in " + NSStringFromClass(self), reason: "Override primaryKey if you want to support automatic creation, otherwise disable this feature", userInfo: nil).raise()
        return ""
    }
}

private extension String {
    var camelCase: String {
        let spaced = self.stringByReplacingOccurrencesOfString("_", withString: " ", options: [], range:Range<String.Index>(start: self.startIndex, end: self.endIndex))
        let capitalized = spaced.capitalizedString
        let spaceless = capitalized.stringByReplacingOccurrencesOfString(" ", withString: "", options:[], range:Range<String.Index>(start:self.startIndex, end:self.endIndex))
        return spaceless.stringByReplacingCharactersInRange(Range<String.Index>(start:spaceless.startIndex, end:spaceless.startIndex.successor()), withString: "\(spaceless[spaceless.startIndex])".lowercaseString)
    }
}

extension NSObject {
    // create a static method to get a swift class for a string name
    class func swiftClassFromString(className: String) -> AnyClass! {
        // get the project name
        if  let appName: String? = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as? String {
            // generate the full name of your class (take a look into your "YourProject-swift.h" file)
            let classStringName = "_TtC\(appName!.utf16.count)\(appName)\(className.characters.count)\(className)"
            // return the class!
            
            return NSClassFromString(classStringName)
        }
        return nil;
    }
}