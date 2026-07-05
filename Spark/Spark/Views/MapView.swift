//
//  MapView.swift
//  Spark
//
//  Created by YULIYA MAKSIMCHYK on 23.06.2026.
//

import SwiftUI
import MapKit




struct MapView: View {
    
    
    @State private var region = MKCoordinateRegion  (
        center: CLLocationCoordinate2D (
            latitude: 53.9023, longitude: 27.5619
        ),
        
        span:
            MKCoordinateSpan(
                latitudeDelta: 0.02, longitudeDelta: 0.05
        )
    )

    @State var searchText = ""
    
    @State var countOportunities: Int = 5
    
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                MapSearchBar(text: $searchText)
                    .padding(.horizontal, 20)
                    
                    .background(.ultraThinMaterial)
                .background(.ultraThinMaterial)
                

                HStack {
                    
                    OportunityMarker(count: $countOportunities)
                        .frame(width: 200, alignment: .leading)
                    
                    Spacer()
                    
                }.padding(.horizontal, 20)
                
                
                
    
                Spacer()
                
                //BottomEventCard()
            }
            
            
           
            
        }
    }
}

#Preview {
    MapView()
}
