//
//  Resource.swift
//  Spine
//
//  Created by Ward van Teijlingen on 25-08-14.
//  Copyright (c) 2014 Ward van Teijlingen. All rights reserved.
//

import Foundation
import BrightFutures

/**
*  Describes a resource attribute that can be persisted to the server.
*/
public struct ResourceAttribute {

	/**
	The type of attribute.

	- Property: A plain property.
	- Date:     A formatted date property.
	- ToOne:    A to-one relationship.
	- ToMany:   A to-many relationship.
	*/
	public enum AttributeType {
		case Property, Date, ToOne, ToMany
	}

	/// The type of attribute.
	var type: AttributeType

	/// The name of the attribute in the JSON representation.
	/// This can be empty, in which case the same name as the attribute is used.
	var representationName: String?

	public init(type: AttributeType) {
		self.type = type
	}

	public init(type: AttributeType, representationName: String) {
		self.type = type
		self.representationName = representationName
	}

	func isRelationship() -> Bool {
		return (self.type == .ToOne || self.type == .ToMany)
	}
}


/**
*  Represents a link to one or multiple other resources
*/
struct ResourceLink {

	/// The URL of the link
	var href: String?

	/// The IDs of the linked resources
	var IDs: [String]?

	/// The type of the linked resources
	var type: String?

	/// The IDs of the linked resources, as as string joined by commas
	var joinedIDs: String {
		if let IDs = self.IDs {
			return ",".join(IDs)
			}
			return ""
	}

	init() {

	}

	init(href: String?, IDs: [String]? = nil, type: String? = nil) {
		self.href = href
		self.IDs = IDs
		self.type = type
	}

	init(href: String?, ID: String? = nil, type: String? = nil) {
		self.href = href

		if ID != nil {
			self.IDs = [ID!]
		}

		self.type = type
	}
}

var ResourceDirtyCheckingKVOContext = "ResourceDirtyCheckingKVOContext"

/**
*  A base recource class that provides some defaults for resources.
*  You must create custom resource classes by subclassing from Resource.
*/
public class Resource: NSObject, Printable {

	// MARK: Bookkeeping

	/// The unique identifier of this resource. If this is nil, the resource hasn't been saved yet.
	public var resourceID: String?

	/// The location (URL) of this resource.
	internal var resourceLocation: String?

	/// Links to other resources.
	internal var links: [String: ResourceLink] = [:]

	/// Attributes that are dirty
	private var dirtyAttributes: [String] = []

	internal var dirtyObservingActive: Bool = false


	// MARK: Resource type configuration

	/// The type of this resource in plural form. For example: 'posts', 'users'.
	public var resourceType: String { return "_undefined" }

	/// Array of attributes that must be mapped by Spine.
	public var persistentAttributes: [String: ResourceAttribute] { return [:] }



	// MARK: Initializers

	// This is needed for the dynamic instantiation based on the metatype
	required override public init() {
		super.init()
		self.startDirtyObserving()
	}

	public init(resourceID: String) {
		self.resourceID = resourceID
		super.init()
		self.startDirtyObserving()
	}

	deinit {
		self.stopDirtyObserving()
	}


	// MARK: Printable protocol

	override public var description: String {
		return "\(self.resourceType)[\(self.resourceID)]"
	}



	// MARK: Dirty checking

	private func startDirtyObserving() {
		for (attributeName, attribute) in self.persistentAttributes {
			if attribute.isRelationship() {
				continue
			}
			self.addObserver(self, forKeyPath: attributeName, options: nil, context: &ResourceDirtyCheckingKVOContext)
		}

		self.dirtyObservingActive = true
	}

	private func stopDirtyObserving() {
		for (attributeName, attribute) in self.persistentAttributes {
			if attribute.isRelationship() {
				continue
			}

			self.removeObserver(self, forKeyPath: attributeName, context: &ResourceDirtyCheckingKVOContext)
		}
	}

	override public func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: [NSObject : AnyObject]!, context: UnsafeMutablePointer<Void>) {
		if context == &ResourceDirtyCheckingKVOContext {
			if self.dirtyObservingActive && !contains(self.dirtyAttributes, keyPath) {
				self.dirtyAttributes.append(keyPath)
			}
		} else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
		}
	}

	internal func isDirty(attributeName: String) -> Bool {
		return contains(self.dirtyAttributes, attributeName)
	}

	internal func resetDirtyStatus() {
		self.dirtyAttributes = []
	}
}


// MARK: - Convenience functions

extension Resource {

	/**
	Saves this resource asynchronously.

	:returns: A future of this resource.
	*/
	public func save() -> Future<Resource> {
		return Spine.sharedInstance.saveResource(self)
	}

	/**
	Deletes this resource asynchronously.

	:returns: A void future.
	*/
	public func delete() -> Future<Void> {
		return Spine.sharedInstance.deleteResource(self)
	}

	/**
	Finds one resource of this type with a given ID.

	:param: ID The ID of the resource to find.

	:returns: A future of Resource.
	*/
	public class func findOne(ID: String) -> Future<(Resource, Meta?)> {
		let instance = self()
		return Spine.sharedInstance.fetchResourceWithType(instance.resourceType, ID: ID)
	}

	/**
	Finds multiple resources of this type by given IDs.

	:param: IDs The IDs of the resources to find.

	:returns: A future of an array of resources.
	*/
	public class func find(IDs: [String]) -> Future<([Resource], Meta?)> {
		let instance = self()
		let query = Query(resourceType: instance.resourceType, resourceIDs: IDs)
		return Spine.sharedInstance.fetchResourcesForQuery(query)
	}

	/**
	Finds all resources of this type.

	:returns: A future of an array of resources.
	*/
	public class func findAll() -> Future<([Resource], Meta?)> {
		let instance = self()
		let query = Query(resourceType: instance.resourceType)
		return Spine.sharedInstance.fetchResourcesForQuery(query)
	}

	/**
	Finds resources related to this resource by the given relationship.

	:param: relationship Name of the relationship.

	:returns: A future of an array of resources.
	*/
	public func findRelated(relationship: String) -> Future<([Resource], Meta?)> {
		let query = Query(resource: self, relationship: relationship)
		return Spine.sharedInstance.fetchResourcesForQuery(query)
	}
}


//MARK: - Meta

public class Meta: Resource {
	final override public var resourceType: String { return "_meta" }

	final override internal func startDirtyObserving() { }
	final override internal func stopDirtyObserving() { }
}