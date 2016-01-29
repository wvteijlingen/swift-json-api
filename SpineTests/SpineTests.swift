//
//  SpineTests.swift
//  SpineTests
//
//  Created by Ward van Teijlingen on 30-08-14.
//  Copyright (c) 2014 Ward van Teijlingen. All rights reserved.
//

import UIKit
import XCTest
import SwiftyJSON
import BrightFutures

class SpineTests: XCTestCase {
	var spine: Spine!
	var HTTPClient: CallbackHTTPClient!
	
	override func setUp() {
		super.setUp()
		HTTPClient = CallbackHTTPClient()
		spine = Spine(baseURL: NSURL(string:"http://example.com")!, networkClient: HTTPClient)
		spine.registerResource(Foo)
		spine.registerResource(Bar)
	}
}

// MARK: -

class FindAllTests: SpineTests {
	func testItShouldSucceed() {
		let fixture = JSONFixtureWithName("MultipleFoos")
		
		HTTPClient.handler = { request, payload in
			XCTAssertEqual(request.HTTPMethod!, "GET", "HTTP method not as expected.")
			XCTAssertEqual(request.URL!, NSURL(string:"http://example.com/foos")!, "Request URL not as expected.")
			return (responseData: fixture.data, statusCode: 200, error: nil)
		}
		
		let expectation = expectationWithDescription("testFindByType")
		
		spine.findAll(Foo.self).onSuccess { fooCollection, _, _ in
			expectation.fulfill()
			for (index, resource) in fooCollection.enumerate() {
				XCTAssertEqual(fooCollection.count, 2, "Deserialized resources count not equal.")
				XCTAssert(resource is Foo, "Deserialized resource should be of class 'Foo'.")
				let foo = resource as! Foo
				assertFooResource(foo, isEqualToJSON: fixture.json["data"][index])
			}
			}.onFailure { error in
				expectation.fulfill()
				XCTFail("Find failed with error: \(error).")
		}
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}
	
	func testItShouldFailOnAPIError() {
		let fixture = JSONFixtureWithName("Errors")
		HTTPClient.respondWith(404, data: fixture.data)
		
		let expectation = expectationWithDescription("testFindByTypeWithAPIError")
		let future = spine.findAll(Foo.self)
		assertFutureFailure(future, withErrorDomain: SpineServerErrorDomain, errorCode: 404, expectation: expectation)
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}
	
	func testItShouldFailOnNetworkError() {
		HTTPClient.simulateNetworkErrorWithCode(999)
		
		let expectation = expectationWithDescription("testFindByTypeWithNetworkError")
		let future = spine.findAll(Foo.self)
		assertFutureFailure(future, withErrorDomain: "SimulatedNetworkError", errorCode: 999, expectation: expectation)
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}
}

class FindByIDTests: SpineTests {
	
	func testItShouldSucceed() {
		let fixture = JSONFixtureWithName("MultipleFoos")
		
		HTTPClient.handler = { request, payload in
			XCTAssertEqual(request.HTTPMethod!, "GET", "HTTP method not as expected.")
			XCTAssertEqual(request.URL!, NSURL(string:"http://example.com/foos?filter[id]=1,2")!, "Request URL not as expected.")
			return (responseData: fixture.data, statusCode: 200, error: nil)
		}
		
		let expectation = expectationWithDescription("testFindByIDAndType")
		
		spine.find(["1","2"], ofType: Foo.self).onSuccess { fooCollection, _, _ in
			expectation.fulfill()
			for (index, resource) in fooCollection.enumerate() {
				XCTAssertEqual(fooCollection.count, 2, "Expected resource count to be 2.")
				XCTAssert(resource is Foo, "Expected resource to be of class 'Foo'.")
				let foo = resource as! Foo
				assertFooResource(foo, isEqualToJSON: fixture.json["data"][index])
			}
			}.onFailure { error in
				expectation.fulfill()
				XCTFail("Find failed with error: \(error).")
		}
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}
	
	func testItShouldFailOnAPIError() {
		HTTPClient.respondWith(404)
		
		let expectation = expectationWithDescription("testFindByIDAndTypeWithAPIError")
		let future = spine.find(["1","2"], ofType: Foo.self)
		assertFutureFailure(future, withErrorDomain: SpineServerErrorDomain, errorCode: 404, expectation: expectation)
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}
	
