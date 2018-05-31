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

    func serialize(from resource: Resource,
                   into serializedData: inout [String: Any],
                   withKeyFormatter keyFormatter: KeyFormatter,
                   withValueFormatters valueFormatters: ValueFormatterRegistry,
                   withOptions options: SerializationOptions)

    func extract(from serializedData: JSON,
                 intoResource resource: Resource,
                 withKeyFormatter keyFormatter: KeyFormatter,
                 withValueFormatters valueFormatters: ValueFormatterRegistry,
                 fromResourcePool pool: inout [Resource],
                 withFactory factory: ResourceFactory)
    func resolve(for resource: Resource, withResourcePool pool: [Resource])
    func updateOperations<T: Resource>(for resource: T, wihtSpine spine: Spine) -> [RelationshipOperation]
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

    public func resolve(for resource: Resource, withResourcePool pool: [Resource]) {}
}

protocol Attribute: Field {

}

extension Attribute {
    public var relatedType: Resource.Type? {
        return nil
    }

    public func serialize(from resource: Resource,
                          into serializedData: inout [String: Any],
                          withKeyFormatter keyFormatter: KeyFormatter,
                          withValueFormatters valueFormatters: ValueFormatterRegistry,
                          withOptions options: SerializationOptions) {
        let key = keyFormatter.format(self)

        Spine.logDebug(.serializing, "Serializing attribute \(self) as '\(key)'")

        var value: Any? = nil
        if let unformattedValue = resource.value(forField: self.name) {
            value = valueFormatters.formatValue(unformattedValue, forAttribute: self)
        } else if(!options.contains(.OmitNullValues)){
            value = NSNull()
        }

        if let value = value {
            if serializedData["attributes"] == nil {
                serializedData["attributes"] = [key: value]
            } else {
                var relationships = serializedData["attributes"] as! [String: Any]
                relationships[key] = value
                serializedData["attributes"] = relationships
            }
        }
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

    public func updateOperations<T: Resource>(for resource: T, wihtSpine spine: Spine) -> [RelationshipOperation] {
        return []
    }
}


public struct PlainAttribute : Attribute {
    public var name: String
    public var serializedName: String
    public var isReadOnly: Bool = false

    public init(_ name: String) {
        self.name = name
        self.serializedName = name
    }
}

public struct BooleanAttribute : Attribute {
    public var name: String
    public var serializedName: String
    public var isReadOnly: Bool = false

    public init(_ name: String) {
        self.name = name
        self.serializedName = name
    }
}

public struct URLAttribute : Attribute {
    public var name: String
    public var serializedName: String
    public var isReadOnly: Bool = false
    public let baseURL: URL?

