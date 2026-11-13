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

    func makeProfile() -> UserProfile {
        UserProfile(
            id: id,
            name: name,
            region: region,
            bio: bio,
            skills: skills,
            interests: interests,
            achievements: []
        )
    }
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