	func testItShouldFailOnNetworkError() {
		HTTPClient.simulateNetworkErrorWithCode(999)
		
		let expectation = expectationWithDescription("testFindByIDAndTypeWithNetworkError")
		let future = spine.find(["1","2"], ofType: Foo.self)
		assertFutureFailure(future, withErrorDomain: "SimulatedNetworkError", errorCode: 999, expectation: expectation)
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}
}

class FindOneByIDTests: SpineTests {
	func testItShouldSucceed() {
		let fixture = JSONFixtureWithName("SingleFoo")
		
		HTTPClient.handler = { request, payload in
			XCTAssertEqual(request.HTTPMethod!, "GET", "HTTP method not as expected.")
			XCTAssertEqual(request.URL!, NSURL(string:"http://example.com/foos/1")!, "Request URL not as expected.")
			return (responseData: fixture.data, statusCode: 200, error: nil)
		}
		
		let expectation = expectationWithDescription("testFindOneByIDAndType")
		
		spine.findOne("1", ofType: Foo.self).onSuccess { foo, _, _ in
			expectation.fulfill()
			assertFooResource(foo, isEqualToJSON: fixture.json["data"])
			}.onFailure { error in
				expectation.fulfill()
				XCTFail("Find failed with error: \(error).")
		}
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}
	
	func testItShouldFailOnAPIError() {
		HTTPClient.respondWith(404)
		
		let expectation = expectationWithDescription("testFindOneByTypeWithAPIError")
		let future = spine.findOne("1", ofType: Foo.self)
		assertFutureFailure(future, withErrorDomain: SpineServerErrorDomain, errorCode: 404, expectation: expectation)
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}
	
	func testItShouldFailOnNetworkError() {
		HTTPClient.simulateNetworkErrorWithCode(999)
		
		let expectation = expectationWithDescription("testFindOneByTypeWithNetworkError")
		let future = spine.findOne("1", ofType: Foo.self)
		assertFutureFailure(future, withErrorDomain: "SimulatedNetworkError", errorCode: 999, expectation: expectation)
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}
}

class FindByQueryTests: SpineTests {
	func testItShouldSucceed() {
		let fixture = JSONFixtureWithName("MultipleFoos")
		
		HTTPClient.handler = { request, payload in
			XCTAssertEqual(request.HTTPMethod!, "GET", "HTTP method not as expected.")
			XCTAssertEqual(request.URL!, NSURL(string:"http://example.com/foos?filter[id]=1,2")!, "Request URL not as expected.")
			return (responseData: fixture.data, statusCode: 200, error: nil)
		}
		
		let query = Query(resourceType: Foo.self, resourceIDs: ["1", "2"])
		let expectation = expectationWithDescription("testFindByQuery")
		
		spine.find(query).onSuccess { fooCollection, _, _ in
			expectation.fulfill()
			for (index, resource) in fooCollection.enumerate() {
				XCTAssertEqual(fooCollection.count, 2, "Deserialized resources count not equal.")
				XCTAssert(resource is Foo, "Deserialized resource should be of class 'Foo'.")
				let foo = resource as! Foo
				assertFooResource(foo, isEqualToJSON: fixture.json["data"][index])
			}
			}.onFailure { error in
				expectation.fulfill()
				XCTFail("Find failed with error: \(error).")
		}
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}
	
	func testItShouldFailOnAPIError() {
		HTTPClient.respondWith(404)
		
		let expectation = expectationWithDescription("testFindByQueryWithAPIError")
		
		let query = Query(resourceType: Foo.self, resourceIDs: ["1"])
		let future = spine.find(query)
		assertFutureFailure(future, withErrorDomain: SpineServerErrorDomain, errorCode: 404, expectation: expectation)
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}
	
	func testItShouldFailOnNetworkError() {
		HTTPClient.simulateNetworkErrorWithCode(999)
		
		let expectation = expectationWithDescription("testFindByQueryWithNetworkError")
		
		let query = Query(resourceType: Foo.self, resourceIDs: ["1"])
		let future = spine.find(query)
		assertFutureFailure(future, withErrorDomain: "SimulatedNetworkError", errorCode: 999, expectation: expectation)
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}
}

