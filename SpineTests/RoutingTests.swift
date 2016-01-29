//
//  RoutingTests.swift
//  Spine
//
//  Created by Ward van Teijlingen on 19-02-15.
//  Copyright (c) 2015 Ward van Teijlingen. All rights reserved.
//

import UIKit
import XCTest

class RoutingTests: XCTestCase {
	let spine = Spine(baseURL: NSURL(string:"http://example.com")!)

	func testURLForResourceType() {
		let URL = spine.router.URLForResourceType("foos")
		let expectedURL = NSURL(string: "http://example.com/foos")!
		XCTAssertEqual(URL, expectedURL, "URL not as expected.")
	}

	func testURLForQuery() {
		var query = Query(resourceType: Foo.self, resourceIDs: ["1", "2"])
		query.include("toOneAttribute", "toManyAttribute")
		query.whereAttribute("stringAttribute", equalTo: "stringValue")
		query.restrictFieldsTo("stringAttribute", "integerAttribute")
		query.addAscendingOrder("integerAttribute")
		query.addDescendingOrder("floatAttribute")
		
		let URL = spine.router.URLForQuery(query)
		let expectedURL = NSURL(string: "http://example.com/foos?filter[id]=1,2&include=to-one-attribute,to-many-attribute&filter[string-attribute]=stringValue&fields[foos]=string-attribute,integer-attribute&sort=+integer-attribute,-float-attribute")!
		
		XCTAssertEqual(URL, expectedURL, "URL not as expected.")
	}
	
	func testPagePagination() {
		var query = Query(resourceType: Foo.self)
		query.paginate(PageBasedPagination(pageNumber: 1, pageSize: 5))
		
		let URL = spine.router.URLForQuery(query)
		let expectedURL = NSURL(string: "http://example.com/foos?page[number]=1&page[size]=5")!
		
		XCTAssertEqual(URL, expectedURL, "URL not as expected.")
	}
	
	func testOffsetPagination() {
		var query = Query(resourceType: Foo.self)
		query.paginate(OffsetBasedPagination(offset: 20, limit: 5))
		
		let URL = spine.router.URLForQuery(query)
		let expectedURL = NSURL(string: "http://example.com/foos?page[offset]=20&page[limit]=5")!
		
		XCTAssertEqual(URL, expectedURL, "URL not as expected.")
	}
}