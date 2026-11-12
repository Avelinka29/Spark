import MapKit
import SwiftUI

struct MapView: View {
    let isAuthenticated: Bool

    @State private var model = MapViewModel()
    @State private var presentedOpportunity: Opportunity?

    var body: some View {
        @Bindable var model = model

        ZStack {
            Map(position: $model.cameraPosition) {
                UserAnnotation()

                ForEach(model.visibleOpportunities) { opportunity in
                    if let coordinate = opportunity.coordinate {
                        Annotation(opportunity.title, coordinate: coordinate) {
                            OpportunityPin(color: opportunity.mapColor)
                                .onTapGesture {
                                    model.select(opportunity)
                                }
                        }
                    }
                }
            }
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                MapSearchBar(text: $model.searchText)
                    .padding(.horizontal, 20)
                    .padding(.top, -40)

                HStack {
                    OportunityMarker(count: .constant(model.opportunitiesCount))
                        .frame(width: 210)
                    Spacer()
                }
                .padding(.horizontal, 20)

                Spacer()

                if let opportunity = model.selectedOpportunity,
                   let coordinate = opportunity.coordinate {
                    PreviewEventMap(
                        title: opportunity.title,
                        category: opportunity.category,
                        color: opportunity.mapColor,
                        distance: model.distance(from: coordinate)
                    ) {
                        presentedOpportunity = opportunity
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                    .transition(.move(edge: .bottom))
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.height > 60 {
                                    withAnimation(.spring()) {
                                        model.selectedOpportunity = nil
                                    }
                                }
                            }
                    )
                }
            }
            .animation(.spring(response: 0.35), value: model.selectedOpportunity?.id)
        }
        .sheet(item: $presentedOpportunity) { opportunity in
            NavigationStack {
                OpportunityDetailsView(
                    opportunity: opportunity,
                    isAuthenticated: isAuthenticated
                )
            }
        }
    }
}

#Preview {
    MapView(isAuthenticated: false)
}
