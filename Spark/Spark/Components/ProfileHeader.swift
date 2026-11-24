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
                .clipShape(RoundedRectangle(cornerRadius: 28))
                
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
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 18)
                .padding(.horizontal, 20)
                
                
            }
            
            ProfileAvatar(
                image: avatarImage,
                canEdit: canEditAvatar,
                onImageSelected: onAvatarSelected
            )
   
        }.frame(height: 170)
            .padding(.horizontal, 16)
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
