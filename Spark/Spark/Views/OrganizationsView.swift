import SwiftUI

struct OrganizationDTO: Decodable, Identifiable {
    let id: UUID
    let name: String
    let region: String
    let bio: String
}

struct OrganizationPageCheck: Decodable { let id: UUID }

private struct OrganizationDetailDTO: Decodable {
    let id: UUID
    let name: String
    let region: String
    let bio: String
    let events: [OpportunityDTO]
}

private struct OrganizationFollowRequest: Encodable {
    let kind = "organization"
    let value: String
}

struct OrganizationsView: View {
    let token: String?
    @Environment(\.dismiss) private var dismiss
    @State private var organizations: [OrganizationDTO] = []
    @State private var search = ""
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            List {
                if loading { ProgressView() }
                if let error { Text(error).foregroundStyle(.red); Button("Повторить") { Task { await load() } } }
                let results = organizations.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || $0.region.localizedCaseInsensitiveContains(search) }
                if results.isEmpty && !loading && error == nil {
                    Text("Подтверждённых организаций пока не найдено.").foregroundStyle(.secondary)
                }
                ForEach(results) { organization in
                    NavigationLink {
                        OrganizationDetailsView(id: organization.id, token: token)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Label(organization.name, systemImage: "building.2")
                            if !organization.region.isEmpty { Text(organization.region).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                }
            }
            .navigationTitle("Организации")
            .searchable(text: $search, prompt: "Название или регион")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Готово") { dismiss() } } }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do { organizations = try await APIClient.shared.send(path: "organizations"); error = nil }
        catch { self.error = error.localizedDescription }
    }
}

struct OrganizationDetailsView: View {
    let id: UUID
    let token: String?
    @State private var organization: OrganizationDetailDTO?
    @State private var follow: FollowDTO?
    @State private var error: String?
    @State private var saving = false

    var body: some View {
        List {
            if let organization {
                Section {
                    Text(organization.name).font(.title2.bold())
                    if !organization.region.isEmpty { Label(organization.region, systemImage: "mappin") }
                    if !organization.bio.isEmpty { Text(organization.bio) }
                    Label("Подтверждена администратором Spark", systemImage: "checkmark.seal")
                        .font(.footnote).foregroundStyle(.secondary)
                    if token != nil {
                        Button(follow == nil ? "Подписаться" : "Отписаться") { Task { await toggleFollow() } }
                            .disabled(saving)
                    }
                }
                let today = Date().formatted(.iso8601.year().month().day())
                let upcoming = organization.events.filter { ($0.endsAt ?? $0.startsAt).map { $0 >= today } ?? false }
                let past = organization.events.filter { ($0.endsAt ?? $0.startsAt).map { $0 < today } ?? false }
                let undated = organization.events.filter { $0.startsAt == nil && $0.endsAt == nil }
                Section("Предстоящие и текущие") {
                    if upcoming.isEmpty { Text("Пока нет событий.").foregroundStyle(.secondary) }
                    ForEach(upcoming, id: \.id) { event in eventLink(event) }
                }
                Section("Прошедшие") {
                    if past.isEmpty { Text("Пока нет событий.").foregroundStyle(.secondary) }
                    ForEach(past, id: \.id) { event in eventLink(event) }
                }
                if !undated.isEmpty {
                    Section("Дата не указана") { ForEach(undated, id: \.id) { event in eventLink(event) } }
                }
            } else if error == nil { ProgressView() }
            if let error { Text(error).foregroundStyle(.red); Button("Повторить") { Task { await load() } } }
        }
        .navigationTitle("Организация")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func eventLink(_ item: OpportunityDTO) -> some View {
        NavigationLink {
            OpportunityDetailsView(opportunity: item.makeOpportunity(), accessToken: token)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                if let date = item.startsAt { Text(date).font(.caption).foregroundStyle(.secondary) }
            }
        }
    }

    private func load() async {
        do {
            organization = try await APIClient.shared.send(path: "organizations/\(id)")
            if let token {
                let follows: [FollowDTO] = try await APIClient.shared.send(path: "follows", token: token)
                follow = follows.first { $0.kind == "organization" && $0.value == id.uuidString.lowercased() }
            }
            error = nil
        } catch { self.error = error.localizedDescription }
    }

    private func toggleFollow() async {
        guard let token else { return }
        saving = true
        defer { saving = false }
        do {
            if let follow {
                let _: EmptyResponse = try await APIClient.shared.send(path: "follows/\(follow.id)", method: "DELETE", token: token)
                self.follow = nil
            } else {
                follow = try await APIClient.shared.send(path: "follows", method: "POST", body: OrganizationFollowRequest(value: id.uuidString), token: token)
            }
            error = nil
        } catch { self.error = error.localizedDescription }
    }
}
