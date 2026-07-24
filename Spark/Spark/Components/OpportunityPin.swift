//
//  OpportunityPin.swift
//  Spark
//
//  Created by Avelina Maksimchik on 06.07.2026.
//

import SwiftUI

struct OpportunityPin: View {
    
    let color: SparkColor
    
    var body: some View {
        Circle()
            .fill(color.color)
            .frame(width: 55, height: 55)
            .overlay {
                Image(systemName: "scope")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
            }.shadow(radius: 8)
        
    }
             
}

#Preview {
    OpportunityPin(color: .pink)
}
