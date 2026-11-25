import SwiftUI

struct SavedOpportunitiesView: View {
    let token: String
    @Environment(\.dismiss) private var dismiss
    @State private var items: [OpportunityDTO] = []
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            List {
                if loading { ProgressView() }
                if items.isEmpty && !loading && error == nil { Text("Сохранённых событий пока нет.").foregroundStyle(.secondary) }
                ForEach(items, id: \.id) { item in
                    NavigationLink(item.title) { OpportunityDetailsView(opportunity: item.makeOpportunity(), accessToken: token) }
                }
                if let error { Text(error).foregroundStyle(.red); Button("Повторить") { Task { await load() } } }
            }
            .navigationTitle("Сохранённое")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Готово") { dismiss() } } }
            .onAppear { Task { await load() } }
            .refreshable { await load() }
        }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do { items = try await APIClient.shared.send(path: "bookmarks", token: token); error = nil }
        catch { self.error = error.localizedDescription }
    }
}
