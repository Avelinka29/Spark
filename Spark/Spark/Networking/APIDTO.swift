import Foundation
import SwiftUI

struct AuthRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let name: String
    let username: String
    let organizationName: String?
    enum CodingKeys: String, CodingKey {
        case email, password, name, username
        case organizationName = "organization_name"
    }
}

struct UsernameRequest: Encodable { let username: String }
struct PortfolioVisibilityRequest: Encodable {
    let portfolioPublic: Bool
    enum CodingKeys: String, CodingKey { case portfolioPublic = "portfolio_public" }
}
struct UsernameLookup: Decodable { let id: UUID; let name: String; let username: String }

struct EmailRequest: Encodable {
    let email: String
}

struct VerifyCodeRequest: Encodable {
    let email: String
    let code: String
}

struct ResetPasswordRequest: Encodable {
    let email: String
    let code: String
    let newPassword: String

    enum CodingKeys: String, CodingKey {
        case email, code
        case newPassword = "new_password"
    }
}

struct MessageResponse: Decodable {
    let message: String
    let developmentCode: String?

    enum CodingKeys: String, CodingKey {
        case message
        case developmentCode = "development_code"
    }
}

struct AvatarDTO: Codable {
    let data: String
    let contentType: String

    enum CodingKeys: String, CodingKey {
        case data
        case contentType = "content_type"
    }
}

struct GoogleAuthRequest: Encodable {
    let idToken: String

    enum CodingKeys: String, CodingKey {
        case idToken = "id_token"
    }
}

struct TokenResponse: Decodable {
    let accessToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}

struct OpportunityDTO: Decodable {
    let id: UUID
    let category: String
    let title: String
    let summary: String
    let details: String
    let organizer: String
    let sourceURL: String?
    let registrationURL: String?
    let acceptsRegistrations: Bool?
    let ownerID: UUID?
    let imageURL: String?
    let locationName: String
    let latitude: Double?
    let longitude: Double?
    let startsAt: String?
    let endsAt: String?
    let deadline: String?
    let reward: Int?

    enum CodingKeys: String, CodingKey {
        case id, category, title, summary, details, organizer
        case imageURL = "image_url"
        case sourceURL = "source_url"
        case registrationURL = "registration_url"
        case acceptsRegistrations = "accepts_registrations"
        case ownerID = "owner_id"
        case locationName = "location_name"
        case latitude, longitude
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case deadline, reward
    }

    func makeOpportunity() -> Opportunity {
        let category = EventCategory(rawValue: category) ?? .other
        let presentation = category.presentation
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        let today = Calendar.current.startOfDay(for: Date())
        let endDate = (endsAt ?? startsAt).flatMap { formatter.date(from: $0) }
        let deadlineDate = deadline.flatMap { formatter.date(from: $0) }
        let status: String?
        if let endDate, endDate < today {
            status = "ЗАВЕРШЕНО"
        } else if let deadlineDate, deadlineDate < today {
            status = "ПРИЁМ ЗАКРЫТ"
        } else if endDate != nil || deadlineDate != nil {
            status = "АКТУАЛЬНО"
        } else {
            status = nil
        }

        return Opportunity(
            id: id,
            imageName: presentation.imageName,
            category: category,
            title: title,
            summary: summary,
            details: details,
            themeColor: presentation.color.color,
            mapColor: presentation.color,
            dateText: [startsAt, endsAt].compactMap { $0 }.joined(separator: " — "),
            deadlineText: deadline ?? "Не указан",
            participantCount: nil,
            locationName: locationName,
            status: status,
            reward: reward,
            organizer: organizer,
            latitude: latitude,
            longitude: longitude
            , sourceURL: sourceURL, registrationURL: registrationURL,
            acceptsRegistrations: acceptsRegistrations ?? false, ownerID: ownerID
        )
    }
}

struct ProjectRoleDTO: Codable {
    let id: UUID?
    let title: String
    let skills: String
    let isOpen: Bool?

    enum CodingKeys: String, CodingKey {
        case id, title, skills
        case isOpen = "is_open"
    }
}

struct AIProjectMatchDTO: Decodable, Identifiable {
    let id: UUID
    let reason: String
}

struct AIFeedbackRequest: Encodable { let helpful: Bool }

struct ProjectDTO: Codable {
    let id: UUID?
    let ownerID: UUID?
    let category: String
    let title: String
    let summary: String
    let ownerRole: String
    let roles: [ProjectRoleDTO]
    var resultURL: String? = nil