class FindOneByQueryTests: SpineTests {
	func testItShouldSucceed() {
		let fixture = JSONFixtureWithName("SingleFoo")
		
		HTTPClient.handler = { request, payload in
			XCTAssertEqual(request.HTTPMethod!, "GET", "HTTP method not as expected.")
			XCTAssertEqual(request.URL!, NSURL(string:"http://example.com/foos/1")!, "Request URL not as expected.")
			return (responseData: fixture.data, statusCode: 200, error: nil)
		}
		
		let query = Query(resourceType: Foo.self, resourceIDs: ["1"])
		let expectation = expectationWithDescription("testFindOneByQuery")
		
		spine.findOne(query).onSuccess { foo, _, _ in
			expectation.fulfill()
			assertFooResource(foo, isEqualToJSON: fixture.json["data"])
			}.onFailure { error in
				expectation.fulfill()
				XCTFail("Find failed with error: \(error).")
		}
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}
	
	func testItShouldFailOnAPIError() {
		HTTPClient.respondWith(404)
		
		let expectation = expectationWithDescription("testFindOneByQueryWithAPIError")
		
		let query = Query(resourceType: Foo.self, resourceIDs: ["1"])
		let future = spine.findOne(query)
		assertFutureFailure(future, withErrorDomain: SpineServerErrorDomain, errorCode: 404, expectation: expectation)
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}
	
	func testItShouldFailOnNetworkError() {
		HTTPClient.simulateNetworkErrorWithCode(999)
		
		let expectation = expectationWithDescription("testFindOneByQueryWithNetworkError")
		
		let query = Query(resourceType: Foo.self, resourceIDs: ["1"])
		let future = spine.findOne(query)
		assertFutureFailure(future, withErrorDomain: "SimulatedNetworkError", errorCode: 999, expectation: expectation)
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}

}


class DeleteTests: SpineTests {
	
	func testItShouldSucceed() {
		HTTPClient.handler = { request, payload in
			XCTAssertEqual(request.URL!, NSURL(string:"http://example.com/bars/1")!, "Request URL not as expected.")
			XCTAssertEqual(request.HTTPMethod!, "DELETE", "Expected HTTP method to be 'DELETE'.")
			return (responseData: NSData(), statusCode: 204, error: nil)
		}
		
		let bar = Bar(id: "1")
		let expectation = expectationWithDescription("testDeleteResource")
		
		spine.delete(bar).onSuccess {
			expectation.fulfill()
		}.onFailure { error in
			expectation.fulfill()
			XCTFail("Delete failed with error: \(error).")
		}
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}
	
	func testItShouldFailOnAPIError() {
		HTTPClient.respondWith(404)
		
		let bar = Bar(id: "1")
		let expectation = expectationWithDescription("testDeleteResourceWithAPIError")
		let future = spine.delete(bar)
		assertFutureFailure(future, withErrorDomain: SpineServerErrorDomain, errorCode: 404, expectation: expectation)
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}
	
	func testItShouldFailOnNetworkError() {
		HTTPClient.simulateNetworkErrorWithCode(999)
		
		let bar = Bar(id: "1")
		let expectation = expectationWithDescription("testDeleteResourceWithNetworkError")
		let future = spine.delete(bar)
		assertFutureFailure(future, withErrorDomain: "SimulatedNetworkError", errorCode: 999, expectation: expectation)
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}
	
}


class SaveTests: SpineTests {
	
	var fixture: (data: NSData, json: JSON)!
	var foo: Foo!
	
	override func setUp() {
		super.setUp()

		fixture = JSONFixtureWithName("SingleFoo")

		do {
			let document = try spine.serializer.deserializeData(fixture.data)
			foo = document.data!.first as! Foo
		} catch let error as NSError {
			XCTFail("Deserialisation failed with error: \(error).")
		}
	}
	
	func testItShouldPOSTWhenCreatingANewResource() {
		HTTPClient.handler = { request, payload in
			XCTAssertEqual(request.HTTPMethod!, "POST", "HTTP method not as expected.")
			XCTAssertEqual(request.URL!, NSURL(string:"http://example.com/foos")!, "Request URL not as expected.")
			return (responseData: self.fixture.data, statusCode: 201, error: nil)
		}

		foo = Foo()
		let future = spine.save(foo)
		let expectation = expectationWithDescription("")
		assertFutureSuccess(future, expectation: expectation)
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}

