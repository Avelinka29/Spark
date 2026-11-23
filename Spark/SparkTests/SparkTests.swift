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

struct ProjectRecommendationTests {
    @Test
    func matchesSkillsAndInterestsOnlyForOpenRoles() {
        let profile = UserProfile(id: UUID(), name: "Test", region: "", bio: "", skills: ["Swift"], interests: ["EdTech"], achievements: [])
        let project = Project(category: "EdTech", title: "Project", summary: "Learning", ownerRole: "Founder", vacancies: [Vacancy(title: "iOS", roleDescription: "Swift")])
        let matches = ProjectRecommendations.matching(projects: [project], profile: profile)
        #expect(matches.count == 1)
        #expect(matches.first?.reasons.count == 2)
        var closed = project
        closed.vacancies[0].isActive = false
        #expect(ProjectRecommendations.matching(projects: [closed], profile: profile).isEmpty)
        #expect(ProjectRecommendations.matching(projects: [project], profile: nil).isEmpty)
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

struct KeychainStoreTests {
    @Test
    func `Token can be saved read and deleted`() throws {
        let store = KeychainStore(
            service: "SparkTests.\(UUID().uuidString)",
            account: "test-token"
        )
        defer { store.deleteToken() }

        try store.saveToken("test-access-token")
        #expect(store.readToken() == "test-access-token")

        store.deleteToken()
        #expect(store.readToken() == nil)
    }
}

struct AuthValidationTests {
    @Test @MainActor
    func `Login requires email and password`() async {
        let store = makeAuthStore()

        let succeeded = await store.login(email: "", password: "")

        #expect(!succeeded)
        #expect(store.errorMessage == "Введите email и пароль.")
    }

    @Test @MainActor
    func `Registration rejects a short password before network request`() async {
        let store = makeAuthStore()

        let succeeded = await store.register(
            name: "Авелина",
            email: "avelina@example.com",
            password: "short"
        )

        #expect(!succeeded)
        #expect(store.errorMessage == "Пароль должен содержать не менее 8 символов.")
    }

    @MainActor
    private func makeAuthStore() -> AuthStore {
        let suiteName = "SparkTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return AuthStore(
            keychain: KeychainStore(service: suiteName, account: "test-token"),
            defaults: defaults
        )
    }
}
