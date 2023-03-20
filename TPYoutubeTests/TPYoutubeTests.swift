//
//  TPYoutubeTests.swift
//  TPYoutubeTests
//
//  Created by Thang Phung on 17/03/2023.
//

import XCTest

final class TPYoutubeTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        
        let expectation = self.expectation(description: "API TEST")
        let parameters = "{\n    \"context\": {\n        \"client\": {\n            \"clientName\": \"IOS\",\n            \"clientVersion\": \"17.36.4\",\n            \"clientScreen\": \"WATCH\"\n        }\n    },\n    \"videoId\": \"KZ_0nbgqTqk\",\n    \"racyCheckOk\": true,\n    \"contentCheckOk\": true\n}"
        let postData = parameters.data(using: .utf8)
        
        var request = URLRequest(url: URL(string: "https://youtubei.googleapis.com/youtubei/v1/player?key=")!, timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                debugPrint(String(describing: error))
                return
            }
            
            debugPrint(String(data: data, encoding: .utf8)!)
            expectation.fulfill()
        }
        
        task.resume()
        waitForExpectations(timeout: 30, handler: nil)
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