    public init(_ name: String, for url: URL? = nil) {
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

    public init(_ name: String, format: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ") {
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

    func serializeLinkData(for resource: Resource, with serializer: Serializer) throws -> Data

}

extension Relationship {
    public var relatedType: Resource.Type? {
        return Linked.self
    }


    func extractRelationshipData(_ linkData: JSON) -> RelationshipData {
        let selfURL = linkData["links"]["self"].url
        let relatedURL = linkData["links"]["related"].url
        let data: [ResourceIdentifier<Linked>]?

        if let toOne = linkData["data"].dictionary {
            // XXX: assert ["type"]!.stringValue == Linked.resourceType
            data = [ResourceIdentifier(type: Linked.self, id: toOne["id"]!.stringValue)]
        } else if let toMany = linkData["data"].array {
            data = toMany.map { JSON -> ResourceIdentifier<Linked> in
                // XXX: assert ["type"]!.stringValue == Linked.resourceType
                return ResourceIdentifier(type: Linked.self, id: JSON["id"].stringValue)
            }
        } else {
            data = nil
        }
        
        return TypedRelationshipData(selfURL: selfURL, relatedURL: relatedURL, data: data)
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

    public init(_ name: String, to linkedType: T.Type) {
        self.name = name
        self.serializedName = name
    }

    public func serialize(from resource: Resource,
                          into serializedData: inout [String: Any],
                          withKeyFormatter keyFormatter: KeyFormatter,
                          withValueFormatters valueFormatters: ValueFormatterRegistry,
                          withOptions options: SerializationOptions) {
        let key = keyFormatter.format(self)

        Spine.logDebug(.serializing, "Serializing toOne relationship \(self) as '\(key)'")

        if options.contains(.IncludeToOne) {
            let serializedId: Any
            let linkedResource = resource.value(forField: self.name) as? Linked

            if let resourceId = linkedResource?.id {
                serializedId = resourceId
            } else {
                serializedId = NSNull()
            }

            let serializedRelationship = [
                "data": [
                    "type": Linked.resourceType,
                    "id": serializedId
                ]
            ]

            if serializedData["relationships"] == nil {
                serializedData["relationships"] = [key: serializedRelationship]
            } else {
                var relationships = serializedData["relationships"] as! [String: Any]
                relationships[key] = serializedRelationship
                serializedData["relationships"] = relationships
            }
        }

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
            // XXX: assert(linkData["data"]?["type"].string == Linked.resourceType)

            if let id = linkData["data"]?["id"].string {
                linkedResource = factory.dispense(Linked.self, id: id, pool: &pool)
            } else {
                linkedResource = Linked.init()
            }

            if let resourceURL = linkData["links"]?["related"].url {
                linkedResource!.url = resourceURL
            }
        }
        
        if let linkedResource = linkedResource {
            if resource.value(forField: self.name) == nil || (resource.value(forField: self.name) as? Resource)?.isLoaded == false {
                resource.setValue(linkedResource, forField: self.name)
            }
        }
    }

    public func serializeLinkData(for resource: Resource, with serializer: Serializer) throws -> Data {
        let relatedResource = resource.value(forField: self.name) as? Linked
        return try serializer.serializeLinkData(relatedResource)
    }

    public func updateOperations<T: Resource>(for resource: T, wihtSpine spine: Spine) -> [RelationshipOperation] {
        let operation = RelationshipReplaceOperation(resource: resource, relationship: self, spine: spine)
        return [operation]
    }
}

public struct ToManyRelationship<T: Resource> : Relationship {
    public typealias Linked = T

    public var name: String
    public var serializedName: String
    public var isReadOnly: Bool = false

    public init(_ name: String, to linkedType: T.Type) {
        self.name = name
        self.serializedName = name
    }

    public func serialize(from resource: Resource,
                          into serializedData: inout [String: Any],
                          withKeyFormatter keyFormatter: KeyFormatter,
                          withValueFormatters valueFormatters: ValueFormatterRegistry,
                          withOptions options: SerializationOptions) {
        let key = keyFormatter.format(self)

        Spine.logDebug(.serializing, "Serializing toMany relationship \(self) as '\(key)'")

        if options.contains(.IncludeToMany) {
            let linkedResources = resource.value(forField: self.name) as? ResourceCollection<Linked>
            var resourceIdentifiers: [ResourceIdentifier<T>] = []

            if let resources = linkedResources?.resources {
                resourceIdentifiers = resources.filter { $0.id != nil }.map { resource in
                    return ResourceIdentifier(type: T.self, id: resource.id!)
                }
            }

            let serializedRelationship = [
                "data": resourceIdentifiers.map { $0.toDictionary() }
            ]

            if serializedData["relationships"] == nil {
                serializedData["relationships"] = [key: serializedRelationship]
            } else {
                var relationships = serializedData["relationships"] as! [String: Any]
                relationships[key] = serializedRelationship
                serializedData["relationships"] = relationships
            }
        }
        
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
            let resourcesURL: URL? = linkData["links"]?["related"].url
            let linkURL: URL? = linkData["links"]?["self"].url

            if let linkage = linkData["data"]?.array {
                // XXX: assert  $0["type"].stringValue == T.resourceType
                let mappedLinkage = linkage.map { ResourceIdentifier(type: T.self, id: $0["id"].stringValue) }
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

    public func resolve(for resource: Resource, withResourcePool pool: [Resource]) {
        guard let linkedResourceCollection = resource.value(forField: self.name) as? LinkedResourceCollection<Linked> else {
            Spine.logInfo(.serializing, "Cannot resolve relationship '\(self.name)' of \(resource.resourceType):\(resource.id!) because the JSON did not include the relationship.")
            return
        }

        guard let linkage = linkedResourceCollection.linkage else {
            Spine.logInfo(.serializing, "Cannot resolve relationship '\(self.name)' of \(resource.resourceType):\(resource.id!) because the JSON did not include linkage.")
            return
        }

        let targetResources = linkage.flatMap { (link: ResourceIdentifier) in
            return pool.filter { $0.resourceType == link.type && $0.id == link.id } as! [Linked]
        }

        if !targetResources.isEmpty {
            linkedResourceCollection.resources = targetResources
            linkedResourceCollection.isLoaded = true
        }
    }

    public func serializeLinkData(for resource: Resource, with serializer: Serializer) throws -> Data {
        let relatedResources = (resource.value(forField: self.name) as? ResourceCollection<Linked>)?.resources ?? []
        return try serializer.serializeLinkData(relatedResources)
    }

    public func updateOperations<T: Resource>(for resource: T, wihtSpine spine: Spine) -> [RelationshipOperation] {
        let addOperation = RelationshipMutateOperation(resource: resource, relationship: self, mutation: .add, spine: spine)
        let removeOperation = RelationshipMutateOperation(resource: resource, relationship: self, mutation: .remove, spine: spine)
        return [addOperation, removeOperation]
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


