import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import VisionKit

struct SocialView: View {
    let store: SocialStore
    let currentUserID: UUID?
    let onSignIn: () -> Void

    @State private var showProfileCode = false
    @State private var showScanner = false
    @State private var showManualEntry = false
    @State private var profileLink = ""
    @State private var selectedProfile: ScannedProfile?
    @State private var showUsernameSearch = false
    @State private var usernameSearch = ""
    @State private var searchError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    if store.isAuthenticated {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Найти друзей")
                                .font(.title2.bold())
                            Button {
                                showUsernameSearch = true
                            } label: {
                                HStack {
                                    Label("Найти друга по нику", systemImage: "magnifyingglass")
                                    Spacer()
                                    Image(systemName: "arrow.right").accessibilityHidden(true)
                                }
                                .font(.subheadline.weight(.semibold))
                                .padding(14)
                                .foregroundStyle(Color(red: 0.16, green: 0.13, blue: 0.35))
                                .background(.white, in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                        .sparkHero()

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 10) { profileActions }
                            VStack(spacing: 10) { profileActions }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .tint(.primaryLitePurple)

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
                    } else {
                        GuestCommunityView(onSignIn: onSignIn)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Сообщество")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showProfileCode) {
                if let currentUserID {
                    NavigationStack {
                        ScrollView {
                            ProfileShareCard(profileID: currentUserID)
                                .padding(20)
                        }
                        .background(Color(.systemGroupedBackground))
                        .navigationTitle("Мой QR-код")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            Button("Готово") { showProfileCode = false }
                        }
                    }
                }
            }
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
                        store.reportError("QR-код не содержит ссылку на профиль Spark.")
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
            .alert("Найти друга", isPresented: $showUsernameSearch) {
                TextField("Ник", text: $usernameSearch).textInputAutocapitalization(.never).autocorrectionDisabled()
                Button("Найти") {
                    Task {
                        if let id = await store.findUsername(usernameSearch) {
                            selectedProfile = ScannedProfile(id: id)
                        } else {
                            searchError = store.errorMessage ?? "Не удалось выполнить поиск."
                        }
                    }
                }
                Button("Отмена", role: .cancel) {}
            } message: { Text("Введите точный ник пользователя.") }
            .alert("Поиск", isPresented: Binding(get: { searchError != nil }, set: { if !$0 { searchError = nil } })) {
                Button("Понятно", role: .cancel) {}
            } message: { Text(searchError ?? "") }
            .onChange(of: store.pendingProfileID) { _, profileID in
                guard let profileID else { return }
                selectedProfile = ScannedProfile(id: profileID)
                store.consumePendingProfile()
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

    @ViewBuilder
    private var profileActions: some View {
        if let currentUserID {
            Button {
                showProfileCode = true
            } label: {
                Label("Мой QR-код", systemImage: "qrcode")
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(maxWidth: .infinity)
            }
            Menu {
                Button("Сканировать QR-код", systemImage: "qrcode.viewfinder") { showScanner = true }
                Button("Ввести ссылку", systemImage: "link") { showManualEntry = true }
                Button("Открыть мой профиль", systemImage: "person.crop.circle") {
                    selectedProfile = ScannedProfile(id: currentUserID)
                }
            } label: {
                Label("Открыть профиль", systemImage: "person.crop.circle")
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct GuestCommunityView: View {
    let onSignIn: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.title)
                .accessibilityHidden(true)
            Text("Друзья и проектные чаты")
                .font(.title2.bold())
            Text("Войди, чтобы найти друзей по нику или QR-коду и общаться со своей командой.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.88))
            Button(action: onSignIn) {
                Text("Войти или зарегистрироваться")
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
}

private struct ScannedProfile: Identifiable {
    let id: UUID
}

private struct ProfileShareCard: View {
    let profileID: UUID
    private var profileURL: URL {
        URL(string: "spark://profile/\(profileID.uuidString)")!
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "qrcode")
                    .foregroundStyle(.primaryLitePurple)
                    .font(.title3)
                    .frame(width: 42, height: 42)
                    .background(Color.primaryLitePurple.opacity(0.1), in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Твой QR-код").font(.headline)
                    Text("Друзья смогут быстро найти твой профиль")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            if let image = QRCodeGenerator.image(for: profileURL.absoluteString) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityLabel("QR-код профиля")
            }

            ShareLink(item: profileURL) {
                Label("Поделиться ссылкой", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.primaryLitePurple)
        }
        .sparkCard(padding: 20)
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
                SparkEmptyRow(
                    title: "Пока нет друзей",
                    detail: "Найди друга по нику или поделись своим QR-кодом.",
                    symbol: "person.2"
                )
            } else {
                ForEach(friends) { friend in
                    Button {
                        onOpen(friend)
                    } label: {
                        HStack(spacing: 12) {
                            SparkTileIcon(symbol: "person.fill")
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
                    .sparkCard()
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
                SparkEmptyRow(
                    title: "Чатов пока нет",
                    detail: "Чат появится, когда все роли в твоём проекте будут заняты.",
                    symbol: "bubble.left.and.bubble.right"
                )
            } else {
                ForEach(chats) { chat in
                    NavigationLink {
                        ProjectChatView(chat: chat, store: store, currentUserID: currentUserID)
                    } label: {
                        HStack(spacing: 12) {
                            SparkTileIcon(symbol: "bubble.left.and.bubble.right.fill")
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
                        .sparkCard()
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
    @State private var showReport = false

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
                        if let username = profile.username {
                            Text("@\(username)").foregroundStyle(.secondary)
                        }
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

                        if !profile.portfolioVisible {
                            Text("Пользователь скрыл портфолио.").font(.footnote).foregroundStyle(.secondary)
                        }

                        if !profile.projects.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Проекты").font(.headline)
                                ForEach(profile.projects) { project in
                                    VStack(alignment: .leading) {
                                        Text(project.title).font(.subheadline.bold())
                                        Text(project.role).font(.caption).foregroundStyle(.secondary)
                                        if let value = project.resultURL, let url = URL(string: value), url.scheme == "https" {
                                            Link("Результат проекта", destination: url).font(.caption)
                                        }
                                    }
                                }
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if !profile.events.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Мероприятия").font(.headline)
                                ForEach(profile.events) { event in
                                    VStack(alignment: .leading, spacing: 3) {
                                        Label(event.title, systemImage: "calendar")
                                        Text(event.verified ? "Подтверждено организатором" : "Отмечено самостоятельно")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }

                        friendshipAction(profile)
                        if profile.id != currentUserID, store.reportToken != nil {
                            Button("Пожаловаться на профиль") { showReport = true }
                                .font(.footnote).foregroundStyle(.secondary)
                        }
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
            .sheet(isPresented: $showReport) {
                if let token = store.reportToken { ContentReportView(token: token, kind: "user", targetID: profileID) }
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
    @State private var showWorkspace = false

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
        .toolbar {
            Button { showWorkspace = true } label: { Image(systemName: "checklist") }
                .accessibilityLabel("Рабочее пространство команды")
        }
        .sheet(isPresented: $showWorkspace) {
            TeamWorkspaceView(chat: chat, store: store)
        }
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
