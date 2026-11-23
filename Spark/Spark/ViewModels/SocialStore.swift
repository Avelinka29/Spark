import Foundation
import Observation

@MainActor
@Observable
final class SocialStore {
    private(set) var friends: [FriendDTO] = []
    private(set) var chats: [ChatDTO] = []
    private(set) var messages: [ChatMessageDTO] = []
    private(set) var viewedProfile: PublicProfileDTO?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var pendingProfileID: UUID?

    private let token: String?

    init(token: String?) {
        self.token = token
    }

    var acceptedFriends: [FriendDTO] {
        friends.filter { $0.status == "friends" }
    }

    var incomingRequests: [FriendDTO] {
        friends.filter { $0.status == "pending_received" }
    }

    var outgoingRequests: [FriendDTO] {
        friends.filter { $0.status == "pending_sent" }
    }

    func load() async {
        guard let token else {
            friends = []
            chats = []
            return
        }
        isLoading = true
        defer { isLoading = false }

        do {
            async let loadedFriends: [FriendDTO] = APIClient.shared.send(
                path: "friends",
                token: token
            )
            async let loadedChats: [ChatDTO] = APIClient.shared.send(
                path: "chats",
                token: token
            )
            friends = try await loadedFriends
            chats = try await loadedChats
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadProfile(id: UUID) async {
        guard let token else { return }
        do {
            viewedProfile = try await APIClient.shared.send(
                path: "profiles/\(id)",
                token: token
            )
            errorMessage = nil
        } catch {
            viewedProfile = nil
            errorMessage = error.localizedDescription
        }
    }

    func requestFriend(profileID: UUID) async -> Bool {
        guard let token else { return false }
        do {
            let _: FriendDTO = try await APIClient.shared.send(
                path: "friends/\(profileID)",
                method: "POST",
                token: token
            )
            await load()
            await loadProfile(id: profileID)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func acceptFriendship(_ friendship: FriendDTO) async {
        guard let token else { return }
        do {
            let _: FriendDTO = try await APIClient.shared.send(
                path: "friends/\(friendship.friendshipID)/accept",
                method: "PATCH",
                token: token
            )
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeFriendship(_ friendship: FriendDTO) async {
        guard let token else { return }
        do {
            let _: EmptyResponse = try await APIClient.shared.send(
                path: "friends/\(friendship.friendshipID)",
                method: "DELETE",
                token: token
            )
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMessages(chatID: UUID) async {
        guard let token else { return }
        do {
            messages = try await APIClient.shared.send(
                path: "chats/\(chatID)/messages",
                token: token
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendMessage(chatID: UUID, text: String) async -> Bool {
        guard let token else { return false }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        do {
            let _: ChatMessageDTO = try await APIClient.shared.send(
                path: "chats/\(chatID)/messages",
                method: "POST",
                body: ChatMessageCreateRequest(text: trimmed),
                token: token
            )
            await loadMessages(chatID: chatID)
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func profileID(from value: String) -> UUID? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if let id = UUID(uuidString: trimmed) {
            return id
        }
        guard let components = URLComponents(string: trimmed) else { return nil }
        if components.scheme == "spark", components.host == "profile",
           let value = components.path.split(separator: "/").last {
            return UUID(uuidString: String(value))
        }
        return nil
    }

    func openProfileURL(_ url: URL) {
        guard let profileID = profileID(from: url.absoluteString) else {
            errorMessage = "Ссылка не содержит профиль Spark."
            return
        }
        pendingProfileID = profileID
    }

    func consumePendingProfile() {
        pendingProfileID = nil
    }

    func workspace(chatID: UUID) async throws -> TeamWorkspaceDTO {
        guard let token else { throw APIError.notAuthenticated }
        return try await APIClient.shared.send(path: "chats/\(chatID)/workspace", token: token)
    }

    func saveWorkspace(chatID: UUID, value: TeamWorkspaceDTO) async throws {
        guard let token else { throw APIError.notAuthenticated }
        let _: TeamWorkspaceDTO = try await APIClient.shared.send(path: "chats/\(chatID)/workspace", method: "PUT", body: value, token: token)
    }

    func tasks(chatID: UUID) async throws -> [TeamTaskDTO] {
        guard let token else { throw APIError.notAuthenticated }
        return try await APIClient.shared.send(path: "chats/\(chatID)/tasks", token: token)
    }

    func createTask(chatID: UUID, title: String) async throws {
        guard let token else { throw APIError.notAuthenticated }
        let _: TeamTaskDTO = try await APIClient.shared.send(path: "chats/\(chatID)/tasks", method: "POST", body: TeamTaskCreateRequest(title: title), token: token)
    }

    func updateTask(chatID: UUID, task: TeamTaskDTO) async throws {
        guard let token else { throw APIError.notAuthenticated }
        let _: TeamTaskDTO = try await APIClient.shared.send(path: "chats/\(chatID)/tasks/\(task.id)", method: "PATCH", body: TeamTaskUpdateRequest(done: !task.done), token: token)
    }

    func deleteTask(chatID: UUID, taskID: UUID) async throws {
        guard let token else { throw APIError.notAuthenticated }
        let _: EmptyResponse = try await APIClient.shared.send(path: "chats/\(chatID)/tasks/\(taskID)", method: "DELETE", token: token)
    }

    func reportError(_ message: String) {
        errorMessage = message
    }
}
