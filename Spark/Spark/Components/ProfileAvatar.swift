//
//  ProfileAvatar.swift
//  Spark
//
//  Created by Avelina Maksimchik on 01.08.2026.
//

import SwiftUI
import PhotosUI

struct ProfileAvatar: View {
    let image: UIImage?
    let canEdit: Bool
    let onImageSelected: (Data) -> Void

    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .foregroundStyle(Color(.secondarySystemBackground))
                    .frame(width: 75, height: 75)
                    .shadow(radius: 20, y: 4)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 75, height: 75)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                } else {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.primaryLitePurple)
                        .font(.system(size: 45))
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if canEdit {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Image(systemName: image == nil ? "plus" : "pencil")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.primaryWhite)
                            .frame(width: 28, height: 28)
                            .background { GradientBackground() }
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 20)
            .offset(y: 55)
        }
        .task(id: selectedItem) {
            guard let data = try? await selectedItem?.loadTransferable(type: Data.self) else {
                return
            }
            onImageSelected(data)
        }
    }
}

#Preview {
    ProfileAvatar(image: nil, canEdit: true, onImageSelected: { _ in })
}
