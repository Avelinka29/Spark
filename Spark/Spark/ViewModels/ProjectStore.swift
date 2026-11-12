import Foundation
import Observation

@MainActor
@Observable
final class ProjectStore {
    private(set) var projects: [Project]
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var myApplications: [ProjectApplicationDTO] = []
    private(set) var receivedApplications: [ProjectApplicationDTO] = []

    private let token: String?

    var isAuthenticated: Bool { token != nil }

    init(token: String? = nil, projects: [Project] = []) {
        self.token = token
        self.projects = projects
    }

    var openRolesCount: Int {
        projects.reduce(0) { count, project in
            count + project.vacancies.filter(\.isActive).count
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response: [ProjectDTO] = try await APIClient.shared.send(path: "projects")
            projects = response.map { $0.makeProject() }
            if token != nil {
                async let mine: [ProjectApplicationDTO] = APIClient.shared.send(
                    path: "applications/mine",
                    token: token
                )
                async let received: [ProjectApplicationDTO] = APIClient.shared.send(
                    path: "applications/received",
                    token: token
                )
                myApplications = try await mine
                receivedApplications = try await received
            }
        } catch {
            errorMessage = "Сервер проектов недоступен."
        }
    }

    func createProject(_ project: Project) async -> Bool {
        guard let token else {
            errorMessage = "Для создания проекта необходимо войти."
            return false
        }

        do {
            let payload = ProjectDTO(
                id: nil,
                ownerID: nil,
                category: project.category,
                title: project.title,
                summary: project.summary,
                ownerRole: project.ownerRole,
                roles: project.vacancies.map {
                    ProjectRoleDTO(
                        id: nil,
                        title: $0.title,
                        skills: $0.roleDescription,
                        isOpen: nil
                    )
                }
            )
            let response: ProjectDTO = try await APIClient.shared.send(
                path: "projects",
                method: "POST",
                body: payload,
                token: token
            )
            projects.insert(response.makeProject(), at: 0)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func join(projectID: Project.ID, vacancyID: Vacancy.ID) async {
        guard let token else {
            errorMessage = "Для отклика необходимо войти."
            return
        }

        do {
            let _: ApplicationResponse = try await APIClient.shared.send(
                path: "project-roles/\(vacancyID)/applications",
                method: "POST",
                token: token
            )

            guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
                  let vacancyIndex = projects[projectIndex].vacancies.firstIndex(
                    where: { $0.id == vacancyID }
                  ) else {
                return
            }

            projects[projectIndex].vacancies[vacancyIndex].isActive = false
            projects[projectIndex].vacancies[vacancyIndex].status = "ЗАЯВКА"
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func decideApplication(id: UUID, accept: Bool) async {
        guard let token else { return }
        do {
            let _: ProjectApplicationDTO = try await APIClient.shared.send(
                path: "applications/\(id)",
                method: "PATCH",
                body: ApplicationStatusRequest(status: accept ? "accepted" : "rejected"),
                token: token
            )
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelApplication(id: UUID) async {
        guard let token else { return }
        do {
            let _: EmptyResponse = try await APIClient.shared.send(
                path: "applications/\(id)",
                method: "DELETE",
                token: token
            )
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteProject(id: UUID) async -> Bool {
        guard let token else { return false }
        do {
            let _: EmptyResponse = try await APIClient.shared.send(
                path: "projects/\(id)",
                method: "DELETE",
                token: token
            )
            projects.removeAll { $0.id == id }
            receivedApplications.removeAll { $0.projectID == id }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

private struct ApplicationResponse: Decodable {
    let id: UUID
}
