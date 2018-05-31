//
//  Query.swift
//  Spine
//
//  Created by Ward van Teijlingen on 30-08-14.
//  Copyright (c) 2014 Ward van Teijlingen. All rights reserved.
//

import Foundation

/// A Query defines search criteria used to retrieve data from an API.
///
/// Custom query URL
/// ================
/// Usually Query objects are turned into URLs by the Router. The Router decides how the query configurations
/// are translated to URL components. However, queries can also be instantiated with a custom URL.
/// This is used when the API returns hrefs for example. Custom URL components will not be 'parsed'
/// into their respective configuration variables, so the query configuration may not correspond to
/// the actual URL generated by the Router.
public struct Query<T: Resource> {
	/// The type of resource to fetch. This can be nil if in case of an expected heterogenous response.
	var resourceType: ResourceType?

	/// The specific IDs the fetch.
	var resourceIDs: [String]?
	
	/// The optional base URL
	internal var url: URL?
	
	/// Related resources that must be included in a compound document.
	public internal(set) var includes: [String] = []
	
	/// Comparison predicates used to filter resources.
	public internal(set) var filters: [NSComparisonPredicate] = []
	
	/// Serialized names of fields that will be returned, per resource type. If no fields are specified, all fields are returned.
	public internal(set) var fields: [ResourceType: [String]] = [:]
	
	/// Sort descriptors to sort resources.
	public internal(set) var sortDescriptors: [NSSortDescriptor] = []
	
	public internal(set) var pagination: Pagination?
	
	
	//MARK: Init
	
	/// Inits a new query for the given resource type and optional resource IDs.
	///
	/// - parameter resourceType: The type of resource to query.
	/// - parameter resourceIDs:  The IDs of the resources to query. Pass nil to fetch all resources of the given type.
	
	/// - returns: Query
	public init(resourceType: T.Type, resourceIDs: [String]? = nil) {
		self.resourceType = T.resourceType
		self.resourceIDs = resourceIDs
	}
	
	/// Inits a new query that fetches the given resource.
	///
	/// - parameter resource: The resource to fetch.
	///
	/// - returns: Query
	public init(resource: T) {
		assert(resource.id != nil, "Cannot instantiate query for resource, id is nil.")
        self.resourceType = resource.resourceType
		self.url = resource.url
		self.resourceIDs = [resource.id!]
	}
	
	/// Inits a new query that fetches resources from the given resource collection.
	///
	/// - parameter resourceType:       The type of resource to query.
	/// - parameter resourceCollection: The resource collection whose resources to fetch.
	///
	/// - returns: Query
	public init(resourceType: T.Type, resourceCollection: ResourceCollection<T>) {
		self.resourceType = T.resourceType
		self.url = resourceCollection.resourcesURL
	}

	/// Inits a new query that fetches resource of type `resourceType`, by using the given URL.
	///
	/// - parameter resourceType: The type of resource to query.
	/// - parameter path:         The URL path used to fetch the resources.
	///
	/// - returns: Query
	public init(resourceType: T.Type, path: String) {
		self.resourceType = T.resourceType
		self.url = URL(string: path)
	}
	
	init(url: URL) {
		self.url = url
	}
	
	
	// MARK: Including
	
	/// Includes the given relationships in the query.
	///
	/// - parameter relationshipNames: The names of the relationships to include.
	public mutating func include(_ relationshipNames: String...) {
		for relationshipName in relationshipNames {
			includes.append(relationshipName)
		}
	}
	
	/// Removes previously included relationships.
	///
	/// - parameter relationshipNames: The names of the included relationships to remove.
	public mutating func removeInclude(_ relationshipNames: String...) {
		includes = includes.filter { !relationshipNames.contains($0) }
	}
	
	
	// MARK: Filtering
	
