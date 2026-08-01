//
//  ProjectView.swift
//  Spark
//
//  Created by YULIYA MAKSIMCHYK on 23.06.2026.
//

import SwiftUI

struct ProjectView: View {

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                
           
                ScrollView {
                   
                    VStack(spacing: 0) {
                        
                        HStack {
                            Spacer()
                            
                            ActiveProject(color: .litePurple, imageName: "sparkles", title: "ПРОЕКТЫ", status: "активных", type: .count(2), isActive: true, strokeWidht: 3, titleSize: 30)
                            
                            ActiveProject(color: .green, imageName: "person.2", title: "РОЛИ",  status: "открыто", type: .count(3), isActive: true, strokeWidht: 3, titleSize: 30)
                           
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Активные проекты")
                                .font(.system(size: 20, weight: .bold))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 20)
                        
                        CardActiveProject(category: "EDTECH", color: .litePurple, title: "EduScan: AI-помощник для школьников", description: "Мобильное приложение, которое помогает школьникам готовиться к ЦТ и ЦЭ с помощью ИИ. Распознаёт задания по фото", vacancies:  [
                            Vacancy(title: "Flutter Developer", imageName: "terminal", status: "НУЖЕН", roleDescription: "Dart/Firebase", isActive: true),
                            Vacancy(title: "ML Engineer", imageName: "terminal", status: "НУЖЕН", roleDescription: "Python/PyTorch", isActive: true),
                            Vacancy(title: "UI/UX Designer", imageName: "terminal", status: "ЗАНЯТО", roleDescription: "Figma/Прототипирование", isActive: false),
                            Vacancy(title: "UI/UX Designer", imageName: "terminal", status: "ЗАНЯТО", roleDescription: "Figma/Прототипирование", isActive: false)
                        ])
                        
                        
                        .padding(.bottom, 16)
                        
                        CardActiveProject(category: "EDTECH", color: .green, title: "EduScan: AI-помощник для школьников", description: "Мобильное приложение, которое помогает школьникам готовиться к ЦТ и ЦЭ с помощью ИИ. Распознаёт задания по фото", vacancies:  [
                            Vacancy(title: "Flutter Developer", imageName: "terminal", status: "НУЖЕН", roleDescription: "Dart/Firebase", isActive: true),
                            Vacancy(title: "ML Engineer", imageName: "terminal", status: "НУЖЕН", roleDescription: "Python/PyTorch", isActive: true),
                            Vacancy(title: "UI/UX Designer", imageName: "terminal", status: "ЗАНЯТО", roleDescription: "Figma/Прототипирование", isActive: false),
                            Vacancy(title: "UI/UX Designer", imageName: "terminal", status: "ЗАНЯТО", roleDescription: "Figma/Прототипирование", isActive: false)
                        ])
                        
                    }
                    .padding(.top, 80)
                    
                    
                    
                }
                .padding(.horizontal, 20)
                
               
                ZStack {
                    LinearGradient(
                        colors: [
                            Color("PrimaryBlue"),
                            Color("PrimaryLitePurple"),
                            Color("PrimaryPurple")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea(edges: .top)
                    
                    Circle()
                        .fill(.primaryYellow)
                        .blur(radius: 60)
                        .frame(width: 100, height: 120)
                        .offset(x: 160, y: 8)
                    
                    HStack {
                        Text("ProjectHub")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primaryWhite)
                        
                        Spacer()
                        
                        ZStack {
                            Rectangle()
                                .fill(.primaryWhite)
                                .opacity(0.4)
                                .cornerRadius(30)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "folder")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22)
                                .foregroundStyle(.primaryWhite)
                        }
                    }
                    .padding(.top, 50)
                    .padding(.horizontal, 20)
                }
                .frame(height: 0)
                .zIndex(1)
                
            }
        }
    }
}

#Preview {
    ProjectView()
}
