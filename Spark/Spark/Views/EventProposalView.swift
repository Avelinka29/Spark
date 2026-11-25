import SwiftUI

struct EventProposalView: View {
    @Environment(\.dismiss) private var dismiss

    let onSend: (OpportunityCreateRequest, String) async -> Bool

    @State private var category: EventCategory = .meetups
    @State private var title = ""
    @State private var summary = ""
    @State private var details = ""
    @State private var locationName = "Минск"
    @State private var latitude = "53.9023"
    @State private var longitude = "27.5619"
    @State private var message = ""
    @State private var sourceURL = ""
    @State private var registrationURL = ""
    @State private var isSending = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Событие") {
                    Picker("Категория", selection: $category) {
                        ForEach(EventCategory.allCases.filter { $0 != .all }, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    TextField("Название", text: $title)
                    TextField("Краткое описание", text: $summary, axis: .vertical)
                    TextField("Полное описание", text: $details, axis: .vertical)
                        .lineLimit(3...8)
                    TextField("Ссылка на источник (https://)", text: $sourceURL)
                        .textInputAutocapitalization(.never).keyboardType(.URL).autocorrectionDisabled()
                    TextField("Внешняя регистрация (https://)", text: $registrationURL)
                        .textInputAutocapitalization(.never).keyboardType(.URL).autocorrectionDisabled()
                }

                Section("Место на карте") {
                    TextField("Название места", text: $locationName)
                    TextField("Широта", text: $latitude)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Долгота", text: $longitude)
                        .keyboardType(.numbersAndPunctuation)
                }

                Section("Сообщение администратору") {
                    TextField("Почему событие стоит добавить?", text: $message, axis: .vertical)
                        .lineLimit(3...8)
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("Предложить событие")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Отправить") { send() }
                        .disabled(isSending)
                }
            }
        }
    }

    private func send() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanTitle.count >= 3,
              cleanSummary.count >= 3,
              cleanDetails.count >= 3,
              cleanMessage.count >= 3,
              let latitudeValue = Double(latitude.replacingOccurrences(of: ",", with: ".")),
              let longitudeValue = Double(longitude.replacingOccurrences(of: ",", with: ".")),
              (-90...90).contains(latitudeValue),
              (-180...180).contains(longitudeValue),
              locationName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else {
            errorMessage = "Заполните сведения о событии, сообщение и координаты."
            return
        }

        let source = sourceURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let registration = registrationURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !source.isEmpty, (URL(string: source)?.scheme != "https" || URL(string: source)?.host == nil) {
            errorMessage = "Укажите корректную ссылку на источник с https://."
            return
        }
        if !registration.isEmpty, (URL(string: registration)?.scheme != "https" || URL(string: registration)?.host == nil) {
            errorMessage = "Укажите корректную ссылку на регистрацию с https://."
            return
        }
        var event = OpportunityCreateRequest(
            category: category.rawValue,
            title: cleanTitle,
            summary: cleanSummary,
            details: cleanDetails,
            imageURL: nil,
            locationName: locationName,
            latitude: latitudeValue,
            longitude: longitudeValue,
            startsAt: nil,
            endsAt: nil,
            deadline: nil,
            reward: nil
        )
        event.sourceURL = source.isEmpty ? nil : source
        event.registrationURL = registration.isEmpty ? nil : registration
        Task {
            isSending = true
            if await onSend(event, cleanMessage) {
                dismiss()
            } else {
                errorMessage = "Не удалось отправить предложение."
            }
            isSending = false
        }
    }
}

struct AdminEventProposalsView: View {
    let store: ProfileStore
    let onApproved: () -> Void

    var body: some View {
        NavigationStack {
            List(store.eventProposals) { proposal in
                VStack(alignment: .leading, spacing: 10) {
                    Text(proposal.event.title)
                        .font(.headline)
                    Text("От: \(proposal.authorName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(proposal.event.summary)
                    Text(proposal.message)
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    if proposal.status == "pending" {
                        HStack {
                            Button("Опубликовать") {
                                Task {
                                    if await store.decideEventProposal(id: proposal.id, approve: true) {
                                        onApproved()
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Отклонить", role: .destructive) {
                                Task {
                                    await store.decideEventProposal(id: proposal.id, approve: false)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        Text(proposal.status == "approved" ? "Опубликовано" : "Отклонено")
                            .font(.caption.bold())
                    }
                }
                .padding(.vertical, 6)
            }
            .overlay {
                if store.eventProposals.isEmpty {
                    ContentUnavailableView(
                        "Предложений пока нет",
                        systemImage: "tray",
                        description: Text("Здесь появятся события от пользователей.")
                    )
                }
            }
            .navigationTitle("Предложения")
            .safeAreaInset(edge: .bottom) {
                if let errorMessage = store.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding()
                        .background(.regularMaterial)
                }
            }
            .task { await store.loadEventProposals() }
            .refreshable { await store.loadEventProposals() }
        }
    }
}
