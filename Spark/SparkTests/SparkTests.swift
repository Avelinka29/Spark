import Foundation
import Testing
@testable import Spark

struct OpportunityModelTests {
    @Test @MainActor
    func `Category and search filters combine`() {
        let model = OpportunitiesViewModel(opportunities: mockOpportunities)

        model.selectedCategory = .hackathons
        model.searchText = "Сбера"

        #expect(model.visibleOpportunities.count == 1)
        #expect(model.visibleOpportunities.first?.category == .hackathons)
    }

    @Test @MainActor
    func `Empty result is represented by an empty collection`() {
        let model = OpportunitiesViewModel(opportunities: mockOpportunities)

        model.searchText = "несуществующая возможность"

        #expect(model.visibleOpportunities.isEmpty)
    }
}

struct ProjectStoreTests {
    @Test @MainActor
    func `Open role count includes only active vacancies`() {
        let project = Project(
            category: "EdTech",
            title: "Test",
            summary: "Test project summary",
            ownerRole: "Founder",
            vacancies: [
                Vacancy(title: "iOS", roleDescription: "Swift"),
                Vacancy(
                    title: "Design",
                    status: "ЗАНЯТО",
                    roleDescription: "Figma",
                    isActive: false
                )
            ]
        )
        let store = ProjectStore(projects: [project])

        #expect(store.openRolesCount == 1)
    }
}

struct APIDTOTests {
    @Test
    func `Opportunity response maps to app model`() throws {
        let data = Data(
            #"""
            {
              "id": "2A835521-238B-4BBE-AB8B-06F4D9DF01A1",
              "category": "Хакатоны",
              "title": "AI Hackathon",
              "summary": "Summary",
              "details": "Details",
              "organizer": "Spark",
              "image_url": null,
              "location_name": "Минск",
              "latitude": 53.9,
              "longitude": 27.56,
              "starts_at": "2026-05-12",
              "ends_at": "2026-05-14",
              "deadline": "2026-05-10",
              "reward": 5000
            }
            """#.utf8
        )

        let dto = try JSONDecoder().decode(OpportunityDTO.self, from: data)
        let opportunity = dto.makeOpportunity()

        #expect(opportunity.title == "AI Hackathon")
        #expect(opportunity.category == .hackathons)
        #expect(opportunity.coordinate != nil)
    }
}
