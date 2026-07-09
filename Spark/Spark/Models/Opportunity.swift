//
//  ResultMapModel.swift
//  Spark
//
//  Created by Avelina Maksimchik on 08.07.2026.
//

import Foundation
import MapKit
import SwiftUI

struct Place: Identifiable {
    let id: UUID = UUID()
    let title: String
    let category: String
    let placemark: MKPlacemark
    let color: Color
    let coordinate: CLLocationCoordinate2D
    let address: String
}


