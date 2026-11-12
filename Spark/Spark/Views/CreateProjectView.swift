import SwiftUI

struct CreateProjectView: View {
    struct DraftRole: Identifiable {
        let id = UUID()
        var name = ""
        var skills = ""
    }

    @Environment(\.dismiss) private var dismiss

    let store: ProjectStore

    @State private var projectTitle = ""
    @State private var projectDescription = ""
    @State private var ownerRole = ""
    @State private var selectedCategory = "EdTech"
    @State private var projectRoles = [DraftRole()]

    private let categories = [
        "FinTech",
        "EdTech",
        "GreenTech",
        "HealthTech",
        "Социальный проект",
        "Другое"
    ]

    private var canCreate: Bool {
        !projectTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !projectDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !ownerRole.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Название проекта", text: $projectTitle)

                    TextField(
                        "Описание проекта",
                        text: $projectDescription,
                        axis: .vertical
                    )
                    .lineLimit(4...8)

                    Picker("Категория", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }

                    TextField("Ваша роль", text: $ownerRole)
                }

                Section {
                    ForEach($projectRoles) { $role in
                        VStack(alignment: .leading) {
                            TextField("Название роли", text: $role.name)
                            TextField("Необходимые навыки", text: $role.skills)
                        }
                    }
                    .onDelete { offsets in
                        projectRoles.remove(atOffsets: offsets)
                    }

                    Button("Добавить роль", systemImage: "plus") {
                        projectRoles.append(DraftRole())
                    }
                } header: {
                    Text("Роли в команде")
                } footer: {
                    Text("Пустые роли не будут добавлены.")
                }
            }
            .navigationTitle("Новый проект")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        createProject()
                    }
                    .disabled(!canCreate)
                }
            }
        }
    }

    private func createProject() {
        let vacancies = projectRoles.compactMap { role -> Vacancy? in
            let name = role.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else {
                return nil
            }

            return Vacancy(
                title: name,
                roleDescription: role.skills.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }

        let project = Project(
            category: selectedCategory,
            title: projectTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            summary: projectDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            ownerRole: ownerRole.trimmingCharacters(in: .whitespacesAndNewlines),
            vacancies: vacancies
        )

        Task {
            if await store.createProject(project) {
                dismiss()
            }
        }
    }
}

#Preview {
    CreateProjectView(store: ProjectStore())
}
