import SwiftUI
import MapKit

final class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // MARK: - Location
    
    private let locationManager = CLLocationManager()
    
//    @Published var region = MKCoordinateRegion(
//        center: CLLocationCoordinate2D(
//            latitude: 53.9023,
//            longitude: 27.5619
//        ),
//        span: MKCoordinateSpan(
//            latitudeDelta: 0.02,
//            longitudeDelta: 0.05
//        )
//    )
    
    @Published var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: 53.9023,
                longitude: 27.5619
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.02,
                longitudeDelta: 0.05
            )
        )
    )
    
    // MARK: - Search
    
    @Published var searchText = ""
    
    @Published var selectedCategory: EventCategory = .all
    
    // MARK: - Opportunities
    
    @Published private(set) var opportunities = mockOpportunities
    
    @Published var selectedOpportunity: Opportunity?
    
    @Published var isShowDetails = false
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        checkLocationIsEnabled()
    }
    
    private func checkLocationIsEnabled() {
        
        guard CLLocationManager.locationServicesEnabled() else {
            return
        }
        
        checkLocationAuthorization()
    }
    
    private func checkLocationAuthorization() {
        
        switch locationManager.authorizationStatus {
            
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            
        case .authorizedWhenInUse,
                .authorizedAlways:
            
            locationManager.startUpdatingLocation()
            
            if let location = locationManager.location {
                
                
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(
                            latitudeDelta: 0.02,
                            longitudeDelta: 0.05
                        )
                    )
                )
            }
            
        case .restricted:
            print("Location restricted")
            
        case .denied:
            print("Location denied")
            
        @unknown default:
            break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {

        checkLocationAuthorization()
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.first else { return }

        cameraPosition = .region(
            MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.02,
                    longitudeDelta: 0.05
                )
            )
        )

        locationManager.stopUpdatingLocation()
    }
    
    var filteredOpportunities: [Opportunity] {

        opportunities.filter {

            ($0.category == selectedCategory ||
             selectedCategory == .all)

            &&

            (searchText.isEmpty ||
             $0.title.localizedCaseInsensitiveContains(searchText))
        }
    }
    
    var opportunitiesCount: Int {

        filteredOpportunities.count
    }
    
    func select(_ opportunity: Opportunity) {

        selectedOpportunity = opportunity

        isShowDetails = true
    }
    
    func focus(on opportunity: Opportunity) {
        withAnimation(.easeInOut(duration: 0.35)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: opportunity.coordinate,
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.02,
                        longitudeDelta: 0.05
                    )
                )
            )
        }
    }
    
    func resetFilters() {
        searchText = ""
        selectedCategory = .all
    }
    
    func distance (from coordinate: CLLocationCoordinate2D) -> String {
        
        guard let location = locationManager.location else {
            return ""
        }
        
        let destination = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
            
        let distance = location.distance(from: destination)
        
        switch distance {
        case ..<1000:
            return "\(Int(distance)) м"
        default:
            return String(format: "%.1f км", distance/1000)
        }
        
    }
}
