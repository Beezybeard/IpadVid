enum AppLaunchState: Equatable, Sendable {
    case enrollmentRequired
    case libraryPlaceholder

    static func resolve(arguments: [String]) -> Self {
        #if DEBUG
        if arguments.contains("--ui-test-library") {
            return .libraryPlaceholder
        }
        #endif
        return .enrollmentRequired
    }
}
