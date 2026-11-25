import SwiftUI
import UserNotifications

struct OpportunityDetailsView: View {
    let opportunity: Opportunity
    let accessToken: String?

    @State private var isSaved = false
    @State private var isBookmarkLoading = false
    @State private var bookmarkError: String?
    @State private var bookmarkFeedbackTrigger = 0
    @State private var isGoing = false
    @State private var hasAttended = false
    @State private var isVerified = false
    @State private var participantsToVerify: [AttendanceParticipantDTO]?
    @State private var verifyingParticipant: UUID?
    @State private var attendanceLoading = false
    @State private var attendingFriends: [AttendingFriendDTO] = []
    @State private var showInvite = false
    @State private var reminderMessage: String?
    @State private var showAuthenticationRequired = false
    @State private var showReport = false
    @State private var showRegistration = false
    @State private var registrations: [EventRegistrationDTO]?
    @State private var hasOrganizationPage = false

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
                if hasOrganizationPage, let ownerID = opportunity.ownerID {
                    NavigationLink {
                        OrganizationDetailsView(id: ownerID, token: accessToken)
                    } label: { Label("Профиль организации", systemImage: "building.2") }
                        .padding(.horizontal)
                }

                if let value = opportunity.sourceURL, let url = URL(string: value), url.scheme == "https" {
                    Link(destination: url) {
                        Label("Открыть источник события", systemImage: "arrow.up.right.square")
                    }.padding(.horizontal)
                    Text("Ссылку указал автор события; Spark не подтверждает её содержимое.")
                        .font(.footnote).foregroundStyle(.secondary).padding(.horizontal)
                } else {
                    Text("Ссылка на источник не указана")
                        .font(.footnote).foregroundStyle(.secondary).padding(.horizontal)
                }
                if let value = opportunity.registrationURL, let url = URL(string: value), url.scheme == "https" {
                    Link(destination: url) { Label("Регистрация на сайте организатора", systemImage: "arrow.up.right.square") }
                        .padding(.horizontal)
                    Text("Откроется внешний сайт; данные профиля Spark не передаются автоматически.")
                        .font(.footnote).foregroundStyle(.secondary).padding(.horizontal)
                }
                if opportunity.acceptsRegistrations {
                    Button("Подать заявку в Spark") {
                        if accessToken == nil { showAuthenticationRequired = true }
                        else { showRegistration = true }
                    }.buttonStyle(.borderedProminent).tint(.primaryLitePurple).padding(.horizontal)
                }
                if let registrations { EventRegistrationsList(registrations: registrations) }

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
                            Task { await toggleAttendance() }
                        } else {
                            showAuthenticationRequired = true
                        }
                    } label: {
                        Text(isGoing ? "Я собираюсь ✓" : "Я собираюсь")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.primaryLitePurple)
                    .disabled(attendanceLoading || hasAttended)
                }
                .padding(.horizontal)
                if isGoing {
                    Text("Это отметка для друзей, а не регистрация у организатора.")
                        .font(.footnote).foregroundStyle(.secondary).padding(.horizontal)
                }
                if isGoing {
                    Button(hasAttended ? "Участие добавлено в портфолио" : "Я участвовал(а)") {
                        Task { await markAttended() }
                    }
                    .disabled(hasAttended || attendanceLoading || !hasEventStarted)
                    .padding(.horizontal)
                    Text(isVerified ? "Участие подтверждено организатором." : (hasEventStarted ? "Участие появится в профиле. Пока оно не подтверждено организатором." : "Отметить участие можно с даты начала события."))
                        .font(.footnote).foregroundStyle(.secondary).padding(.horizontal)
                }
                if let participants = participantsToVerify {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Подтверждение участников").font(.headline)
                        Text("Здесь только пользователи, которые сами отметили участие.")
                            .font(.footnote).foregroundStyle(.secondary)
                        if participants.isEmpty {
                            Text("Пока нет отметок об участии.").font(.subheadline).foregroundStyle(.secondary)
                        }
                        ForEach(participants) { participant in
                            HStack {
                                Text(participant.name)
                                Spacer()
                                Button(participant.verified ? "Отменить подтверждение" : "Подтвердить") {
                                    Task { await verifyParticipant(participant.id, revoke: participant.verified) }
                                }
                                .disabled(verifyingParticipant != nil)
                            }
                        }
                    }.padding(.horizontal)
                }
                if !attendingFriends.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Друзья собираются").font(.headline)
                        ForEach(attendingFriends) { friend in
                            Label(friend.name, systemImage: "person.fill")
                        }
                    }
                    .padding(.horizontal)
                }
                if accessToken != nil {
                    Button {
                        showInvite = true
                    } label: {
                        Label("Пригласить друга", systemImage: "person.badge.plus")
                    }
                    .padding(.horizontal)
                    Button("Пожаловаться на событие") { showReport = true }
                        .font(.footnote).foregroundStyle(.secondary).padding(.horizontal)
                }
                if reminderDate != nil {
                    Button {
                        Task { await scheduleReminder() }
                    } label: {
                        Label("Напомнить за день до дедлайна", systemImage: "bell.badge")
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 24)
        }
        .navigationTitle("Возможность")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showInvite) {
            if let accessToken {
                InviteFriendView(opportunityID: opportunity.id, token: accessToken)
            }
        }
        .sheet(isPresented: $showReport) {
            if let accessToken { ContentReportView(token: accessToken, kind: "opportunity", targetID: opportunity.id) }
        }
        .sheet(isPresented: $showRegistration, onDismiss: { Task { await loadRegistrations() } }) {
            if let accessToken { EventRegistrationView(event: opportunity, token: accessToken) }
        }
        .sensoryFeedback(.success, trigger: bookmarkFeedbackTrigger)
        .task(id: opportunity.id) {
            await loadBookmarkState()
            await loadAttendance()
            await loadParticipants()
            await loadRegistrations()
            await checkOrganizationPage()
        }
        .alert("Нужна авторизация", isPresented: $showAuthenticationRequired) {
            Button("Понятно", role: .cancel) {}
        } message: {
            Text("Войдите в аккаунт, чтобы сохранять возможности и отмечать планы.")
        }
        .alert("Не удалось сохранить", isPresented: Binding(
            get: { bookmarkError != nil },
            set: { if !$0 { bookmarkError = nil } }
        )) {
            Button("Понятно", role: .cancel) {}
        } message: {
            Text(bookmarkError ?? "Неизвестная ошибка")
        }
        .alert("Напоминание", isPresented: Binding(
            get: { reminderMessage != nil }, set: { if !$0 { reminderMessage = nil } }
        )) {
            Button("Понятно", role: .cancel) {}
        } message: {
            Text(reminderMessage ?? "")
        }
    }

    private func checkOrganizationPage() async {
        guard let ownerID = opportunity.ownerID else { return }
        do {
            let _: OrganizationPageCheck = try await APIClient.shared.send(path: "organizations/\(ownerID)")
            hasOrganizationPage = true
        } catch { hasOrganizationPage = false }
    }

    private func loadRegistrations() async {
        guard let accessToken, opportunity.acceptsRegistrations else { return }
        do { registrations = try await APIClient.shared.send(path: "opportunities/\(opportunity.id)/registrations", token: accessToken) }
        catch { registrations = nil }
    }

    private var reminderDate: Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        guard let deadline = formatter.date(from: opportunity.deadlineText),
              let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: deadline),
              let date = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: previousDay),
              date > Date() else { return nil }
        return date
    }

    private func scheduleReminder() async {
        guard let date = reminderDate else { return }
        do {
            let center = UNUserNotificationCenter.current()
            guard try await center.requestAuthorization(options: [.alert, .sound]) else {
                reminderMessage = "Разрешите уведомления в настройках устройства."
                return
            }
            let content = UNMutableNotificationContent()
            content.title = "Скоро дедлайн"
            content.body = "Завтра заканчивается приём заявок: \(opportunity.title)."
            content.sound = .default
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            try await center.add(UNNotificationRequest(identifier: "deadline.\(opportunity.id)", content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)))
            reminderMessage = "Напомним за день до окончания приёма заявок в 10:00."
        } catch { reminderMessage = error.localizedDescription }
    }

    private func loadAttendance() async {
        guard let accessToken else { return }
        do {
            let state: AttendanceDTO = try await APIClient.shared.send(
                path: "opportunities/\(opportunity.id)/attendance", token: accessToken)
            isGoing = state.going
            hasAttended = state.attended
            isVerified = state.verified
            attendingFriends = state.friends
        } catch {
            bookmarkError = error.localizedDescription
        }
    }

    private func loadParticipants() async {
        guard let accessToken else { return }
        do {
            participantsToVerify = try await APIClient.shared.send(
                path: "opportunities/\(opportunity.id)/attendance/participants", token: accessToken)
        } catch APIError.server(let statusCode, _) where statusCode == 403 {
            participantsToVerify = nil
        } catch {
            participantsToVerify = nil
        }
    }

    private func verifyParticipant(_ participantID: UUID, revoke: Bool) async {
        guard let accessToken else { return }
        verifyingParticipant = participantID
        defer { verifyingParticipant = nil }
        do {
            let _: EmptyResponse = try await APIClient.shared.send(
                path: "opportunities/\(opportunity.id)/attendance/participants/\(participantID)/verify",
                method: revoke ? "DELETE" : "PUT", token: accessToken)
            await loadParticipants()
        } catch { bookmarkError = error.localizedDescription }
    }

    private var hasEventStarted: Bool {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        guard let start = opportunity.dateText.components(separatedBy: " — ").first,
              let date = formatter.date(from: start) else { return false }
        return date <= Date()
    }

    private func markAttended() async {
        guard let accessToken else { return }
        attendanceLoading = true
        defer { attendanceLoading = false }
        do {
            let _: EmptyResponse = try await APIClient.shared.send(
                path: "opportunities/\(opportunity.id)/attendance/attended", method: "PUT", token: accessToken)
            await loadAttendance()
        } catch { bookmarkError = error.localizedDescription }
    }

    private func toggleAttendance() async {
        guard let accessToken else { return }
        attendanceLoading = true
        defer { attendanceLoading = false }
        do {
            let _: EmptyResponse = try await APIClient.shared.send(
                path: "opportunities/\(opportunity.id)/attendance",
                method: isGoing ? "DELETE" : "PUT", token: accessToken)
            await loadAttendance()
        } catch {
            bookmarkError = error.localizedDescription
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
