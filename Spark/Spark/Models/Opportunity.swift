import Foundation
import MapKit
import SwiftUI

struct Opportunity: Identifiable {
    let id: UUID
    let imageName: String
    let category: EventCategory
    let title: String
    let summary: String
    let details: String
    let themeColor: Color
    let mapColor: SparkColor
    let dateText: String
    let deadlineText: String
    let participantCount: Int?
    let locationName: String
    let status: String?
    let reward: Int?
    let organizer: String
    let latitude: Double?
    let longitude: Double?

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else {
            return nil
        }

        return CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
    }
}
