//
//  PreviewEventMap.swift
//  Spark
//
//  Created by Avelina Maksimchik on 22.07.2026.
//

import SwiftUI



struct PreviewEventMap: View {
    
    let eventTitle: String
    let eventCategory: EventCategory
    let eventColor: SparkColor
    let distance: String
    
    var body: some View {
        HStack(spacing: 10) {
            
            ZStack {
                
                Rectangle()
                    .frame(width: 50, height: 50)
                    .cornerRadius(10)
                    .foregroundColor(eventColor.color)
                
                Image(systemName: "scope")
                    .foregroundColor(.primaryWhite)
                    .font(.system(size: 24))
                    
                
            }
            
            VStack(alignment: .leading, spacing: 6) {
                
                Text(eventTitle)
                    .font(.system(size: 20, weight: .medium))
                    .lineLimit(2)
                    
                
                
                    Text("\(eventCategory.rawValue) • \(distance) от тебя")
                    .font(.system(size: 14))
                    .fixedSize(horizontal: false, vertical: true)
                    
            }.frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.primaryWhite)
                
            
            Spacer()
            
            Button {
                
            } label: {
                HStack(spacing: 6) {
                   
                    Text("Перейти")
                        .foregroundColor(.primaryWhite)
                        
                    
                    Image(systemName: "location")
                        .foregroundColor(.primaryWhite)
                        
             
                    
                }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(eventColor.color)
                    .clipShape(Capsule())
                    
                    
                
            }
            
            
            
        }.padding(.horizontal, 20)
            .padding(.vertical, 10)
            .frame(height: 90)
        .frame(maxWidth: .infinity)
            .background(Color.primaryGrey1.opacity(0.3))
            .background(.regularMaterial)
            .cornerRadius(20)
            
        
        
    }
}

#Preview {
    PreviewEventMap(eventTitle: "Хахатоны", eventCategory: .hackathons, eventColor: .litePurple, distance: "1.1 км")
}


//.background(Color.primaryGrey1.opacity(0.3))
//.background(.ultraThinMaterial)
