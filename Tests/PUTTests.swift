import Foundation
import XCTest

class PUTTests: XCTestCase {
    let baseURL = "http://httpbin.org"

    func testSynchronousPUT() {
        var synchronous = false
        let networking = Networking(baseURL: baseURL)
        networking.put("/put", parameters: nil) { _, _ in
            synchronous = true
        }

        XCTAssertTrue(synchronous)
    }

    func testPUT() {
        let networking = Networking(baseURL: baseURL)
        networking.put("/put", parameters: ["username": "jameson", "password": "secret"]) { json, error in
            guard let json = json as? [String: Any] else { XCTFail(); return }
            let JSONResponse = json["json"] as? [String: String]
            XCTAssertEqual("jameson", JSONResponse?["username"])
            XCTAssertEqual("secret", JSONResponse?["password"])
            XCTAssertNil(error)

            guard let headers = json["headers"] as? [String: String] else { XCTFail(); return }
            XCTAssertEqual(headers["Content-Type"], "application/json")
        }
    }

    func testPUTWithHeaders() {
        let networking = Networking(baseURL: baseURL)
        networking.put("/put") { json, headers, _ in
            guard let json = json as? [String: Any] else { XCTFail(); return }
            guard let url = json["url"] as? String else { XCTFail(); return }
            XCTAssertEqual(url, "http://httpbin.org/put")

            guard let connection = headers["Connection"] as? String else { XCTFail(); return }
            XCTAssertEqual(connection, "keep-alive")
            XCTAssertEqual(headers["Content-Type"] as? String, "application/json")
        }
    }

    func testPUTWithIvalidPath() {
        let networking = Networking(baseURL: baseURL)
        networking.put("/posdddddt", parameters: ["username": "jameson", "password": "secret"]) { json, error in
            XCTAssertEqual(error?.code, 404)
            XCTAssertNil(json)
        }
    }

    func testFakePUT() {
        let networking = Networking(baseURL: baseURL)

        networking.fakePUT("/story", response: [["name": "Elvis"]])

        networking.put("/story", parameters: ["username": "jameson", "password": "secret"]) { json, _ in
            let json = json as? [[String: String]]
            let value = json?[0]["name"]
            XCTAssertEqual(value, "Elvis")
        }
    }

    func testFakePUTWithInvalidStatusCode() {
        let networking = Networking(baseURL: baseURL)

        networking.fakePUT("/story", response: nil, statusCode: 401)

        networking.put("/story", parameters: nil) { _, error in
            XCTAssertEqual(error?.code, 401)
        }
    }

    func testFakePUTUsingFile() {
        let networking = Networking(baseURL: baseURL)

        networking.fakePUT("/entries", fileName: "entries.json", bundle: Bundle(for: PUTTests.self))

        networking.put("/entries", parameters: nil) { json, _ in
            guard let json = json as? [[String: Any]] else { XCTFail(); return }
            let entry = json[0]
            let value = entry["title"] as? String
            XCTAssertEqual(value, "Entry 1")
        }
    }

    func testCancelPUTWithPath() {
        let expectation = self.expectation(description: "testCancelPUT")

        let networking = Networking(baseURL: baseURL)
        networking.isSynchronous = true
        var completed = false
        networking.put("/put", parameters: ["username": "jameson", "password": "secret"]) { _, error in
            XCTAssertTrue(completed)
            XCTAssertEqual(error?.code, URLError.cancelled.rawValue)
            expectation.fulfill()
        }

        networking.cancelPUT("/put")
        completed = true

        waitForExpectations(timeout: 150.0, handler: nil)
    }

    func testCancelPUTWithID() {
        let expectation = self.expectation(description: "testCancelPUT")

        let networking = Networking(baseURL: baseURL)
        networking.isSynchronous = true
        let requestID = networking.put("/put", parameters: ["username": "jameson", "password": "secret"]) { _, error in
            XCTAssertEqual(error?.code, URLError.cancelled.rawValue)
            expectation.fulfill()
        }

        networking.cancel(with: requestID)

        waitForExpectations(timeout: 150.0, handler: nil)
    }
}
