import CoreLocation
import MapKit
import Observation
import SwiftUI

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

    @ObservationIgnored
    private let locationManager = CLLocationManager()

    private let opportunities: [Opportunity]

    override init() {
        opportunities = mockOpportunities.filter { $0.coordinate != nil }
        visibleOpportunities = opportunities
        super.init()

        locationManager.delegate = self
        checkLocationAvailability()
    }

    var opportunitiesCount: Int {
        visibleOpportunities.count
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
        checkLocationAuthorization()
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.first else {
            return
        }

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
            locationManager.startUpdatingLocation()
        case .restricted, .denied:
            break
        @unknown default:
            break
        }
    }
}
