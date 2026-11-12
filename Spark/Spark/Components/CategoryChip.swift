//
//  CategoryChip.swift
//  Spark
//
//  Created by YULIYA MAKSIMCHYK on 22.06.2026.
//

import SwiftUI

struct CategoryChip: View {
    
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action){

                
            if isSelected {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .primaryWhite : .primaryGrey1)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(isSelected ? Color.primaryLitePurple : SparkColor.surface.color)
                    .clipShape(Capsule())
                
            } else {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .primaryWhite : .primaryGrey1)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(isSelected ? Color.primaryLitePurple : SparkColor.surface.color)
                    .overlay(Capsule().stroke(.primaryGrey1))
                    .clipShape(Capsule())
                
            }
            
                
        }
    }
}

#Preview {
    CategoryChip(title: "Все", isSelected: false, action: {})
}
