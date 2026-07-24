//
//  SwiftUIView.swift
//  Spark
//
//  Created by mac on 15.06.26.
//

import SwiftUI
    
    enum SparkColor {
        
        case white
        case black
        case grey
        case litePurple
        case purple
        case yellow
        case pink
        case blue
        case green
        
        var color: Color {
            switch self {
            case .white:
                return .primaryWhite
            case .black:
                return .black
            case .grey:
                return .primaryGrey1
            case .litePurple:
                return .primaryLitePurple
            case .purple:
                return .primaryPurple
            case .yellow:
                return .primaryYellow
            case .pink:
                return .primaryPink
            case .blue:
                return .primaryBlue
            case .green:
                return .primaryGreen
            
            }
        }
        
    }
    
    
