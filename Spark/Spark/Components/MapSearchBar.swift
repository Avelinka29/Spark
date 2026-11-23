//
//  MapSearchBar.swift
//  Spark
//
//  Created by Avelina Maksimchik on 02.07.2026.
//

import SwiftUI

struct MapSearchBar: View {
    
    @Binding var text: String
    @Binding var selectedCategory: EventCategory
    
    var body: some View {
        HStack(spacing: 20) {
            
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.primaryWhite.opacity(0.9))
                .font(.system(size: 24, weight: .medium))
                
            
            TextField("", text: $text, prompt: Text("Поиск возможностей").foregroundStyle(Color.primaryWhite.opacity(0.75)))
                .foregroundStyle(Color.primaryWhite)
            
            
            
            
                
            
            Spacer()
            
            Menu {
                Picker("Категория", selection: $selectedCategory) {
                    ForEach(EventCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.primaryWhite)
                    .overlay(alignment: .topTrailing) {
                        if selectedCategory != .all {
                            Circle().fill(.primaryLitePurple).frame(width: 8, height: 8)
                                .offset(x: 5, y: -5)
                        }
                    }
            }
            .accessibilityLabel("Фильтр по категории")
            
            if !text.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)){
                        text = ""}
                } label: {
                Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.primaryWhite.opacity(0.3))
                }
                .transition(.opacity.combined(with: .scale))
            }
                
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(Color.primaryGrey1.opacity(0.3))
        .background(.ultraThinMaterial)
        .overlay{
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.15), lineWidth: 1)
            
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.15), radius: 18, y: 8)
        
    }
}

#Preview {
    ZStack {
        Color.blue
        MapSearchBar(text: .constant(""), selectedCategory: .constant(.all))
            .padding()
    }
}
