import XCTest

@MainActor
final class AccessibilityAuditTests: XCTestCase {

    private func completeOnboardingIfNeeded(_ app: XCUIApplication) throws {
        let welcome = app.staticTexts["Welcome to SwiftyCitizen"]
        guard welcome.waitForExistence(timeout: 5) else { return }

        app.buttons["Set up your test"].tap()

        let disclaimer = app.switches["I understand this is a study aid, not legal advice"]
        if disclaimer.exists && !disclaimer.isSelected {
            disclaimer.tap()
        }

        // Study language picker: tap the cell, then pick English.
        let languageCell: XCUIElement?
        if app.buttons["Study support"].exists {
            languageCell = app.buttons["Study support"]
        } else if let choose = app.staticTexts.allElementsBoundByAccessibilityElement.first(where: { $0.label == "Choose a language" }) {
            languageCell = choose
        } else {
            languageCell = nil
        }
        if let cell = languageCell, cell.waitForExistence(timeout: 2) {
            cell.tap()
            if app.buttons["English"].waitForExistence(timeout: 3) {
                app.buttons["English"].tap()
            }
        }

        app.buttons["Save"].waitForExistence(timeout: 3)
        app.buttons["Save"].tap()
    }

    private func launchAndEnsureHome() throws -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        try completeOnboardingIfNeeded(app)
        XCTAssertTrue(app.tabBars.buttons["Home"].exists, "Home tab should be present after onboarding")
        return app
    }

    func testHomeTab() throws {
        let app = try launchAndEnsureHome()
        continueAfterFailure = true
        try app.performAccessibilityAudit()
    }

    func testStudyTab() throws {
        let app = try launchAndEnsureHome()
        continueAfterFailure = true
        app.tabBars.buttons["Study"].tap()
        XCTAssertTrue(app.tabBars.buttons["Study"].isSelected, "Study tab should be selected after tap")
        try app.performAccessibilityAudit()
    }

    func testPracticeTab() throws {
        let app = try launchAndEnsureHome()
        continueAfterFailure = true
        app.tabBars.buttons["Practice"].tap()
        XCTAssertTrue(app.tabBars.buttons["Practice"].isSelected, "Practice tab should be selected after tap")
        try app.performAccessibilityAudit()
    }

    func testProgressTab() throws {
        let app = try launchAndEnsureHome()
        continueAfterFailure = true
        app.tabBars.buttons["Progress"].tap()
        XCTAssertTrue(app.tabBars.buttons["Progress"].isSelected, "Progress tab should be selected after tap")
        try app.performAccessibilityAudit()
    }
}