	func testItShouldPATCHWhenUpdatingAResource() {
		var resourcePatched = false
		
		HTTPClient.handler = { request, payload in
			XCTAssertEqual(request.HTTPMethod!, "PATCH", "HTTP method not as expected.")
			if(request.URL! == NSURL(string: "http://example.com/foos/1")!) {
				resourcePatched = true
			}
			return (responseData: self.fixture.data, statusCode: 201, error: nil)
		}

		let future = spine.save(foo)
		let expectation = expectationWithDescription("")
		assertFutureSuccess(future, expectation: expectation)
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
			XCTAssertTrue(resourcePatched)
		}
	}
	
	func testItShouldFailOnAPIError() {
		HTTPClient.respondWith(400)
		
		let expectation = expectationWithDescription("testCreateResourceWithAPIError")
		let future = spine.save(foo)
		assertFutureFailure(future, withErrorDomain: SpineServerErrorDomain, errorCode: 400, expectation: expectation)

		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}
	
	func testItShouldFailOnNetworkError() {
		HTTPClient.simulateNetworkErrorWithCode(999)
		
		let expectation = expectationWithDescription("testDeleteResourceWithNetworkError")
		let future = spine.save(foo)
		assertFutureFailure(future, withErrorDomain: "SimulatedNetworkError", errorCode: 999, expectation: expectation)
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}
}

class SaveRelationshipsTests: SpineTests {

	var fixture: (data: NSData, json: JSON)!
	var foo: Foo!

	override func setUp() {
		super.setUp()

		fixture = JSONFixtureWithName("SingleFooIncludingBars")

		do {
			let document = try spine.serializer.deserializeData(fixture.data)
			foo = document.data!.first as! Foo
		} catch let error as NSError {
			XCTFail("Deserialisation failed with error: \(error).")
		}
	}

	func testItShouldPATCHToOne() {
		var relationshipUpdated = false

		HTTPClient.handler = { request, payload in
			if(request.HTTPMethod! == "PATCH" && request.URL! == NSURL(string: "http://example.com/foos/1/relationships/to-one-attribute")!) {
				let data = JSON(data: payload!)["data"].dictionary!
				if data["type"]!.string == "bars" && data["id"]!.string == "10" {
					relationshipUpdated = true
				}
			}
			return (responseData: self.fixture.data, statusCode: 201, error: nil)
		}

		let future = spine.save(foo)
		let expectation = expectationWithDescription("")
		assertFutureSuccess(future, expectation: expectation)

		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
			XCTAssertTrue(relationshipUpdated)
		}
	}

	func testItShouldDELETEToOne() {
		var relationshipUpdated = false

		HTTPClient.handler = { request, payload in
			if(request.HTTPMethod! == "DELETE" && request.URL! == NSURL(string: "http://example.com/foos/1/relationships/to-one-attribute")!) {
				if payload == nil {
					relationshipUpdated = true
				}
			}
			return (responseData: self.fixture.data, statusCode: 201, error: nil)
		}

		foo.toOneAttribute = nil

		let future = spine.save(foo)
		let expectation = expectationWithDescription("")
		assertFutureSuccess(future, expectation: expectation)

		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
			XCTAssertTrue(relationshipUpdated)
		}
	}

	func testItShouldPOSTToMany() {
		var relationshipUpdated = false

		HTTPClient.handler = { request, payload in
			if(request.HTTPMethod! == "POST" && request.URL! == NSURL(string: "http://example.com/foos/1/relationships/to-many-attribute")!) {
				let data = JSON(data: payload!)["data"].array!
				XCTAssertEqual(data.count, 1, "Expected data count to be 1.")

				if data[0]["type"].string == "bars" && data[0]["id"].string == "13" {
					relationshipUpdated = true
				}
			}
			return (responseData: self.fixture.data, statusCode: 201, error: nil)
		}

		let bar = Bar(id: "13")
		foo.toManyAttribute!.addResource(bar)

		let future = spine.save(foo)
		let expectation = expectationWithDescription("")
		assertFutureSuccess(future, expectation: expectation)

		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
			XCTAssertTrue(relationshipUpdated)
		}
	}

	func testItShouldDELETEToMany() {
		var relationshipUpdated = false

		HTTPClient.handler = { request, payload in
			if(request.HTTPMethod! == "DELETE" && request.URL! == NSURL(string: "http://example.com/foos/1/relationships/to-many-attribute")!) {
				let data = JSON(data: payload!)["data"].array!
				XCTAssertEqual(data.count, 1, "Expected data count to be 1.")

				if data[0]["type"].string == "bars" && data[0]["id"].string == "11" {
					relationshipUpdated = true
				}
			}
			return (responseData: self.fixture.data, statusCode: 201, error: nil)
		}

		let bar = foo.toManyAttribute!.resources.first!
		foo.toManyAttribute!.removeResource(bar)

		let future = spine.save(foo)
		let expectation = expectationWithDescription("")
		assertFutureSuccess(future, expectation: expectation)

		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
			XCTAssertTrue(relationshipUpdated)
		}
	}

	func testItShouldFailOnAPIError() {
		HTTPClient.handler = { request, payload in
			print(request.URL!)
			if(request.HTTPMethod! == "DELETE" && request.URL! == NSURL(string: "http://example.com/foos/1/relationships/to-one-attribute")!) {
				return (responseData: nil, statusCode: 422, error: NSError(domain: "SimulatedAPIError", code: 422, userInfo: nil))
			}
			return (responseData: self.fixture.data, statusCode: 201, error: nil)
		}

		foo.toOneAttribute = nil

		let expectation = expectationWithDescription("SimulatedAPIError")
		let future = spine.save(foo)
		assertFutureFailure(future, withErrorDomain: "SimulatedAPIError", errorCode: 422, expectation: expectation)

		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}

}

