//
//  SwiftyCitizenUITests.swift
//  SwiftyCitizenUITests
//
//  Created by andres paladines on 9/10/26.
//

import XCTest

final class SwiftyCitizenUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        let welcome = app.staticTexts["Welcome to SwiftyCitizen"]
        let configuredHome = app.staticTexts["Your study plan is ready"]
        XCTAssertTrue(welcome.waitForExistence(timeout: 5) || configuredHome.waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launch()

        let welcome = app.staticTexts["Welcome to SwiftyCitizen"]
        let homeTabButton = app.tabBars.buttons["Home"]

        if welcome.waitForExistence(timeout: 5) {
            continueAfterFailure = true
            try app.performAccessibilityAudit()
        } else if homeTabButton.exists {
            homeTabButton.tap()
            continueAfterFailure = true
            try app.performAccessibilityAudit()
        } else {
            XCTFail("Unexpected launch state: neither Welcome nor Home screen is visible.")
        }
    }
}
