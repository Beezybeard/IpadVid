import Foundation
import Testing
@testable import AllFabVideoLibrary

@MainActor
private struct EnrollmentServiceStub: EnrollmentServing {
    var result: Result<EnrollmentCredentials, EnrollmentError>

    init(result: Result<EnrollmentCredentials, EnrollmentError>) {
        self.result = result
    }

    func enroll(code: String, displayLabel: String) async throws -> EnrollmentCredentials {
        try result.get()
    }
}

@MainActor
private final class CredentialStoreStub: CredentialStoring {
    private(set) var saved: EnrollmentCredentials?
    var shouldFailSave = false

    func save(_ credentials: EnrollmentCredentials) throws {
        if shouldFailSave { throw EnrollmentError.server(statusCode: 500) }
        saved = credentials
    }

    func load() throws -> EnrollmentCredentials? { saved }
    func delete() throws { saved = nil }
}

@Suite("Device enrollment")
@MainActor
struct DeviceEnrollmentTests {
    private let credentials = EnrollmentCredentials(
        device: DeviceIdentity(id: "server-device-id", display_label: "Bay 1 iPad"),
        access_token: "access-token-example-value",
        access_expires_at: Date(timeIntervalSince1970: 1_900_000_000),
        refresh_token: "refresh-token-example-value",
        refresh_expires_at: Date(timeIntervalSince1970: 1_900_000_100)
    )

    @Test("Successful enrollment saves credentials and clears the code field")
    func successfulEnrollmentPersistsCredentials() async throws {
        let store = CredentialStoreStub()
        let model = EnrollmentModel(
            service: EnrollmentServiceStub(result: .success(credentials)),
            credentialStore: store
        )
        model.code = "  a-valid-enrollment-code-123  "
        model.displayLabel = "  Bay 1 iPad  "

        await model.submit()

        #expect(model.isEnrolled)
        #expect(model.code.isEmpty)
        #expect(model.message == nil)
        #expect(try store.load() == credentials)
    }

    @Test("Invalid code does not save credentials or mark device enrolled")
    func invalidEnrollmentDoesNotPersist() async throws {
        let store = CredentialStoreStub()
        let model = EnrollmentModel(
            service: EnrollmentServiceStub(result: .failure(.invalidCode)),
            credentialStore: store
        )
        model.code = "a-valid-enrollment-code-123"
        model.displayLabel = "Bay 2 iPad"

        await model.submit()

        #expect(!model.isEnrolled)
        #expect(model.message?.contains("invalid") == true)
        #expect(try store.load() == nil)
    }

    @Test("Failed Keychain persistence does not claim successful enrollment")
    func persistenceFailureDoesNotMarkEnrolled() async {
        let store = CredentialStoreStub()
        store.shouldFailSave = true
        let model = EnrollmentModel(
            service: EnrollmentServiceStub(result: .success(credentials)),
            credentialStore: store
        )
        model.code = "a-valid-enrollment-code-123"
        model.displayLabel = "Bay 3 iPad"

        await model.submit()

        #expect(!model.isEnrolled)
        #expect(model.message?.contains("Request a new code") == true)
        #expect(store.saved == nil)
    }

    @Test("Invalid local input is rejected before making a request")
    func invalidInputIsRejected() async {
        let store = CredentialStoreStub()
        let model = EnrollmentModel(
            service: EnrollmentServiceStub(result: .success(credentials)),
            credentialStore: store
        )
        model.code = "short"
        model.displayLabel = " "

        await model.submit()

        #expect(!model.isEnrolled)
        #expect(model.message != nil)
        #expect(store.saved == nil)
    }
}
