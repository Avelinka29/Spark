import Foundation
import Observation

@MainActor
@Observable
final class AuthStore {
    private(set) var accessToken: String?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var developmentCode: String?

    private let keychain: KeychainStore
    private let biometrics: BiometricAuthService
    private let googleAuth: GoogleAuthService
    private let defaults: UserDefaults

    private static let biometricEnabledKey = "spark.biometricUnlockEnabled"

    init(
        keychain: KeychainStore = KeychainStore(),
        biometrics: BiometricAuthService = BiometricAuthService(),
        googleAuth: GoogleAuthService = GoogleAuthService(),
        defaults: UserDefaults = .standard
    ) {
        self.keychain = keychain
        self.biometrics = biometrics
        self.googleAuth = googleAuth
        self.defaults = defaults
        accessToken = keychain.readToken()
    }

    var isAuthenticated: Bool {
        accessToken != nil
    }

    var isBiometricEnabled: Bool {
        defaults.bool(forKey: Self.biometricEnabledKey)
    }

    var canUseBiometrics: Bool {
        biometrics.isAvailable
    }

    func login(email: String, password: String) async -> Bool {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Введите email и пароль."
            return false
        }

        return await authenticate(
            path: "auth/login",
            body: AuthRequest(
                email: normalizedEmail,
                password: password
            )
        )
    }

    func register(name: String, email: String, password: String) async -> Bool {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !normalizedName.isEmpty, !normalizedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Заполните имя, email и пароль."
            return false
        }
        guard password.count >= 8 else {
            errorMessage = "Пароль должен содержать не менее 8 символов."
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response: MessageResponse = try await APIClient.shared.send(
                path: "auth/register",
                method: "POST",
                body: RegisterRequest(
                email: normalizedEmail,
                password: password,
                name: normalizedName
            )
            )
            developmentCode = response.developmentCode
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func verifyEmail(email: String, code: String, password: String) async -> Bool {
        do {
            let _: MessageResponse = try await APIClient.shared.send(
                path: "auth/verify-email",
                method: "POST",
                body: VerifyCodeRequest(email: email.lowercased(), code: code)
            )
            developmentCode = nil
            return await login(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func resendVerification(email: String) async {
        do {
            let response: MessageResponse = try await APIClient.shared.send(
                path: "auth/resend-verification",
                method: "POST",
                body: EmailRequest(email: email.lowercased())
            )
            developmentCode = response.developmentCode
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func requestPasswordReset(email: String) async -> Bool {
        do {
            let response: MessageResponse = try await APIClient.shared.send(
                path: "auth/forgot-password",
                method: "POST",
                body: EmailRequest(email: email.lowercased())
            )
            developmentCode = response.developmentCode
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func resetPassword(email: String, code: String, newPassword: String) async -> Bool {
        guard newPassword.count >= 8 else {
            errorMessage = "Пароль должен содержать не менее 8 символов."
            return false
        }
        do {
            let _: MessageResponse = try await APIClient.shared.send(
                path: "auth/reset-password",
                method: "POST",
                body: ResetPasswordRequest(
                    email: email.lowercased(),
                    code: code,
                    newPassword: newPassword
                )
            )
            developmentCode = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func authenticateWithGoogle(isRegistration: Bool) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let idToken = try await googleAuth.signIn()
            let response: TokenResponse = try await APIClient.shared.send(
                path: isRegistration ? "auth/google/register" : "auth/google/login",
                method: "POST",
                body: GoogleAuthRequest(idToken: idToken)
            )
            try keychain.saveToken(response.accessToken)
            accessToken = response.accessToken
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func continueAsGuest() {
        clearError()
    }

    func logout() {
        accessToken = nil
        keychain.deleteToken()
        googleAuth.signOut()
        defaults.set(false, forKey: Self.biometricEnabledKey)
    }

    func unlockWithBiometrics() async -> Bool {
        guard isAuthenticated, isBiometricEnabled else {
            return false
        }

        do {
            try await biometrics.authenticate(
                reason: "Разблокируйте Spark, чтобы продолжить."
            )
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Не удалось подтвердить личность. Войдите с помощью email и пароля."
            return false
        }
    }

    func setBiometricEnabled(_ enabled: Bool) async -> Bool {
        guard enabled else {
            defaults.set(false, forKey: Self.biometricEnabledKey)
            return true
        }

        guard canUseBiometrics else {
            errorMessage = "Face ID или код-пароль недоступны на этом устройстве."
            return false
        }

        do {
            try await biometrics.authenticate(
                reason: "Включите Face ID для быстрой разблокировки Spark."
            )
            defaults.set(true, forKey: Self.biometricEnabledKey)
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Face ID не был включён."
            return false
        }
    }

    private func authenticate(path: String, body: any Encodable) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response: TokenResponse = try await APIClient.shared.send(
                path: path,
                method: "POST",
                body: body
            )
            try keychain.saveToken(response.accessToken)
            accessToken = response.accessToken
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
