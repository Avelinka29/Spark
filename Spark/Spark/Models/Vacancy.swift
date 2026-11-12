import Foundation

struct Vacancy: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var imageName: String
    var status: String
    var roleDescription: String
    var isActive: Bool

    init(
        id: UUID = UUID(),
        title: String,
        imageName: String = "terminal",
        status: String = "НУЖЕН",
        roleDescription: String,
        isActive: Bool = true
    ) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.status = status
        self.roleDescription = roleDescription
        self.isActive = isActive
    }
}
