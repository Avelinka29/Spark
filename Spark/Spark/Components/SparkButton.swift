//
//  SparkButton.swift
//  Spark
//
//  Created by mac on 15.06.26.
//

import SwiftUI

struct SparkButton: View {
    
    let title: String
    let icon: String?
    let backgroundColor: SparkColor
    let isInfinity: Bool
    let action: () -> Void
    
    
    var body: some View {
        

        
        Button(action: action)
            {
                Text(title)
                    .foregroundColor(.primaryWhite)
                    .font(.system(size: 18, weight: .medium))
                
                
                if let icon {
                    Image(systemName: icon)
                        .foregroundColor(.primaryWhite)
                        .fontWeight(.medium)
                }
            }
            .padding()
            .frame(maxWidth: isInfinity ? .infinity : nil)
            .frame(height: 45)
            .background(backgroundColor.color)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.25),
                    radius: 4,
                    x: 0,
                    y: 5)
            .padding(.top, 10)
            
        

    }
}

#Preview {
    SparkButton(title: "Войти",
                icon: "arrow.forward",
                backgroundColor: .litePurple,
                isInfinity: true)
    {
        print("Нажали")
    }
    
}
