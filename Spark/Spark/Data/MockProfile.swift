import Foundation

let mockProfile = UserProfile(
    id: UUID(),
    name: "Авелина Максимчик",
    region: "Минск, Беларусь",
    bio: "Развиваю продукты, которые помогают молодым людям находить возможности и команды.",
    skills: ["Swift", "SwiftUI", "Product Design"],
    interests: ["EdTech", "Хакатоны", "Социальные проекты"],
    achievements: [
        Achievement(
            title: "Участник AI Hackathon",
            issuer: "Spark Community",
            issuedAt: .now
        )
    ]
)

let guestProfile = UserProfile(
    id: UUID(),
    name: "Гость",
    region: "Гостевой режим",
    bio: "Войдите в аккаунт, чтобы сохранять проекты, заявки и достижения.",
    skills: [],
    interests: [],
    achievements: []
)
