import Testing
@testable import AllFabVideoLibrary

@Suite("App launch state")
struct AppLaunchStateTests {
    @Test("A normal launch requires enrollment")
    func normalLaunchRequiresEnrollment() {
        #expect(AppLaunchState.resolve(arguments: []) == .enrollmentRequired)
    }

    @Test("The UI-test argument opens the offline library placeholder")
    func libraryUITestArgumentSelectsLibrary() {
        #expect(
            AppLaunchState.resolve(arguments: ["AllFabVideoLibrary", "--ui-test-library"])
                == .libraryPlaceholder
        )
    }

    @Test("Unrelated launch arguments cannot bypass enrollment")
    func unrelatedArgumentsDoNotBypassEnrollment() {
        #expect(
            AppLaunchState.resolve(arguments: ["AllFabVideoLibrary", "--unknown"])
                == .enrollmentRequired
        )
    }
}
