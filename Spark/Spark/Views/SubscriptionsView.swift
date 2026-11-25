import SwiftUI
import Observation

struct FollowDTO: Decodable, Identifiable {
    let id: UUID
    let kind: String
    let value: String
    let label: String
}

private struct FollowRequest: Encodable {
    let kind: String
    let value: String
}

struct FollowFeedDTO: Decodable {
    let opportunities: [OpportunityDTO]
    let projects: [ProjectDTO]
}

@MainActor
@Observable
final class SubscriptionStore {
    var follows: [FollowDTO] = []
    var feed: FollowFeedDTO?
    var opportunities: [OpportunityDTO] = []
    var projects: [ProjectDTO] = []
    var organizations: [OrganizationDTO] = []
    var currentUserID: UUID?
    var isLoading = false
    var isSaving = false
    var error: String?
    let token: String

    init(token: String) { self.token = token }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let followsResponse: [FollowDTO] = APIClient.shared.send(path: "follows", token: token)
            async let feedResponse: FollowFeedDTO = APIClient.shared.send(path: "follows/feed", token: token)
            async let opportunitiesResponse: [OpportunityDTO] = APIClient.shared.send(path: "opportunities")
            async let projectsResponse: [ProjectDTO] = APIClient.shared.send(path: "projects")
            async let profileResponse: ProfileDTO = APIClient.shared.send(path: "profile/me", token: token)
            async let organizationResponse: [OrganizationDTO] = APIClient.shared.send(path: "organizations")
            let (loadedFollows, loadedFeed, loadedOpportunities, loadedProjects, profile, loadedOrganizations) = try await (followsResponse, feedResponse, opportunitiesResponse, projectsResponse, profileResponse, organizationResponse)
            (follows, feed, opportunities, projects) = (loadedFollows, loadedFeed, loadedOpportunities, loadedProjects)
            organizations = loadedOrganizations
            currentUserID = profile.id
            error = nil
        } catch { self.error = error.localizedDescription }
    }

    func follow(kind: String, value: String) async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let _: FollowDTO = try await APIClient.shared.send(path: "follows", method: "POST", body: FollowRequest(kind: kind, value: value), token: token)
            await load()
        } catch { self.error = error.localizedDescription }
    }

    func remove(_ follow: FollowDTO) async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let _: EmptyResponse = try await APIClient.shared.send(path: "follows/\(follow.id)", method: "DELETE", token: token)
            await load()
        } catch { self.error = error.localizedDescription }
    }

    func isFollowing(kind: String, value: String) -> Bool {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return follows.contains { $0.kind == kind && $0.value == normalized }
    }
}

struct SubscriptionHighlights: View {
    let token: String
    let refreshID: UUID
    @State private var store: SubscriptionStore

    init(token: String, refreshID: UUID) {
        self.token = token
        self.refreshID = refreshID
        _store = State(initialValue: SubscriptionStore(token: token))
    }

    var body: some View {
        if let feed = store.feed, !feed.opportunities.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("По твоим подпискам").font(.title3.bold())
                ForEach(Array(feed.opportunities.prefix(3)), id: \.id) { item in
                    NavigationLink {
                        OpportunityDetailsView(opportunity: item.makeOpportunity(), accessToken: token)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title).font(.headline)
                            Text(item.deadline.map { "Дедлайн: \($0)" } ?? item.organizer)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .task(id: refreshID) { await store.load() }
        } else {
            Color.clear.frame(height: 0).task(id: refreshID) { await store.load() }
        }
    }
}

struct SubscriptionsView: View {
    let token: String
    @Environment(\.dismiss) private var dismiss
    @State private var store: SubscriptionStore
    @State private var projectStore: ProjectStore
    @State private var newTopic = ""

