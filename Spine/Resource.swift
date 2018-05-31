//
//  Resource.swift
//  Spine
//
//  Created by Ward van Teijlingen on 25-08-14.
//  Copyright (c) 2014 Ward van Teijlingen. All rights reserved.
//

import Foundation
import Reflection

public typealias ResourceType = String

/// A ResourceIdentifier uniquely identifies a resource that exists on the server.
public struct ResourceIdentifier<T: Resource> : Equatable {
	/// The resource type.
	var type: ResourceType
	
	/// The resource ID.
	public var id: String

	/// Constructs a new ResourceIdentifier instance with given `type` and `id`.
	init(type: T.Type, id: String) {
		self.type = type.resourceType
		self.id = id
	}

	/// Constructs a new ResourceIdentifier instance from the given dictionary.
	/// The dictionary must contain values for the "type" and "id" keys.
	init(dictionary: NSDictionary) {
		type = dictionary["type"] as! ResourceType
		id = dictionary["id"] as! String
	}

	/// Returns a dictionary with "type" and "id" keys containing the type and id.
	public func toDictionary() -> NSDictionary {
		return ["type": type, "id": id]
	}
}

public func ==<T: Resource>(lhs: ResourceIdentifier<T>, rhs: ResourceIdentifier<T>) -> Bool {
	return lhs.id == rhs.id
}

public protocol RelationshipData {
    var selfURL: URL? { get }
}


/// A RelationshipData struct holds data about a relationship.
public struct TypedRelationshipData<T: Resource> : RelationshipData {
	public var selfURL: URL?
	var relatedURL: URL?
	var data: [ResourceIdentifier<T>]?
	
	init(selfURL: URL?, relatedURL: URL?, data: [ResourceIdentifier<T>]?) {
		self.selfURL = selfURL
		self.relatedURL = relatedURL
		self.data = data
	}
	
	/// Constructs a new ResourceIdentifier instance from the given dictionary.
	/// The dictionary must contain values for the "type" and "id" keys.
	init(dictionary: NSDictionary) {
		selfURL = dictionary["selfURL"] as? URL
		relatedURL = dictionary["relatedURL"] as? URL
        data = (dictionary["data"] as? [[String: String]])?.map { d in
            return ResourceIdentifier(type: T.self, id: d["id"]!) // XXX force unwrap
        }

}
	
	/// Returns a dictionary with "type" and "id" keys containing the type and id.
	func toDictionary() -> NSDictionary {
		var dictionary = [String: Any]()
		if let selfURL = selfURL {
			dictionary["selfURL"] = selfURL as AnyObject?
		}
		if let relatedURL = relatedURL {
			dictionary["relatedURL"] = relatedURL as AnyObject?
		}
		if let data = data {
			dictionary["data"] = data.map { $0.toDictionary() }
		}
		return dictionary as NSDictionary
	}
}

/// A base recource class that provides some defaults for resources.
/// You can create custom resource classes by subclassing from Resource.
public protocol Resource: class, NSObjectProtocol {  // NSCoding,
	/// The resource type in plural form.
    static var resourceType: ResourceType { get }
//	open class var resourceType: ResourceType {
//		fatalError("Override resourceType in a subclass.")
//	}

	/// All fields that must be persisted in the API.
	static var fields: [Field] { get }
	
	/// The ID of this resource.
    var id: String? { get set } // and set?
	
	/// The canonical URL of the resource.
    var url: URL? { get set }
	
	/// Whether the fields of the resource are loaded.
    var isLoaded: Bool { get set }
	
	/// The metadata for this resource.
    var meta: [String: Any]? { get set }
	
	/// Raw relationship data keyed by relationship name.
    var relationships: [String: RelationshipData] { get set }

    // XXX: don't remove
//    var description: String { get }
//    var debugDescription: String { get }


    /// Returns the value for the field named `field`.
    func value(forField field: String) -> Any?

    /// Sets the value for the field named `field` to `value`.
    func setValue(_ value: Any?, forField field: String)

    /// Set the values for all fields to nil and sets `isLoaded` to false.
    func unload()

    /// Returns the field named `name`, or nil if no such field exists.
    static func field(named name: String) -> Field?

    // XXX: Combines id url isLoaded ...
    var resourceData: ResourceData { get set }

    /// XXX: New stuff
    static func includeKeys(_ keys: [String], with formatter: KeyFormatter) -> [String]

    init()
}

extension Resource {
//    static var fields: [Field] {
//        return []
//    }

    public var id: String? {
        get {
            return self.resourceData.id
        }
        set {
            self.resourceData.id = newValue
        }
    }

