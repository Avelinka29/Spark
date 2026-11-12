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
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    
    let vacancies: [Vacancy]
    
    var countOpen: Int {
        vacancies.filter {$0.isActive}.count
    }
    
    var countClose: Int {
        vacancies.filter {!$0.isActive}.count
    }
    
    
    var body: some View {
        
        
        VStack(alignment: .leading, spacing: 14) {
            Text(category)
                .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primaryWhite)
                    .opacity(0.6)

            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primaryWhite)

            Text(description)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primaryWhite.opacity(0.72))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if !vacancies.isEmpty {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(vacancies) { vacancy in
                        ProjectRoleCard(vacancy: vacancy)
                    }
                }
            }

            HStack(spacing: 8) {
                Text("\(countOpen) открыто")
                    .foregroundStyle(.primaryYellow)

                Text("\(countClose) занято")
                    .foregroundStyle(.primaryWhite.opacity(0.6))

                Spacer(minLength: 8)

                Label(
                    isAuthenticated ? "Подробнее" : "Войдите",
                    systemImage: isAuthenticated ? "arrow.right" : "lock"
                )
                .foregroundStyle(.primaryWhite)
                .font(.system(size: 15, weight: .semibold))
                .padding(.horizontal, 14)
                .frame(minHeight: 40)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.primaryWhite, lineWidth: 1)
                }
            }
            .font(.system(size: 16, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(color.color)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct ProjectRoleCard: View {
    let vacancy: Vacancy

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(vacancy.title, systemImage: vacancy.imageName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.primaryWhite.opacity(0.72))
                .lineLimit(2)

            Text(vacancy.roleDescription)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.primaryWhite)
                .lineLimit(2)

            Text(vacancy.status)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.primaryWhite.opacity(0.72))
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        .padding(14)
        .background(
            vacancy.isActive
                ? Color.white.opacity(0.18)
                : Color.black.opacity(0.16)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            if vacancy.isActive {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.primaryWhite.opacity(0.32), lineWidth: 2)
            }
        }
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
