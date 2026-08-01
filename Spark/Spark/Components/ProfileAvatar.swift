//
//  ProfileAvatar.swift
//  Spark
//
//  Created by Avelina Maksimchik on 01.08.2026.
//

import SwiftUI
import PhotosUI

struct ProfileAvatar: View {
    
    @StateObject private var vm = ProfileViewModel()
    
    var body: some View {
        
        
        HStack{
            
            ZStack{
                
                
                RoundedRectangle(cornerRadius: 20)
                    .foregroundStyle(.primaryWhite)
                    .frame(width: 75, height: 75)
                    .shadow(radius: 20, y: 4)
                
                if let image = vm.avatarImage {
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 75, height: 75)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    
                } else {
                    
                    Image(systemName: "person.fill")
                        .foregroundStyle(.primaryGrey1)
                        .font(.system(size: 45))
                }
                
                
            }
            
            .overlay(alignment: .bottomTrailing){
                
                if vm.avatarImage == nil {
                    
                    PhotosPicker(selection: $vm.selectedItem, matching: .images){
                        
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.primaryWhite)
                            .frame(alignment: .bottomTrailing)
                            .background{
                                GradientBackground()
                            }
                            .clipShape(Circle())
                            .shadow(radius: 3)
                        
                        
                    }
                    
                }
                
                
                
                Spacer()
                
            }.frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 20)
                .offset(y: 55)
            
 
        }
        
        .task(id: vm.selectedItem) {
            await vm.loadImage()
        }
        
        
        
    }
    
    
}

#Preview {
    ProfileAvatar()
}
