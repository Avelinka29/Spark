import Foundation
import Observation
import SwiftUI

struct SparkNotification: Identifiable, Decodable, Equatable {
    let id: UUID
    let title: String
    let message: String
    var isRead: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, message
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

@MainActor
@Observable
final class NotificationStore {
    private(set) var notifications: [SparkNotification] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let token: String?

    init(token: String?) {
        self.token = token
    }

    var unreadCount: Int {
        notifications.count { !$0.isRead }
    }

    func load() async {
        guard let token else {
            notifications = []
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            notifications = try await APIClient.shared.send(
                path: "notifications",
                token: token
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markRead(_ notification: SparkNotification) async {
        guard let token, !notification.isRead else { return }

        do {
            let _: EmptyResponse = try await APIClient.shared.send(
                path: "notifications/\(notification.id)/read",
                method: "PATCH",
                token: token
            )
            guard let index = notifications.firstIndex(where: { $0.id == notification.id }) else {
                return
            }
            notifications[index].isRead = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct NotificationCenterView: View {
    let store: NotificationStore

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading && store.notifications.isEmpty {
                    ProgressView("Загружаем уведомления…")
                } else if store.notifications.isEmpty {
                    ContentUnavailableView(
                        "Уведомлений пока нет",
                        systemImage: "bell",
                        description: Text("Здесь появятся отклики и решения по заявкам.")
                    )
                } else {
                    List(store.notifications) { notification in
                        Button {
                            Task {
                                await store.markRead(notification)
                            }
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(notification.isRead ? Color.clear : Color.primaryLitePurple)
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 7)

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(notification.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(notification.message)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text(notification.createdAt, format: .relative(presentation: .named))
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .refreshable {
                        await store.load()
                    }
                }
            }
            .navigationTitle("Уведомления")
            .task {
                await store.load()
            }
        }
    }
}
