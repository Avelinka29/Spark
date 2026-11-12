//
//  SparkTextField.swift
//  Spark
//
//  Created by mac on 15.06.26.
//

import SwiftUI

struct SparkTextField: View {
    
    let icon: String?
    let iconColor: SparkColor
    let iconSize: Double
    let placeholder: String
    let borderColor: SparkColor
    let backgroundColor: SparkColor
    let isSecure: Bool
    let borderWidth: Double
    let height: Double
    let cornerRadius: Double

    @Binding var text: String
    
    
    init(icon: String? = nil,
         iconColor: SparkColor = .grey,
         iconSize: Double = 18,
         placeholder: String,
         borderColor: SparkColor = .grey,
         backgroundColor: SparkColor = .surface,
         isSecure: Bool = false,
         borderWidth: Double = 1,
         text: Binding<String>,
         height: Double = 50,
         cornerRadius: Double = 15) {
        self.icon = icon
        self.iconColor = iconColor
        self.iconSize = iconSize
        self.placeholder = placeholder
        self.borderColor = borderColor
        self.backgroundColor = backgroundColor
        self.isSecure = isSecure
        self.borderWidth = borderWidth
        self._text = text
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        
        HStack(spacing: 12){
            
            if let icon = icon{
              
                    Image(systemName: icon)
                        .font(.system(size: iconSize))
                        .foregroundStyle(iconColor.color)
                }
                if isSecure {
                    SecureField(
                        "",
                        text: $text,
                        prompt: Text(placeholder).foregroundStyle(.primaryGrey1)
                    )
                } else {
                    TextField(
                        "",
                        text: $text,
                        prompt: Text(placeholder).foregroundStyle(.primaryGrey1)
                    )
                
                
            }}
        .padding()
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: cornerRadius).fill(backgroundColor.color))
        .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(borderColor.color.opacity(0.3), lineWidth: 1))
        .shadow(color: .black.opacity(0.25),
                radius: 4,
                x: 0,
                y: 4)
    }
}

#Preview {
    SparkTextField(
        icon: "person",
        iconColor: .grey,
        iconSize: 18.0,
        placeholder: "Имя",
        borderColor: .grey,
        backgroundColor: .surface,
        isSecure: false,
        text: .constant(""),
        height: 50,
        cornerRadius: 15
        
        
    )
}
