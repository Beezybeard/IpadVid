import Foundation
import Observation
import Security

struct DeviceIdentity: Codable, Equatable, Sendable {
    let id: String
    let display_label: String
}

struct EnrollmentCredentials: Codable, Equatable, Sendable {
    let device: DeviceIdentity
    let access_token: String
    let access_expires_at: Date
    let refresh_token: String
    let refresh_expires_at: Date
}

struct EnrollmentPayload: Encodable, Sendable {
    let code: String
    let display_label: String
}

@MainActor
protocol CredentialStoring {
    func save(_ credentials: EnrollmentCredentials) throws
    func load() throws -> EnrollmentCredentials?
    func delete() throws
}

struct KeychainCredentialStore: CredentialStoring {
    private let service = "com.example.allfabvideolibrary.device-credentials"
    private let account = "enrollment-session"

    func save(_ credentials: EnrollmentCredentials) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(credentials)
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let update: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, update as CFDictionary)
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else {
            throw KeychainError(status: updateStatus)
        }
        var query = baseQuery
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else { throw KeychainError(status: addStatus) }
    }

    func load() throws -> EnrollmentCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError(status: status)
        }
        return try Self.decodeCredentials(from: data)
    }

    fileprivate static func decodeCredentials(from data: Data) throws -> EnrollmentCredentials {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: value) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: value) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO-8601 date")
        }
        return try decoder.decode(EnrollmentCredentials.self, from: data)
    }

    func delete() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status: status)
        }
    }
}

private struct KeychainError: Error, Sendable {
    let status: OSStatus
}

@MainActor
protocol EnrollmentServing {
    func enroll(code: String, displayLabel: String) async throws -> EnrollmentCredentials
}

struct DeviceEnrollmentClient: EnrollmentServing {
    let baseURL: URL
    var session: URLSession = .shared

    func enroll(code: String, displayLabel: String) async throws -> EnrollmentCredentials {
        let endpoint = baseURL.appending(path: "/v1/devices/enroll")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            EnrollmentPayload(code: code, display_label: displayLabel)
        )
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw EnrollmentError.invalidResponse }
        guard http.statusCode == 200 else {
            if http.statusCode == 401 { throw EnrollmentError.invalidCode }
            throw EnrollmentError.server(statusCode: http.statusCode)
        }
        do {
            return try KeychainCredentialStore.decodeCredentials(from: data)
        } catch {
            throw EnrollmentError.invalidResponse
        }
    }
}

enum EnrollmentError: Error, Equatable, Sendable {
    case invalidCode
    case invalidResponse
    case server(statusCode: Int)
}

@MainActor
@Observable
final class EnrollmentModel {
    var code = ""
    var displayLabel = ""
    private(set) var isSubmitting = false
    private(set) var message: String?
    private(set) var isEnrolled = false

    private let service: any EnrollmentServing
    private let credentialStore: any CredentialStoring

    init(
        service: any EnrollmentServing,
        credentialStore: any CredentialStoring,
        hasSavedSession: Bool = false
    ) {
        self.service = service
        self.credentialStore = credentialStore
        isEnrolled = hasSavedSession
    }

    func submit() async {
        guard !isSubmitting else { return }
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLabel = displayLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (20...256).contains(trimmedCode.count), !trimmedLabel.isEmpty,
              trimmedLabel.count <= 120 else {
            message = "Enter a valid enrollment code and device name."
            return
        }

        isSubmitting = true
        message = nil
        defer { isSubmitting = false }
        do {
            let credentials = try await service.enroll(
                code: trimmedCode,
                displayLabel: trimmedLabel
            )
            code = ""
            do {
                try credentialStore.save(credentials)
            } catch {
                message = "Enrollment used the code, but this iPad could not save its credentials. Request a new code."
                return
            }
            isEnrolled = true
        } catch EnrollmentError.invalidCode {
            message = "That enrollment code is invalid, expired, or already used."
        } catch {
            message = "Enrollment failed. Check your connection and try again."
        }
    }
}
