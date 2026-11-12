import Foundation
import Observation

@MainActor
@Observable
final class OpportunitiesViewModel {
    var searchText = "" {
        didSet { updateVisibleOpportunities() }
    }

    var selectedCategory: EventCategory = .all {
        didSet { updateVisibleOpportunities() }
    }

    private(set) var opportunities: [Opportunity]
    private(set) var visibleOpportunities: [Opportunity]
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(opportunities: [Opportunity] = mockOpportunities) {
        self.opportunities = opportunities
        self.visibleOpportunities = opportunities
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response: [OpportunityDTO] = try await APIClient.shared.send(
                path: "opportunities"
            )
            opportunities = response.map { $0.makeOpportunity() }
            updateVisibleOpportunities()
        } catch {
            errorMessage = "Сервер недоступен — показаны демонстрационные данные."
        }
    }

    func resetFilters() {
        searchText = ""
        selectedCategory = .all
    }

    private func updateVisibleOpportunities() {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        visibleOpportunities = opportunities.filter { opportunity in
            let matchesCategory =
                selectedCategory == .all ||
                opportunity.category == selectedCategory

            let matchesSearch =
                normalizedSearch.isEmpty ||
                opportunity.title.localizedCaseInsensitiveContains(normalizedSearch) ||
                opportunity.summary.localizedCaseInsensitiveContains(normalizedSearch) ||
                opportunity.organizer.localizedCaseInsensitiveContains(normalizedSearch)

            return matchesCategory && matchesSearch
        }
    }
}