class PaginatingTests: SpineTests {
	func testLoadNextPageInCollection() {
		let fixture = JSONFixtureWithName("PagedFoos-2")
		let nextURL = NSURL(string: "http://example.com/foos?page[limit]=2&page[number]=2")!
		
		HTTPClient.handler = { request, payload in
			XCTAssertEqual(request.URL!, nextURL, "Request URL not as expected.")
			return (responseData: fixture.data, statusCode: 200, error: nil)
		}
		
		let collection = ResourceCollection(resources: [Foo(id: "1"), Foo(id: "2")], resourcesURL: NSURL(string: "http://example.com/foos?page[limit]=2")!)
		collection.nextURL = nextURL
		
		let expectation = expectationWithDescription("testLoadNextPageInCollection")
		
		spine.loadNextPageOfCollection(collection).onSuccess { collection in
			expectation.fulfill()
			XCTAssertEqual(collection.count, 4, "Expected count to be 4.")
			XCTAssertEqual(collection.resourcesURL!, nextURL, "Expected resourcesURL to be updated to new page")
			XCTAssertEqual(collection.previousURL!, NSURL(string: "http://example.com/foos?page[limit]=2")!, "Expected previousURL to be updated to previous page")
			XCTAssertNil(collection.nextURL, "Expected nextURL to be nil.")
			
		}.onFailure { error in
			expectation.fulfill()
			XCTFail("Loading failed with error: \(error).")
		}
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}
	
	func testLoadPreviousPageInColleciton() {
		let fixture = JSONFixtureWithName("PagedFoos-1")
		
		HTTPClient.handler = { request, payload in
			XCTAssertEqual(request.URL!, NSURL(string: "http://example.com/foos?page[limit]=2")!, "Request URL not as expected.")
			return (responseData: fixture.data, statusCode: 200, error: nil)
		}
		
		
		let secondPageResources = [Foo(id: "3"), Foo(id: "4")]
		let collection = ResourceCollection(resources: secondPageResources, resourcesURL: NSURL(string: "http://example.com/foos?page[limit]=2")!)
		collection.previousURL = NSURL(string: "http://example.com/foos?page[limit]=2")!
		
		let expectation = expectationWithDescription("testLoadPreviousPageInColleciton")
		
		spine.loadPreviousPageOfCollection(collection).onSuccess { collection in
			expectation.fulfill()
			XCTAssertEqual(collection.count, 4, "Expected count to be 4.")
			
			}.onFailure { error in
				expectation.fulfill()
				XCTFail("Loading failed with error: \(error).")
		}
		
		waitForExpectationsWithTimeout(10) { error in
			XCTAssertNil(error, "\(error)")
		}
	}
}