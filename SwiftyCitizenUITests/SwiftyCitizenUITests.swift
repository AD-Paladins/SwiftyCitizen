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

        // In UI tests it is usually best to stop immediately when a failure occurs. Screenshot
        // capture needs every test to run regardless of individual failures, so do not abort.
        continueAfterFailure = true

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

    // Screenshot capture for the Practice and Progress tabs. continueAfterFailure is set per
    // method so a failure in one does not block the other; each launches its own app instance.
    /// Launches the app and completes onboarding (if present) so the main tab bar is reachable.
    @MainActor
    private func launchAndEnsureHome() throws -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        try AccessibilityAuditTests().completeOnboardingIfNeeded(app)
        XCTAssertTrue(
            app.tabBars.buttons["Home"].exists,
            "Home tab should be present after onboarding"
        )
        return app
    }

    /// Saves a PNG of the current screen to the test process temp dir.
    @MainActor
    private func captureScreenshot(_ app: XCUIApplication, filename: String) throws {
        let screenshot = app.screenshot()
        let data = screenshot.image.pngData() ?? Data()
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(filename)
        try data.write(to: url)
    }

    @MainActor
    func testCapturePracticeScreenshot() throws {
        continueAfterFailure = true
        let app = try launchAndEnsureHome()
        app.tabBars.buttons["Practice"].tap()
        XCTAssertTrue(
            app.tabBars.buttons["Practice"].isSelected,
            "Practice tab should be selected after tap"
        )
        try captureScreenshot(app, filename: "practice_screenshot.png")
    }

    @MainActor
    func testCaptureProgressScreenshot() throws {
        continueAfterFailure = true
        let app = try launchAndEnsureHome()
        app.tabBars.buttons["Progress"].tap()
        XCTAssertTrue(
            app.tabBars.buttons["Progress"].isSelected,
            "Progress tab should be selected after tap"
        )
        try captureScreenshot(app, filename: "progress_screenshot.png")
    }
}
