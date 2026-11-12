import SwiftUI

struct OpportunityDetailsView: View {
    let opportunity: Opportunity
    let isAuthenticated: Bool

    @State private var isSaved = false
    @State private var hasApplied = false
    @State private var showAuthenticationRequired = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                OpportunityHeroSection(
                    imageName: opportunity.imageName,
                    status: opportunity.status,
                    reward: opportunity.reward
                )

                OpportunityOverviewSection(
                    category: opportunity.category,
                    title: opportunity.title,
                    summary: opportunity.summary,
                    color: opportunity.themeColor
                )

                OpportunityFactsSection(
                    dateText: opportunity.dateText,
                    deadlineText: opportunity.deadlineText,
                    locationName: opportunity.locationName,
                    organizer: opportunity.organizer
                )

                Text(opportunity.details)
                    .font(.body)
                    .lineSpacing(6)
                    .padding(.horizontal)

                HStack(spacing: 12) {
                    Button {
                        isSaved.toggle()
                    } label: {
                        Label(
                            isSaved ? "Сохранено" : "Сохранить",
                            systemImage: isSaved ? "bookmark.fill" : "bookmark"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.primaryLitePurple)

                    Button {
                        if isAuthenticated {
                            hasApplied = true
                        } else {
                            showAuthenticationRequired = true
                        }
                    } label: {
                        Text(hasApplied ? "Заявка отправлена" : "Подать заявку")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.primaryLitePurple)
                    .disabled(hasApplied)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 24)
        }
        .navigationTitle("Возможность")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Нужна авторизация", isPresented: $showAuthenticationRequired) {
            Button("Понятно", role: .cancel) {}
        } message: {
            Text("Войдите в аккаунт, чтобы подать заявку.")
        }
    }
}

private struct OpportunityHeroSection: View {
    let imageName: String
    let status: String?
    let reward: Int?

    var body: some View {
        ZStack(alignment: .top) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 280)
                .clipped()

            HStack {
                if let status {
                    Text(status)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .foregroundStyle(.primary)
                        .background(Color(.secondarySystemBackground).opacity(0.95))
                        .clipShape(Capsule())
                }

                Spacer()

                if let reward {
                    Text("\(reward) Br")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(.primaryYellow)
                        .clipShape(Capsule())
                }
            }
            .padding()
        }
    }
}

private struct OpportunityOverviewSection: View {
    let category: EventCategory
    let title: String
    let summary: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(category.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(color.opacity(0.15))
                .clipShape(Capsule())

            Text(title)
                .font(.title.bold())

            Text(summary)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
}

private struct OpportunityFactsSection: View {
    let dateText: String
    let deadlineText: String
    let locationName: String
    let organizer: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(dateText, systemImage: "calendar")
            Label("Подать до \(deadlineText)", systemImage: "clock")
            Label(locationName, systemImage: "mappin.and.ellipse")
            Label(organizer, systemImage: "building.2")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        OpportunityDetailsView(opportunity: mockOpportunities[0], isAuthenticated: false)
    }
}
