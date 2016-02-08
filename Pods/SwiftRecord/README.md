# SwiftRecord [![CocoaPod][pd-bdg]][pd] [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT) [![Issues](http://img.shields.io/github/issues/arkverse/SwiftRecord.svg)]( https://github.com/arkverse/SwiftRecord/issues)
[pd-bdg]: https://img.shields.io/cocoapods/v/SwiftRecord.svg
[pd]: http://cocoadocs.org/docsets/SwiftRecord
by [ark](http://www.arkverse.com). tweet [@arkverse](https://twitter.com/arkverse) for any feature requests. Feedback is greatly appreciated!

##About

ActiveRecord style Core Data object management. Tremendously convenient and easy to use. Necessary for any and every Core Data project.

Written purely in Swift and based heavily on [ObjectiveRecord](https://github.com/supermarin/ObjectiveRecord)

Easy creates, saves, deletes and queries. Do it using:

- `[String:AnyObject]` dictionaries for creates, queries or sorts
- `String` for queries and sorts, ie `name == 'someName'` or `date ASC`
- `NSPredicate` and `NSSortDescriptor`/`[NSSortDescriptor]` for queries and sorts if you'd like

Now supports setting an autoincrementing ID for your `NSManagedObject` subclasses

This library also reads in your json dictionaries for you. Includes automatic camelCase changing ie `first_name` from server to `firstName` locally. You can customize the dictionary mappings too. Read more in the [mapping section](#mapping). 

Object relationships are also generated from dictionaries, but disabled by default. Set `SwiftRecord.generateRelationships` to true to enable this feature. See the [relationships section](#relationships)

Visit [ark](http://www.arkverse.com) for a more [beginner friendly guide to SwiftRecord](http://www.arkverse.com/swiftrecord-easy-core-data-written-in-swift/)

[Check out our UIClosures library too](https://github.com/arkverse/UIClosures)

if you love SwiftRecord, tweet it!
<a href="https://twitter.com/intent/tweet?text=SwiftRecord%3A+an+amazing+swift+Core+Data+library&url=https%3A%2F%2Fgithub.com%2Farkverse%2FSwiftRecord&hashtags=ios%2Cswift%2Ccoredata&original_referer=http%3A%2F%2Fgithub.com%2F&tw_p=tweetbutton" target="_blank">
  <img src="http://jpillora.com/github-twitter-button/img/tweet.png"
       alt="tweet button" title="SwiftRecord: an amazing swift Core Data library"></img>
</a>

## Table of Contents

1. [Installation](#installation)
2. [Creates, Saves, Deletes](#create,)
3. [querying](#querying)
4. [sorting, limits](#sorting, limits)
5. [aggregation](#aggregation)
6. [custom coredata](#custom core data)
7. [mapping](#mapping)
8. [relationships](#relationships)
9. [autoincrement](#autoincrement)

## Installation

#### via [CocoaPods](http://cocoapods.org)
1. Edit your Podfile to use frameworks and add SwiftRecord:
		
		platform :ios, '8.0'
		use_frameworks!
	
		pod 'SwiftRecord'
2. run `pod install`

#### via Carthage

1. Just add SwiftRecord to your Cartfile:

	github "arkverse/SwiftRecord" >= 0.0.1
	
2. and run `carthage update`

#### Manual Installation
Drag and drop either `Classes/SwiftRecord.swift` or `SwiftRecord.framework` into your project

## Usage

1. At the top of every `NSManagedObject` swift class add:

	```swift
	import SwiftRecord
	
	@objc(Event)
	class Event: NSManagedObject {
		@NSManaged var eventID: NSNumber
		@NSManaged var name: String
		@NSManaged var type: String
		@NSManaged var when: NSDate
		@NSManaged var creator: User
		@NSManaged var attendess: NSSet
	}
	```
2. Set up Core Data by naming your model file `MyAppName.xcdatamodel`. Optionally, you can set your own model name by calling `CoreDataManager.sharedManager.modelName = "mymodelname"`

### create, save & delete:

```swift
var event = Event.create() as! Event // Downcasts are necessary, 
event.type = "Birthday"
event.when = NSDate()
event.save() // simple save
event.delete() // simple delete

var properties: [String:AnyObject] = ["name":"productQA","type":"meeting", "when":NSDate()]
var meeting = Event.create(properties) as! Event // Remember to downcast
```

Note: the downside to using swift is that `NSManagedObject` and `[NSManagedObject]`(arrays) are returned*, so api calls have to down casted into your class type. Feel free to always force downcast. `MyObject` calls will always create `MyObject` unless your class could not be found

*`instancetype`, `Self` in Swift, has only just been added, and still pretty useless

### querying

Easily query against your entities. Queries accept optional condition, sort and limit parameters.

```swift
// grab all Events
var events = Event.all() as! [Event]

// all past events before now
var pastEvents = Event.query("when < %@", NSDate()) as! [Event]

// specific event, yes we have support for format&arguments. Note, finding specific events return optional vars
var thisEvent = Event.find("name == %@ AND when == %@", "productQA", NSDate()) as? Event

// Use dictionaries to query too
var birthdayEvents = Event.query(["type":"birthday"]) as! [Event]

// or NSPredicates
var predicate = NSPredicate("type == %@", "meeting")
var meetingEvents = Event.query(predicate) as! [Event]
```

### sorting, limits

```swift
// Events sorted by date, defaults to ascending
var events = Event.all(sort: "when") as! [Event]
// Descending
var descendingEvents = Event.all(sort:["when":"DESC"]) as! [Event]
// or
var descEvents = Event.all(sort:"when DESC, eventID ASC")

// All meeting events sorted by when desc and eventID ascending and limit 10
var theseEvents = Event.query(["type":"meeting"], sort:["when":"DESC","eventID":"ASC"], limit: 10) as! [Event]

// NSSortDescriptor as sort arg (or array of NSSortDescriptors
Event.all(sort: NSSortDescriptor(key:"when",ascending:true))
```

### Aggregation

```swift
// count all Events
var count = Event.count()

// count meeting Events
var count = Event.count("type == 'meeting'")
```

### Custom Core Data

#### Custom ManagedObjectContext
if you made your own, feel free to set it

```swift
var myContext: NSManagedObjectContext = ...

CoreDataManager.sharedManager.managedObjectContext = myContext
```

#### Custom CoreData model or .sqlite database
Don't set these if you set your own context.
If you have a modelName different from the name of your app, set it. If you want a different databse name, set it.
```swift
CoreDataManager.sharedManager.modelName = "MyModelName"
CoreDataManager.sharedManager.databaseName = "custom_database_name"
```

### Mapping

The most of the time, your JSON web service returns keys like `first_name`, `last_name`, etc. <br/>
Your Swift implementation has camelCased properties - `firstName`, `lastName`.<br/>

We automatically check against camelCase variations.

If you have different variations, override `static func mappings() -> [String:String]` to specify your local to remote key mapping

The key string is your local name, the value string, your remote name.

```swift
// this method is called once, so you don't have to do any caching / singletons
class Event: NSManagedObject {

override class func mappings() -> [String:String] {
	return ["localName":"remoteName","eventID":"_id","attendees":"people"]
}
  // firstName => first_name is automatically handled
}

@end
```

### Relationships
While it is advised against, you can have your NSManagedObject relationships in your dictionaries and they will be filled, but first you must enable it by setting:

	SwiftRecord.generateRelationships = true
	
Once this is set, you rels will be filled, ie:

```swift
var personDict = ["email":"zaid@arkverse.com","firstName":"zaid"]
var eventDict = ["name":"product QA meeting","when":NSDate(),"creator":personDict]
var event = Event.create(eventDict) as! Event
var person: Person = event.creator
println(person.username)
```

### Autoincrement
If you would like SwiftRecord to manage autoincrementing your ID property for you, enable it just by override autoIncrementingId() and return the key for your ID property:

```swift
public class Event: NSManagedObject {

   override public func autoIncrementingId() -> String? {
       return "eventId"
   }
```
Note, this will set your ID property whenever one isn't provided. You will have duplicate ID's if you set your own objects id. For example, autoincrement is at ID 150 and you create an object with ID 200, autoincrement will eventually create an object with ID 200 as well. Enforcing uniqueness in Core Data is too expensive.

#### Testing

ObjectiveRecord supports CoreData's in-memory store. In any place, before your tests start running, it's enough to call
```swift
CoreDataManager.sharedManager.useInMemoryStore()
```

#### Roadmap

- improve Swiftiness
- JSON generation
- Possible add NSOrderedSet support in Relationship init
- Support Realm
- Better typing

## License

SwiftRecord is available under the MIT license. See the LICENSE file
for more information.

Check out [ark](http://www.arkverse.com) for more about us

![ga tracker](https://www.google-analytics.com/collect?v=1&a=257770996&t=pageview&dl=https%3A%2F%2Fgithub.com%2Farkverse%2FSwiftRecord&ul=en-us&de=UTF-8&cid=978224512.1377738459&tid=UA-63011921-1&z=887657232 "ga tracker")
