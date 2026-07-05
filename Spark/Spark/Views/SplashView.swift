//
//  SplashView.swift
//  Spark
//
//  Created by mac on 14.06.26.
//

import SwiftUI

struct SplashView: View {
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
            
            VStack {
                Spacer()
                Image("LogoFirst")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 255)
                
                    .padding()
                
                Text("SPARK")
                    .font(.system(size: 65, weight: .bold))
                    
                    .foregroundStyle(.primaryWhite)
                    .shadow(color: .black.opacity(0.25),
                            radius: 4,
                            x: 0,
                            y: 4)
                    
                    .padding()
                    
                Text("искры возможностей")
                    .font(.system(size: 28))
                    .bold()
                    .foregroundColor(.primaryWhite)
                    .shadow(color: .black.opacity(0.25),
                            radius: 4,
                            x: 0,
                            y: 4)
                
                Spacer()
            }
        }
        
        
    }
}

#Preview {
    SplashView()
}
