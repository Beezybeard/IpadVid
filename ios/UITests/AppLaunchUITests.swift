import XCTest

final class AppLaunchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testNormalLaunchShowsEnrollmentForm() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.textFields["enrollment.device-name"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.secureTextFields["enrollment.code"].exists)
        XCTAssertTrue(app.buttons["enrollment.submit"].exists)
    }

    @MainActor
    func testOfflineLibraryPlaceholderHasNoPlayButton() {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-test-library")
        app.launch()

        XCTAssertTrue(app.staticTexts["No downloaded videos"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["library.connection.offline"].exists)
        XCTAssertFalse(app.buttons["Play"].exists)
    }
}
