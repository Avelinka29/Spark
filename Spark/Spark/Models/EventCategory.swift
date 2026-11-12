import Foundation

enum EventCategory: String, CaseIterable, Codable, Hashable {
    case all = "Все"
    case hackathons = "Хакатоны"
    case teams = "Команды"
    case internships = "Стажировки"
    case grants = "Гранты"
    case contests = "Конкурсы"
    case volunteering = "Волонтерство"
    case meetups = "Мероприятия"
    case other = "Другое"
}
