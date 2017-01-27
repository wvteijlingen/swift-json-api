//
//  FooResource.swift
//  Spine
//
//  Created by Ward van Teijlingen on 19-02-15.
//  Copyright (c) 2015 Ward van Teijlingen. All rights reserved.
//

import Foundation
import XCTest
import SwiftyJSON

class Foo: NSObject, Resource {
    var resourceData = ResourceData()

    public override required init() {

    }

	var stringAttribute: String?
	var integerAttribute: NSNumber?
	var floatAttribute: NSNumber?
	var booleanAttribute: NSNumber?
	var nilAttribute: AnyObject?
	var dateAttribute: Date?
	var toOneAttribute: Bar?
	var toManyAttribute: LinkedResourceCollection<Bar>?
	
	static var resourceType: String {
		return "foos"
	}
	
	static var fields: [Field] {
		return [
            PlainAttribute("stringAttribute"),
            PlainAttribute("integerAttribute"),
            PlainAttribute("floatAttribute"),
            BooleanAttribute("booleanAttribute"),
            PlainAttribute("nilAttribute"),
            DateAttribute("dateAttribute"),
            ToOneRelationship("toOneAttribute", to: Bar.self),
            ToManyRelationship("toManyAttribute", to: Bar.self)
		]
	}
	
	init(id: String) {
		super.init()
		self.id = id
	}

//	required init(coder: NSCoder) {
//		super.init(coder: coder)
//	}
}

class Bar: NSObject, Resource {
    var resourceData = ResourceData()

    public override required init() {

    }

	var barStringAttribute: String?
	var barIntegerAttribute: NSNumber?
	
	static var resourceType: String {
		return "bars"
	}
	
	static var fields: [Field] {
		return [
			PlainAttribute("barStringAttribute"),
			PlainAttribute("barIntegerAttribute"),
		]
	}
	
	init(id: String) {
		super.init()
		self.id = id
	}

//	required init(coder: NSCoder) {
//		super.init(coder: coder)
//	}
}
