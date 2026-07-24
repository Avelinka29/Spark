//
//  MockOpportunity.swift
//  Spark
//
//  Created by Avelina Maksimchik on 09.07.2026.
//

import SwiftUI
import MapKit

let mockOpportunities = [
    
    Opportunity(
            title: "AI Hackathon Sber",
            description: "48 часов разработки",
            category: .hackathons,
            coordinate: CLLocationCoordinate2D(
                latitude: 53.9023,
                longitude: 27.5619
            ),
            address: "Минск",
            color: .litePurple
            
        ),

        Opportunity(
            title: "EPAM Internship",
            description: "Junior iOS",
            category: .internships,
            coordinate: CLLocationCoordinate2D(
                latitude: 53.9045,
                longitude: 27.5670
            ),
            address: "Минск",
            color: .green
            
        ),

        Opportunity(
            title: "BSUIR Grant",
            description: "Первый проект",
            category: .grants,
            coordinate: CLLocationCoordinate2D(
                latitude: 53.9001,
                longitude: 27.5490
            ),
            address: "Минск",
            color: .yellow
           
        )
    
    
    
]
    



