import SwiftUI

struct AppShellView: View {
    let model: AppShellModel

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            switch model.launchState {
            case .enrollmentRequired:
                EnrollmentRequiredView()
            case .libraryPlaceholder:
                OfflineLibraryPlaceholderView()
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

private struct SidebarView: View {
    var body: some View {
        List {
            Section("Videos") {
                Label("Library", systemImage: "rectangle.stack")
                Label("Downloads", systemImage: "arrow.down.circle")
            }

            Section("App") {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .navigationTitle("All Fab")
        .accessibilityIdentifier("app.sidebar")
    }
}

private struct EnrollmentRequiredView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Enrollment required", systemImage: "ipad.and.iphone")
        } description: {
            Text("Connect to the company service and enter an administrator-approved code before downloading videos.")
        } actions: {
            Text("Enrollment will be enabled in the next verified slice.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Device Enrollment")
        .accessibilityIdentifier("enrollment.required")
    }
}

private struct OfflineLibraryPlaceholderView: View {
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                Text("Offline")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.secondary)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Connection status: Offline")
            .accessibilityIdentifier("library.connection.offline")

            ContentUnavailableView(
                "No downloaded videos",
                systemImage: "play.rectangle",
                description: Text("Downloaded videos will remain available here when the network is unavailable.")
            )
        }
        .padding()
        .navigationTitle("Library")
        .accessibilityIdentifier("library.placeholder")
    }
}

#Preview("Enrollment required") {
    AppShellView(model: AppShellModel(arguments: []))
}

#Preview("Offline library") {
    AppShellView(model: AppShellModel(arguments: ["--ui-test-library"]))
}
