import Foundation

struct ProjectRecommendation: Identifiable {
    let project: Project
    let reasons: [String]
    let score: Int
    var id: UUID { project.id }
}

enum ProjectRecommendations {
    static func matching(projects: [Project], profile: UserProfile?) -> [ProjectRecommendation] {
        guard let profile else { return [] }
        return projects.compactMap { project in
            guard project.ownerID != profile.id else { return nil }
            let openRoles = project.vacancies.filter(\.isActive)
            guard !openRoles.isEmpty else { return nil }
            var reasons: [String] = []
            for interest in profile.interests {
                let value = interest.trimmingCharacters(in: .whitespacesAndNewlines)
                guard value.count >= 2 else { continue }
                if "\(project.category) \(project.title) \(project.summary)".localizedCaseInsensitiveContains(value) {
                    reasons.append("Интерес: \(value)")
                }
            }
            for skill in profile.skills {
                let value = skill.trimmingCharacters(in: .whitespacesAndNewlines)
                guard value.count >= 2 else { continue }
                if let role = openRoles.first(where: { "\($0.title) \($0.roleDescription)".localizedCaseInsensitiveContains(value) }) {
                    reasons.append("Навык \(value) нужен для роли «\(role.title)»")
                }
            }
            var seen = Set<String>()
            reasons = reasons.filter { seen.insert($0).inserted }
            guard !reasons.isEmpty else { return nil }
            return ProjectRecommendation(project: project, reasons: reasons, score: reasons.count)
        }
        .sorted { $0.score == $1.score ? $0.project.title < $1.project.title : $0.score > $1.score }
    }
}
