import SwiftUI

struct EventRegistrationDTO: Decodable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    let message: String
}

private struct EventRegistrationRequest: Encodable {
    let name: String
    let email: String
    let message: String
}

struct EventRegistrationView: View {
    let event: Opportunity
    let token: String
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var registration: EventRegistrationDTO?
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                if let registration {
                    Section("Заявка отправлена") {
                        Text(registration.name)
                        Text(registration.email).foregroundStyle(.secondary)
                        Text("Это заявка организатору, а не подтверждение участия.")
                            .font(.footnote).foregroundStyle(.secondary)
                        Button("Отменить заявку", role: .destructive) { Task { await cancel() } }
                            .disabled(loading)
                    }
                } else {
                    Section("Данные участника") {
                        TextField("Имя", text: $name)
                        TextField("Email", text: $email).keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                        TextField("Сообщение организатору (необязательно)", text: $message, axis: .vertical).lineLimit(3...6)
                    }
                    Section {
                        Text("Проверь данные. После нажатия кнопки имя, email и сообщение будут отправлены организатору события «\(event.organizer)».")
                            .font(.footnote).foregroundStyle(.secondary)
                        Button("Отправить организатору") { Task { await submit() } }
                            .disabled(loading || name.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 || email.isEmpty)
                    }
                }
                if loading { ProgressView() }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Заявка на событие")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Готово") { dismiss() } } }
            .task { await load() }
        }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            async let profile: ProfileDTO = APIClient.shared.send(path: "profile/me", token: token)
            async let existing: EventRegistrationDTO? = APIClient.shared.send(path: "opportunities/\(event.id)/registrations/me", token: token)
            let (loadedProfile, loadedRegistration) = try await (profile, existing)
            name = loadedProfile.name
            email = loadedProfile.email
            registration = loadedRegistration
            error = nil
        } catch { self.error = error.localizedDescription }
    }

    private func submit() async {
        loading = true
        defer { loading = false }
        do {
            registration = try await APIClient.shared.send(path: "opportunities/\(event.id)/registrations", method: "POST",
                body: EventRegistrationRequest(name: name.trimmingCharacters(in: .whitespacesAndNewlines), email: email.trimmingCharacters(in: .whitespacesAndNewlines), message: message), token: token)
            error = nil
        } catch { self.error = error.localizedDescription }
    }

    private func cancel() async {
        loading = true
        defer { loading = false }
        do {
            let _: EmptyResponse = try await APIClient.shared.send(path: "opportunities/\(event.id)/registrations/me", method: "DELETE", token: token)
            registration = nil
            error = nil
        } catch { self.error = error.localizedDescription }
    }
}

struct EventRegistrationsList: View {
    let registrations: [EventRegistrationDTO]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Заявки на событие").font(.headline)
            if registrations.isEmpty { Text("Заявок пока нет.").foregroundStyle(.secondary) }
            ForEach(registrations) { item in
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name).font(.subheadline.bold())
                    Text(item.email).font(.footnote)
                    if !item.message.isEmpty { Text(item.message).font(.footnote).foregroundStyle(.secondary) }
                }
            }
        }.padding(.horizontal)
    }
}
