//
//  ResourceAttribute.swift
//  Spine
//
//  Created by Ward van Teijlingen on 30-12-14.
//  Copyright (c) 2014 Ward van Teijlingen. All rights reserved.
//

import Foundation
import SwiftyJSON


// XXX: remove this
//public func fieldsFromDictionary(_ dictionary: [String: Field]) -> [Field] {
//	return dictionary.map { (name, field) in
//		field.name = name
//		return field
//	}
//}

/// Base field.
/// Do not use this field type directly, instead use a specific subclass.
//open class Field {
//	/// The name of the field as it appears in the model class.
//	/// This is declared as an implicit optional to support the `fieldsFromDictionary` function,
//	/// however it should *never* be nil.
//	public internal(set) var name: String! = nil
//	
//	/// The name of the field that will be used for formatting to the JSON key.
//	/// This can be nil, in which case the regular name will be used.
//	public internal(set) var serializedName: String {
//		get {
//			return _serializedName ?? name
//		}
//		set {
//			_serializedName = newValue
//		}
//	}
//	fileprivate var _serializedName: String?
//	
//	var isReadOnly: Bool = false
//
//	fileprivate init() {}
//	
//	/// Sets the serialized name.
//	///
//	/// - parameter name: The serialized name to use.
//	///
//	/// - returns: The field.
//	public func serializeAs(_ name: String) -> Self {
//		serializedName = name
//		return self
//	}
//	
//	public func readOnly() -> Self {
//		isReadOnly = true
//		return self
//	}
//}

public protocol Field {
    var name: String { get set } // XXX: remove set
    var serializedName: String { get set }
    var isReadOnly: Bool { get set }

    func readOnly() -> Self
    func serializeAs(_ serializeName: String) -> Self

    var relatedType: Resource.Type? { get }

    func extract(from serializedData: JSON,
                 intoResource resource: Resource,
                 withKeyFormatter keyFormatter: KeyFormatter,
                 withValueFormatters valueFormatters: ValueFormatterRegistry,
                 fromResourcePool pool: inout [Resource],
                 withFactory factory: ResourceFactory)
}

extension Field {
    public func readOnly() -> Self {
        var newField = self
        newField.isReadOnly = true
        return newField
    }

    public func serializeAs(_ serializeName: String) -> Self {
        var newField = self
        newField.serializedName = serializeName
        return newField
    }
}

protocol Attribute: Field {

}

extension Attribute {
    public var relatedType: Resource.Type? {
        return nil
    }

    public func extract(from serializedData: JSON,
                        intoResource resource: Resource,
                        withKeyFormatter keyFormatter: KeyFormatter,
                        withValueFormatters valueFormatters: ValueFormatterRegistry,
                        fromResourcePool pool: inout [Resource],
                        withFactory factory: ResourceFactory) {
        let key = keyFormatter.format(self)
        let value = serializedData["attributes"][key]

        if let _ = value.null {
            // XXX: pass
        } else {
            let formattedValue = valueFormatters.unformatValue(value.rawValue, forAttribute: self)
            resource.setValue(formattedValue, forField: self.name)
        }
    }
}


public struct PlainAttribute : Attribute {
    public var name: String
    public var serializedName: String
    public var isReadOnly: Bool = false

    init(_ name: String) {
        self.name = name
        self.serializedName = name
    }
}

public struct BooleanAttribute : Attribute {
    public var name: String
    public var serializedName: String
    public var isReadOnly: Bool = false

    init(_ name: String) {
        self.name = name
        self.serializedName = name
    }
}

public struct URLAttribute : Attribute {
    public var name: String
    public var serializedName: String
    public var isReadOnly: Bool = false
    public let baseURL: URL?

    init(_ name: String, for url: URL? = nil) {
        self.name = name
        self.serializedName = name
        self.baseURL = url
    }
}

public struct DateAttribute : Attribute {
    public var name: String
    public var serializedName: String
    public var isReadOnly: Bool = false
    public let format: String

    init(_ name: String, format: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ") {
        self.name = name
        self.serializedName = name
        self.format = format
    }
}



// MARK: - Built in fields

/// A basic attribute field.
//open class Attribute: Field {
//	override public init() {}
//}

/// A URL attribute that maps to an URL property.
/// You can optionally specify a base URL to which relative
/// URLs will be made absolute.
//public class URLAttribute: Attribute {
//	let baseURL: URL?
//	
//	public init(baseURL: URL? = nil) {
//		self.baseURL = baseURL
//	}
//}

/// A date attribute that maps to an NSDate property.
/// By default, it uses ISO8601 format `yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ`.
/// You can specify a custom format by passing it to the initializer.
//public class DateAttribute: Attribute {
//	let format: String
//
//	public init(format: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ") {
//		self.format = format
//	}
//}