	/// Adds a predicate to filter on a field.
	///
	/// - parameter fieldName: The name of the field to filter on.
	/// - parameter value:     The value to check for.
	/// - parameter type:      The comparison operator to use
	public mutating func addPredicateWithField(_ fieldName: String, value: Any, type: NSComparisonPredicate.Operator) {
		if let field = T.fields.filter({ $0.name == fieldName }).first {
			addPredicateWithKey(field.name, value: value, type: type)
		} else {
			assertionFailure("Resource of type \(T.resourceType) does not contain a field named \(fieldName)")
		}
	}
	
	/// Adds a predicate to filter on a key. The key does not have to correspond
	/// to a field defined on the resource.
	///
	/// - parameter key:   The key of the field to filter on.
	/// - parameter value: The value to check for.
	/// - parameter type:  The comparison operator to use
	public mutating func addPredicateWithKey(_ key: String, value: Any, type: NSComparisonPredicate.Operator) {
		let predicate = NSComparisonPredicate(
				leftExpression: NSExpression(forKeyPath: key),
				rightExpression: NSExpression(forConstantValue: value),
				modifier: .direct,
				type: type,
				options: [])

		filters.append(predicate)
	}

	/// Adds a filter where the given attribute should be equal to the given value.
	///
	/// - parameter attributeName: The name of the attribute to filter on.
	/// - parameter equalTo:       The value to check for.
	public mutating func whereAttribute(_ attributeName: String, equalTo: Any) {
		addPredicateWithField(attributeName, value: equalTo, type: .equalTo)
	}
	
	/// Adds a filter where the given attribute should not be equal to the given value.
	///
	/// - parameter attributeName: The name of the attribute to filter on.
	/// - parameter notEqualTo:    The value to check for.
	public mutating func whereAttribute(_ attributeName: String, notEqualTo: Any) {
		addPredicateWithField(attributeName, value: notEqualTo, type: .notEqualTo)
	}

	/// Adds a filter where the given attribute should be smaller than the given value.
	///
	/// - parameter attributeName: The name of the attribute to filter on.
	/// - parameter lessThan:      The value to check for.
	public mutating func whereAttribute(_ attributeName: String, lessThan: Any) {
		addPredicateWithField(attributeName, value: lessThan, type: .lessThan)
	}

	/// Adds a filter where the given attribute should be less then or equal to the given value.
	///
	/// - parameter attributeName:     The name of the attribute to filter on.
	/// - parameter lessThanOrEqualTo: The value to check for.
	public mutating func whereAttribute(_ attributeName: String, lessThanOrEqualTo: Any) {
		addPredicateWithField(attributeName, value: lessThanOrEqualTo, type: .lessThanOrEqualTo)
	}
	
	/// Adds a filter where the given attribute should be greater then the given value.
	///
	/// - parameter attributeName: The name of the attribute to filter on.
	/// - parameter greaterThan:   The value to check for.
	public mutating func whereAttribute(_ attributeName: String, greaterThan: Any) {
		addPredicateWithField(attributeName, value: greaterThan, type: .greaterThan)
	}

	/// Adds a filter where the given attribute should be greater than or equal to the given value.
	///
	/// - parameter attributeName:        The name of the attribute to filter on.
	/// - parameter greaterThanOrEqualTo: The value to check for.
	public mutating func whereAttribute(_ attributeName: String, greaterThanOrEqualTo: Any) {
		addPredicateWithField(attributeName, value: greaterThanOrEqualTo, type: .greaterThanOrEqualTo)
	}
	
	/// Adds a filter where the given relationship should point to the given resource, or the given
	/// resource should be present in the related resources.
	///
	/// - parameter relationshipName: The name of the relationship to filter on.
	/// - parameter resource:         The resource that should be related.
    public mutating func whereRelationship<U: Resource>(_ relationshipName: String, isOrContains resource: U) {
		assert(resource.id != nil, "Attempt to add a where filter on a relationship, but the target resource does not have an id.")
		addPredicateWithField(relationshipName, value: resource.id! as AnyObject, type: .equalTo)
	}
	
	
	// MARK: Sparse fieldsets
	
