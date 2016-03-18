//
//  TAMSTests.swift
//  TAMSTests
//
//  Created by Daniel Jackson on 3/16/16.
//  Copyright © 2016 Daniel Jackson. All rights reserved.
//

import XCTest
@testable import TAMS

class TAMSTests: XCTestCase {
    
    var expectation:XCTestExpectation?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAPI() {
        
        expectation = self.expectationWithDescription("asynchronous request")
        
        BackendAPI.categoryList { (types) -> Void in
            print("returned [\(types.count)]: \(types)")
            self.expectation?.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(10.0, handler:nil)
    }

//    func testAssetCreate() {
//        
//        expectation = self.expectationWithDescription("asynchronous request - create")
//        
//        let newAsset = Asset(id: -1, name: "Chair", description: "A chair from the RVR building. No one will notice...", type: "Chair", category: "School", imageUrl: "", voiceUrl: "", latitude: 10.56749287634, longitude: -120.8798728976)
//        
//        BackendAPI.create(newAsset) { (success) -> Void in
//            print("returned [success=\(success)]")
//            self.expectation?.fulfill()
//        }
//        
//        self.waitForExpectationsWithTimeout(10.0, handler:nil)
//    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
