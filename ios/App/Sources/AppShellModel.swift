import Foundation
import Observation

@MainActor
@Observable
final class AppShellModel {
    private(set) var launchState: AppLaunchState
    let enrollmentModel: EnrollmentModel?

    init(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        enrollmentModel: EnrollmentModel? = nil
    ) {
        launchState = AppLaunchState.resolve(arguments: arguments)
        self.enrollmentModel = enrollmentModel
    }
}
