//
//  activeProject.swift
//  Spark
//
//  Created by Avelina Maksimchik on 24.07.2026.
//

import SwiftUI

struct ActiveProject: View {
    
    
    let color: SparkColor
    let imageName: String
    let title: String
    let status: String
    
    enum ActiveProjectType {
        case count(Int)
        case role(String)
    }
    
    let type: ActiveProjectType
    
    let isActive: Bool
    
    let strokeWidht: Double
    
    let titleSize: Double
    
    
    var body: some View {
        
        
        VStack(alignment: .leading, spacing: 4) {
            
            HStack{
                Image(systemName: imageName)
                Text(title)
                
            }
            .foregroundStyle(color.color)
            .font(.system(size: 14, weight: .bold))
            .opacity(0.7)
            .fixedSize(horizontal: true, vertical: false)
            
            switch type {
            case .count(let value):
                Text("\(value)")
                    .font(.system(size: titleSize).weight(.bold))
                    .foregroundStyle(color.color)
                
            case .role(let description):
                Text(description)
                    .font(.system(size: titleSize).weight(.bold))
                    .foregroundStyle(color.color)
                    
                
            }
            
            Spacer(minLength: 0)
            
            Text(status)
                .foregroundStyle(color.color)
                .font(.system(size: 14, weight: .bold))
                .opacity(0.7)
            
        }
        .frame(maxWidth: .infinity,
               maxHeight: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 18)
        .background(
            isActive
            ? color.color.opacity(0.2)
            : Color.black.opacity(0.2))
        
        .overlay{
            
            if isActive{
                RoundedRectangle(cornerRadius: 20).stroke(color.color.opacity(0.3), lineWidth: strokeWidht)
    }}
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 4)
    }
}

#Preview {
    ActiveProject(color: .litePurple, imageName: "sparkles", title: "ПРОЕКТЫ", status: "активных", type: .count(2), isActive: true, strokeWidht: 3, titleSize: 30)
}
