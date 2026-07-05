//
//  MainTabView.swift
//  Spark
//
//  Created by YULIYA MAKSIMCHYK on 23.06.2026.
//

import SwiftUI

struct MainTabView: View {
    
    @State private var showCreateProgect = false
    @State private var selectedTab = 0
    
    var body: some View {
        
        ZStack{
            
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem{
                        Label("Лента", systemImage: "house")
                            
                    }.tag(0)
                   
                MapView()
                    .tabItem {
                        Label("Карта", systemImage: "map")
                            
                    }.tag(1)
                    
                ProjectView()
                    .tabItem{
                        Label("Проекты", systemImage: "folder")
                            
                    }.tag(2)
                ProfileView()
                    .tabItem {
                        Label("Профиль", systemImage: "person")
                            
                    }.tag(3)
            }
            
            if selectedTab == 0 || selectedTab == 2 {
                
                VStack{
                    Spacer()
                    Button {
                        showCreateProgect = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 25, weight: .medium))
                            .foregroundColor(.primaryWhite)
                            .frame(width: 55, height: 55)
                        
                            .background(.primaryLitePurple)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.5),
                                    radius: 8,
                                    y: 4)
                            
                    }.padding(.bottom, 55)
                        .transition(.scale)
                        .animation(.spring(), value: selectedTab)
                }}
        }.navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showCreateProgect){
                CreateProjectView()
            }
    }
}

#Preview {
    MainTabView()
}
