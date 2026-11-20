import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import VisionKit

struct SocialView: View {
    let store: SocialStore
    let currentUserID: UUID?

    @State private var showScanner = false
    @State private var showManualEntry = false
    @State private var profileLink = ""
    @State private var selectedProfile: ScannedProfile?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    if let currentUserID {
                        ProfileShareCard(
                            profileID: currentUserID,
                            onScan: { showScanner = true },
                            onEnterLink: { showManualEntry = true }
                        )
                    }

                    if !store.incomingRequests.isEmpty {
                        IncomingRequestsSection(
                            requests: store.incomingRequests,
                            onAccept: { request in
                                Task { await store.acceptFriendship(request) }
                            },
                            onDecline: { request in
                                Task { await store.removeFriendship(request) }
                            }
                        )
                    }

                    FriendsSection(
                        friends: store.acceptedFriends,
                        onOpen: { friend in
                            selectedProfile = ScannedProfile(id: friend.userID)
                        },
                        onRemove: { friend in
                            Task { await store.removeFriendship(friend) }
                        }
                    )

                    ChatsSection(chats: store.chats, store: store, currentUserID: currentUserID)
                }
                .padding()
            }
            .navigationTitle("Сообщество")
            .overlay {
                if store.isLoading && store.friends.isEmpty && store.chats.isEmpty {
                    ProgressView()
                }
            }
            .refreshable {
                await store.load()
            }
            .task {
                await store.load()
            }
            .sheet(isPresented: $showScanner) {
                ProfileCodeScanner { value in
                    showScanner = false
                    if let id = store.profileID(from: value) {
                        selectedProfile = ScannedProfile(id: id)
                    } else {
                        store.errorMessage = "QR-код не содержит ссылку на профиль Spark."
                    }
                }
            }
            .alert("Открыть профиль", isPresented: $showManualEntry) {
                TextField("Ссылка или ID профиля", text: $profileLink)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Открыть") {
                    if let id = store.profileID(from: profileLink) {
                        selectedProfile = ScannedProfile(id: id)
                    }
                    profileLink = ""
                }
                Button("Отмена", role: .cancel) {
                    profileLink = ""
                }
            } message: {
                Text("Вставьте ссылку Spark или идентификатор профиля.")
            }
            .sheet(item: $selectedProfile) { profile in
                PublicProfileView(
                    profileID: profile.id,
                    currentUserID: currentUserID,
                    store: store
                )
            }
        }
    }
}

private struct ScannedProfile: Identifiable {
    let id: UUID
}

private struct ProfileShareCard: View {
    let profileID: UUID
    let onScan: () -> Void
    let onEnterLink: () -> Void

    private var profileURL: URL {
        URL(string: "spark://profile/\(profileID.uuidString)")!
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Мой профиль")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            if let image = QRCodeGenerator.image(for: profileURL.absoluteString) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 170, height: 170)
                    .accessibilityLabel("QR-код профиля")
            }

            Text("Покажите QR-код, чтобы вас добавили в друзья.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack {
                ShareLink(item: profileURL) {
                    Label("Поделиться", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)

                Button(action: onScan) {
                    Label("Сканировать", systemImage: "qrcode.viewfinder")
                }
                .buttonStyle(.bordered)
            }

            Button("Ввести ссылку вручную", action: onEnterLink)
                .font(.footnote)
        }
        .padding(20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24))
    }
}

private struct IncomingRequestsSection: View {
    let requests: [FriendDTO]
    let onAccept: (FriendDTO) -> Void
    let onDecline: (FriendDTO) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Заявки в друзья")
                .font(.title3.bold())

