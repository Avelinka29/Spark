import SwiftUI

struct HomeView: View {
    let accessToken: String?
    var refreshID: UUID = UUID()
    let avatarImage: UIImage?
    let profileName: String?
    var interests: [String] = []
    let unreadNotificationCount: Int
    let onNotificationsTap: () -> Void
    let onAvatarTap: () -> Void

    @State private var model = OpportunitiesViewModel()
    @State private var showSubscriptions = false
    @State private var showGoalRoute = false
    @State private var showOrganizations = false
    @State private var showSaved = false
    @State private var subscriptionRefreshID = UUID()
    @State private var showSignInMessage = false

    private let categories = EventCategory.allCases

    private func homeShortcut(_ title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).font(.headline).foregroundStyle(color)
                    .frame(width: 36, height: 36).background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
                Text(title).font(.subheadline.bold()).foregroundStyle(.primary)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 105, alignment: .leading)
            .padding(14).background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        }.buttonStyle(.plain)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                HomeHeader(
                    isAuthenticated: accessToken != nil,
                    avatarImage: avatarImage,
                    profileName: profileName,
                    unreadNotificationCount: unreadNotificationCount,
                    onNotificationsTap: onNotificationsTap,
                    onTap: onAvatarTap
                )

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Открой для себя").font(.title3.bold())
                    Text("Организации, события и твои возможности")
                        .font(.subheadline).foregroundStyle(.secondary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                        homeShortcut("Организации", subtitle: "Найти и подписаться", icon: "building.2", color: .blue) { showOrganizations = true }
                        homeShortcut("Сохранённое", subtitle: "Твои события", icon: "bookmark", color: .orange) {
                            if accessToken == nil { showSignInMessage = true } else { showSaved = true }
                        }
                        homeShortcut("Подписки", subtitle: "Твоя лента", icon: "bell.badge", color: .purple) {
                            if accessToken == nil { showSignInMessage = true } else { showSubscriptions = true }
                        }
                        homeShortcut("Моя цель", subtitle: "Найти свой путь", icon: "map", color: .mint) {
                            if accessToken == nil { showSignInMessage = true } else { showGoalRoute = true }
                        }
                    }
                }.padding(.horizontal).padding(.vertical, 12)

                if let accessToken {
                    SubscriptionHighlights(token: accessToken, refreshID: subscriptionRefreshID)
                }

                let recommendations = OpportunityRecommendations.matching(model.opportunities, interests: interests)
                if !recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Для тебя").font(.title3.bold())
                        ForEach(recommendations.prefix(3)) { item in
                            NavigationLink {
                                OpportunityDetailsView(opportunity: item.opportunity, accessToken: accessToken)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.opportunity.title).font(.headline)
                                    Text(item.reason).font(.caption).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            }.buttonStyle(.plain)
                        }
                    }.padding(.horizontal)
                }

                LazyVStack(pinnedViews: [.sectionHeaders]) {
                    Section {
                        if model.visibleOpportunities.isEmpty {
                            ContentUnavailableView(
                                "Ничего не найдено",
                                systemImage: "sparkle.magnifyingglass",
                                description: Text("Измени запрос или выбери другую категорию.")
                            )
                            .padding(.top, 48)
                        } else {
                            ForEach(model.visibleOpportunities) { opportunity in
                                NavigationLink {
                                    OpportunityDetailsView(
                                        opportunity: opportunity,
                                        accessToken: accessToken
                                    )
                                } label: {
                                    EventCard(
                                        imageName: opportunity.imageName,
                                        category: opportunity.category,
                                        title: opportunity.title,
                                        summary: opportunity.summary,
                                        color: opportunity.themeColor,
                                        dateText: opportunity.dateText,
                                        participantCount: opportunity.participantCount,
                                        locationName: opportunity.locationName,
                                        status: opportunity.status,
                                        reward: opportunity.reward
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            }
                        }
                    } header: {
                        OpportunityFilters(
                            searchText: $model.searchText,
                            selectedCategory: $model.selectedCategory,
                            categories: categories
                        )
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $showSubscriptions, onDismiss: { subscriptionRefreshID = UUID() }) {
                if let accessToken { SubscriptionsView(token: accessToken) }
            }
            .sheet(isPresented: $showGoalRoute) {
                if let accessToken { GoalRouteView(token: accessToken) }
            }
            .sheet(isPresented: $showOrganizations, onDismiss: { subscriptionRefreshID = UUID() }) { OrganizationsView(token: accessToken) }
            .sheet(isPresented: $showSaved) { if let accessToken { SavedOpportunitiesView(token: accessToken) } }
            .alert("Нужен аккаунт", isPresented: $showSignInMessage) {
                Button("Понятно", role: .cancel) {}
            } message: { Text("Войди, чтобы сохранять события и пользоваться персональными возможностями.") }
            .task(id: refreshID) {
                await model.load()
            }
            .overlay(alignment: .bottom) {
                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .padding(10)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom)
                }
            }
        }
    }
}

private struct HomeHeader: View {
    let isAuthenticated: Bool
    let avatarImage: UIImage?
    let profileName: String?
    let unreadNotificationCount: Int
    let onNotificationsTap: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack {
            Text("SPARK")
                .foregroundStyle(.primaryLitePurple)
                .font(.system(size: 24, weight: .semibold))

            Spacer()

            Button(action: onNotificationsTap) {
                Image(systemName: unreadNotificationCount > 0 ? "bell.fill" : "bell")
                    .font(.title2)
                    .foregroundStyle(.primaryLitePurple)
                    .overlay(alignment: .topTrailing) {
                        if unreadNotificationCount > 0 {
                            Text("\(min(unreadNotificationCount, 99))")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(4)
                                .background(.red, in: Circle())
                                .offset(x: 10, y: -10)
                        }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Уведомления")

            Button(action: onTap) {
                ZStack {
                    Circle()
                        .fill(.primaryLitePurple.opacity(0.16))

                    if let avatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .scaledToFill()
                    } else if let initial = profileName?.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).first {
                        Text(String(initial).uppercased())
                            .font(.title2.bold())
                            .foregroundStyle(.primaryLitePurple)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.title2)
                            .foregroundStyle(.primaryLitePurple)
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(Circle().stroke(.primaryLitePurple2, lineWidth: 3))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                isAuthenticated ? "Открыть профиль" : "Войти в аккаунт"
            )
        }
        .padding(.horizontal)
    }
}

private struct OpportunityFilters: View {
    @Binding var searchText: String
    @Binding var selectedCategory: EventCategory

    let categories: [EventCategory]

    var body: some View {
        VStack(spacing: 12) {
            SparkTextField(
                icon: "magnifyingglass",
                iconColor: .grey,
                iconSize: 18,
                placeholder: "Поиск возможностей",
                borderColor: .litePurple,
                backgroundColor: .surface,
                isSecure: false,
                borderWidth: 8,
                text: $searchText
            )
            .padding(.top, 10)
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(categories, id: \.self) { category in
                        CategoryChip(
                            title: category.rawValue,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 5)
            }
        }
        .background(.ultraThinMaterial)
    }
}

#Preview {
    HomeView(
        accessToken: nil,
        avatarImage: nil,
        profileName: nil,
        unreadNotificationCount: 0,
        onNotificationsTap: {},
        onAvatarTap: {}
    )
}
