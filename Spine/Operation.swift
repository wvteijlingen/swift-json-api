//
//  Operation.swift
//  Spine
//
//  Created by Ward van Teijlingen on 05-04-15.
//  Copyright (c) 2015 Ward van Teijlingen. All rights reserved.
//

import Foundation

/**
The Operation class is an abstract class for all Spine operations.
You must not create instances of this class directly, but instead create
an instance of one of its concrete subclasses.

Subclassing
===========
To support generic subclasses, Operation adds an `execute` method.
Override this method to provide the implementation for a concurrent subclass.

Concurrent state
================
Operation is concurrent by default. To update the state of the operation,
update the `state` instance variable. This will fire off the needed KVO notifications.

Operating against a Spine
=========================
The `Spine` instance variable references the Spine against which to operate.
If you add this operation using the Spine `addOperation` method, the variable
will be set for you. Otherwise, you need to set it yourself.
*/
class Operation: NSOperation {
	/// The Spine instance to operate against.
	var spine: Spine!
	
	/// Convenience variables that proxy to their spine counterpart
	var router: RouterProtocol {
		return spine.router
	}
	var HTTPClient: _HTTPClientProtocol {
		return spine._HTTPClient
	}
	var serializer: JSONSerializer {
		return spine.serializer
	}
	
	override init() {}
	
	final override func start() {
		if self.cancelled {
			state = .Finished
		} else {
			state = .Executing
			main()
		}
	}
	
	final override func main() {
		execute()
	}
	
	func execute() {}
	
	
	// MARK: Concurrency

	enum State: String {
		case Ready = "isReady"
		case Executing = "isExecuting"
		case Finished = "isFinished"
	}

	/// The current state of the operation
	var state: State = .Ready {
		willSet {
			willChangeValueForKey(newValue.rawValue)
			willChangeValueForKey(state.rawValue)
		}
		didSet {
			didChangeValueForKey(oldValue.rawValue)
			didChangeValueForKey(state.rawValue)
		}
	}
	override var ready: Bool {
		return super.ready && state == .Ready
	}
	override var executing: Bool {
		return state == .Executing
	}
	override var finished: Bool {
		return state == .Finished
	}
	override var asynchronous: Bool {
		return true
	}
}

/**
A FetchOperation object fetches resources from a Spine, using a given Query.
*/
class FetchOperation<T: ResourceProtocol>: Operation {
	/// The query describing which resources to fetch.
	let query: Query<T>
	
	/// Existing resources onto which to map the fetched resources.
	var mappingTargets = [ResourceProtocol]()
	
	/// The result of the operation. You can safely force unwrap this in the completionBlock.
	var result: Failable<ResourceCollection>?
	
	init(query: Query<T>) {
		self.query = query
		super.init()
	}
	
	override func execute() {
		let URL = spine.router.URLForQuery(query)
		
		Spine.logInfo(.Spine, "Fetching resources using URL: \(URL)")
		
		HTTPClient.request("GET", URL: URL) { statusCode, responseData, networkError in
			
			if let networkError = networkError {
				self.result = .Failure(networkError)
			} else {
				let deserializationResult = self.serializer.deserializeData(responseData!, mappingTargets: self.mappingTargets)
				
				switch deserializationResult {
				case .Success(let documentWrapper) where documentWrapper.value.errors?.count > 0:
					self.result = Failable(documentWrapper.value.errors!.first!)
					
				case .Success(let documentWrapper) where documentWrapper.value.errors == nil:
					self.result = Failable(self.collectionFromDocument(documentWrapper.value))
					
				case .Failure(let error):
					self.result = .Failure(error)
					
				default: ()
				}
			}
			
			self.state = .Finished
		}
	}
	
	private func collectionFromDocument(document: JSONAPIDocument) -> ResourceCollection {
		let resources = document.data ?? []
		let collection = ResourceCollection(resources: resources)
		collection.resourcesURL = document.links?["self"]
		collection.nextURL = document.links?["next"]
		collection.previousURL = document.links?["previous"]
		
		return collection
	}
}

/**
A DeleteOperation deletes a resources from a Spine.
*/
class DeleteOperation: Operation {
	/// The resource to delete.
	let resource: ResourceProtocol
	
	/// The result of the operation. You can safely force unwrap this in the completionBlock.
	var result: Failable<Void>?
	
	init(resource: ResourceProtocol) {
		self.resource = resource
		super.init()
	}
	
	override func execute() {
		let URL = spine.router.URLForQuery(Query(resource: resource))
		
		Spine.logInfo(.Spine, "Deleting resource \(resource) using URL: \(URL)")
		
		HTTPClient.request("DELETE", URL: URL) { statusCode, responseData, networkError in
			if let error = networkError {
				self.result = Failable(error)
			} else {
				self.result = Failable()
			}
			self.state = .Finished
		}
	}
}

/**
A SaveOperation saves a resources in a Spine. It can be used to either update an existing resource,
or to insert new resources.
*/
class SaveOperation: Operation {
	/// The resource to save.
	let resource: ResourceProtocol
	
	/// The result of the operation. You can safely force unwrap this in the completionBlock.
	var result: Failable<Void>?
	
	/// Whether the resource is a new resource, or an existing resource.
	private let isNewResource: Bool
	
	init(resource: ResourceProtocol) {
		self.resource = resource
		self.isNewResource = (resource.id == nil)
		super.init()
	}
	
