import Foundation
import Observation

@MainActor
@Observable
final class AppShellModel {
    private(set) var launchState: AppLaunchState

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        launchState = AppLaunchState.resolve(arguments: arguments)
    }
}
