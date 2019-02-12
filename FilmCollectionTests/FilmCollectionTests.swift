//
//  FilmCollectionTests.swift
//  FilmCollectionTests
//
//  Created by Heikki Hämälistö on 30/01/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import XCTest
@testable import FilmCollection

class FilmCollectionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testSearch() {
    
        let exp = self.expectation(description: "Search 007 and expect results")
        
        TMDBApi.shared.search(query: "007")
        .done { (results) in
            XCTAssert(results.count > 0, "The number of the search results for the query \"007\" should be greater than zero")
            exp.fulfill()
        }
        .catch { (_) in
            XCTAssert(false, "Searching 007 should return results")
        }
        
        waitForExpectations(timeout: 4.0) { (error) in
            if let _ = error {
                XCTAssert(false, "Timeout while attempting to search \"007\"")
            }
        }
    }
    
    func testLoadingFilm(){
        let exp = self.expectation(description: "Load a film with id 426")
        
        TMDBApi.shared.loadFilm(426, append: ["credits"])
        .done { (results) in
            exp.fulfill()
        }
        .catch { (_) in
            XCTAssertFalse(false, "Loading a film failed")
        }
        
        waitForExpectations(timeout: 10.0) { (error) in
            if let error = error {
                XCTAssert(false, "Timeout while attempting to load a film: \(error.localizedDescription)")
            }
        }
    }
    
    func testLoadingNonExistingFilm(){
        let exp = self.expectation(description: "Load a film with id 0")
        
        TMDBApi.shared.loadFilm(0)
        .done { (results) in
            XCTAssertFalse(false)
        }
        .catch { (_) in
            // Loading the film with an ID "0" should fail
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10.0) { (error) in
            if let _ = error {
                XCTAssertTrue(true, "Timeout is expected because the film ID doesn't exist")
            }
        }
    }
    
}
