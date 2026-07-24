//
//  MapView.swift
//  Spark
//
//  Created by Avelina Maksimchik on 09.07.2026.
//

import SwiftUI
import MapKit

struct MapView: View {

    @StateObject private var vm = MapViewModel()

    var body: some View {

        ZStack {

            Map(position: $vm.cameraPosition) {

                UserAnnotation()

                ForEach(vm.filteredOpportunities) { opportunity in

                    Annotation(
                        opportunity.title,
                        coordinate: opportunity.coordinate
                    ) {

                        OpportunityPin(color: opportunity.color)
                            .onTapGesture {
                                vm.select(opportunity)
                                vm.focus(on: opportunity)
                            }
                    }
                }
            }
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                
                MapSearchBar(text: $vm.searchText)
                    .padding(.horizontal, 20)
                    .padding(.top, -40)
                
                HStack {
                    
                    OportunityMarker(count: .constant(vm.opportunitiesCount))
                        .frame(width: 210)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                
                
                Spacer()
                
                    
                    if let opportunity = vm.selectedOpportunity {
                        PreviewEventMap (eventTitle: opportunity.title, eventCategory: opportunity.category, eventColor: opportunity.color, distance: vm.distance(from: opportunity.coordinate)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                        .transition(.move(edge: .bottom))
                        .gesture(
                            DragGesture()
                                .onEnded { value in

                                    if value.translation.height > 60 {

                                        withAnimation(.spring()) {
                                            vm.selectedOpportunity = nil
                                        }
                                    }
                                }
                        )

                        
                    }
                    
                    
                }.animation(.spring(response: 0.35), value: vm.selectedOpportunity != nil)
            
            }
        }
    }
#Preview {
    MapView()
}
