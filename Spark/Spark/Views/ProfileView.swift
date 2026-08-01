//
//  ProfileView.swift
//  Spark
//
//  Created by YULIYA MAKSIMCHYK on 23.06.2026.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        
        
        NavigationStack {
            
            ZStack(alignment: .top){
                
                ProfileHeader()
                    .zIndex(1)
                   
                
                ScrollView {
                    VStack(spacing: 20){
                        
                        
                        //ProfileContent()
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        
        
    }}
#Preview {
    ProfileView()
}
