//
//  ResultMapModel.swift
//  Spark
//
//  Created by Avelina Maksimchik on 08.07.2026.
//

import MapKit
import SwiftUI

struct Opportunity: Identifiable {

    let id = UUID()

    let title: String
    let description: String
    let category: EventCategory

    let coordinate: CLLocationCoordinate2D
    let address: String

    let color: SparkColor
    
    
}


