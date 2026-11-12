import SwiftUI

struct ProjectView: View {
    let store: ProjectStore
    let currentUserID: UUID?

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

                    if !store.receivedApplications.isEmpty {
                        ApplicationInbox(store: store)
                    }

                    if !store.myApplications.isEmpty {
                        MyApplications(store: store)
                    }

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
                                ProjectDetailsView(
                                    project: project,
                                    store: store,
                                    isOwner: project.ownerID == currentUserID
                                )
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
            .sensoryFeedback(.success, trigger: store.successFeedbackTrigger)
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
    let isOwner: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

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

            if isOwner {
                Section {
                    Button("Удалить проект", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
            }
        }
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Удалить проект без возможности восстановления?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Удалить проект", role: .destructive) {
                Task {
                    if await store.deleteProject(id: project.id) {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct ApplicationInbox: View {
    let store: ProjectStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Заявки в мои проекты")
                .font(.title3.bold())

            ForEach(store.receivedApplications) { application in
                VStack(alignment: .leading, spacing: 8) {
                    Text(application.userName)
                        .font(.headline)
                    Text("\(application.projectTitle) · \(application.roleTitle)")
                        .foregroundStyle(.secondary)

                    if application.status == "pending" {
                        HStack {
                            Button("Принять") {
                                Task { await store.decideApplication(id: application.id, accept: true) }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)

                            Button("Отклонить") {
                                Task { await store.decideApplication(id: application.id, accept: false) }
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    } else {
                        Text(application.status == "accepted" ? "Принята" : "Отклонена")
                            .font(.caption.weight(.semibold))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

private struct MyApplications: View {
    let store: ProjectStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Мои отклики")
                .font(.title3.bold())

            ForEach(store.myApplications) { application in
                HStack {
                    VStack(alignment: .leading) {
                        Text(application.projectTitle).font(.headline)
                        Text("\(application.roleTitle) · \(application.status)")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if application.status != "accepted" {
                        Button("Отменить", role: .destructive) {
                            Task { await store.cancelApplication(id: application.id) }
                        }
                    }
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

#Preview {
    ProjectView(
        store: ProjectStore(projects: mockProjects),
        currentUserID: nil
    )
}
