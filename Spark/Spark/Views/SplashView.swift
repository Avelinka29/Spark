//
//  SplashView.swift
//  Spark
//
//  Created by mac on 14.06.26.
//

import SwiftUI

struct SplashView: View {
    
    @State private var showLogo = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var hideSplash = false
    @State private var showLogin = false
    
    var body: some View {
        NavigationStack{
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
                        .scaleEffect(showLogo ? 1 : 0.7)
                        .opacity(showLogo ? 1 : 0)
                    
                    
                    Text("SPARK")
                        .font(.system(size: 65, weight: .bold))
                    
                        .foregroundStyle(.primaryWhite)
                        .shadow(color: .black.opacity(0.25),
                                radius: 4,
                                x: 0,
                                y: 4)
                        .padding()
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 15)
                    
                    Text("искры возможностей")
                        .font(.system(size: 28))
                        .bold()
                        .foregroundColor(.primaryWhite)
                        .shadow(color: .black.opacity(0.25),
                                radius: 4,
                                x: 0,
                                y: 4)
                        .opacity(showSubtitle ? 1 : 0)
                        .offset(y: showSubtitle ? 0 : 15)
                    
                    Spacer()
                }
                .opacity(hideSplash ? 0 : 1)
                .scaleEffect(hideSplash ? 1.05 : 1)
                
            }
            .navigationDestination(isPresented: $showLogin) {
                LoginView()
            }
            .onAppear{
                startAnimation()
        }
        
            }
        }
        
    private func startAnimation() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7)
        ) {
            showLogo = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeOut(duration: 0.5)){
                showTitle = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.5)){
                showSubtitle = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            withAnimation(.easeInOut(duration: 0.5)){
                hideSplash = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            
                showLogin = true
            
        }
        
        
        
    }
    
    
        
    }




#Preview {
    SplashView()
}
