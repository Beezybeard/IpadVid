import SwiftUI

@main
struct AllFabVideoLibraryApp: App {
    @State private var model: AppShellModel

    init() {
        _model = State(initialValue: AppShellModel())
    }

    var body: some Scene {
        WindowGroup {
            AppShellView(model: model)
        }
    }
}
