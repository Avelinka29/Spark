import Foundation

struct OpportunityRecommendation: Identifiable {
    let opportunity: Opportunity
    let reason: String
    var id: UUID { opportunity.id }
}

enum OpportunityRecommendations {
    static func matching(_ opportunities: [Opportunity], interests: [String], now: Date = Date()) -> [OpportunityRecommendation] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        let today = Calendar.current.startOfDay(for: now)
        return opportunities.compactMap { opportunity in
            if let deadline = formatter.date(from: opportunity.deadlineText), deadline < today { return nil }
            let end = opportunity.dateText.components(separatedBy: " — ").last ?? ""
            if let endDate = formatter.date(from: end), endDate < today { return nil }
            let text = "\(opportunity.category.rawValue) \(opportunity.title) \(opportunity.summary) \(opportunity.details)"
            guard let interest = interests.first(where: {
                let value = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                return value.count >= 2 && text.localizedCaseInsensitiveContains(value)
            }) else { return nil }
            return OpportunityRecommendation(opportunity: opportunity, reason: "Твой интерес: \(interest)")
        }
    }
}
