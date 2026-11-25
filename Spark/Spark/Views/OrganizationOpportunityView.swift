import SwiftUI

struct OrganizationSetupView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (String) async -> Bool

    @State private var organizationName = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Профиль организации") {
                    TextField("Название организации", text: $organizationName)
                    Text("Заявку рассмотрит администратор. После подтверждения вы сможете публиковать мероприятия и возможности.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Организация")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Отправить") {
                        Task {
                            isSaving = true
                            if await onSave(organizationName.trimmingCharacters(in: .whitespacesAndNewlines)) {
                                dismiss()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(organizationName.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 || isSaving)
                }
            }
        }
    }
}

struct OpportunityCreateView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (OpportunityCreateRequest) async -> Bool

    @State private var category: EventCategory = .meetups
    @State private var title = ""
    @State private var summary = ""
    @State private var details = ""
    @State private var locationName = "Минск"
    @State private var latitude = "53.9023"
    @State private var longitude = "27.5619"
    @State private var startsAt = Date()
    @State private var endsAt = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var deadline = Date()
    @State private var reward = ""
    @State private var imageURL = ""
    @State private var sourceURL = ""
    @State private var registrationURL = ""
    @State private var acceptsRegistrations = false
    @State private var isSaving = false
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    Picker("Категория", selection: $category) {
                        ForEach(EventCategory.allCases.filter { $0 != .all }, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    TextField("Название", text: $title)
                    TextField("Краткое описание", text: $summary, axis: .vertical)
                    TextField("Полное описание", text: $details, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section("Место на карте") {
                    TextField("Название места", text: $locationName)
                    TextField("Широта", text: $latitude)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Долгота", text: $longitude)
                        .keyboardType(.numbersAndPunctuation)
                    Text("Для проверки уже указаны координаты центра Минска.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Даты") {
                    DatePicker("Начало", selection: $startsAt, displayedComponents: .date)
                    DatePicker("Окончание", selection: $endsAt, displayedComponents: .date)
                    DatePicker("Приём заявок до", selection: $deadline, displayedComponents: .date)
                }

                Section("Дополнительно") {
                    TextField("Ссылка на источник (https://)", text: $sourceURL)
                        .textInputAutocapitalization(.never).keyboardType(.URL).autocorrectionDisabled()
                    TextField("Внешняя регистрация (https://)", text: $registrationURL)
                        .textInputAutocapitalization(.never).keyboardType(.URL).autocorrectionDisabled()
                    Toggle("Принимать заявки в Spark", isOn: $acceptsRegistrations)
                    if acceptsRegistrations {
                        Text("Участники сами подтверждают отправку имени, email и сообщения. Заявки доступны владельцу события.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    TextField("Ссылка на изображение", text: $imageURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    TextField("Вознаграждение, Br", text: $reward)
                        .keyboardType(.numberPad)
                }

                if let validationMessage {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Новое мероприятие")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Опубликовать") { save() }
                        .disabled(isSaving)
                }
            }
        }
    }

    private func save() {
        guard let latitudeValue = Double(latitude.replacingOccurrences(of: ",", with: ".")),
              let longitudeValue = Double(longitude.replacingOccurrences(of: ",", with: ".")),
              (-90...90).contains(latitudeValue),
              (-180...180).contains(longitudeValue),
              locationName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2,
              Calendar.current.startOfDay(for: endsAt) >= Calendar.current.startOfDay(for: startsAt),
              title.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3,
              summary.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3,
              details.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 else {
            validationMessage = "Заполните описание и проверьте координаты."
            return
        }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        let source = sourceURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let registration = registrationURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !source.isEmpty, (URL(string: source)?.scheme != "https" || URL(string: source)?.host == nil) {
            validationMessage = "Укажите корректную ссылку на источник с https://."
            return
        }
        if !registration.isEmpty, (URL(string: registration)?.scheme != "https" || URL(string: registration)?.host == nil) {
            validationMessage = "Укажите корректную ссылку на регистрацию с https://."
            return
        }
        var request = OpportunityCreateRequest(
            category: category.rawValue,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
            details: details.trimmingCharacters(in: .whitespacesAndNewlines),
            imageURL: imageURL.isEmpty ? nil : imageURL,
            locationName: locationName.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: latitudeValue,
            longitude: longitudeValue,
            startsAt: formatter.string(from: startsAt),
            endsAt: formatter.string(from: endsAt),
            deadline: formatter.string(from: deadline),
            reward: Int(reward)
        )
        request.sourceURL = source.isEmpty ? nil : source
        request.registrationURL = registration.isEmpty ? nil : registration
        request.acceptsRegistrations = acceptsRegistrations

        Task {
            isSaving = true
            if await onSave(request) {
                dismiss()
            } else {
                validationMessage = "Не удалось опубликовать мероприятие."
            }
            isSaving = false
        }
    }
}