	/// Restricts the fields that should be requested. When not set, all fields will be requested.
	/// Note: the server may still choose to return only of a select set of fields.
	///
	/// - parameter fieldNames: Names of fields to fetch.
	public mutating func restrictFieldsTo(_ fieldNames: String...) {
		assert(resourceType != nil, "Cannot restrict fields for query without resource type, use `restrictFieldsOfResourceType` or set a resource type.")
		
		for fieldName in fieldNames {
			restrictFieldsOfResourceType(T.self, to: fieldName)
		}
	}
	
	/// Restricts the fields of a specific resource type that should be requested.
	/// This method can be used to restrict fields of included resources. When not set, all fields will be requested.
	///
	/// Note: the server may still choose to return only of a select set of fields.
	///
	/// - parameter type:       The resource type for which to restrict the properties.
	/// - parameter fieldNames: Names of fields to fetch.
    public mutating func restrictFieldsOfResourceType<U: Resource>(_ type: U.Type, to fieldNames: String...) {
		for fieldName in fieldNames {
			guard let field = type.field(named: fieldName) else {
				assertionFailure("Cannot restrict to field \(fieldName) of resource \(type.resourceType). No such field has been configured.")
				return
			}
			
			if fields[type.resourceType] != nil {
				fields[type.resourceType]!.append(field.serializedName)
			} else {
				fields[type.resourceType] = [field.serializedName]
			}
		}
	}
	
	
	// MARK: Sorting
	
	/// Sort in ascending order by the the given field. Previously added field take precedence over this field.
	///
	/// - parameter fieldName: The name of the field which to order by.
	public mutating func addAscendingOrder(_ fieldName: String) {
		if let _ = T.field(named: fieldName) {
			sortDescriptors.append(NSSortDescriptor(key: fieldName, ascending: true))
		} else {
			assertionFailure("Cannot add order on field \(fieldName) of resource \(T.resourceType). No such field has been configured.")
		}
	}
	
	/// Sort in descending order by the the given field. Previously added field take precedence over this property.
	///
	/// - parameter property: The name of the field which to order by.
	public mutating func addDescendingOrder(_ fieldName: String) {
		if let _ = T.field(named: fieldName) {
			sortDescriptors.append(NSSortDescriptor(key: fieldName, ascending: false))
		} else {
			assertionFailure("Cannot add order on field \(fieldName) of resource \(T.resourceType). No such field has been configured.")
		}
	}
	
	
	// MARK: Pagination
	
	/// Paginate the result using the given pagination configuration. Pass nil to remove pagination.
	///
	/// - parameter pagination: The pagination configuration to use.
	public mutating func paginate(_ pagination: Pagination?) {
		self.pagination = pagination
	}
}


// MARK: - Pagination

/// The Pagination protocol is an empty protocol to which pagination configurations must adhere.
public protocol Pagination { }

/// Page based pagination is a pagination strategy that returns results based on pages of a fixed size.
public struct PageBasedPagination: Pagination {
	var pageNumber: Int
	var pageSize: Int
	
	/// Instantiates a new PageBasedPagination struct.
	///
	/// - parameter pageNumber: The number of the page to return.
	/// - parameter pageSize:   The size of each page.
	///
	/// - returns: PageBasedPagination
	public init(pageNumber: Int, pageSize: Int) {
		self.pageNumber = pageNumber
		self.pageSize = pageSize
	}
}

/// Offet based pagination is a pagination strategy that returns results based on an offset from the beginning of the result set.
public struct OffsetBasedPagination: Pagination {
	var offset: Int
	var limit: Int
	
	/// Instantiates a new OffsetBasedPagination struct.
	///
	/// - parameter offset: The offset from the beginning of the result set.
	/// - parameter limit:  The number of resources to return.
	///
	/// - returns: OffsetBasedPagination
	public init(offset: Int, limit: Int) {
		self.offset = offset
		self.limit = limit
	}
}