	override func execute() {
		let request = requestData()
		
		Spine.logInfo(.Spine, "Saving resource \(resource) using URL: \(request.URL)")
		
		HTTPClient.request(request.method, URL: request.URL, payload: request.payload) { statusCode, responseData, networkError in

            if 400 ... 599 ~= statusCode! {
                let error = NSError(domain: "networkError", code: statusCode!, userInfo: nil)
                self.result = Failable(error)
                self.state = .Finished
                return
            }

			// Map the response back onto the resource
			if let data = responseData {
				self.serializer.deserializeData(data, mappingTargets: [self.resource])
			}
			
			// Separately update relationships if this is an existing resource
			if self.isNewResource {
				self.result = Failable()
				self.state = .Finished
				return
			} else {
				let relationshipOperation = RelationshipOperation(resource: self.resource)
				relationshipOperation.spine = self.spine

				relationshipOperation.completionBlock = {
					if let error = relationshipOperation.result?.error {
						self.result = Failable(error)
					}
					
					self.state = .Finished
				}

				relationshipOperation.execute()
			}
		}
	}
	
	private func requestData() -> (URL: NSURL, method: String, payload: NSData) {
		if isNewResource {
			return (
				URL: router.URLForResourceType(resource.type),
				method: "POST",
				payload: serializer.serializeResources([resource], options: SerializationOptions(includeID: false, dirtyFieldsOnly: false, includeToOne: true, includeToMany: true))
			)
		} else {
			return (
				URL: router.URLForQuery(Query(resource: resource)),
				method: "PUT",
				payload: serializer.serializeResources([resource])
			)
		}
	}
}

/**
A SaveOperation updates the relationships of a given resource.
It will add and remove resources to and from many-to-many relationships, and update to-one relationships.
*/
class RelationshipOperation: Operation {
	/// The resource for which to save the relationships.
	let resource: ResourceProtocol
	
	/// The result of the operation. You can safely force unwrap this in the completionBlock.
	var result: Failable<Void>?
	
	init(resource: ResourceProtocol) {
		self.resource = resource
		super.init()
	}
	
	override func execute() {
		// TODO: Where do we call success here?
		
		typealias Operation = (relationship: Relationship, type: String, resources: [ResourceProtocol])
		
		var operations: [Operation] = []
		
		// Create operations
		enumerateFields(resource) { field in
			switch field {
			case let toOne as ToOneRelationship:
				let linkedResource = self.resource.valueForField(toOne.name) as! ResourceProtocol
				if linkedResource.id != nil {
					operations.append((relationship: toOne, type: "replace", resources: [linkedResource]))
				}
			case let toMany as ToManyRelationship:
				let linkedResources = self.resource.valueForField(toMany.name) as! LinkedResourceCollection
				operations.append((relationship: toMany, type: "add", resources: linkedResources.addedResources))
				operations.append((relationship: toMany, type: "remove", resources: linkedResources.removedResources))
			default: ()
			}
		}
		
		// Run the operations
		var stop = false
		for operation in operations {
			if stop {
				break
			}
			
			switch operation.type {
			case "add":
				self.addRelatedResources(operation.resources, relationship: operation.relationship) { error in
					if let error = error {
						self.result = Failable(error)
						stop = true
					}
				}
			case "remove":
				self.removeRelatedResources(operation.resources, relationship: operation.relationship) { error in
					if let error = error {
						self.result = Failable(error)
						stop = true
					}
				}
			case "replace":
				self.setRelatedResource(operation.resources.first!, relationship: operation.relationship) { error in
					if let error = error {
						self.result = Failable(error)
						stop = true
					}
				}
			default: ()
			}
		}
		
		self.state = .Finished
	}
	
	private func addRelatedResources(relatedResources: [ResourceProtocol], relationship: Relationship, callback: (NSError?) -> ()) {
		if isEmpty(relatedResources) {
			callback(nil)
			return
		}
		
		let jsonPayload = serializeLinkageToJSON(convertResourcesToLinkage(relatedResources))
		let URL = self.router.URLForRelationship(relationship, ofResource: self.resource)
		// TODO: Move serialization
		
		self.HTTPClient.request("POST", URL: URL, payload: jsonPayload) { statusCode, responseData, networkError in
			if let networkError = networkError {
				callback(networkError)
			} else {
				callback(nil)
			}
		}
	}
	
	private func removeRelatedResources(relatedResources: [ResourceProtocol], relationship: Relationship, callback: (NSError?) -> ()) {
		if isEmpty(relatedResources) {
			callback(nil)
			return
		}
	
		let jsonPayload = serializeLinkageToJSON(convertResourcesToLinkage(relatedResources))
		let URL = router.URLForRelationship(relationship, ofResource: self.resource)
		// TODO: Move serialization
		
		self.HTTPClient.request("DELETE", URL: URL) { statusCode, responseData, networkError in
			if let networkError = networkError {
				callback(networkError)
			} else {
				callback(nil)
			}
		}
	}
	
	private func setRelatedResource(relatedResource: ResourceProtocol, relationship: Relationship, callback: (NSError?) -> ()) {
		let URL = router.URLForRelationship(relationship, ofResource: self.resource)
		let jsonPayload = serializeLinkageToJSON(convertResourcesToLinkage([relatedResource]))
		
		HTTPClient.request("PATCH", URL: URL, payload: jsonPayload) { statusCode, responseData, networkError in
			if let networkError = networkError {
				callback(networkError)
			} else {
				callback(nil)
			}
		}
	}
	
	private func convertResourcesToLinkage(resources: [ResourceProtocol]) -> [[String: String]] {
		let linkage: [[String: String]] = resources.map { resource in
			assert(resource.id != nil, "Attempt to (un)relate resource without id. Only existing resources can be (un)related.")
			return [resource.type: resource.id!]
		}
		
		return linkage
	}
	
	private func serializeLinkageToJSON(linkage: [[String: String]]) -> NSData? {
		return NSJSONSerialization.dataWithJSONObject(["data": linkage], options: NSJSONWritingOptions(0), error: nil)
	}
}