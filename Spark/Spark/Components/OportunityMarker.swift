//
//  OportunitiesCount.swift
//  Spark
//
//  Created by Avelina Maksimchik on 02.07.2026.
//

import SwiftUI

struct OportunityMarker: View {
    
    @Binding var count: Int
    
    var body: some View {
        
        switch count {
        case 0:
            HStack {
                Image(systemName: "mappin")
                    .foregroundStyle(Color.primaryRed)
                
                Text("\(count) возможностей рядом" )
                    .foregroundStyle(Color.primaryWhite)
            } .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(Color.primaryGrey1.opacity(0.5))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))
                .cornerRadius(10)
                .font(.system(size: 18, weight: .bold))
            
            
            
        case 1:
            HStack {
                Image(systemName: "mappin")
                    .foregroundStyle(Color.primaryRed)
                
                Text("\(count) возможность рядом" )
                    .foregroundStyle(Color.primaryWhite)
            } .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(Color.primaryGrey1.opacity(0.5))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))
                .cornerRadius(10)
                .font(.system(size: 18, weight: .bold))
            
        case 2...4:
            HStack {
                Image(systemName: "mappin")
                    .foregroundStyle(Color.primaryRed)
                
                Text("\(count) возможности рядом" )
                    .foregroundStyle(Color.primaryWhite)
            } .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(Color.primaryGrey1.opacity(0.5))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))
                .cornerRadius(10)
                .font(.system(size: 18, weight: .bold))
            
        case 5...count:
            HStack {
                Image(systemName: "mappin")
                    .foregroundStyle(Color.primaryRed)
                
                Text("\(count) возможностей рядом" )
                    .foregroundStyle(Color.primaryWhite)
            } .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(Color.primaryGrey1.opacity(0.5))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))
                .cornerRadius(10)
                .font(.system(size: 18, weight: .bold))
            
        default:
            HStack {
                Image(systemName: "mappin")
                    .foregroundStyle(Color.primaryRed)
                
                Text("\(count) возможностей рядом" )
                    .foregroundStyle(Color.primaryWhite)
            } 
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(Color.primaryGrey1.opacity(0.5))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))
                .cornerRadius(10)
                .font(.system(size: 18, weight: .bold))
        }
        
       
        
        
        
    }
}

#Preview {
    OportunityMarker(count: .constant(10))
}