/// A boolean attribute that maps to an NSNumber property.
//public class BooleanAttribute: Attribute {}

/// A basic relationship field.
/// Do not use this field type directly, instead use either `ToOneRelationship` or `ToManyRelationship`.
//public class Relationship: Field {
//	let linkedType: Resource.Type
//	
//	public init(_ type: Resource.Type) {
//		linkedType = type
//	}
//}

//public class Relationship<T: Resource>: Field {
//	let linkedType: T.Type
//
//	public init(_ type: T.Type) {
//		linkedType = type
//	}
//}

//protocol Relationship {
//    associatedtype LinkedType: Resource
//
////    init(_ type: LinkedType.Type)
//}

//extension Relationship {
//    let linkedTo: LinkedType
//
//    public init(_ type: LinkedType.Type) {
//        linkedTo = type
//    }
//}

//public class ToOneRelationship<T: Resource>: Field, Relationship {
//    typealias LinkedType = T
//
//    public init(_ type: T.Type) { }
//}
//
//public class ToManyRelationship<T: Resource>: Field, Relationship {
//    typealias LinkedType = T
//
//
//    public init(_ type: T.Type) { }
//}





public protocol Relationship : Field {
    associatedtype Linked: Resource
    // XXX: create protocol that combines Resource and LinkedResourceCollection
//    associatedtype ReturnValue

}

extension Relationship {
    public var relatedType: Resource.Type? {
        return Linked.self
    }


    func extractRelationshipData(_ linkData: JSON) -> RelationshipData {
        let selfURL = linkData["links"]["self"].URL
        let relatedURL = linkData["links"]["related"].URL
        let data: [ResourceIdentifier]?

        if let toOne = linkData["data"].dictionary {
            data = [ResourceIdentifier(type: toOne["type"]!.stringValue, id: toOne["id"]!.stringValue)]
        } else if let toMany = linkData["data"].array {
            data = toMany.map { JSON -> ResourceIdentifier in
                return ResourceIdentifier(type: JSON["type"].stringValue, id: JSON["id"].stringValue)
            }
        } else {
            data = nil
        }
        
        return RelationshipData(selfURL: selfURL, relatedURL: relatedURL, data: data)
    }
}

//public protocol ToOneRelationshipProtocol: Relationship {
//    // XXX: move to RelationshipProtocol
//    func extractToOneRelationship(_ key: String, from serializedData: JSON, linkedType: Linked.Type) -> Linked?
//}
//
//public protocol ToManyRelationshipProtocol: Relationship {
//    // XXX: move to RelationshipProtocol
//    func extractToManyRelationship(_ key: String, from serializedData: JSON) -> LinkedResourceCollection<Linked>?
//}

public struct ToOneRelationship<T: Resource> : Relationship {
    public typealias Linked = T
//    public typealias ReturnValue = Linked

    public var name: String
    public var serializedName: String
    public var isReadOnly: Bool = false

    init(_ name: String, to linkedType: T.Type) {
        self.name = name
        self.serializedName = name
    }

    public func extract(from serializedData: JSON,
                        intoResource resource: Resource,
                        withKeyFormatter keyFormatter: KeyFormatter,
                        withValueFormatters valueFormatters: ValueFormatterRegistry,
                        fromResourcePool pool: inout [Resource],
                        withFactory factory: ResourceFactory) {
        let key = keyFormatter.format(self)
        resource.relationships[self.name] = self.extractRelationshipData(serializedData["relationships"][key])

        var linkedResource: T? = nil

        if let linkData = serializedData["relationships"][key].dictionary {
            assert(linkData["data"]?["type"].string == Linked.resourceType)

            if let id = linkData["data"]?["id"].string {
                linkedResource = factory.dispense(Linked.self, id: id, pool: &pool)
            } else {
                linkedResource = Linked.init()
            }

            if let resourceURL = linkData["links"]?["related"].URL {
                linkedResource!.url = resourceURL
            }
        }
        
        if let linkedResource = linkedResource {
            if linkedResource.value(forField: self.name) == nil || (linkedResource.value(forField: self.name) as? Resource)?.isLoaded == false {
                linkedResource.setValue(linkedResource, forField: self.name)
            }
        }
    }

}

public struct ToManyRelationship<T: Resource> : Relationship {
    public typealias Linked = T

    public var name: String
    public var serializedName: String
    public var isReadOnly: Bool = false

    init(_ name: String, to linkedType: T.Type) {
        self.name = name
        self.serializedName = name
    }

