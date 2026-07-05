//
//  Event.swift
//  Spark
//
//  Created by YULIYA MAKSIMCHYK on 22.06.2026.
//

import SwiftUI

struct Event: Identifiable {
    
    let id = UUID()
    
    let image: String
    let category: EventCategory
    let title: String
    let description: String
    let color: Color
    let date: String
    let participants: Int?
    let location: String
    let status: String?
    let bonus: Int?
}
