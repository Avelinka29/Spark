import Observation
import UIKit

@MainActor
@Observable
final class ProfileStore {
    private(set) var profile: UserProfile?
    private(set) var avatarImage: UIImage?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var portfolio: PublicProfileDTO?
    private(set) var portfolioError: String?
    private(set) var eventProposals: [EventProposalDTO] = []
    private(set) var organizationApplications: [OrganizationApplicationDTO] = []

    private let token: String?

    var isAuthenticated: Bool { token != nil }
    var reportToken: String? { token }

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
            do {
                portfolio = try await APIClient.shared.send(path: "profiles/\(loadedProfile.id)", token: token)
                portfolioError = nil
            } catch {
                portfolioError = "Не удалось загрузить портфолио. Потяните экран вниз, чтобы повторить."
            }
            avatarImage = await loadRemoteAvatar(token: token)
                ?? loadAvatar(userID: loadedProfile.id)
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

    func setUsername(_ value: String) async -> Bool {
        guard let token else { return false }
        let username = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard username.range(of: "^[a-z0-9_]{3,32}$", options: .regularExpression) != nil else {
            errorMessage = "Ник: 3–32 латинские буквы, цифры или подчёркивание."
            return false
        }
        do {
            let _: ProfileDTO = try await APIClient.shared.send(path: "profile/username", method: "PUT", body: UsernameRequest(username: username), token: token)
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func setPortfolioVisibility(_ visible: Bool) async -> Bool {
        guard let token else { return false }
        do {
            let _: ProfileDTO = try await APIClient.shared.send(path: "profile/portfolio-visibility", method: "PUT",
                body: PortfolioVisibilityRequest(portfolioPublic: visible), token: token)
            await load()
            return true
        } catch { errorMessage = error.localizedDescription; return false }
    }

    func updateProfile(
        name: String,
        region: String,
        bio: String,
        skills: [String],
        interests: [String]
    ) async -> Bool {
        guard let token else { return false }
        do {
            let response: ProfileDTO = try await APIClient.shared.send(
                path: "profile/me",
                method: "PATCH",
                body: ProfileUpdateRequest(
                    name: name,
                    region: region,
                    bio: bio,
                    skills: skills,
                    interests: interests
                ),
                token: token
            )
            let achievements = profile?.achievements ?? []
            var updatedProfile = response.makeProfile()
            updatedProfile.achievements = achievements
            profile = updatedProfile
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func enableOrganization(name: String) async -> Bool {
        guard let token else { return false }
        do {
            let response: ProfileDTO = try await APIClient.shared.send(
                path: "profile/organization",
                method: "PATCH",
                body: OrganizationProfileRequest(organizationName: name),
                token: token
            )
            var updated = response.makeProfile()
            updated.achievements = profile?.achievements ?? []
            profile = updated
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func createOpportunity(_ request: OpportunityCreateRequest) async -> Bool {
        guard let token else { return false }
        do {
            let _: OpportunityDTO = try await APIClient.shared.send(
                path: "opportunities",
                method: "POST",
                body: request,
                token: token
            )
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func loadOrganizationApplications() async {
        guard let token else { return }
        do {
            organizationApplications = try await APIClient.shared.send(path: "organization-applications", token: token)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func decideOrganizationApplication(id: UUID, approve: Bool) async {
        guard let token else { return }
        do {
            let _: OrganizationApplicationDTO = try await APIClient.shared.send(
                path: "organization-applications/\(id)", method: "PATCH",
                body: OrganizationDecisionRequest(status: approve ? "approved" : "rejected"), token: token
            )
            await loadOrganizationApplications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func proposeEvent(_ request: OpportunityCreateRequest, message: String) async -> Bool {
        guard let token else { return false }
        do {
            let _: EventProposalDTO = try await APIClient.shared.send(
                path: "event-proposals",
                method: "POST",
                body: EventProposalCreateRequest(event: request, message: message),
                token: token
            )
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func loadEventProposals() async {
        guard let token else { return }
        do {
            eventProposals = try await APIClient.shared.send(path: "event-proposals", token: token)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func decideEventProposal(id: UUID, approve: Bool) async -> Bool {
        guard let token else { return false }
        do {
            let _: EventProposalDTO = try await APIClient.shared.send(
                path: "event-proposals/\(id)",
                method: "PATCH",
                body: EventProposalDecisionRequest(status: approve ? "approved" : "rejected"),
                token: token
            )
            await loadEventProposals()
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

    func deleteAccount() async -> Bool {
        guard let token else { return false }
        let userID = profile?.id
        do {
            let _: EmptyResponse = try await APIClient.shared.send(
                path: "profile/me",
                method: "DELETE",
                token: token
            )
            profile = nil
            avatarImage = nil
            if let userID, let url = try? avatarURL(userID: userID) {
                try? FileManager.default.removeItem(at: url)
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updateAvatar(with data: Data) {
        guard let token,
              let userID = profile?.id,
              let image = UIImage(data: data),
              let jpegData = image.jpegData(compressionQuality: 0.82) else {
            errorMessage = "Не удалось загрузить выбранное изображение."
            return
        }

        avatarImage = UIImage(data: jpegData)
        Task {
            do {
                let _: EmptyResponse = try await APIClient.shared.send(
                    path: "profile/avatar",
                    method: "PUT",
                    body: AvatarDTO(
                        data: jpegData.base64EncodedString(),
                        contentType: "image/jpeg"
                    ),
                    token: token
                )
                let url = try avatarURL(userID: userID)
                try jpegData.write(to: url, options: .atomic)
                errorMessage = nil
            } catch {
                avatarImage = loadAvatar(userID: userID)
                errorMessage = "Не удалось сохранить фотографию профиля на сервере."
            }
        }
    }

    private func loadRemoteAvatar(token: String) async -> UIImage? {
        do {
            let response: AvatarDTO = try await APIClient.shared.send(
                path: "profile/avatar",
                token: token
            )
            guard let data = Data(base64Encoded: response.data) else {
                return nil
            }
            return UIImage(data: data)
        } catch {
            return nil
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
