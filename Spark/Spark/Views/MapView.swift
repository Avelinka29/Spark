import MapKit
import SwiftUI

struct MapView: View {
    let accessToken: String?
    let refreshID: UUID

    @State private var model = MapViewModel()
    @State private var presentedOpportunity: Opportunity?
    @State private var selectedGroup: MapOpportunityGroup?

    var body: some View {
        @Bindable var model = model

        ZStack {
            Map(position: $model.cameraPosition) {
                UserAnnotation()

                ForEach(model.pinGroups) { group in
                    if let opportunity = group.opportunities.first {
                        Annotation(opportunity.title, coordinate: group.coordinate) {
                            OpportunityPin(color: opportunity.mapColor)
                                .overlay(alignment: .topTrailing) {
                                    if group.opportunities.count > 1 {
                                        Text("\(group.opportunities.count)")
                                            .font(.caption2.bold())
                                            .foregroundStyle(.white)
                                            .padding(5)
                                            .background(.primaryLitePurple, in: Circle())
                                            .offset(x: 8, y: -8)
                                    }
                                }
                                .onTapGesture {
                                    if group.opportunities.count == 1 {
                                        model.select(opportunity)
                                    } else {
                                        selectedGroup = group
                                    }
                                }
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .onMapCameraChange(frequency: .onEnd) { context in
                model.updateVisibleMapRect(context.rect)
            }

            VStack(alignment: .leading, spacing: 20) {
                MapSearchBar(text: $model.searchText, selectedCategory: $model.selectedCategory)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                HStack {
                    OportunityMarker(count: .constant(model.opportunitiesCount))
                        .frame(width: 210)
                    Spacer()
                }
                .padding(.horizontal, 20)

                if model.locationDenied {
                    Link("Разрешить геолокацию в настройках", destination: URL(string: UIApplication.openSettingsURLString)!)
                        .font(.footnote.weight(.medium))
                        .padding(10)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                } else if let locationError = model.locationError {
                    HStack {
                        Text(locationError)
                        Button("Повторить") { model.requestLocation() }
                    }
                    .font(.footnote)
                    .padding(10)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                }

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
        .sheet(item: $selectedGroup) { group in
            NavigationStack {
                List(group.opportunities) { opportunity in
                    Button {
                        selectedGroup = nil
                        model.select(opportunity)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(opportunity.title).font(.headline)
                            Text(opportunity.locationName).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
                .navigationTitle("События в этом месте")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $presentedOpportunity) { opportunity in
            NavigationStack {
                OpportunityDetailsView(
                    opportunity: opportunity,
                    accessToken: accessToken
                )
            }
        }
        .task(id: refreshID) {
            model.requestLocation()
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
    MapView(accessToken: nil, refreshID: UUID())
}
