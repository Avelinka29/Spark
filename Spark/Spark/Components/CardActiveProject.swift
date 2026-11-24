//
//  CardActiveProject.swift
//  Spark
//
//  Created by Avelina Maksimchik on 24.07.2026.
//

import SwiftUI

struct CardActiveProject: View {
    
    let category: String
    let color: SparkColor
    let title: String
    let description: String
    let isAuthenticated: Bool
    
    let vacancies: [Vacancy]
    
    var countOpen: Int {
        vacancies.filter {$0.isActive}.count
    }
    
    
    var body: some View {
        
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(category)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(color.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(color.color.opacity(0.1), in: Capsule())
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            Text(title).font(.headline).foregroundStyle(.primary)
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            Divider().padding(.vertical, 2)
            Label("Открытых ролей: \(countOpen)", systemImage: "person.2")
                .font(.caption.weight(.semibold))
                .foregroundStyle(color.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    CardActiveProject(category: "EDTECH", color: .litePurple, title: "EduScan: AI-помощник для школьников", description: "Мобильное приложение, которое помогает школьникам готовиться к ЦТ и ЦЭ с помощью ИИ. Распознаёт задания по фото", isAuthenticated: false, vacancies:  [
        Vacancy(title: "Flutter Developer", imageName: "terminal", status: "НУЖЕН", roleDescription: "Dart/Firebase", isActive: true),
        Vacancy(title: "ML Engineer", imageName: "terminal", status: "НУЖЕН", roleDescription: "Python/PyTorch", isActive: true),
        Vacancy(title: "UI/UX Designer", imageName: "terminal", status: "ЗАНЯТО", roleDescription: "Figma/Прототипирование", isActive: false),
        Vacancy(title: "UI/UX Designer", imageName: "terminal", status: "ЗАНЯТО", roleDescription: "Figma/Прототипирование", isActive: false)
    ])
}
