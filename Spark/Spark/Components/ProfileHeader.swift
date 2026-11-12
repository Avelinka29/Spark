//
//  ProfileHeader.swift
//  Spark
//
//  Created by Avelina Maksimchik on 01.08.2026.
//

import SwiftUI

struct ProfileHeader: View {
    let avatarImage: UIImage?
    let canEditAvatar: Bool
    let onAvatarSelected: (Data) -> Void
    let onSettings: () -> Void

    var body: some View {
        
        ZStack{
 
            ZStack {
                LinearGradient(
                    colors: [
                        Color("PrimaryBlue"),
                        Color("PrimaryLitePurple"),
                        Color("PrimaryPurple")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(edges: .top)
                
                Circle()
                    .fill(.primaryYellow)
                    .blur(radius: 60)
                    .frame(width: 100, height: 120)
                    .offset(x: 160, y: 8)
                
                VStack {
                    
                    HStack {
                        
                        Spacer()
                        
                        Button(action: onSettings) {
                            ZStack {
                                
                                Rectangle()
                                    .fill(.primaryWhite)
                                    .opacity(0.4)
                                    .cornerRadius(30)
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "gear")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22)
                                    .foregroundStyle(.primaryWhite)
                            }
                            
                        }
                    }

                    
                }
                .padding(.top, 50)
                .padding(.horizontal, 20)
                
                
            }
            
            ProfileAvatar(
                image: avatarImage,
                canEdit: canEditAvatar,
                onImageSelected: onAvatarSelected
            )
   
        }.frame(height: 150)
    }
}

#Preview {
    ProfileHeader(
        avatarImage: nil,
        canEditAvatar: true,
        onAvatarSelected: { _ in },
        onSettings: {}
    )
}
