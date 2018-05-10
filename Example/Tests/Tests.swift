import UIKit
import XCTest
import BrytescoreAPI

class Tests: XCTestCase {

    let _apiManager = BrytescoreAPIManager(apiKey: "fakefakefake")

    override func setUp() {
        super.setUp()
        _apiManager.devMode(enabled: true)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInitialization() {
        XCTAssertNotNil(_apiManager, "Cannot find BrytescoreAPIManager instance");
        XCTAssertEqual(_apiManager.getAPIKey(), "fakefakefake", "API key was not set correctly")
    }
}
