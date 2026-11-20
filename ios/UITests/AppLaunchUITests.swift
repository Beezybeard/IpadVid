import XCTest

@MainActor
final class AppLaunchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testNormalLaunchExplainsEnrollmentRequirement() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Enrollment required"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Enrollment will be enabled in the next verified slice."].exists)
    }

    func testOfflineLibraryPlaceholderHasNoPlayButton() {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-test-library")
        app.launch()

        XCTAssertTrue(app.staticTexts["No downloaded videos"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["library.connection.offline"].exists)
        XCTAssertFalse(app.buttons["Play"].exists)
    }
}
