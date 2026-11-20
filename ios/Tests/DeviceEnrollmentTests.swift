import Foundation
import Testing
@testable import AllFabVideoLibrary

@MainActor
private final class EnrollmentServiceStub: EnrollmentServing {
    var enrollmentResult: Result<EnrollmentCredentials, EnrollmentError>
    var refreshResult: Result<EnrollmentCredentials, EnrollmentError>?
    var currentDeviceResult: Result<DeviceIdentity, EnrollmentError>?
    private(set) var refreshCallCount = 0
    private(set) var currentDeviceCallCount = 0

    init(
        enrollmentResult: Result<EnrollmentCredentials, EnrollmentError>,
        refreshResult: Result<EnrollmentCredentials, EnrollmentError>? = nil,
        currentDeviceResult: Result<DeviceIdentity, EnrollmentError>? = nil
    ) {
        self.enrollmentResult = enrollmentResult
        self.refreshResult = refreshResult
        self.currentDeviceResult = currentDeviceResult
    }

    func enroll(code: String, displayLabel: String) async throws -> EnrollmentCredentials {
        try enrollmentResult.get()
    }

    func refresh(refreshToken: String) async throws -> EnrollmentCredentials {
        refreshCallCount += 1
        guard let refreshResult else { throw EnrollmentError.invalidResponse }
        return try refreshResult.get()
    }

    func currentDevice(accessToken: String) async throws -> DeviceIdentity {
        currentDeviceCallCount += 1
        guard let currentDeviceResult else { throw EnrollmentError.invalidResponse }
        return try currentDeviceResult.get()
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
            service: EnrollmentServiceStub(enrollmentResult: .success(credentials)),
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
            service: EnrollmentServiceStub(enrollmentResult: .failure(.invalidCode)),
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
            service: EnrollmentServiceStub(enrollmentResult: .success(credentials)),
            credentialStore: store
        )
        model.code = "a-valid-enrollment-code-123"
        model.displayLabel = "Bay 3 iPad"

        await model.submit()

        #expect(!model.isEnrolled)
        #expect(model.message?.contains("Request a new code") == true)
        #expect(store.saved == nil)
    }

    @Test("Expired access token is rotated and validated before updating Keychain")
    func expiredSessionRotatesRefreshToken() async throws {
        let old = EnrollmentCredentials(
            device: credentials.device,
            access_token: "old-access-token",
            access_expires_at: Date(timeIntervalSince1970: 1_700_000_000),
            refresh_token: "old-refresh-token",
            refresh_expires_at: Date(timeIntervalSince1970: 1_900_000_100)
        )
        let rotated = EnrollmentCredentials(
            device: credentials.device,
            access_token: "new-access-token",
            access_expires_at: credentials.access_expires_at,
            refresh_token: "new-refresh-token",
            refresh_expires_at: credentials.refresh_expires_at
        )
        let service = EnrollmentServiceStub(
            enrollmentResult: .failure(.invalidResponse),
            refreshResult: .success(rotated),
            currentDeviceResult: .success(credentials.device)
        )
        let store = CredentialStoreStub()
        try store.save(old)
        let model = EnrollmentModel(service: service, credentialStore: store)

        await model.restoreSession(now: Date(timeIntervalSince1970: 1_800_000_000))

        #expect(model.isEnrolled)
        #expect(service.refreshCallCount == 1)
        #expect(service.currentDeviceCallCount == 1)
        #expect(try store.load() == rotated)
    }

    @Test("Unauthorized refresh clears the saved session and requires enrollment")
    func revokedSessionRequiresEnrollment() async throws {
        let service = EnrollmentServiceStub(
            enrollmentResult: .failure(.invalidResponse),
            refreshResult: .failure(.unauthorized)
        )
        let store = CredentialStoreStub()
        try store.save(credentials)
        let model = EnrollmentModel(service: service, credentialStore: store)

        await model.restoreSession(now: Date(timeIntervalSince1970: 1_800_000_000))

        #expect(!model.isEnrolled)
        #expect(try store.load() == nil)
        #expect(model.message?.contains("revoked") == true)
    }

    @Test("Offline validation preserves session for local library access")
    func offlineSessionIsRetained() async throws {
        let service = EnrollmentServiceStub(
            enrollmentResult: .failure(.invalidResponse),
            currentDeviceResult: .failure(.server(statusCode: 503))
        )
        let store = CredentialStoreStub()
        try store.save(credentials)
        let model = EnrollmentModel(service: service, credentialStore: store)

        await model.restoreSession()

        #expect(model.isEnrolled)
        #expect(try store.load() == credentials)
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
