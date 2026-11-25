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
            HStack(spacing: 12) {
                SparkTileIcon(symbol: "folder.fill")
                VStack(alignment: .leading, spacing: 4) {
                    Text(category)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            if !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Divider()

            Label(countOpen == 0 ? "Набор закрыт" : "Открытые роли: \(countOpen)", systemImage: "person.2")
                .font(.caption.weight(.semibold))
                .foregroundStyle(countOpen == 0 ? Color.secondary : color.color)
        }
        .sparkCard()
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
