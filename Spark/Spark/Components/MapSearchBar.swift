//
//  MapSearchBar.swift
//  Spark
//
//  Created by Avelina Maksimchik on 02.07.2026.
//

import SwiftUI

struct MapSearchBar: View {
    
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 20) {
            
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.primaryWhite)
                .font(.system(size: 24))
                .opacity(01)
            
            TextField("", text: $text, prompt: Text("Поиск возможностей рядом").foregroundStyle(Color.primaryWhite.opacity(1)))
                .foregroundStyle(Color.primaryWhite)
               
                
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(Color.primaryGrey1.opacity(0.5))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))
        .cornerRadius(10)
    }
}

#Preview {
    MapSearchBar(text: .constant(""))
}
