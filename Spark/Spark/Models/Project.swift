import Foundation

struct Project: Identifiable, Equatable, Codable {
    let id: UUID
    let ownerID: UUID?
    var category: String
    var title: String
    var summary: String
    var ownerRole: String
    var vacancies: [Vacancy]
    var memberCount: Int

    init(
        id: UUID = UUID(),
        ownerID: UUID? = nil,
        category: String,
        title: String,
        summary: String,
        ownerRole: String,
        vacancies: [Vacancy],
        memberCount: Int = 1
    ) {
        self.id = id
        self.ownerID = ownerID
        self.category = category
        self.title = title
        self.summary = summary
        self.ownerRole = ownerRole
        self.vacancies = vacancies
        self.memberCount = memberCount
    }
}
