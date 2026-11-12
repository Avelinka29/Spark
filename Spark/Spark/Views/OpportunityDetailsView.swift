import SwiftUI

struct OpportunityDetailsView: View {
    let opportunity: Opportunity
    let accessToken: String?

    @State private var isSaved = false
    @State private var isBookmarkLoading = false
    @State private var bookmarkError: String?
    @State private var bookmarkFeedbackTrigger = 0
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
                        if accessToken == nil {
                            showAuthenticationRequired = true
                        } else {
                            Task {
                                await toggleBookmark()
                            }
                        }
                    } label: {
                        Label(
                            isSaved ? "Сохранено" : "Сохранить",
                            systemImage: isSaved ? "bookmark.fill" : "bookmark"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.primaryLitePurple)
                    .disabled(isBookmarkLoading)

                    Button {
                        if accessToken != nil {
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
        .sensoryFeedback(.success, trigger: bookmarkFeedbackTrigger)
        .task(id: opportunity.id) {
            await loadBookmarkState()
        }
        .alert("Нужна авторизация", isPresented: $showAuthenticationRequired) {
            Button("Понятно", role: .cancel) {}
        } message: {
            Text("Войдите в аккаунт, чтобы сохранять возможности и подавать заявки.")
        }
        .alert("Не удалось сохранить", isPresented: Binding(
            get: { bookmarkError != nil },
            set: { if !$0 { bookmarkError = nil } }
        )) {
            Button("Понятно", role: .cancel) {}
        } message: {
            Text(bookmarkError ?? "Неизвестная ошибка")
        }
    }

    private func loadBookmarkState() async {
        guard let accessToken else {
            isSaved = false
            return
        }

        do {
            let bookmarks: [OpportunityDTO] = try await APIClient.shared.send(
                path: "bookmarks",
                token: accessToken
            )
            isSaved = bookmarks.contains { $0.id == opportunity.id }
        } catch {
            bookmarkError = error.localizedDescription
        }
    }

    private func toggleBookmark() async {
        guard let accessToken else {
            showAuthenticationRequired = true
            return
        }

        isBookmarkLoading = true
        defer { isBookmarkLoading = false }

        do {
            let method = isSaved ? "DELETE" : "POST"
            let _: EmptyResponse = try await APIClient.shared.send(
                path: "opportunities/\(opportunity.id)/bookmark",
                method: method,
                token: accessToken
            )
            isSaved.toggle()
            bookmarkFeedbackTrigger += 1
        } catch {
            bookmarkError = error.localizedDescription
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
        OpportunityDetailsView(opportunity: mockOpportunities[0], accessToken: nil)
    }
}
