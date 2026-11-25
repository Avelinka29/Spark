import SwiftUI

private struct ReportRequest: Encodable {
    let kind: String
    let targetID: UUID
    let reason: String
    enum CodingKeys: String, CodingKey { case kind, reason; case targetID = "target_id" }
}

private struct ReportDTO: Decodable, Identifiable {
    let id: UUID
    let kind: String
    let targetID: UUID
    let reason: String
    let status: String
    enum CodingKeys: String, CodingKey { case id, kind, reason, status; case targetID = "target_id" }
}

private struct ReportDecisionRequest: Encodable { let status: String }

struct ContentReportView: View {
    let token: String
    let kind: String
    let targetID: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    @State private var isSending = false
    @State private var sent = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                if sent {
                    Label("Жалоба отправлена на рассмотрение", systemImage: "checkmark.circle")
                } else {
                    Section("Что произошло?") {
                        TextField("Опиши проблему", text: $reason, axis: .vertical).lineLimit(4...8)
                        Text("Администратор рассмотрит сообщение. Не указывай пароли или коды.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    if let error { Text(error).foregroundStyle(.red) }
                    Button("Отправить жалобу") {
                        Task {
                            isSending = true
                            defer { isSending = false }
                            do {
                                let _: ReportDTO = try await APIClient.shared.send(path: "reports", method: "POST",
                                    body: ReportRequest(kind: kind, targetID: targetID, reason: reason.trimmingCharacters(in: .whitespacesAndNewlines)), token: token)
                                sent = true
                            } catch { self.error = error.localizedDescription }
                        }
                    }.disabled(isSending || reason.trimmingCharacters(in: .whitespacesAndNewlines).count < 5 || reason.count > 1000)
                }
            }
            .navigationTitle("Жалоба")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } } }
        }
    }
}

struct AdminReportsView: View {
    let token: String
    @State private var reports: [ReportDTO] = []
    @State private var error: String?
    @State private var loading = false

    var body: some View {
        NavigationStack {
            List {
                if reports.isEmpty && !loading && error == nil { Text("Новых жалоб нет.").foregroundStyle(.secondary) }
                ForEach(reports) { report in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(report.kind == "user" ? "Пользователь" : report.kind == "project" ? "Проект" : "Событие").font(.headline)
                        Text(report.reason)
                        Text("ID объекта: \(report.targetID.uuidString)").font(.caption).textSelection(.enabled)
                        HStack {
                            Button("Рассмотрено") { Task { await decide(report, status: "reviewed") } }
                            Button("Отклонить") { Task { await decide(report, status: "dismissed") } }
                        }.font(.subheadline)
                    }.padding(.vertical, 4)
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Жалобы")
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do { reports = try await APIClient.shared.send(path: "admin/reports", token: token); error = nil }
        catch { self.error = error.localizedDescription }
    }

    private func decide(_ report: ReportDTO, status: String) async {
        do {
            let _: ReportDTO = try await APIClient.shared.send(path: "admin/reports/\(report.id)", method: "PATCH", body: ReportDecisionRequest(status: status), token: token)
            await load()
        } catch { self.error = error.localizedDescription }
    }
}
