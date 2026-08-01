//
//  Gradient.swift
//  Spark
//
//  Created by Avelina Maksimchik on 01.08.2026.
//

import SwiftUI

struct GradientBackground: View {
    var body: some View {
        ZStack {
            
            LinearGradient(colors: [
                Color("PrimaryBlue"),
                Color("PrimaryLitePurple"),
                Color("PrimaryPurple")
            ],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            Circle()
                .fill(.primaryPink)
                .blur(radius: 80)
                .frame(width: 220, height: 220)
                .offset(x: 150, y: -280)
            
            Circle()
                .fill(.primaryPink)
                .blur(radius: 80)
                .frame(width: 220, height: 220)
                .offset(x: 150, y: 280)
            
            Circle()
                .fill(.primaryBlue)
                .blur(radius: 100)
                .frame(width: 220, height: 220)
                .offset(x: -10, y: 280)
        }
    }
}

#Preview {
    GradientBackground()
}
