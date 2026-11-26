import SwiftUI

struct GoalRouteView: View {
    let token: String
    @Environment(\.dismiss) private var dismiss
    @State private var goal = ""
    @State private var searched = false
    @State private var loading = false
    @State private var error: String?
    @State private var opportunities: [OpportunityDTO] = []
    @State private var projects: [ProjectDTO] = []
    @State private var projectStore: ProjectStore
    @State private var userID: UUID?

    init(token: String) {
        self.token = token
        _projectStore = State(initialValue: ProjectStore(token: token))
    }

    var body: some View {
        NavigationStack {
            List {
                SparkDiscoveryHero(title: "Маршрут к цели", subtitle: "Введи цель или интерес. Spark найдёт связанные события и проекты.", symbol: "location.north.fill")
                    .listRowInsets(EdgeInsets()).listRowBackground(Color.clear).listRowSeparator(.hidden)
                Section("Моя цель") {
                    TextField("Например, мобильная разработка", text: $goal)
                    Button("Построить маршрут", systemImage: "arrow.right") { Task { await buildRoute() } }
                        .disabled(loading || goal.trimmingCharacters(in: .whitespacesAndNewlines).count < 2)
                    Text("Поиск основан на совпадениях слов в опубликованных данных.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Попробуй одну из тем") {
                    HStack {
                        ForEach(["EdTech", "Дизайн", "Swift"], id: \.self) { example in
                            Button(example) { goal = example; Task { await buildRoute() } }
                                .buttonStyle(.bordered).tint(.primaryLitePurple)
                        }
                    }
                }
                if loading { ProgressView("Ищем возможности…") }
                if let error { Text(error).foregroundStyle(.red) }
                if searched && !loading {
                    Section("1. Найди событие") {
                        if opportunities.isEmpty { Text("Подходящих актуальных событий пока нет.").foregroundStyle(.secondary) }
                        ForEach(opportunities, id: \.id) { event in
                            NavigationLink(event.title) {
                                OpportunityDetailsView(opportunity: event.makeOpportunity(), accessToken: token)
                            }
                        }
                    }
                    Section("2. Присоединись к проекту") {
                        if projects.isEmpty { Text("Подходящих открытых проектов пока нет.").foregroundStyle(.secondary) }
                        ForEach(projects, id: \.id) { item in
                            let project = item.makeProject()
                            NavigationLink(project.title) {
                                SubscribedProjectView(project: project, store: projectStore, currentUserID: userID)
                            }
                        }
                    }
                    Section("3. Покажи результат") {
                        Text("Добавь в профиль подтверждённое участие и роль в проекте. Владелец проекта может указать ссылку на результат.")
                            .font(.subheadline)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Маршрут к цели")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Готово") { dismiss() } } }
        }
    }

    private func buildRoute() async {
        let words = goal.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { $0.count >= 2 }
        guard !words.isEmpty else { return }
        loading = true
        defer { loading = false }
        do {
            async let eventResponse: [OpportunityDTO] = APIClient.shared.send(path: "opportunities")
            async let projectResponse: [ProjectDTO] = APIClient.shared.send(path: "projects")
            async let profileResponse: ProfileDTO = APIClient.shared.send(path: "profile/me", token: token)
            let (events, allProjects, profile) = try await (eventResponse, projectResponse, profileResponse)
            userID = profile.id
            let today = Date().formatted(.iso8601.year().month().day())
            opportunities = Array(events.filter { event in
                let text = "\(event.title) \(event.summary) \(event.category)".lowercased()
                let current = [event.deadline, event.startsAt, event.endsAt].compactMap { $0 }
                return (current.isEmpty || current.contains { $0 >= today }) && words.contains { text.contains($0) }
            }.prefix(4))
            projects = Array(allProjects.filter { project in
                let text = "\(project.title) \(project.summary) \(project.category) " + project.roles.map { "\($0.title) \($0.skills)" }.joined(separator: " ")
                return project.roles.contains { $0.isOpen ?? true } && words.contains { text.lowercased().contains($0) }
            }.prefix(4))
            error = nil
            searched = true
        } catch { self.error = error.localizedDescription; searched = false }
    }
}