    var url: URL? {
        get {
            return self.resourceData.url
        }
        set {
            self.resourceData.url = newValue
        }
    }

    var isLoaded: Bool {
        get {
            return self.resourceData.isLoaded
        }
        set {
            self.resourceData.isLoaded = newValue
        }
    }

    var relationships: [String: RelationshipData] {
        get {
            return self.resourceData.relationships
        }
        set {
            self.resourceData.relationships = newValue
        }
    }

    var meta: [String: Any]? {
        get {
            return self.resourceData.meta
        }
        set {
            self.resourceData.meta = newValue
        }
    }

    /// Returns the value for the field named `field`.
    func value(forField field: String) -> Any? {
        do {
            return try get(field, from: self)
        } catch {
            // XXX: throw error
            fatalError("Can't get value for field '\(field)'")
        }
    }

    /// Sets the value for the field named `field` to `value`.
    func setValue(_ value: Any?, forField field: String) {
        unowned var unownedSelf = self
        do {
            if let value = value {
                try set(value, key: field, for: &unownedSelf)
            } else {
                try set(NSNull(), key: field, for: &unownedSelf)
            }
        } catch {
            // XXX: throw error
            fatalError("Can't set value '\(value)' for field '\(field)'")
        }
    }

//	public init() {
//        // XXX: check this for recursion
//        self.init()
//    }

//	public init(coder: NSCoder) {
////		super.init()
////        self.init()
//		self.id = coder.decodeObject(forKey: "id") as? String
//		self.url = coder.decodeObject(forKey: "url") as? URL
//		self.isLoaded = coder.decodeBool(forKey: "isLoaded")
//		self.meta = coder.decodeObject(forKey: "meta") as? [String: AnyObject]
//		
//		if let relationshipsData = coder.decodeObject(forKey: "relationships") as? [String: NSDictionary] {
//			var relationships = [String: RelationshipData]()
//			for (key, value) in relationshipsData {
//				relationships[key] = RelationshipData.init(dictionary: value)
//			}
//		}
//	}
//
//	public func encode(with coder: NSCoder) {
//		coder.encode(id, forKey: "id")
//		coder.encode(url, forKey: "url")
//		coder.encode(isLoaded, forKey: "isLoaded")
//		coder.encode(meta, forKey: "meta")
//		
//		var relationshipsData = [String: NSDictionary]()
//		for (key, value) in relationships {
//			relationshipsData[key] = value.toDictionary()
//		}
//		coder.encode(relationshipsData, forKey: "relationships")
//	}

	/// Set the values for all fields to nil and sets `isLoaded` to false.
	public func unload() {
        for field in Self.fields {
			setValue(nil, forField: field.name)
		}
		
		isLoaded = false
	}
	
	/// Returns the field named `name`, or nil if no such field exists.
	static func field(named name: String) -> Field? {
		return fields.filter { $0.name == name }.first
	}

    static func includeKeys(_ keys: [String], with formatter: KeyFormatter) -> [String] {
        if keys.count == 0 {
            return []
        }

        let k = keys[0]

        if let field = self.field(named: k), let relatedType = field.relatedType {
            let remainingKeys = Array(keys[1..<keys.count])
            return [formatter.format(field)] + relatedType.includeKeys(remainingKeys, with: formatter)
        }
//        for part in include.components(separatedBy: ".") {
//            if let relationship = relatedResourceType.field(named: part) as? Relationship {
//                keys.append(keyFormatter.format(relationship))
//                relatedResourceType = relationship.linkedType
//            }
        return []
    }
}

//extension Resource where Self: NSObject {
//    /// Returns the value for the field named `field`.
//    func value(forField field: String) -> Any? {
//        return value(forKey: field) as AnyObject?
//    }
//
//    /// Sets the value for the field named `field` to `value`.
//    func setValue(_ value: Any?, forField field: String) {
//        setValue(value, forKey: field)
//    }
//}

extension Resource {
//	var description: String {
//		return "\(Self.resourceType)(\(id), \(url))"
//	}
//	
//	var debugDescription: String {
//		return description
//	}
}

// Instance counterparts of class functions
extension Resource {
	final var resourceType: ResourceType { return type(of: self).resourceType }
	final var fields: [Field] { return type(of: self).fields }
}

public func == <T: Resource> (left: T, right: T) -> Bool {
    return (left.id == right.id) && (left.resourceType == right.resourceType)
}

public struct ResourceData {
    var id: String?
    var url: URL?
    var isLoaded: Bool
    var meta: [String : Any]?
    var relationships: [String : RelationshipData]

    public init() {
        self.isLoaded = false
        self.relationships = [:]
    }
}
