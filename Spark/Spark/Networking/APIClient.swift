import Foundation

enum APIError: LocalizedError {
    case invalidResponse
    case networkUnavailable
    case server(statusCode: Int, message: String)
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Сервер вернул некорректный ответ."
        case .networkUnavailable:
            return "Не удалось подключиться к Spark Backend. Проверьте, что Mac и iPhone находятся в одной Wi-Fi сети, а сервер запущен."
        case let .server(_, message):
            return message
        case .notAuthenticated:
            return "Необходимо войти в аккаунт."
        }
    }
}

struct EmptyResponse: Decodable {}

actor APIClient {
    static let shared = APIClient()

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        baseURL: URL = APIConfiguration.baseURL,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    func send<Response: Decodable>(
        path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        token: String? = nil
    ) async throws -> Response {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .cannotConnectToHost, .cannotFindHost,
                    .dnsLookupFailed, .networkConnectionLost, .timedOut:
                throw APIError.networkUnavailable
            default:
                throw error
            }
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let detail = serverMessage(from: data, statusCode: httpResponse.statusCode)
            throw APIError.server(statusCode: httpResponse.statusCode, message: detail)
        }

        if data.isEmpty, let emptyResponse = EmptyResponse() as? Response {
            return emptyResponse
        }

        return try decoder.decode(Response.self, from: data)
    }

    private func serverMessage(from data: Data, statusCode: Int) -> String {
        if let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data) {
            switch envelope.detail {
            case let .message(message):
                return localizedServerMessage(message, statusCode: statusCode)
            case let .validation(errors):
                return errors.map { localizedValidationMessage($0.message) }.joined(separator: "\n")
            }
        }

        return "Ошибка сервера: \(statusCode)"
    }

    private func localizedServerMessage(_ message: String, statusCode: Int) -> String {
        switch message {
        case "Invalid email or password" where statusCode == 401:
            return "Неверный email или пароль."
        case "Email already registered":
            return "Пользователь с таким email уже зарегистрирован."
        case "Invalid Google token":
            return "Google не подтвердил вход. Попробуйте ещё раз."
        case "Google email is not verified":
            return "Email аккаунта Google не подтверждён."
        case "Email is linked to another Google account":
            return "Этот email уже связан с другим аккаунтом Google."
        case "Google account is not registered":
            return "Аккаунт Spark для этой почты не найден. Перейдите во вкладку «Регистрация»."
        case "Google account already exists":
            return "Аккаунт уже существует. Перейдите во вкладку «Вход»."
        case "Google Sign-In is not configured":
            return "Вход через Google временно недоступен."
        case "Email is not verified":
            return "Подтвердите email с помощью кода из письма."
        case "Invalid or expired verification code":
            return "Код неверный или срок его действия истёк."
        case "Email delivery is not configured":
            return "Отправка писем временно недоступна."
        default:
            return message
        }
    }

    private func localizedValidationMessage(_ message: String) -> String {
        if message.contains("at least 8 characters") {
            return "Пароль должен содержать не менее 8 символов."
        }
        if message.contains("valid email address") {
            return "Введите корректный email."
        }
        if message.contains("Field required") {
            return "Заполните все обязательные поля."
        }
        return message
    }
}

private enum APIConfiguration {
    static let baseURL: URL = {
        if let override = ProcessInfo.processInfo.environment["SPARK_API_BASE_URL"],
           let url = URL(string: normalized(override)) {
            return url
        }

#if targetEnvironment(simulator)
        return URL(string: "http://127.0.0.1:8000/api/v1/")!
#else
        return URL(string: "http://MacBook-Air-YULIYA.local:8000/api/v1/")!
#endif
    }()

    private static func normalized(_ value: String) -> String {
        value.hasSuffix("/") ? value : value + "/"
    }
}

private struct APIErrorEnvelope: Decodable {
    let detail: APIDetail
}

private enum APIDetail: Decodable {
    case message(String)
    case validation([APIValidationError])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let message = try? container.decode(String.self) {
            self = .message(message)
        } else {
            self = .validation(try container.decode([APIValidationError].self))
        }
    }
}

private struct APIValidationError: Decodable {
    let message: String

    enum CodingKeys: String, CodingKey {
        case message = "msg"
    }
}

private struct AnyEncodable: Encodable {
    private let encodeValue: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        encodeValue = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeValue(encoder)
    }
}
