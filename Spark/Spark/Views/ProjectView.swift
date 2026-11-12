import SwiftUI

struct ProjectView: View {
    let store: ProjectStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ProjectSummary(
                        projectsCount: store.projects.count,
                        rolesCount: store.openRolesCount
                    )

                    Text("Активные проекты")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if store.projects.isEmpty && !store.isLoading {
                        ContentUnavailableView(
                            "Проектов пока нет",
                            systemImage: "person.3.sequence",
                            description: Text("Создай первый проект и собери свою команду.")
                        )
                        .padding(.vertical, 40)
                    } else {
                        ForEach(store.projects) { project in
                            NavigationLink {
                                ProjectDetailsView(project: project, store: store)
                            } label: {
                                CardActiveProject(
                                    category: project.category.uppercased(),
                                    color: .litePurple,
                                    title: project.title,
                                    description: project.summary,
                                    isAuthenticated: store.isAuthenticated,
                                    vacancies: project.vacancies
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 180)
            }
            .navigationTitle("ProjectHub")
            .task {
                await store.load()
            }
            .overlay(alignment: .bottom) {
                if let errorMessage = store.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .padding(10)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom)
                }
            }
        }
    }
}

private struct ProjectSummary: View {
    let projectsCount: Int
    let rolesCount: Int

    var body: some View {
        HStack {
            ActiveProject(
                color: .litePurple,
                imageName: "sparkles",
                title: "ПРОЕКТЫ",
                status: "активных",
                type: .count(projectsCount),
                isActive: true,
                strokeWidht: 3,
                titleSize: 26
            )

            ActiveProject(
                color: .green,
                imageName: "person.2",
                title: "РОЛИ",
                status: "открыто",
                type: .count(rolesCount),
                isActive: true,
                strokeWidht: 3,
                titleSize: 26
            )
        }
    }
}

private struct ProjectDetailsView: View {
    let project: Project
    let store: ProjectStore

    var body: some View {
        List {
            Section("О проекте") {
                Text(project.summary)
                Label(project.ownerRole, systemImage: "person.crop.circle")
                Label("\(project.memberCount) участников", systemImage: "person.2")
            }

            Section("Роли") {
                if !store.isAuthenticated {
                    Label("Войдите, чтобы откликаться на роли", systemImage: "lock")
                        .foregroundStyle(.secondary)
                }

                ForEach(project.vacancies) { vacancy in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(vacancy.title)
                            .font(.headline)
                        Text(vacancy.roleDescription)
                            .foregroundStyle(.secondary)

                        Button(vacancy.isActive ? "Откликнуться" : vacancy.status) {
                            Task {
                                await store.join(
                                    projectID: project.id,
                                    vacancyID: vacancy.id
                                )
                            }
                        }
                        .disabled(!vacancy.isActive || !store.isAuthenticated)
                    }
                }
            }
        }
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProjectView(store: ProjectStore())
}
