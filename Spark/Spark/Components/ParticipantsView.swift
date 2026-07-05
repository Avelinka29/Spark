//
//  ParticipantsView.swift
//  Spark
//
//  Created by YULIYA MAKSIMCHYK on 22.06.2026.
//

import SwiftUI

struct ParticipantsView: View {
    var body: some View {
        HStack(spacing: -8){
            Image(systemName: "person.circle.fill")
            Image(systemName: "person.circle.fill")
            Image(systemName: "person.circle.fill")
        }
        .font(.system(size: 18))
        .foregroundColor(.primaryLitePurple.opacity(0.5))
    }
}

#Preview {
    ParticipantsView()
}
