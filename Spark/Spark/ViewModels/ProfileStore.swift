import Observation
import UIKit

@MainActor
@Observable
final class ProfileStore {
    private(set) var profile: UserProfile?
    private(set) var avatarImage: UIImage?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let token: String?

    var isAuthenticated: Bool { token != nil }

    init(token: String?) {
        self.token = token
    }

    func load() async {
        guard let token else {
            profile = guestProfile
            errorMessage = "Гостевой профиль"
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response: ProfileDTO = try await APIClient.shared.send(
                path: "profile/me",
                token: token
            )
            async let achievementResponse: [AchievementDTO] = APIClient.shared.send(
                path: "achievements",
                token: token
            )
            var loadedProfile = response.makeProfile()
            loadedProfile.achievements = try await achievementResponse.compactMap {
                $0.makeAchievement()
            }
            profile = loadedProfile
            avatarImage = loadAvatar(userID: loadedProfile.id)
        } catch {
            profile = nil
            errorMessage = error.localizedDescription
        }
    }

    func addAchievement(title: String, issuer: String, date: Date) async -> Bool {
        guard let token else { return false }
        let payload = AchievementDTO(
            id: nil,
            title: title,
            issuer: issuer,
            issuedAt: date.formatted(.iso8601.year().month().day())
        )
        do {
            let _: AchievementDTO = try await APIClient.shared.send(
                path: "achievements",
                method: "POST",
                body: payload,
                token: token
            )
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deleteAchievement(id: UUID) async {
        guard let token else { return }
        do {
            let _: EmptyResponse = try await APIClient.shared.send(
                path: "achievements/\(id)",
                method: "DELETE",
                token: token
            )
            profile?.achievements.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateAvatar(with data: Data) {
        guard let userID = profile?.id,
              let image = UIImage(data: data),
              let jpegData = image.jpegData(compressionQuality: 0.82) else {
            errorMessage = "Не удалось загрузить выбранное изображение."
            return
        }

        do {
            let url = try avatarURL(userID: userID)
            try jpegData.write(to: url, options: .atomic)
            avatarImage = UIImage(data: jpegData)
            errorMessage = nil
        } catch {
            errorMessage = "Не удалось сохранить фотографию профиля."
        }
    }

    private func loadAvatar(userID: UUID) -> UIImage? {
        guard let url = try? avatarURL(userID: userID),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return UIImage(data: data)
    }

    private func avatarURL(userID: UUID) throws -> URL {
        let directory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("SparkAvatars", isDirectory: true)

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory.appendingPathComponent("\(userID.uuidString).jpg")
    }
}