    public func extract(from serializedData: JSON,
                        intoResource resource: Resource,
                        withKeyFormatter keyFormatter: KeyFormatter,
                        withValueFormatters valueFormatters: ValueFormatterRegistry,
                        fromResourcePool: inout [Resource],
                        withFactory: ResourceFactory) {
        let key = keyFormatter.format(self)
        resource.relationships[self.name] = self.extractRelationshipData(serializedData["relationships"][key])

        var resourceCollection: LinkedResourceCollection<T>? = nil

        if let linkData = serializedData["relationships"][key].dictionary {
            let resourcesURL: URL? = linkData["links"]?["related"].URL
            let linkURL: URL? = linkData["links"]?["self"].URL

            if let linkage = linkData["data"]?.array {
                let mappedLinkage = linkage.map { ResourceIdentifier(type: $0["type"].stringValue, id: $0["id"].stringValue) }
                resourceCollection = LinkedResourceCollection<T>(resourcesURL: resourcesURL, linkURL: linkURL, linkage: mappedLinkage)
            } else {
                resourceCollection = LinkedResourceCollection<T>(resourcesURL: resourcesURL, linkURL: linkURL, linkage: nil)
            }
        }

        if let linkedResourceCollection = resourceCollection {
            if linkedResourceCollection.linkage != nil || resource.value(forField: self.name) == nil {
                resource.setValue(linkedResourceCollection, forField: self.name)
            }
        }
    }

//    public func extractToManyRelationship(_ key: String, from serializedData: JSON) -> LinkedResourceCollection<Linked>? {
//        var resourceCollection: LinkedResourceCollection<T>? = nil
//
//        if let linkData = serializedData["relationships"][key].dictionary {
//            let resourcesURL: URL? = linkData["links"]?["related"].URL
//            let linkURL: URL? = linkData["links"]?["self"].URL
//
//            if let linkage = linkData["data"]?.array {
//                let mappedLinkage = linkage.map { ResourceIdentifier(type: $0["type"].stringValue, id: $0["id"].stringValue) }
//                resourceCollection = LinkedResourceCollection<T>(resourcesURL: resourcesURL, linkURL: linkURL, linkage: mappedLinkage)
//            } else {
//                resourceCollection = LinkedResourceCollection<T>(resourcesURL: resourcesURL, linkURL: linkURL, linkage: nil)
//            }
//        }
//        
//        return resourceCollection
//    }
}

/// A to-one relationship field.
//public class ToOneRelationship: Relationship { }
//public class ToOneRelationship<T: Resource>: Field, ToOneRelationshipProtcol {
//    typealias Linked = T
//    typealias ReturnValue = Linked
//
//    func extractToOneRelationship(_ key: String, from serializedData: JSON, linkedType: T.Type) -> T? {
//        var resource: T? = nil
//
//        if let linkData = serializedData["relationships"][key].dictionary {
//            let type = linkData["data"]?["type"].string ?? linkedType.resourceType
//
//            // XXX: do not remove this
////            if let id = linkData["data"]?["id"].string {
////                do {
////                    resource = try resourceFactory.dispense(type, id: id, pool: &resourcePool)
////                } catch {
////                    resource = try! resourceFactory.dispense(linkedType.resourceType, id: id, pool: &resourcePool)
////                }
////            } else {
////                do {
////                    resource = try resourceFactory.instantiate(type)
////                } catch {
////                    resource = try! resourceFactory.instantiate(linkedType.resourceType)
////                }
////            }
//
//            if let resourceURL = linkData["links"]?["related"].URL {
//                resource!.url = resourceURL
//            }
//        }
//        
//        return resource
//    }
//}

/// A to-many relationship field.
//public class ToManyRelationship: Relationship { }
//public class ToManyRelationship<T: Resource>: Field, ToManyRelationshipProtcol {
//    typealias Linked = T
//    typealias ReturnValue = LinkedResourceCollection<Linked>
//
//    func extractToManyRelationship<T>(_ key: String, from serializedData: JSON) -> LinkedResourceCollection<T>? {
//        var resourceCollection: LinkedResourceCollection<T>? = nil
//
//        if let linkData = serializedData["relationships"][key].dictionary {
//            let resourcesURL: URL? = linkData["links"]?["related"].URL
//            let linkURL: URL? = linkData["links"]?["self"].URL
//
//            if let linkage = linkData["data"]?.array {
//                let mappedLinkage = linkage.map { ResourceIdentifier(type: $0["type"].stringValue, id: $0["id"].stringValue) }
//                resourceCollection = LinkedResourceCollection<T>(resourcesURL: resourcesURL, linkURL: linkURL, linkage: mappedLinkage)
//            } else {
//                resourceCollection = LinkedResourceCollection<T>(resourcesURL: resourcesURL, linkURL: linkURL, linkage: nil)
//            }
//        }
//        
//        return resourceCollection
//    }
//}
