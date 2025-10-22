//
//  WNNetworkToolTests.swift
//  WNNetworkTool Tests
//
//  Created by WNNetworkTool
//

import XCTest
@testable import WayneNetwork

final class WNNetworkToolTests: XCTestCase {
    
    // MARK: - HTTPMethod Tests
    
    func testHTTPMethods() {
        XCTAssertEqual(HTTPMethod.get.rawValue, "GET")
        XCTAssertEqual(HTTPMethod.post.rawValue, "POST")
        XCTAssertEqual(HTTPMethod.put.rawValue, "PUT")
        XCTAssertEqual(HTTPMethod.delete.rawValue, "DELETE")
        XCTAssertEqual(HTTPMethod.patch.rawValue, "PATCH")
    }
    
    // MARK: - HTTPHeaders Tests
    
    func testHTTPHeadersInit() {
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        XCTAssertEqual(headers.count, 2)
        XCTAssertEqual(headers["Content-Type"], "application/json")
        XCTAssertEqual(headers["Accept"], "application/json")
    }
    
    func testHTTPHeadersUpdate() {
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "application/json")
        
        XCTAssertEqual(headers["Content-Type"], "application/json")
        
        headers.update(name: "Content-Type", value: "text/plain")
        XCTAssertEqual(headers["Content-Type"], "text/plain")
    }
    
    func testHTTPHeadersRemove() {
        var headers: HTTPHeaders = ["Content-Type": "application/json"]
        headers.remove(name: "Content-Type")
        
        XCTAssertNil(headers["Content-Type"])
    }
    
    func testCommonHeaders() {
        let authHeader = HTTPHeader.authorization(bearerToken: "token123")
        XCTAssertEqual(authHeader.name, "Authorization")
        XCTAssertEqual(authHeader.value, "Bearer token123")
        
        let contentTypeHeader = HTTPHeader.contentType("application/json")
        XCTAssertEqual(contentTypeHeader.name, "Content-Type")
        XCTAssertEqual(contentTypeHeader.value, "application/json")
    }
    
    // MARK: - URL Encoding Tests
    
    func testURLEncodingQueryString() throws {
        let parameters: Parameters = ["foo": "bar", "baz": "qux"]
        let url = try "https://example.com".asURL()
        var request = URLRequest(url: url)
        
        request = try URLEncoding.queryString.encode(request, with: parameters)
        
        XCTAssertNotNil(request.url?.query)
        XCTAssertTrue(request.url?.query?.contains("foo=bar") ?? false)
        XCTAssertTrue(request.url?.query?.contains("baz=qux") ?? false)
    }
    
    func testURLEncodingHTTPBody() throws {
        let parameters: Parameters = ["foo": "bar", "baz": "qux"]
        let url = try "https://example.com".asURL()
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request = try URLEncoding.httpBody.encode(request, with: parameters)
        
        XCTAssertNotNil(request.httpBody)
        let bodyString = String(data: request.httpBody!, encoding: .utf8)
        XCTAssertTrue(bodyString?.contains("foo=bar") ?? false)
        XCTAssertTrue(bodyString?.contains("baz=qux") ?? false)
    }
    
    // MARK: - JSON Encoding Tests
    
    func testJSONEncoding() throws {
        let parameters: Parameters = ["foo": "bar", "count": 42]
        let url = try "https://example.com".asURL()
        var request = URLRequest(url: url)
        
        request = try JSONEncoding.default.encode(request, with: parameters)
        
        XCTAssertNotNil(request.httpBody)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        
        let json = try JSONSerialization.jsonObject(with: request.httpBody!, options: []) as? [String: Any]
        XCTAssertEqual(json?["foo"] as? String, "bar")
        XCTAssertEqual(json?["count"] as? Int, 42)
    }
    
    // MARK: - URLConvertible Tests
    
    func testStringURLConvertible() throws {
        let urlString = "https://example.com"
        let url = try urlString.asURL()
        
        XCTAssertEqual(url.absoluteString, urlString)
    }
    
    func testURLConvertible() throws {
        let originalURL = URL(string: "https://example.com")!
        let convertedURL = try originalURL.asURL()
        
        XCTAssertEqual(originalURL, convertedURL)
    }
    
    func testInvalidURLString() {
        let invalidString = "not a valid url"
        
        XCTAssertThrowsError(try invalidString.asURL())
    }
    
    // MARK: - Response Serialization Tests
    
    func testDataResponseSerializer() throws {
        let serializer = DataResponseSerializer()
        let data = "test data".data(using: .utf8)!
        
        let result = try serializer.serialize(
            request: nil,
            response: nil,
            data: data,
            error: nil
        )
        
        XCTAssertEqual(result, data)
    }
    
    func testStringResponseSerializer() throws {
        let serializer = StringResponseSerializer()
        let testString = "test string"
        let data = testString.data(using: .utf8)!
        
        let result = try serializer.serialize(
            request: nil,
            response: nil,
            data: data,
            error: nil
        )
        
        XCTAssertEqual(result, testString)
    }
    
    func testJSONResponseSerializer() throws {
        let serializer = JSONResponseSerializer()
        let json: [String: Any] = ["foo": "bar", "count": 42]
        let data = try JSONSerialization.data(withJSONObject: json)
        
        let result = try serializer.serialize(
            request: nil,
            response: nil,
            data: data,
            error: nil
        ) as? [String: Any]
        
        XCTAssertEqual(result?["foo"] as? String, "bar")
        XCTAssertEqual(result?["count"] as? Int, 42)
    }
    
    // MARK: - Network Reachability Tests
    
    func testNetworkReachabilityInit() {
        let manager = NetworkReachabilityManager()
        XCTAssertNotNil(manager)
    }
    
    func testNetworkReachabilityWithHost() {
        let manager = NetworkReachabilityManager(host: "www.apple.com")
        XCTAssertNotNil(manager)
        XCTAssertEqual(manager?.host, "www.apple.com")
    }
    
    // MARK: - Performance Tests
    
    func testURLEncodingPerformance() {
        let parameters: Parameters = [
            "key1": "value1",
            "key2": "value2",
            "key3": "value3",
            "key4": "value4",
            "key5": "value5"
        ]
        
        measure {
            for _ in 0..<1000 {
                let url = try! "https://example.com".asURL()
                var request = URLRequest(url: url)
                _ = try! URLEncoding.default.encode(request, with: parameters)
            }
        }
    }
    
    func testJSONEncodingPerformance() {
        let parameters: Parameters = [
            "key1": "value1",
            "key2": "value2",
            "key3": "value3",
            "key4": "value4",
            "key5": "value5"
        ]
        
        measure {
            for _ in 0..<1000 {
                let url = try! "https://example.com".asURL()
                var request = URLRequest(url: url)
                _ = try! JSONEncoding.default.encode(request, with: parameters)
            }
        }
    }
}

