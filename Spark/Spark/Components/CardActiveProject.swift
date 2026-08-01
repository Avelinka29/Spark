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
    
    let colomns = [
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
        
        
        ZStack{
            
            VStack(alignment: .leading, spacing: 6) {
                
                
                VStack{
                    Text("\(category)")
                }.font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primaryWhite)
                    .opacity(0.6)
                    .padding(.vertical, 10)
                
                VStack {
                    Text("\(title)")
                }.font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primaryWhite)
                
                VStack {
                    Text("\(description)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primaryWhite)
                        .opacity(0.7)
                        .lineSpacing(4)
                        .padding(.bottom, 10)
                }
                
                
                
                
                LazyVGrid(columns: colomns, spacing: 12) {
                    
                    ForEach(vacancies) {vacancy in
                        
                        ActiveProject(color: .white, imageName: vacancy.imageName, title: vacancy.title, status: vacancy.status, type: .role(vacancy.roleDescription), isActive: vacancy.isActive, strokeWidht: 3, titleSize: 14)
                        
                        
                    }
                    
                }
                
                HStack {
                    Text("\(countOpen) открыто")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primaryYellow)
                    
                    Text("\(countClose) занято")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primaryWhite.opacity(0.6))
                    
                    Spacer()
                    
                    Button{}
                    label: {
                        HStack(spacing: 10){
                            
                            Text("Присоединиться")
                                .foregroundColor(.primaryWhite)
                                .font(.system(size: 16, weight: .semibold))
                                .padding(.horizontal, 16)
                            
                        }
                        .frame(width: 170)
                        .frame(height: 35)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(.primaryWhite, lineWidth: 1))
                        .shadow(color: .black.opacity(0.2),
                                radius: 4,
                                x: 0,
                                y: 5)
                        
                        
                    }.frame(maxWidth: .infinity, alignment: .trailing)
                    
                    
                    
                }.padding(.top, 10)
                
                
                
                
            }.frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 20)
                .padding(.horizontal, 10)
                .background(color.color)
                .cornerRadius(20)
        }
       
        
    }
}

#Preview {
    CardActiveProject(category: "EDTECH", color: .litePurple, title: "EduScan: AI-помощник для школьников", description: "Мобильное приложение, которое помогает школьникам готовиться к ЦТ и ЦЭ с помощью ИИ. Распознаёт задания по фото", vacancies:  [
        Vacancy(title: "Flutter Developer", imageName: "terminal", status: "НУЖЕН", roleDescription: "Dart/Firebase", isActive: true),
        Vacancy(title: "ML Engineer", imageName: "terminal", status: "НУЖЕН", roleDescription: "Python/PyTorch", isActive: true),
        Vacancy(title: "UI/UX Designer", imageName: "terminal", status: "ЗАНЯТО", roleDescription: "Figma/Прототипирование", isActive: false),
        Vacancy(title: "UI/UX Designer", imageName: "terminal", status: "ЗАНЯТО", roleDescription: "Figma/Прототипирование", isActive: false)
    ])
}