            ForEach(requests) { request in
                VStack(alignment: .leading, spacing: 10) {
                    Text(request.name)
                        .font(.headline)
                    if !request.region.isEmpty {
                        Text(request.region)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Button("Принять") { onAccept(request) }
                            .buttonStyle(.borderedProminent)
                        Button("Отклонить", role: .destructive) { onDecline(request) }
                            .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct FriendsSection: View {
    let friends: [FriendDTO]
    let onOpen: (FriendDTO) -> Void
    let onRemove: (FriendDTO) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Друзья")
                .font(.title3.bold())

            if friends.isEmpty {
                ContentUnavailableView(
                    "Пока нет друзей",
                    systemImage: "person.2",
                    description: Text("Поделитесь QR-кодом или отсканируйте профиль друга.")
                )
            } else {
                ForEach(friends) { friend in
                    Button {
                        onOpen(friend)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.primaryLitePurple)
                            VStack(alignment: .leading) {
                                Text(friend.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(friend.region.isEmpty ? "Регион не указан" : friend.region)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Удалить из друзей", role: .destructive) {
                            onRemove(friend)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ChatsSection: View {
    let chats: [ChatDTO]
    let store: SocialStore
    let currentUserID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Проектные чаты")
                .font(.title3.bold())

            if chats.isEmpty {
                ContentUnavailableView(
                    "Чатов пока нет",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Чат появится автоматически, когда все роли проекта будут заняты.")
                )
            } else {
                ForEach(chats) { chat in
                    NavigationLink {
                        ProjectChatView(chat: chat, store: store, currentUserID: currentUserID)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.title2)
                                .foregroundStyle(.primaryLitePurple)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(chat.projectTitle)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(chat.lastMessage ?? "\(chat.memberCount) участников")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PublicProfileView: View {
    @Environment(\.dismiss) private var dismiss

    let profileID: UUID
    let currentUserID: UUID?
    let store: SocialStore

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile = store.viewedProfile, profile.id == profileID {
                    VStack(spacing: 20) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 90))
                            .foregroundStyle(.primaryLitePurple)

                        Text(profile.name)
                            .font(.title.bold())
                        if !profile.region.isEmpty {
                            Label(profile.region, systemImage: "mappin")
                                .foregroundStyle(.secondary)
                        }
                        if !profile.bio.isEmpty {
                            Text(profile.bio)
                                .multilineTextAlignment(.center)
                        }

                        ProfileTagCloud(title: "Навыки", values: profile.skills)
                        ProfileTagCloud(title: "Интересы", values: profile.interests)

                        friendshipAction(profile)
                    }
                    .padding(24)
                } else {
                    ProgressView("Загружаем профиль…")
                        .padding(.top, 80)
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
            .task {
                await store.loadProfile(id: profileID)
            }
        }
    }

    @ViewBuilder
    private func friendshipAction(_ profile: PublicProfileDTO) -> some View {
        switch profile.friendshipStatus {
        case "none":
            Button {
                Task { _ = await store.requestFriend(profileID: profile.id) }
            } label: {
                Label("Добавить в друзья", systemImage: "person.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        case "pending_sent":
            Label("Заявка отправлена", systemImage: "clock")
                .foregroundStyle(.secondary)
        case "pending_received":
            Text("Заявка ожидает ответа в разделе «Сообщество».")
                .foregroundStyle(.secondary)
        case "friends":
            Label("У вас в друзьях", systemImage: "person.2.fill")
                .foregroundStyle(.green)
        default:
            EmptyView()
        }
    }
}

private struct ProfileTagCloud: View {
    let title: String
    let values: [String]

    var body: some View {
        if !values.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                Text(values.formatted())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ProjectChatView: View {
    let chat: ChatDTO
    let store: SocialStore
    let currentUserID: UUID?

    @State private var messageText = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(store.messages) { message in
                            MessageBubble(
                                senderName: message.senderName,
                                text: message.text,
                                isCurrentUser: message.senderID == currentUserID
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: store.messages.count) {
                    if let lastID = store.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                TextField("Сообщение", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                Button {
                    let text = messageText
                    messageText = ""
                    Task {
                        if !(await store.sendMessage(chatID: chat.id, text: text)) {
                            messageText = text
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(.bar)
        }
        .navigationTitle(chat.projectTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            while !Task.isCancelled {
                await store.loadMessages(chatID: chat.id)
                try? await Task.sleep(for: .seconds(3))
            }
        }
    }
}

private struct MessageBubble: View {
    let senderName: String
    let text: String
    let isCurrentUser: Bool

    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 3) {
            if !isCurrentUser {
                Text(senderName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .foregroundStyle(isCurrentUser ? .white : .primary)
                .background(
                    isCurrentUser ? Color.primaryLitePurple : Color.secondary.opacity(0.16),
                    in: RoundedRectangle(cornerRadius: 16)
                )
        }
        .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
    }
}

private enum QRCodeGenerator {
    static func image(for value: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(value.utf8)
        filter.correctionLevel = "M"
        let context = CIContext()
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
              let cgImage = context.createCGImage(output, from: output.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

private struct ProfileCodeScanner: UIViewControllerRepresentable {
    let onCode: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCode: onCode)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        guard DataScannerViewController.isSupported,
              DataScannerViewController.isAvailable else {
            return UIHostingController(
                rootView: ContentUnavailableView(
                    "Сканер недоступен",
                    systemImage: "qrcode.viewfinder",
                    description: Text("Используйте ввод ссылки вручную.")
                )
            )
        }

        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        try? controller.startScanning()
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onCode: (String) -> Void

        init(onCode: @escaping (String) -> Void) {
            self.onCode = onCode
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            for item in addedItems {
                if case let .barcode(barcode) = item,
                   let value = barcode.payloadStringValue {
                    dataScanner.stopScanning()
                    onCode(value)
                    return
                }
            }
        }
    }
}
