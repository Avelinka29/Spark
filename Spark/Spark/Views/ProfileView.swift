import SwiftUI

struct ProfileView: View {
    let store: ProfileStore
    let isBiometricEnabled: Bool
    let canUseBiometrics: Bool
    let onBiometricChange: (Bool) async -> Bool
    let onLogout: () -> Void
    let onOpportunityCreated: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if let profile = store.profile {
                    ProfileContent(
                        profile: profile,
                        store: store,
                        avatarImage: store.avatarImage,
                        canEditAvatar: store.isAuthenticated,
                        onAvatarSelected: store.updateAvatar,
                        onAddAchievement: store.addAchievement,
                        onDeleteAchievement: store.deleteAchievement,
                        onUpdateProfile: store.updateProfile,
                        onEnableOrganization: store.enableOrganization,
                        onCreateOpportunity: store.createOpportunity,
                        onOpportunityCreated: onOpportunityCreated,
                        onDeleteAccount: store.deleteAccount,
                        isBiometricEnabled: isBiometricEnabled,
                        canUseBiometrics: canUseBiometrics,
                        onBiometricChange: onBiometricChange,
                        onLogout: onLogout
                    )
                } else if store.isLoading {
                    ProgressView("Загружаем профиль…")
                } else {
                    VStack(spacing: 16) {
                        ContentUnavailableView(
                            "Профиль недоступен",
                            systemImage: "person.crop.circle.badge.exclamationmark",
                            description: Text(store.errorMessage ?? "Не удалось загрузить данны.")
                        )

                        Button("Повторить") {
                            Task {
                                await store.load()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await store.load()
            }
        }
    }
}

private struct ProfileContent: View {
    let profile: UserProfile
    let store: ProfileStore
    let avatarImage: UIImage?
    let canEditAvatar: Bool
    let onAvatarSelected: (Data) -> Void
    let onAddAchievement: (String, String, Date) async -> Bool
    let onDeleteAchievement: (UUID) async -> Void
    let onUpdateProfile: (String, String, String, [String], [String]) async -> Bool
    let onEnableOrganization: (String) async -> Bool
    let onCreateOpportunity: (OpportunityCreateRequest) async -> Bool
    let onOpportunityCreated: () -> Void
    let onDeleteAccount: () async -> Bool
    let isBiometricEnabled: Bool
    let canUseBiometrics: Bool
    let onBiometricChange: (Bool) async -> Bool
    let onLogout: () -> Void

    @State private var showSettings = false
    @State private var showAchievementForm = false
    @State private var showProfileEditor = false
    @State private var showOrganizationSetup = false
    @State private var showOpportunityCreator = false
    @State private var showEventProposal = false
    @State private var showAdminProposals = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ProfileHeader(
                    avatarImage: avatarImage,
                    canEditAvatar: canEditAvatar,
                    onAvatarSelected: onAvatarSelected,
                    onSettings: { showSettings = true }
                )

                ProfileIdentitySection(
                    name: profile.name,
                    region: profile.region,
                    bio: profile.bio
                )

                if canEditAvatar {
                    Button {
                        showProfileEditor = true
                    } label: {
                        Label("Редактировать профиль", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal, 24)
                }

                OrganizationActionsSection(
                    accountType: profile.accountType,
                    organizationName: profile.organizationName,
                    onSetup: { showOrganizationSetup = true },
                    onCreateOpportunity: { showOpportunityCreator = true },
                    onProposeEvent: { showEventProposal = true },
                    onReviewProposals: { showAdminProposals = true }
                )

                ProfileTagsSection(title: "Навыки", tags: profile.skills)
                ProfileTagsSection(title: "Интересы", tags: profile.interests)
                AchievementSection(
                    achievements: profile.achievements,
                    canEdit: canEditAvatar,
                    onAdd: { showAchievementForm = true },
                    onDelete: onDeleteAchievement
                )
            }
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $showSettings) {
            ProfileSettingsView(
                isBiometricEnabled: isBiometricEnabled,
                canUseBiometrics: canUseBiometrics,
                onBiometricChange: onBiometricChange,
                onDeleteAccount: onDeleteAccount
            ) {
                showSettings = false

                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(350))
                    onLogout()
                }
            }
        }
        .sheet(isPresented: $showAchievementForm) {
            AchievementForm { title, issuer, date in
                let saved = await onAddAchievement(title, issuer, date)
                if saved {
                    showAchievementForm = false
                }
                return saved
            }
        }
        .sheet(isPresented: $showOrganizationSetup) {
            OrganizationSetupView(onSave: onEnableOrganization)
        }
        .sheet(isPresented: $showOpportunityCreator) {
            OpportunityCreateView { request in
                let saved = await onCreateOpportunity(request)
                if saved { onOpportunityCreated() }
                return saved
            }
        }
        .sheet(isPresented: $showEventProposal) {
            EventProposalView(onSend: store.proposeEvent)
        }
        .sheet(isPresented: $showAdminProposals) {
            AdminEventProposalsView(store: store, onApproved: onOpportunityCreated)
        }
        .sheet(isPresented: $showProfileEditor) {
            ProfileEditView(profile: profile) { name, region, bio, skills, interests in
                let saved = await onUpdateProfile(name, region, bio, skills, interests)
                if saved {
                    showProfileEditor = false
                }
                return saved
            }
        }
    }
}

private struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (String, String, String, [String], [String]) async -> Bool

    @State private var name: String
    @State private var region: String
    @State private var bio: String
    @State private var skillsText: String
    @State private var interestsText: String
    @State private var isSaving = false

    init(
        profile: UserProfile,
        onSave: @escaping (String, String, String, [String], [String]) async -> Bool
    ) {
        self.onSave = onSave
        _name = State(initialValue: profile.name)
        _region = State(initialValue: profile.region)
        _bio = State(initialValue: profile.bio)
        _skillsText = State(initialValue: profile.skills.joined(separator: ", "))
        _interestsText = State(initialValue: profile.interests.joined(separator: ", "))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Имя", text: $name)
                    TextField("Регион", text: $region)
                    TextField("О себе", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Навыки") {
                    TextField("Swift, дизайн, маркетинг", text: $skillsText, axis: .vertical)
                    Text("Разделяйте навыки запятыми.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Интересы") {
                    TextField("EdTech, стартапы, волонтёрство", text: $interestsText, axis: .vertical)
                    Text("Разделяйте интересы запятыми.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        isSaving = true
                        Task {
                            _ = await onSave(
                                name.trimmingCharacters(in: .whitespacesAndNewlines),
                                region.trimmingCharacters(in: .whitespacesAndNewlines),
                                bio.trimmingCharacters(in: .whitespacesAndNewlines),
                                commaSeparatedValues(skillsText),
                                commaSeparatedValues(interestsText)
                            )
                            isSaving = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 || isSaving)
                }
            }
        }
    }

    private func commaSeparatedValues(_ text: String) -> [String] {
        text.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    let onLogout: () -> Void
    let canUseBiometrics: Bool
    let onBiometricChange: (Bool) async -> Bool
    let onDeleteAccount: () async -> Bool

    @State private var isBiometricEnabled: Bool
    @State private var showDeleteConfirmation = false

    init(
        isBiometricEnabled: Bool,
        canUseBiometrics: Bool,
        onBiometricChange: @escaping (Bool) async -> Bool,
        onDeleteAccount: @escaping () async -> Bool,
        onLogout: @escaping () -> Void
    ) {
        _isBiometricEnabled = State(initialValue: isBiometricEnabled)
        self.canUseBiometrics = canUseBiometrics
        self.onBiometricChange = onBiometricChange
        self.onDeleteAccount = onDeleteAccount
        self.onLogout = onLogout
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if canUseBiometrics {
                    Toggle(isOn: $isBiometricEnabled) {
                        Label("Разблокировка Face ID", systemImage: "faceid")
                    }
                    .padding(.horizontal, 24)
                    .onChange(of: isBiometricEnabled) { _, enabled in
                        Task {
                            let succeeded = await onBiometricChange(enabled)
                            if !succeeded {
                                isBiometricEnabled.toggle()
                            }
                        }
                    }
                }

                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Label("Политика конфиденциальности", systemImage: "hand.raised")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal, 24)

                Spacer()

                Button(action: onLogout) {
                    Label("Выйти из аккаунта", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.horizontal, 24)

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Удалить аккаунт", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal, 24)

                Spacer()
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .confirmationDialog(
            "Аккаунт и все связанные данные будут удалены без возможности восстановления.",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Удалить аккаунт", role: .destructive) {
                Task {
                    if await onDeleteAccount() {
                        onLogout()
                    }
                }
            }
            Button("Отмена", role: .cancel) {}
        }
    }
}

private struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PrivacySection(
                    title: "Какие данные хранит Spark",
                    text: "Данные аккаунта и профиля, аватар, достижения, закладки, проекты, отклики и внутренние уведомления. При входе через Google Spark получает идентификатор, имя и подтверждённый email аккаунта."
                )
                PrivacySection(
                    title: "Для чего используются данные",
                    text: "Чтобы обеспечивать авторизацию, показывать профиль, сохранять выбранные возможности и поддерживать совместную работу над проектами. Spark не продаёт персональные данные."
                )
                PrivacySection(
                    title: "Хранение и защита",
                    text: "Данные профиля хранятся в базе Spark Backend. Токен сессии хранится в Keychain устройства. Пароли сохраняются только в виде защищённого хеша."
                )
                PrivacySection(
                    title: "Удаление данных",
                    text: "Аккаунт и связанные с ним данные можно удалить в настройках профиля. Это действие необратимо."
                )
                PrivacySection(
                    title: "Сторонние сервисы",
                    text: "Google Sign-In используется только по выбору пользователя и обрабатывается в соответствии с политикой конфиденциальности Google."
                )

                Text("Редакция от 15 ноября 2026 года")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .navigationTitle("Конфиденциальность")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PrivacySection: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProfileIdentitySection: View {
    let name: String
    let region: String
    let bio: String

    var body: some View {
        VStack(spacing: 10) {
            Text(name)
                .font(.title2.bold())

            if !region.isEmpty {
                Label(region, systemImage: "mappin.and.ellipse")
                    .foregroundStyle(.secondary)
            }

            if !bio.isEmpty {
                Text(bio)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }
}

private struct OrganizationActionsSection: View {
    let accountType: String
    let organizationName: String?
    let onSetup: () -> Void
    let onCreateOpportunity: () -> Void
    let onProposeEvent: () -> Void
    let onReviewProposals: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if accountType == "organization" || accountType == "admin" {
                Label(
                    accountType == "admin" ? "Администратор Spark" : (organizationName ?? "Организация"),
                    systemImage: accountType == "admin" ? "checkmark.shield.fill" : "building.2.fill"
                )
                .font(.title3.bold())

                Button(action: onCreateOpportunity) {
                    Label("Добавить мероприятие", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.primaryLitePurple)

                if accountType == "admin" {
                    Button(action: onReviewProposals) {
                        Label("Предложения пользователей", systemImage: "tray.full")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Button(action: onProposeEvent) {
                    Label("Предложить событие администратору", systemImage: "paperplane")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.primaryLitePurple)

                Button(action: onSetup) {
                    Label("Создать профиль организации", systemImage: "building.2")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal)
    }
}

private struct ProfileTagsSection: View {
    let title: String
    let tags: [String]

    var body: some View {
        if !tags.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.title3.bold())

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(.primaryLitePurple.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        }
    }
}

private struct AchievementSection: View {
    let achievements: [Achievement]
    let canEdit: Bool
    let onAdd: () -> Void
    let onDelete: (UUID) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Достижения")
                    .font(.title3.bold())
                Spacer()
                if canEdit {
                    Button(action: onAdd) {
                        Label("Добавить", systemImage: "plus")
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }

            if achievements.isEmpty {
                Text("Достижения появятся после участия в возможностях и проектах.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(achievements) { achievement in
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.primaryYellow)

                        VStack(alignment: .leading) {
                            Text(achievement.title)
                                .font(.headline)
                            Text(achievement.issuer)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(achievement.issuedAt, format: .dateTime.year())
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if canEdit {
                            Button(role: .destructive) {
                                Task { await onDelete(achievement.id) }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .padding(.horizontal)
    }
}

private struct AchievementForm: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (String, String, Date) async -> Bool

    @State private var title = ""
    @State private var issuer = ""
    @State private var issuedAt = Date()
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Название достижения", text: $title)
                TextField("Организатор", text: $issuer)
                DatePicker("Дата получения", selection: $issuedAt, displayedComponents: .date)
            }
            .navigationTitle("Новое достижение")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        Task {
                            isSaving = true
                            _ = await onSave(
                                title.trimmingCharacters(in: .whitespacesAndNewlines),
                                issuer.trimmingCharacters(in: .whitespacesAndNewlines),
                                issuedAt
                            )
                            isSaving = false
                        }
                    }
                    .disabled(
                        isSaving ||
                        title.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 ||
                        issuer.trimmingCharacters(in: .whitespacesAndNewlines).count < 2
                    )
                }
            }
        }
    }
}

#Preview {
    ProfileView(
        store: ProfileStore(token: nil),
        isBiometricEnabled: false,
        canUseBiometrics: true,
        onBiometricChange: { _ in true },
        onLogout: {},
        onOpportunityCreated: {}
    )
}
