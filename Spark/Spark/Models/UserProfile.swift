import Foundation

struct Achievement: Identifiable, Equatable, Codable {
    let id: UUID
    let title: String
    let issuer: String
    let issuedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        issuer: String,
        issuedAt: Date
    ) {
        self.id = id
        self.title = title
        self.issuer = issuer
        self.issuedAt = issuedAt
    }
}

struct UserProfile: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var region: String
    var bio: String
    var skills: [String]
    var interests: [String]
    var achievements: [Achievement]
}
