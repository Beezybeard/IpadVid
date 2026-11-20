import SwiftUI

@main
struct AllFabVideoLibraryApp: App {
    @State private var model: AppShellModel

    init() {
        let configuredURL = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String
            ?? "http://127.0.0.1:8000"
        let baseURL = URL(string: configuredURL) ?? URL(string: "http://127.0.0.1:8000")!
        let credentialStore = KeychainCredentialStore()
        let hasSavedSession = ((try? credentialStore.load()) ?? nil) != nil
        let enrollment = EnrollmentModel(
            service: DeviceEnrollmentClient(baseURL: baseURL),
            credentialStore: credentialStore,
            hasSavedSession: hasSavedSession
        )
        _model = State(initialValue: AppShellModel(enrollmentModel: enrollment))
    }

    var body: some Scene {
        WindowGroup {
            AppShellView(model: model)
        }
    }
}
