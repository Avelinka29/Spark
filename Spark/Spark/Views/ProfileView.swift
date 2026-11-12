import SwiftUI

struct ProfileView: View {
    let store: ProfileStore
    let isBiometricEnabled: Bool
    let canUseBiometrics: Bool
    let onBiometricChange: (Bool) async -> Bool
    let onLogout: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if let profile = store.profile {
                    ProfileContent(
                        profile: profile,
                        avatarImage: store.avatarImage,
                        canEditAvatar: store.isAuthenticated,
                        onAvatarSelected: store.updateAvatar,
                        onAddAchievement: store.addAchievement,
                        onDeleteAchievement: store.deleteAchievement,
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
    let avatarImage: UIImage?
    let canEditAvatar: Bool
    let onAvatarSelected: (Data) -> Void
    let onAddAchievement: (String, String, Date) async -> Bool
    let onDeleteAchievement: (UUID) async -> Void
    let isBiometricEnabled: Bool
    let canUseBiometrics: Bool
    let onBiometricChange: (Bool) async -> Bool
    let onLogout: () -> Void

    @State private var showSettings = false
    @State private var showAchievementForm = false

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
                onBiometricChange: onBiometricChange
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
    }
}

private struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    let onLogout: () -> Void
    let canUseBiometrics: Bool
    let onBiometricChange: (Bool) async -> Bool

    @State private var isBiometricEnabled: Bool

    init(
        isBiometricEnabled: Bool,
        canUseBiometrics: Bool,
        onBiometricChange: @escaping (Bool) async -> Bool,
        onLogout: @escaping () -> Void
    ) {
        _isBiometricEnabled = State(initialValue: isBiometricEnabled)
        self.canUseBiometrics = canUseBiometrics
        self.onBiometricChange = onBiometricChange
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
        onLogout: {}
    )
}
