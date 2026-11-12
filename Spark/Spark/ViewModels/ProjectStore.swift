import Foundation
import Observation

@MainActor
@Observable
final class ProjectStore {
    private(set) var projects: [Project]
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let token: String?

    var isAuthenticated: Bool { token != nil }

    init(token: String? = nil, projects: [Project] = mockProjects) {
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct ApplicationResponse: Decodable {
    let id: UUID
}