    enum CodingKeys: String, CodingKey {
        case id, category, title, summary, roles
        case ownerID = "owner_id"
        case ownerRole = "owner_role"
        case resultURL = "result_url"
    }

    func makeProject() -> Project {
        Project(
            id: id ?? UUID(),
            ownerID: ownerID,
            category: category,
            title: title,
            summary: summary,
            ownerRole: ownerRole,
            vacancies: roles.map {
                Vacancy(
                    id: $0.id ?? UUID(),
                    title: $0.title,
                    status: ($0.isOpen ?? true) ? "НУЖЕН" : "ЗАНЯТО",
                    roleDescription: $0.skills,
                    isActive: $0.isOpen ?? true
                )
            }, resultURL: resultURL
        )
    }
}

struct ProjectUpdateRequest: Encodable {
    let category: String
    let title: String
    let summary: String
    let ownerRole: String
    let resultURL: String

    enum CodingKeys: String, CodingKey {
        case category, title, summary
        case ownerRole = "owner_role"
        case resultURL = "result_url"
    }
}

struct ProjectRoleCreateRequest: Encodable {
    let title: String
    let skills: String
}

struct ProjectApplicationDTO: Identifiable, Decodable {
    let id: UUID
    let userID: UUID
    let userName: String
    let roleID: UUID
    let roleTitle: String
    let projectID: UUID
    let projectTitle: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case id, status
        case userID = "user_id"
        case userName = "user_name"
        case roleID = "role_id"
        case roleTitle = "role_title"
        case projectID = "project_id"
        case projectTitle = "project_title"
    }
}

struct ApplicationStatusRequest: Encodable {
    let status: String
}

struct ProfileDTO: Decodable {
    let id: UUID
    let email: String
    let name: String
    let username: String?
    let region: String
    let bio: String
    let skills: [String]
    let interests: [String]
    let accountType: String
    let organizationName: String?
    let organizationStatus: String?
    let portfolioPublic: Bool
    let birthDate: String?

    enum CodingKeys: String, CodingKey {
        case id, email, name, username, region, bio, skills, interests
        case accountType = "account_type"
        case organizationName = "organization_name"
        case organizationStatus = "organization_status"
        case portfolioPublic = "portfolio_public"
        case birthDate = "birth_date"
    }

    func makeProfile() -> UserProfile {
        UserProfile(
            id: id,
            name: name,
            region: region,
            bio: bio,
            skills: skills,
            interests: interests,
            achievements: [],
            accountType: accountType,
            organizationName: organizationName,
            organizationStatus: organizationStatus
            , username: username, portfolioPublic: portfolioPublic, birthDate: birthDate
        )
    }
}

struct OrganizationProfileRequest: Encodable {
    let organizationName: String

    enum CodingKeys: String, CodingKey {
        case organizationName = "organization_name"
    }
}

struct OrganizationApplicationDTO: Decodable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    let organizationName: String
    let organizationStatus: String

    enum CodingKeys: String, CodingKey {
        case id, name, email
        case organizationName = "organization_name"
        case organizationStatus = "organization_status"
    }
}

struct OrganizationDecisionRequest: Encodable {
    let status: String
}

struct AttendingFriendDTO: Decodable, Identifiable {
    let id: UUID
    let name: String
}

struct AttendanceDTO: Decodable {
    let going: Bool
    let attended: Bool
    let verified: Bool
    let friends: [AttendingFriendDTO]
}

struct AttendanceParticipantDTO: Decodable, Identifiable {
    let id: UUID
    let name: String
    let verified: Bool
}

struct TeamTaskDTO: Decodable, Identifiable {
    let id: UUID
    let title: String
    let done: Bool
}

struct TeamTaskCreateRequest: Encodable { let title: String }
struct TeamTaskUpdateRequest: Encodable { let done: Bool }
struct TeamWorkspaceDTO: Codable {
    var links: String = ""
    var meeting: String = ""
}

struct OpportunityCreateRequest: Codable {
    let category: String
    let title: String
    let summary: String
    let details: String
    let imageURL: String?
    let locationName: String
    let latitude: Double
    let longitude: Double
    let startsAt: String?
    let endsAt: String?
    let deadline: String?
    let reward: Int?
    var sourceURL: String? = nil
    var registrationURL: String? = nil
    var acceptsRegistrations: Bool? = nil

    enum CodingKeys: String, CodingKey {
        case category, title, summary, details, latitude, longitude, deadline, reward
        case imageURL = "image_url"
        case sourceURL = "source_url"
        case registrationURL = "registration_url"
        case acceptsRegistrations = "accepts_registrations"
        case locationName = "location_name"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
    }
}

