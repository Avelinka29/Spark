import SwiftUI

struct TeamWorkspaceView: View {
    let chat: ChatDTO
    let store: SocialStore
    @State private var workspace = TeamWorkspaceDTO()
    @State private var tasks: [TeamTaskDTO] = []
    @State private var newTask = ""
    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Прогресс команды") {
                    if tasks.isEmpty {
                        Text("Добавьте первую задачу.").foregroundStyle(.secondary)
                    } else {
                        ProgressView(value: Double(tasks.filter(\.done).count), total: Double(tasks.count))
                        Text("Выполнено: \(tasks.filter(\.done).count) из \(tasks.count)").font(.caption)
                    }
                }
                Section("Задачи") {
                    ForEach(tasks) { task in
                        Button {
                            Task { await toggle(task) }
                        } label: {
                            Label(task.title, systemImage: task.done ? "checkmark.circle.fill" : "circle")
                        }
                        .swipeActions {
                            Button("Удалить", role: .destructive) { Task { await delete(task) } }
                        }
                    }
                    HStack {
                        TextField("Новая задача", text: $newTask)
                        Button("Добавить") { Task { await add() } }
                            .disabled(newTask.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                    }
                }
                Section("Ближайшая встреча") {
                    TextField("Дата, время и место", text: $workspace.meeting, axis: .vertical)
                }
                Section("Общие ссылки") {
                    TextField("Ссылки и заметки", text: $workspace.links, axis: .vertical).lineLimit(3...8)
                }
                Section {
                    Button("Сохранить встречу и ссылки") { Task { await save() } }
                        .disabled(isSaving || isLoading)
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .navigationTitle(chat.projectTitle)
            .overlay { if isLoading { ProgressView() } }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        do {
            async let loadedWorkspace = store.workspace(chatID: chat.id)
            async let loadedTasks = store.tasks(chatID: chat.id)
            (workspace, tasks) = try await (loadedWorkspace, loadedTasks)
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do { try await store.saveWorkspace(chatID: chat.id, value: workspace); errorMessage = nil }
        catch { errorMessage = error.localizedDescription }
    }

    private func add() async {
        isSaving = true
        defer { isSaving = false }
        do { try await store.createTask(chatID: chat.id, title: newTask); newTask = ""; tasks = try await store.tasks(chatID: chat.id); errorMessage = nil }
        catch { errorMessage = error.localizedDescription }
    }

    private func toggle(_ task: TeamTaskDTO) async {
        do { try await store.updateTask(chatID: chat.id, task: task); tasks = try await store.tasks(chatID: chat.id); errorMessage = nil }
        catch { errorMessage = error.localizedDescription }
    }

    private func delete(_ task: TeamTaskDTO) async {
        do { try await store.deleteTask(chatID: chat.id, taskID: task.id); tasks = try await store.tasks(chatID: chat.id); errorMessage = nil }
        catch { errorMessage = error.localizedDescription }
    }
}
