import SwiftUI

struct OrganizationApplicationsView: View {
    let store: ProfileStore
    @State private var processingID: UUID?

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.organizationApplications) { application in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(application.organizationName).font(.headline)
                        Text(application.name)
                        Text(application.email).font(.subheadline).foregroundStyle(.secondary)
                        HStack {
                            Button("Подтвердить") { decide(application.id, approve: true) }
                                .buttonStyle(.borderedProminent)
                            Button("Отклонить", role: .destructive) { decide(application.id, approve: false) }
                                .buttonStyle(.bordered)
                        }
                        .disabled(processingID != nil)
                    }
                    .padding(.vertical, 6)
                }
            }
            .overlay {
                if store.organizationApplications.isEmpty && store.errorMessage == nil {
                    ContentUnavailableView("Заявок пока нет", systemImage: "tray")
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let error = store.errorMessage {
                    Text(error).font(.footnote).foregroundStyle(.red).padding().background(.regularMaterial)
                }
            }
            .navigationTitle("Заявки организаций")
            .task { await store.loadOrganizationApplications() }
            .refreshable { await store.loadOrganizationApplications() }
        }
    }

    private func decide(_ id: UUID, approve: Bool) {
        processingID = id
        Task {
            await store.decideOrganizationApplication(id: id, approve: approve)
            processingID = nil
        }
    }
}
