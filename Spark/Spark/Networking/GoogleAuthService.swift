import GoogleSignIn
import UIKit

enum GoogleAuthError: LocalizedError {
    case presentationUnavailable
    case missingIDToken

    var errorDescription: String? {
        switch self {
        case .presentationUnavailable:
            return "Не удалось открыть окно входа Google."
        case .missingIDToken:
            return "Google не вернул данные для входа. Попробуйте ещё раз."
        }
    }
}

struct GoogleAuthService {
    @MainActor
    func signIn() async throws -> String {
        guard let presentingViewController = UIApplication.shared.activeViewController else {
            throw GoogleAuthError.presentationUnavailable
        }

        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingViewController
        )
        guard let idToken = result.user.idToken?.tokenString else {
            throw GoogleAuthError.missingIDToken
        }
        return idToken
    }

    @MainActor
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
}

private extension UIApplication {
    var activeViewController: UIViewController? {
        let windowScene = connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        return windowScene?.windows.first(where: \.isKeyWindow)?.rootViewController
    }
}
