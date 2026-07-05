//
//  HomeView.swift
//  Spark
//
//  Created by mac on 15.06.26.
//

import SwiftUI

struct HomeView: View {
    
    
    @State private var userSearch: String = ""
    @State private var selectedCategory: EventCategory = .all
    
    let categories: [EventCategory] = [
        .all,
        .hackathons,
        .teams,
        .internships,
        .grants,
        .contests,
        .volunteering,
        .meetups,
        .other
    ]
    
    var filteredEvents: [Event] {
        mockEvents.filter { event in
            selectedCategory == .all || event.category == selectedCategory
        }
    }
    
    var body: some View {
        
        ScrollView{

            HStack {
                
                Text ("SPARK")
                    .foregroundColor(.primaryLitePurple)
                    .font(.system(size: 24, weight: .semibold))
                    .padding(.leading)
                
                Spacer()
                Image("Avelina")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 100))
                    .overlay(RoundedRectangle(cornerRadius: 100).stroke(.primaryLitePurple2, lineWidth: 3))
                    .padding(.trailing)
            }
            
            Divider()

            LazyVStack (
                pinnedViews: [.sectionHeaders]
            ){
                Section {
                    ForEach (filteredEvents){ event in
                        EventCard(image: event.image, category: event.category, title: event.title, description: event.description, color: event.color, date: event.date, participants: event.participants, location: event.location, status: event.status, bonus: event.bonus)
                            .padding(.horizontal)
                    }} header: {
                        
                        VStack(spacing: 12){
            
            SparkTextField(icon: "magnifyingglass", iconColor: .grey, iconSize: 18, placeholder: "ИЩУ КОМАНДУ", borderColor: .litePurple, backgroundColor: .white, isSecure: false, borderWidth: 8.0, text: $userSearch)
                .padding(.top, 10)
                .padding(.horizontal)
                

                            ScrollView(.horizontal, showsIndicators: false) {
                                
                                HStack{
                                    
                                    ForEach (categories, id: \.self){ category in
                                        
                                        CategoryChip(title: category.rawValue, isSelected: selectedCategory == category){
                                            selectedCategory = category
                                        }
                                    }
                                    
                                    
                                }}.padding(.horizontal)
                                .padding(.bottom, 5)
                     
                        }.background(.ultraThinMaterial)
                    }
                        
            }

        }.navigationBarBackButtonHidden(true)
        .frame(maxWidth: .infinity)
        
    }
}

#Preview {
    HomeView()
}
