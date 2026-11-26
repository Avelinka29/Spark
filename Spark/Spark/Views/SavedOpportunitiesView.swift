import SwiftUI

struct SavedOpportunitiesView: View {
    let token: String
    @Environment(\.dismiss) private var dismiss
    @State private var items: [OpportunityDTO] = []
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SparkDiscoveryHero(title: "Сохранённое", subtitle: "События, к которым хочешь вернуться.", symbol: "bookmark")
                    if loading { ProgressView("Загружаем события…").frame(maxWidth: .infinity).padding() }
                    if items.isEmpty && !loading && error == nil {
                        SparkDiscoveryEmpty(title: "Пока ничего не сохранено", detail: "Открой событие и нажми на закладку, чтобы добавить его сюда.", symbol: "bookmark", actionTitle: "Открыть ленту") { dismiss() }
                    }
                    ForEach(items, id: \.id) { item in
                        NavigationLink {
                            OpportunityDetailsView(opportunity: item.makeOpportunity(), accessToken: token)
                        } label: {
                            HStack {
                                SparkTileIcon(symbol: "calendar")
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title).font(.headline).foregroundStyle(.primary)
                                    Text(item.organizer).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.secondary)
                            }.sparkCard()
                        }.buttonStyle(.plain)
                    }
                    if let error {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(error).foregroundStyle(.red)
                            Button("Повторить") { Task { await load() } }
                        }.sparkCard()
                    }
                }.padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Сохранённое")
            .navigationBarTitleDisplayMode(.inline)
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
