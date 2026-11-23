import SwiftUI

struct InviteFriendView: View {
    let opportunityID: UUID
    let token: String
    @State private var friends: [FriendDTO] = []
    @State private var invited: Set<UUID> = []
    @State private var sending: UUID?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        NavigationStack {
            List(friends) { friend in
                HStack {
                    Text(friend.name)
                    Spacer()
                    Button(invited.contains(friend.userID) ? "Отправлено" : "Пригласить") {
                        Task { await invite(friend) }
                    }
                    .disabled(invited.contains(friend.userID) || sending != nil)
                }
            }
            .overlay {
                if isLoading { ProgressView() }
                else if friends.isEmpty && error == nil {
                    ContentUnavailableView("Пока нет друзей", systemImage: "person.2", description: Text("Добавьте друзей в разделе «Сообщество»."))
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let error { Text(error).font(.footnote).foregroundStyle(.red).padding() }
            }
            .navigationTitle("Пригласить друга")
            .task { await load() }
        }
    }

    private func load() async {
        defer { isLoading = false }
        do {
            let response: [FriendDTO] = try await APIClient.shared.send(path: "friends", token: token)
            friends = response.filter { $0.status == "friends" }
            error = nil
        } catch { self.error = error.localizedDescription }
    }

    private func invite(_ friend: FriendDTO) async {
        sending = friend.userID
        defer { sending = nil }
        do {
            let _: EmptyResponse = try await APIClient.shared.send(path: "opportunities/\(opportunityID)/invite/\(friend.userID)", method: "POST", token: token)
            invited.insert(friend.userID)
            error = nil
        } catch { self.error = error.localizedDescription }
    }
}
