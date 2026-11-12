import MapKit
import SwiftUI

struct MapView: View {
    let accessToken: String?

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

                if model.isLoading {
                    ProgressView("Загружаем возможности…")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                } else if let errorMessage = model.errorMessage {
                    MapLoadingErrorView(message: errorMessage) {
                        Task {
                            await model.load()
                        }
                    }
                    .padding(.horizontal, 20)
                } else if model.visibleOpportunities.isEmpty {
                    Text("На карте пока нет подходящих возможностей.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                }

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
                    accessToken: accessToken
                )
            }
        }
        .task {
            await model.load()
        }
    }
}

private struct MapLoadingErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.callout)
                .multilineTextAlignment(.center)
            Button("Повторить", action: retry)
                .buttonStyle(.borderedProminent)
                .tint(.primaryLitePurple)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    MapView(accessToken: nil)
}
