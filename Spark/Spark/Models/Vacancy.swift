//
//  Vacancy.swift
//  Spark
//
//  Created by Avelina Maksimchik on 25.07.2026.
//

import SwiftUI

struct Vacancy: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let status: String
    let roleDescription: String
    let isActive: Bool
}


