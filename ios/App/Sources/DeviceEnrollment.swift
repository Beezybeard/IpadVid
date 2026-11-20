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

struct RefreshPayload: Encodable, Sendable {
    let refresh_token: String
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
    func refresh(refreshToken: String) async throws -> EnrollmentCredentials
    func currentDevice(accessToken: String) async throws -> DeviceIdentity
}

struct DeviceEnrollmentClient: EnrollmentServing {
    let baseURL: URL
    var session: URLSession = .shared

    func enroll(code: String, displayLabel: String) async throws -> EnrollmentCredentials {
        let payload = EnrollmentPayload(code: code, display_label: displayLabel)
        let body = try JSONEncoder().encode(payload)
        do {
            let data = try await send(path: "/v1/devices/enroll", method: "POST", body: body)
            return try decodeCredentials(data)
        } catch EnrollmentError.unauthorized {
            throw EnrollmentError.invalidCode
        }
    }

    func refresh(refreshToken: String) async throws -> EnrollmentCredentials {
        let payload = RefreshPayload(refresh_token: refreshToken)
        let body = try JSONEncoder().encode(payload)
        let data = try await send(path: "/v1/devices/token/refresh", method: "POST", body: body)
        return try decodeCredentials(data)
    }

    func currentDevice(accessToken: String) async throws -> DeviceIdentity {
        let data = try await send(
            path: "/v1/devices/self",
            method: "GET",
            bearerToken: accessToken
        )
        do {
            return try JSONDecoder().decode(DeviceIdentity.self, from: data)
        } catch {
            throw EnrollmentError.invalidResponse
        }
    }

    private func send(
        path: String,
        method: String,
        body: Data? = nil,
        bearerToken: String? = nil
    ) async throws -> Data {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        if let bearerToken {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw EnrollmentError.invalidResponse }
        guard http.statusCode == 200 else {
            if http.statusCode == 401 { throw EnrollmentError.unauthorized }
            throw EnrollmentError.server(statusCode: http.statusCode)
        }
        return data
    }

    private func decodeCredentials(_ data: Data) throws -> EnrollmentCredentials {
        do {
            return try KeychainCredentialStore.decodeCredentials(from: data)
        } catch {
            throw EnrollmentError.invalidResponse
        }
    }
}

enum EnrollmentError: Error, Equatable, Sendable {
    case invalidCode
    case unauthorized
    case invalidResponse
    case server(statusCode: Int)
}

@MainActor
@Observable
final class EnrollmentModel {
    var code = ""
    var displayLabel = ""
    private(set) var isSubmitting = false
    private(set) var isRestoring = false
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

    func restoreSession(now: Date = .now) async {
        guard !isRestoring else { return }
        guard let saved = try? credentialStore.load() else {
            isEnrolled = false
            return
        }
        isEnrolled = true
        message = nil
        isRestoring = true
        defer { isRestoring = false }

        do {
            let active: EnrollmentCredentials
            if saved.access_expires_at > now {
                active = saved
            } else {
                active = try await service.refresh(refreshToken: saved.refresh_token)
                // Refresh tokens rotate at the server; persist the replacement before further requests.
                try credentialStore.save(active)
            }
            let identity = try await service.currentDevice(accessToken: active.access_token)
            guard identity.id == active.device.id else {
                throw EnrollmentError.unauthorized
            }
        } catch EnrollmentError.unauthorized {
            try? credentialStore.delete()
            isEnrolled = false
            message = "This iPad’s session expired or was revoked. Enroll again with a new code."
        } catch {
            // Keep the saved session available offline; retry server validation when connected.
            isEnrolled = true
        }
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
