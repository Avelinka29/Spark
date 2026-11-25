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
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .foregroundStyle(Color(.secondarySystemBackground))
                    .frame(width: 88, height: 88)
                    .shadow(color: .black.opacity(0.14), radius: 12, y: 5)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
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
                    .accessibilityLabel("Изменить фото профиля")
                }
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
