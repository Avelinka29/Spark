import CoreLocation
import MapKit
import Observation
import SwiftUI

struct MapOpportunityGroup: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let opportunities: [Opportunity]
}

@MainActor
@Observable
final class MapViewModel: NSObject, @preconcurrency CLLocationManagerDelegate {
    var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 53.9023, longitude: 27.5619),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.05)
        )
    )
    var searchText = "" {
        didSet { updateVisibleOpportunities() }
    }
    var selectedCategory: EventCategory = .all {
        didSet { updateVisibleOpportunities() }
    }
    var selectedOpportunity: Opportunity?

    private(set) var visibleOpportunities: [Opportunity]
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var locationDenied = false
    private(set) var locationError: String?
    private var visibleMapRect: MKMapRect?

    @ObservationIgnored
    private let locationManager = CLLocationManager()

    private var opportunities: [Opportunity]

    override init() {
        opportunities = []
        visibleOpportunities = []
        super.init()

        locationManager.delegate = self
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response: [OpportunityDTO] = try await APIClient.shared.send(
                path: "opportunities"
            )
            opportunities = response
                .map { $0.makeOpportunity() }
                .filter { $0.coordinate != nil }
            updateVisibleOpportunities()
        } catch {
            opportunities = []
            visibleOpportunities = []
            selectedOpportunity = nil
            errorMessage = "Не удалось загрузить возможности для карты."
        }
    }

    var opportunitiesCount: Int {
        guard let visibleMapRect else { return 0 }
        return visibleOpportunities.filter { opportunity in
            guard let coordinate = opportunity.coordinate else { return false }
            return visibleMapRect.contains(MKMapPoint(coordinate))
        }.count
    }

    var pinGroups: [MapOpportunityGroup] {
        let groups = Dictionary(grouping: visibleOpportunities) { opportunity in
            "\(opportunity.latitude ?? 0),\(opportunity.longitude ?? 0)"
        }
        return groups.compactMap { key, opportunities in
            guard let coordinate = opportunities.first?.coordinate else { return nil }
            return MapOpportunityGroup(id: key, coordinate: coordinate, opportunities: opportunities)
        }.sorted { $0.id < $1.id }
    }

    func updateVisibleMapRect(_ rect: MKMapRect) {
        visibleMapRect = rect
    }

    func requestLocation() {
        locationError = nil
        checkLocationAvailability()
    }

    func select(_ opportunity: Opportunity) {
        selectedOpportunity = opportunity
        focus(on: opportunity)
    }

    func focus(on opportunity: Opportunity) {
        guard let coordinate = opportunity.coordinate else {
            return
        }

        withAnimation(.easeInOut(duration: 0.35)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.05)
                )
            )
        }
    }

    func resetFilters() {
        searchText = ""
        selectedCategory = .all
    }

    func distance(from coordinate: CLLocationCoordinate2D) -> String {
        guard let location = locationManager.location else {
            return "расстояние неизвестно"
        }

        let destination = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        let distance = location.distance(from: destination)

        if distance < 1_000 {
            return "\(Int(distance)) м"
        }

        return String(format: "%.1f км", distance / 1_000)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationDenied = manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            locationError = nil
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let locationError = error as? CLError, locationError.code == .denied {
            locationDenied = true
            self.locationError = nil
        } else {
            locationError = "Не удалось определить местоположение. Можно продолжить пользоваться картой."
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.first else {
            return
        }

        locationError = nil

        cameraPosition = .region(
            MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.05)
            )
        )
        locationManager.stopUpdatingLocation()
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
                opportunity.summary.localizedCaseInsensitiveContains(normalizedSearch)

            return matchesCategory && matchesSearch
        }
        if let selectedOpportunity,
           !visibleOpportunities.contains(where: { $0.id == selectedOpportunity.id }) {
            self.selectedOpportunity = nil
        }
    }

    private func checkLocationAvailability() {
        guard CLLocationManager.locationServicesEnabled() else {
            return
        }

        checkLocationAuthorization()
    }

    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .restricted, .denied:
            break
        @unknown default:
            break
        }
    }
}
