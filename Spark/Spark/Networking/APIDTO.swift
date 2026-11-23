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
}

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
        case locationName = "location_name"
        case latitude, longitude
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case deadline, reward
    }

    func makeOpportunity() -> Opportunity {
        let category = EventCategory(rawValue: category) ?? .other
        let presentation = category.presentation

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
            status: "АКТУАЛЬНО",
            reward: reward,
            organizer: organizer,
            latitude: latitude,
            longitude: longitude
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

struct ProjectDTO: Codable {
    let id: UUID?
    let ownerID: UUID?
    let category: String
    let title: String
    let summary: String
    let ownerRole: String
    let roles: [ProjectRoleDTO]

    enum CodingKeys: String, CodingKey {
        case id, category, title, summary, roles
        case ownerID = "owner_id"
        case ownerRole = "owner_role"
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
            }
        )
    }
}

struct ProjectUpdateRequest: Encodable {
    let category: String
    let title: String
    let summary: String
    let ownerRole: String

    enum CodingKeys: String, CodingKey {
        case category, title, summary
        case ownerRole = "owner_role"
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
    let region: String
    let bio: String
    let skills: [String]
    let interests: [String]
    let accountType: String
    let organizationName: String?
    let organizationStatus: String?

    enum CodingKeys: String, CodingKey {
        case id, email, name, region, bio, skills, interests
        case accountType = "account_type"
        case organizationName = "organization_name"
        case organizationStatus = "organization_status"
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

    enum CodingKeys: String, CodingKey {
        case category, title, summary, details, latitude, longitude, deadline, reward
        case imageURL = "image_url"
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
    let region: String
    let bio: String
    let skills: [String]
    let interests: [String]
}

struct PublicProfileDTO: Identifiable, Decodable, Equatable {
    let id: UUID
    let name: String
    let region: String
    let bio: String
    let skills: [String]
    let interests: [String]
    let friendshipStatus: String

    enum CodingKeys: String, CodingKey {
        case id, name, region, bio, skills, interests
        case friendshipStatus = "friendship_status"
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
