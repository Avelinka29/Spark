//
//  SwiftUIView.swift
//  Spark
//
//  Created by YULIYA MAKSIMCHYK on 23.06.2026.
//

import SwiftUI

struct SwiftUIView: View {
    
    enum EventCategory: String {
        case all = "Все"
        case hackathons = "Хахатоны"
        case teams = "Команды"
        case internships = "Стажировки"
        case grants = "Гранты"
        case contests = "Конкурсы"
        case volunteering = "Волонтерство"
        case other = "Другое"
        
    }
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    SwiftUIView()
}
