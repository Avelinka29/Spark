import SwiftUI

struct MainTabView: View {
    @State private var showCreateProject = false
    @State private var selectedTab = 0
    @State private var projectStore: ProjectStore
    @State private var profileStore: ProfileStore
    @State private var showAuthenticationRequired = false

    private let accessToken: String?
    private let isBiometricEnabled: Bool
    private let canUseBiometrics: Bool
    private let onBiometricChange: (Bool) async -> Bool
    private let onLogout: () -> Void

    init(
        accessToken: String? = nil,
        isBiometricEnabled: Bool = false,
        canUseBiometrics: Bool = false,
        onBiometricChange: @escaping (Bool) async -> Bool = { _ in false },
        onLogout: @escaping () -> Void = {}
    ) {
        self.accessToken = accessToken
        self.isBiometricEnabled = isBiometricEnabled
        self.canUseBiometrics = canUseBiometrics
        self.onBiometricChange = onBiometricChange
        self.onLogout = onLogout
        _projectStore = State(initialValue: ProjectStore(token: accessToken))
        _profileStore = State(initialValue: ProfileStore(token: accessToken))
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView(
                    accessToken: accessToken,
                    avatarImage: profileStore.avatarImage,
                    profileName: profileStore.profile?.name,
                    onAvatarTap: {
                        if accessToken == nil {
                            onLogout()
                        } else {
                            selectedTab = 3
                        }
                    }
                )
                    .tabItem {
                        Label("Лента", systemImage: "house")
                    }
                    .tag(0)

                MapView(accessToken: accessToken)
                    .tabItem {
                        Label("Карта", systemImage: "map")
                    }
                    .tag(1)

                ProjectView(
                    store: projectStore,
                    currentUserID: profileStore.profile?.id
                )
                    .tabItem {
                        Label("Проекты", systemImage: "folder")
                    }
                    .tag(2)

                ProfileView(
                    store: profileStore,
                    isBiometricEnabled: isBiometricEnabled,
                    canUseBiometrics: canUseBiometrics,
                    onBiometricChange: onBiometricChange,
                    onLogout: onLogout
                )
                    .tabItem {
                        Label("Профиль", systemImage: "person")
                    }
                    .tag(3)
            }

            if selectedTab == 0 || selectedTab == 2 {
                VStack {
                    Spacer()

                    Button {
                        if accessToken == nil {
                            showAuthenticationRequired = true
                        } else {
                            showCreateProject = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 25, weight: .medium))
                            .foregroundStyle(.primaryWhite)
                            .frame(width: 55, height: 55)
                            .background(.primaryLitePurple)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
                    }
                    .accessibilityLabel("Создать проект")
                    .padding(.bottom, 55)
                    .transition(.scale)
                }
                .animation(.spring(), value: selectedTab)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await profileStore.load()
        }
        .sheet(isPresented: $showCreateProject) {
            CreateProjectView(store: projectStore)
        }
        .alert("Нужна авторизация", isPresented: $showAuthenticationRequired) {
            Button("Понятно", role: .cancel) {}
        } message: {
            Text("Войдите в аккаунт, чтобы создавать проекты.")
        }
    }
}

#Preview {
    MainTabView()
}
