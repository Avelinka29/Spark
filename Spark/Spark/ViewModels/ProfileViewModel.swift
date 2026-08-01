//
//  ProfileViewModel.swift
//  Spark
//
//  Created by Avelina Maksimchik on 01.08.2026.
//

import SwiftUI
import PhotosUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var selectedItem: PhotosPickerItem?
    @Published var avatarImage: UIImage?
    
    
    func loadImage() async {
        guard let selectedItem else {return}
        
        guard
            let data = try? await selectedItem.loadTransferable(type: Data.self),
            let image = UIImage(data: data)
                
        else {return}
        
        avatarImage = image
    }
}
