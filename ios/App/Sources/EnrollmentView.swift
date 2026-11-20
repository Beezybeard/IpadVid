import SwiftUI

struct EnrollmentView: View {
    @State private var model: EnrollmentModel

    init(model: EnrollmentModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        Form {
            Section {
                Text("Enter the one-time code provided by your administrator to enroll this iPad.")
                    .foregroundStyle(.secondary)
                TextField("Device name", text: $model.displayLabel)
                    .textContentType(.name)
                    .accessibilityIdentifier("enrollment.device-name")
                SecureField("Enrollment code", text: $model.code)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("enrollment.code")
                Button {
                    Task { await model.submit() }
                } label: {
                    if model.isSubmitting {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Enroll iPad").frame(maxWidth: .infinity)
                    }
                }
                .disabled(model.isSubmitting || model.isEnrolled)
                .accessibilityIdentifier("enrollment.submit")
            }

            if let message = model.message {
                Section {
                    Text(message)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("enrollment.error")
                }
            }

            if model.isEnrolled {
                ContentUnavailableView(
                    "iPad enrolled",
                    systemImage: "checkmark.shield",
                    description: Text("This device can now connect to the video library.")
                )
                .accessibilityIdentifier("enrollment.complete")
            }
        }
        .navigationTitle("Device Enrollment")
    }
}
