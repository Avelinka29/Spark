import SwiftUI

struct HomeView: View {
    let isAuthenticated: Bool
    let avatarImage: UIImage?
    let profileName: String?
    let onAvatarTap: () -> Void

    @State private var model = OpportunitiesViewModel()

    private let categories = EventCategory.allCases

    var body: some View {
        NavigationStack {
            ScrollView {
                HomeHeader(
                    isAuthenticated: isAuthenticated,
                    avatarImage: avatarImage,
                    profileName: profileName,
                    onTap: onAvatarTap
                )

                Divider()

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
                                        isAuthenticated: isAuthenticated
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
            .task {
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
    let onTap: () -> Void

    var body: some View {
        HStack {
            Text("SPARK")
                .foregroundStyle(.primaryLitePurple)
                .font(.system(size: 24, weight: .semibold))

            Spacer()

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
        isAuthenticated: false,
        avatarImage: nil,
        profileName: nil,
        onAvatarTap: {}
    )
}