    init(token: String) {
        self.token = token
        _store = State(initialValue: SubscriptionStore(token: token))
        _projectStore = State(initialValue: ProjectStore(token: token))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Выбирай темы, организаторов и проекты — подходящие возможности появятся здесь.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text("Пока без push-уведомлений. Организаторы определяются по названию в карточке события.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("Темы") {
                    HStack {
                        TextField("Например, EdTech или хакатоны", text: $newTopic)
                        Button("Добавить") {
                            let topic = newTopic.trimmingCharacters(in: .whitespacesAndNewlines)
                            Task { await store.follow(kind: "topic", value: topic); if store.error == nil { newTopic = "" } }
                        }
                        .disabled(newTopic.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 || store.isSaving)
                    }
                    ForEach(store.follows.filter { $0.kind == "topic" }) { follow in
                        followRow(follow)
                    }
                }

                Section("Подтверждённые организации") {
                    if store.organizations.isEmpty { Text("Организаций пока нет.").foregroundStyle(.secondary) }
                    ForEach(store.organizations) { organization in
                        selectableRow(title: organization.name, kind: "organization", value: organization.id.uuidString)
                    }
                }
                Section("Организаторы по названию события") {
                    let organizers = Array(Set(store.opportunities.map(\.organizer))).sorted()
                    if organizers.isEmpty { Text("Организаторы появятся вместе с событиями.").foregroundStyle(.secondary) }
                    ForEach(organizers, id: \.self) { organizer in
                        selectableRow(title: organizer, kind: "organizer", value: organizer)
                    }
                    ForEach(store.follows.filter { $0.kind == "organizer" && !organizers.contains($0.label) }) { follow in
                        followRow(follow)
                    }
                }

                Section("Проекты") {
                    if store.projects.isEmpty { Text("Проектов пока нет.").foregroundStyle(.secondary) }
                    ForEach(store.projects, id: \.id) { project in
                        if let id = project.id {
                            selectableRow(title: project.title, kind: "project", value: id.uuidString)
                        }
                    }
                }

                Section("Лента подписок") {
                    if let feed = store.feed {
                        if feed.opportunities.isEmpty && feed.projects.isEmpty {
                            Text("Пока ничего не найдено. Попробуй выбрать другие темы или организаторов.")
                                .foregroundStyle(.secondary)
                        }
                        ForEach(feed.opportunities, id: \.id) { item in
                            NavigationLink {
                                OpportunityDetailsView(opportunity: item.makeOpportunity(), accessToken: token)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title).font(.headline)
                                    Text(item.deadline.map { "Дедлайн: \($0)" } ?? item.organizer)
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        ForEach(feed.projects, id: \.id) { item in
                            let project = item.makeProject()
                            NavigationLink {
                                SubscribedProjectView(project: project, store: projectStore, currentUserID: store.currentUserID)
                            } label: {
                                Label(project.title, systemImage: "person.3")
                            }
                        }
                    } else if store.isLoading { ProgressView() }
                }
                if let error = store.error {
                    Section { Text(error).foregroundStyle(.red); Button("Повторить") { Task { await store.load() } } }
                }
            }
            .navigationTitle("Подписки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Готово") { dismiss() } } }
            .task { await store.load() }
            .refreshable { await store.load() }
        }
    }

    private func followRow(_ follow: FollowDTO) -> some View {
        HStack {
            Text(follow.label)
            Spacer()
            Button("Отписаться") { Task { await store.remove(follow) } }
                .font(.caption).disabled(store.isSaving)
        }
    }

    private func selectableRow(title: String, kind: String, value: String) -> some View {
        let follow = store.follows.first { $0.kind == kind && $0.value == value.lowercased() }
        return HStack {
            Text(title)
            Spacer()
            Button(follow == nil ? "Подписаться" : "Отписаться") {
                Task {
                    if let follow { await store.remove(follow) }
                    else { await store.follow(kind: kind, value: value) }
                }
            }
            .font(.caption).disabled(store.isSaving)
        }
    }
}

struct SubscribedProjectView: View {
    let project: Project
    let store: ProjectStore
    let currentUserID: UUID?
    @State private var showReport = false

    var body: some View {
        let current = store.projects.first { $0.id == project.id } ?? project
        List {
            Section("О проекте") {
                Text(current.summary)
                Label(current.ownerRole, systemImage: "person")
            }
            Section("Роли") {
                ForEach(current.vacancies) { role in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(role.title).font(.headline)
                        Text(role.roleDescription).foregroundStyle(.secondary)
                        if project.ownerID != currentUserID {
                        Button(role.isActive ? "Откликнуться" : role.status) {
                            Task { await store.join(projectID: project.id, vacancyID: role.id) }
                        }.disabled(!role.isActive)
                        }
                    }
                }
            }
            if let error = store.errorMessage { Text(error).foregroundStyle(.red) }
            if project.ownerID != currentUserID, store.reportToken != nil {
                Button("Пожаловаться на проект") { showReport = true }
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await store.load() }
        .sheet(isPresented: $showReport) {
            if let token = store.reportToken { ContentReportView(token: token, kind: "project", targetID: project.id) }
        }
    }
}