// MARK: - Integration Tests

final class WNNetworkToolIntegrationTests: XCTestCase {
    
    func testSimpleGETRequest() {
        let expectation = self.expectation(description: "GET request")
        
        WN.request("https://jsonplaceholder.typicode.com/users/1")
            .responseJSON { response in
                XCTAssertNotNil(response.value)
                XCTAssertNil(response.error)
                expectation.fulfill()
            }
        
        waitForExpectations(timeout: 10)
    }
    
    func testGETRequestWithParameters() {
        let expectation = self.expectation(description: "GET request with parameters")
        
        let parameters: Parameters = ["userId": 1]
        
        WN.request("https://jsonplaceholder.typicode.com/posts",
                  parameters: parameters)
            .responseJSON { response in
                XCTAssertNotNil(response.value)
                XCTAssertNil(response.error)
                expectation.fulfill()
            }
        
        waitForExpectations(timeout: 10)
    }
    
    func testPOSTRequest() {
        let expectation = self.expectation(description: "POST request")
        
        let parameters: Parameters = [
            "title": "foo",
            "body": "bar",
            "userId": 1
        ]
        
        WN.request("https://jsonplaceholder.typicode.com/posts",
                  method: .post,
                  parameters: parameters,
                  encoding: JSONEncoding.default)
            .responseJSON { response in
                XCTAssertNotNil(response.value)
                XCTAssertNil(response.error)
                expectation.fulfill()
            }
        
        waitForExpectations(timeout: 10)
    }
    
    func testDownloadRequest() {
        let expectation = self.expectation(description: "Download request")
        
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_download.json")
        
        WN.download("https://jsonplaceholder.typicode.com/users",
                   to: destination)
            .responseURL { response in
                XCTAssertNotNil(response.value)
                XCTAssertNil(response.error)
                
                // Clean up
                try? FileManager.default.removeItem(at: destination)
                
                expectation.fulfill()
            }
        
        waitForExpectations(timeout: 10)
    }
}

