//
//  EventCard.swift
//  Spark
//
//  Created by mac on 20.06.26.
//
////kjhgfd

import SwiftUI



struct EventCard: View {
    
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
    
    
    @State private var showEvent = false
    
    var body: some View {
        

            VStack (alignment: .leading){
                
                ZStack (alignment: .top){
                    
                    Image(image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                    
                    HStack{
                        if let status{
                            Text(status)
                                .font(Font.system(size: 14, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Capsule())
                        }
                        Spacer()
                        
                        if let bonus {
                            Text("\(bonus) Br")
                                .font(Font.system(size: 14, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 6)
                                .background(.primaryYellow)
                                .clipShape(Capsule())
                        }
                        
                    }.padding(15)
                    
                    
                }
                
                
                VStack(alignment: .leading) {
                    HStack{
                        Text(category.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(color)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 6)
                            .background(color.opacity(0.2))
                            .overlay(Capsule().stroke(color, lineWidth: 2))
                            .clipShape(Capsule())
                            
                    }

                
                Text(title)
                    .font(.system(size: 22, weight: .semibold))
                    .padding(.bottom, 10)
                    .lineLimit(2)
                
                Text(description)
                    .lineLimit(2)
                    .foregroundColor(.primaryGrey1)
                    .font(.system(size: 16, weight: .medium))
                    .lineSpacing(8)
                    .padding(.bottom, 10)
                
                HStack {
                    HStack {
                        Image(systemName: "mappin")
                        Text(location)}
                    Spacer()
                    HStack
                    {
                        Image(systemName: "calendar")
                        Text(date)
                    }
                    
                }.foregroundColor(.primaryGrey1)
                    .padding(.bottom, 10)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.primaryGrey1.opacity(0.2))
                
                HStack{
                    
                    if let participants {
                        ParticipantsView()
                        
                        Text("+\(participants)")
                            .foregroundColor(.primaryGrey1)
                            .font(.system(size: 16, weight: .semibold))
                    } else {
                        Image(systemName: "flame")
                            .foregroundColor(.primaryGrey1)
                            .font(.system(size: 16, weight: .semibold))
                        Text("Популярное")
                            .foregroundColor(.primaryGrey1)
                            .font(.system(size: 16, weight: .semibold))
                    }
                   
                    Spacer()
                    
                    SparkButton(title: "Подробнее", icon: "arrow.forward", backgroundColor: .litePurple, isInfinity: false){
                        showEvent = true
                    }
                    
                    
                }}.padding()
            }
            .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.25),
                            radius: 4,
                            x: 0,
                            y: 5
                    )
    }
    }
    


#Preview {
    EventCard(
        image: "Hahaton",
        category: .hackathons,
        title: "Хахатон Сбера 2026: AI Transformation", description: "Создай инновационное решение для миллионов пользователей, 48 часов кода", color: .primaryLitePurple, date: "12 мая — 14 мая", participants: 142, location: "Минск, Беларусь", status: "АКТУАЛЬНО", bonus: 5000
    )

}
