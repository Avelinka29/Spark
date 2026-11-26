import SwiftUI

struct ProjectView: View {
    let store: ProjectStore
    let currentUserID: UUID?
    var profile: UserProfile? = nil
    var onCreateProject: () -> Void = {}
    @State private var showAIConfirmation = false
    @State private var selectedSection = 0

    private var recommendations: [ProjectRecommendation] {
        ProjectRecommendations.matching(projects: store.projects, profile: profile)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ProjectSummary(
                        projectsCount: store.projects.count,
                        rolesCount: store.openRolesCount,
                        onCreate: onCreateProject
                    )

                    Picker("Раздел проектов", selection: $selectedSection) {
                        Text("Все").tag(0)
                        Text("Для меня").tag(1)
                        Text("Отклики").tag(2)
                    }.pickerStyle(.segmented)

                    if selectedSection == 1 && profile != nil {
                        Text("Подбор для тебя").font(.title2.bold())
                        Text("Проекты по твоим навыкам и интересам. Проверь роль перед откликом.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Button {
                            showAIConfirmation = true
                        } label: {
                            if store.aiIsLoading {
                                ProgressView()
                            } else {
                                Label("Подобрать проекты с ИИ", systemImage: "sparkles")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.primaryLitePurple)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                        .disabled(store.aiIsLoading)
                        if let message = store.aiMessage {
                            Text(message).font(.footnote).foregroundStyle(.secondary)
                        }
                        if !store.aiMatches.isEmpty {
                            Text("Подбор ИИ").font(.title3.bold()).frame(maxWidth: .infinity, alignment: .leading)
                            Text("Рекомендации стоит проверить по описанию роли.")
                                .font(.caption).foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            ForEach(store.aiMatches) { match in
                                if let project = store.projects.first(where: { $0.id == match.id }) {
                                    NavigationLink {
                                        ProjectDetailsView(project: project, store: store, isOwner: project.ownerID == currentUserID)
                                    } label: {
                                        RecommendationCard(project: project, reasons: [match.reason], symbol: "sparkles")
                                    }.buttonStyle(.plain)
                                    HStack {
                                        Text("Подходит?").font(.caption).foregroundStyle(.secondary)
                                        Button("Да") { Task { await store.sendAIFeedback(projectID: project.id, helpful: true) } }
                                        Button("Нет") { Task { await store.sendAIFeedback(projectID: project.id, helpful: false) } }
                                        if store.aiFeedback[project.id] != nil {
                                            Text("Спасибо за отзыв").font(.caption).foregroundStyle(.secondary)
                                        }
                                    }.font(.subheadline)
                                }
                            }
                        }
                    }

                    if selectedSection == 1 && !recommendations.isEmpty {
                        Text("Совпадения по профилю")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(recommendations.prefix(3)) { recommendation in
                            NavigationLink {
                                ProjectDetailsView(project: recommendation.project, store: store, isOwner: recommendation.project.ownerID == currentUserID)
                            } label: {
                                RecommendationCard(project: recommendation.project, reasons: recommendation.reasons, symbol: "checkmark.seal")
                            }
                            .buttonStyle(.plain)
                        }
                    } else if selectedSection == 1 && profile != nil && profile?.skills.isEmpty == true && profile?.interests.isEmpty == true {
                        Text("Добавь навыки и интересы в профиле, чтобы увидеть подходящие проекты.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }

                    if selectedSection == 1 && profile == nil {
                        SparkEmptyRow(title: "Войди в аккаунт", detail: "Заполни профиль, чтобы увидеть подходящие проекты.", symbol: "person.crop.circle")
                    }
                    if selectedSection == 2 && store.receivedApplications.isEmpty && store.myApplications.isEmpty {
                        SparkEmptyRow(title: "Откликов пока нет", detail: "Здесь появятся твои отклики и заявки в твои проекты.", symbol: "tray")
                    }
                    if selectedSection == 0 { Text("Все проекты")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, alignment: .leading) }

                    if selectedSection == 2 && !store.receivedApplications.isEmpty {
                        ApplicationInbox(store: store)
                    }

                    if selectedSection == 2 && !store.myApplications.isEmpty {
                        MyApplications(store: store)
                    }

                    if selectedSection == 0 && store.projects.isEmpty && !store.isLoading {
                        SparkEmptyRow(
                            title: "Проектов пока нет",
                            detail: "Создай первый проект и собери команду.",
                            symbol: "person.3"
                        )
                    } else if selectedSection == 0 {
                        LazyVStack(spacing: 10) {
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
                                    title: project.title.replacingOccurrences(of: "[Демо] ", with: "Учебный пример · "),
                                    description: project.summary,
                                    isAuthenticated: store.isAuthenticated,
                                    vacancies: project.vacancies
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Проекты")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Подбор с ИИ", isPresented: $showAIConfirmation) {
                Button("Продолжить") { Task { await store.loadAIRecommendations() } }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Сервер передаст модели ваши навыки, интересы и описания открытых проектов. Имя и email из профиля отдельно не отправляются, но могут встречаться в текстах. Провайдер зависит от настройки сервера.")
            }
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

private struct RecommendationCard: View {
    let project: Project
    let reasons: [String]
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(.primaryLitePurple)
                .frame(width: 38, height: 38)
                .background(Color.primaryLitePurple.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 7) {
                Text(project.category.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.primaryLitePurple)
                Text(project.title.replacingOccurrences(of: "[Демо] ", with: "Учебный пример · ")).font(.headline).foregroundStyle(.primary)
                ForEach(reasons, id: \.self) { reason in
                    Text(reason).font(.subheadline).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct ProjectSummary: View {
    let projectsCount: Int
    let rolesCount: Int

    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Найди свою команду")
                .font(.title2.bold())

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 24) { statistics }
                VStack(alignment: .leading, spacing: 12) { statistics }
            }

            Button(action: onCreate) {
                Label("Создать проект", systemImage: "plus")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(13)
                    .foregroundStyle(Color(red: 0.16, green: 0.13, blue: 0.35))
                    .background(.white, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .sparkHero()
    }

    @ViewBuilder
    private var statistics: some View {
        statistic("Проекты", value: projectsCount)
        statistic("Открытые роли", value: rolesCount)
    }

    private func statistic(_ title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value, format: .number)
                .font(.title2.bold().monospacedDigit())
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.88))
                .fixedSize(horizontal: true, vertical: false)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ProjectDetailsView: View {
    let project: Project
    let store: ProjectStore
    let isOwner: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showEditor = false
    @State private var showReport = false
    @State private var applyingRoleID: UUID?
    @State private var applicationMessage: String?

    private var currentProject: Project {
        store.projects.first { $0.id == project.id } ?? project
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(currentProject.category.uppercased())
                        .font(.caption.weight(.bold)).foregroundStyle(.primaryLitePurple)
                    Text(currentProject.title.replacingOccurrences(of: "[Демо] ", with: "Учебный пример · "))
                        .font(.title.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(currentProject.summary)
                        .font(.body).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Divider().padding(.vertical, 4)
                    Label(currentProject.ownerRole, systemImage: "person.crop.circle")
                    Label("Заполнено ролей: \(currentProject.vacancies.filter { !$0.isActive }.count) из \(currentProject.vacancies.count)", systemImage: "person.2")
                    if let value = currentProject.resultURL, let url = URL(string: value), url.scheme == "https" {
                        Link(destination: url) { Label("Результат проекта", systemImage: "arrow.up.right.square") }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22))

                if currentProject.title.hasPrefix("[Демо]") {
                    Label("Учебный пример: отклик сохранится, но демонстрационный создатель не рассмотрит его.", systemImage: "info.circle")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if isOwner {
                    Label("Заявки появятся во вкладке «Отклики». Когда все роли будут заполнены, чат команды создастся автоматически.", systemImage: "person.3.sequence")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Text("Роли в команде").font(.title3.bold())
                if !store.isAuthenticated {
                    Label("Войдите, чтобы откликаться на роли", systemImage: "lock")
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                ForEach(currentProject.vacancies) { vacancy in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(vacancy.title).font(.headline)
                            Spacer()
                            Text(vacancy.isActive ? "Открыта" : vacancy.status)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(vacancy.isActive ? Color.primaryLitePurple : Color.secondary)
                        }
                        Text(vacancy.roleDescription)
                            .font(.subheadline).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if !isOwner {
                            let application = store.myApplications.first { $0.roleID == vacancy.id }
                            if let application {
                                Label(application.status == "accepted" ? "Вас приняли в команду" : application.status == "rejected" ? "Заявка отклонена" : "Заявка отправлена", systemImage: "checkmark.circle")
                                    .font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                            } else {
                                Button {
                                    applyingRoleID = vacancy.id
                                    Task {
                                        let sent = await store.join(projectID: project.id, vacancyID: vacancy.id)
                                        applicationMessage = sent ? "Заявка отправлена создателю проекта. Следить за ответом можно в разделе «Отклики»." : (store.errorMessage ?? "Не удалось отправить заявку. Попробуй ещё раз.")
                                        applyingRoleID = nil
                                    }
                                } label: {
                                    if applyingRoleID == vacancy.id { ProgressView() }
                                    else { Text(vacancy.isActive ? "Откликнуться" : "Набор закрыт") }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.primaryLitePurple)
                                .disabled(!vacancy.isActive || !store.isAuthenticated || applyingRoleID != nil)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22))
                }

                if isOwner {
                    Button("Удалить проект", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                } else if store.reportToken != nil {
                    Button("Пожаловаться на проект") { showReport = true }
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Проект")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Отклик на проект", isPresented: Binding(get: { applicationMessage != nil }, set: { if !$0 { applicationMessage = nil } })) {
            Button("Понятно", role: .cancel) { applicationMessage = nil }
        } message: { Text(applicationMessage ?? "") }
        .toolbar {
            if isOwner {
                ToolbarItem(placement: .primaryAction) {
                    Button("Изменить") { showEditor = true }
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            ProjectEditorView(project: currentProject, store: store)
        }
        .sheet(isPresented: $showReport) {
            if let token = store.reportToken { ContentReportView(token: token, kind: "project", targetID: project.id) }
        }
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

private struct ProjectEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let project: Project
    let store: ProjectStore

    @State private var category: String
    @State private var title: String
    @State private var summary: String
    @State private var ownerRole: String
    @State private var resultURL: String
    @State private var newRoleTitle = ""
    @State private var newRoleSkills = ""
    @State private var isSaving = false

    private var currentVacancies: [Vacancy] {
        store.projects.first { $0.id == project.id }?.vacancies ?? project.vacancies
    }

    init(project: Project, store: ProjectStore) {
        self.project = project
        self.store = store
        _category = State(initialValue: project.category)
        _title = State(initialValue: project.title)
        _summary = State(initialValue: project.summary)
        _ownerRole = State(initialValue: project.ownerRole)
        _resultURL = State(initialValue: project.resultURL ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Проект") {
                    TextField("Категория", text: $category)
                    TextField("Название", text: $title)
                    TextField("Описание", text: $summary, axis: .vertical)
                        .lineLimit(3...8)
                    TextField("Моя роль", text: $ownerRole)
                    TextField("Ссылка на результат (https://)", text: $resultURL)
                        .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    Text("Ссылка будет видна в портфолио участников, если они не скрыли его.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("Открытые роли") {
                    ForEach(currentVacancies) { vacancy in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(vacancy.title)
                                Text(vacancy.roleDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                Task { await store.deleteRole(id: vacancy.id) }
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }

                Section("Добавить роль") {
                    TextField("Название роли", text: $newRoleTitle)
                    TextField("Навыки", text: $newRoleSkills)
                    Button("Добавить") {
                        Task {
                            if await store.addRole(
                                projectID: project.id,
                                title: newRoleTitle,
                                skills: newRoleSkills
                            ) {
                                newRoleTitle = ""
                                newRoleSkills = ""
                            }
                        }
                    }
                    .disabled(newRoleTitle.trimmingCharacters(in: .whitespacesAndNewlines).count < 2)
                }
                if let error = store.errorMessage { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        Task {
                            isSaving = true
                            if await store.updateProject(
                                id: project.id,
                                category: category,
                                title: title,
                                summary: summary,
                                ownerRole: ownerRole,
                                resultURL: resultURL.trimmingCharacters(in: .whitespacesAndNewlines)
                            ) {
                                dismiss()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(
                        isSaving ||
                        category.count < 2 ||
                        title.count < 2 ||
                        summary.count < 10 ||
                        ownerRole.count < 2
                    )
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
            Text("Выбери участников для открытых ролей. Когда команда соберётся, чат появится в сообществе.")
                .font(.subheadline).foregroundStyle(.secondary)

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
                        Text("\(application.roleTitle) · \(application.status == "pending" ? "На рассмотрении" : application.status == "accepted" ? "Принята" : "Отклонена")")
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