struct EventProposalCreateRequest: Encodable {
    let event: OpportunityCreateRequest
    let message: String
}

struct EventProposalDecisionRequest: Encodable {
    let status: String
}

struct EventProposalDTO: Identifiable, Decodable {
    let id: UUID
    let authorID: UUID
    let authorName: String
    let event: OpportunityCreateRequest
    let message: String
    let status: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, event, message, status
        case authorID = "author_id"
        case authorName = "author_name"
        case createdAt = "created_at"
    }
}

struct ProfileUpdateRequest: Encodable {
    let name: String
    let birthDate: String?

    enum CodingKeys: String, CodingKey { case name, region, bio, skills, interests; case birthDate = "birth_date" }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(birthDate, forKey: .birthDate)
        try container.encode(region, forKey: .region)
        try container.encode(bio, forKey: .bio)
        try container.encode(skills, forKey: .skills)
        try container.encode(interests, forKey: .interests)
    }
    let region: String
    let bio: String
    let skills: [String]
    let interests: [String]
}

struct PublicProfileDTO: Identifiable, Decodable, Equatable {
    let id: UUID
    let name: String
    let username: String?
    let region: String
    let bio: String
    let skills: [String]
    let interests: [String]
    let friendshipStatus: String
    let portfolioVisible: Bool
    let projects: [PortfolioProjectDTO]
    let events: [PortfolioEventDTO]

    enum CodingKeys: String, CodingKey {
        case id, name, username, region, bio, skills, interests, projects, events
        case friendshipStatus = "friendship_status"
        case portfolioVisible = "portfolio_visible"
    }
}

struct PortfolioEventDTO: Decodable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let verified: Bool
    let startsAt: String?
    enum CodingKeys: String, CodingKey {
        case id, title, verified
        case startsAt = "starts_at"
    }
}

struct PortfolioProjectDTO: Decodable, Identifiable, Equatable {
    let projectID: UUID
    let title: String
    let role: String
    let roleID: UUID?
    let resultURL: String?
    var id: String { roleID?.uuidString ?? projectID.uuidString }

    enum CodingKeys: String, CodingKey {
        case projectID = "id"
        case roleID = "role_id"
        case resultURL = "result_url"
        case title, role
    }
}

struct FriendDTO: Identifiable, Decodable, Equatable {
    let friendshipID: UUID
    let userID: UUID
    let name: String
    let region: String
    let status: String

    var id: UUID { friendshipID }

    enum CodingKeys: String, CodingKey {
        case name, region, status
        case friendshipID = "friendship_id"
        case userID = "user_id"
    }
}

struct ChatDTO: Identifiable, Decodable, Equatable {
    let id: UUID
    let projectID: UUID
    let projectTitle: String
    let memberCount: Int
    let lastMessage: String?
    let lastMessageAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case projectID = "project_id"
        case projectTitle = "project_title"
        case memberCount = "member_count"
        case lastMessage = "last_message"
        case lastMessageAt = "last_message_at"
    }
}

struct ChatMessageDTO: Identifiable, Decodable, Equatable {
    let id: UUID
    let chatID: UUID
    let senderID: UUID
    let senderName: String
    let text: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, text
        case chatID = "chat_id"
        case senderID = "sender_id"
        case senderName = "sender_name"
        case createdAt = "created_at"
    }
}

struct ChatMessageCreateRequest: Encodable {
    let text: String
}

struct AchievementDTO: Identifiable, Codable {
    let id: UUID?
    let title: String
    let issuer: String
    let issuedAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, issuer
        case issuedAt = "issued_at"
    }

    func makeAchievement() -> Achievement? {
        let components = issuedAt.split(separator: "-").compactMap { Int($0) }
        guard components.count == 3,
              let date = Calendar.current.date(
                from: DateComponents(
                    year: components[0],
                    month: components[1],
                    day: components[2]
                )
              ) else {
            return nil
        }
        return Achievement(
            id: id ?? UUID(),
            title: title,
            issuer: issuer,
            issuedAt: date
        )
    }
}

private extension EventCategory {
    var presentation: (color: SparkColor, imageName: String) {
        switch self {
        case .hackathons:
            return (.litePurple, "Hahaton")
        case .internships:
            return (.green, "stazh_Yandex")
        case .grants:
            return (.yellow, "granty")
        case .contests:
            return (.litePurple, "olimpiada")
        case .volunteering:
            return (.pink, "volunteer")
        case .meetups:
            return (.blue, "meropriyatiya")
        case .teams, .other, .all:
            return (.purple, "meropriyatiya")
        }
    }
}
