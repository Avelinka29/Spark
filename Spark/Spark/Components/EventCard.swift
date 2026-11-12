import SwiftUI

struct EventCard: View {
    let imageName: String
    let category: EventCategory
    let title: String
    let summary: String
    let color: Color
    let dateText: String
    let participantCount: Int?
    let locationName: String
    let status: String?
    let reward: Int?

    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .top) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()

                HStack {
                    if let status {
                        Text(status)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 6)
                            .background(Color(.secondarySystemBackground).opacity(0.95))
                            .clipShape(Capsule())
                    }

                    Spacer()

                    if let reward {
                        Text("\(reward) Br")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 6)
                            .background(.primaryYellow)
                            .clipShape(Capsule())
                    }
                }
                .padding(15)
            }

            VStack(alignment: .leading) {
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
                    .background(color.opacity(0.2))
                    .overlay(Capsule().stroke(color, lineWidth: 2))
                    .clipShape(Capsule())

                Text(title)
                    .font(.system(size: 22, weight: .semibold))
                    .padding(.bottom, 10)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text(summary)
                    .lineLimit(2)
                    .foregroundStyle(.primaryGrey1)
                    .font(.system(size: 16, weight: .medium))
                    .lineSpacing(8)
                    .padding(.bottom, 10)

                HStack {
                    Label(locationName, systemImage: "mappin")
                    Spacer()
                    Label(dateText, systemImage: "calendar")
                }
                .foregroundStyle(.primaryGrey1)
                .padding(.bottom, 10)

                Divider()

                HStack {
                    if let participantCount {
                        ParticipantsView()
                        Text("+\(participantCount)")
                    } else {
                        Label("Популярное", systemImage: "flame")
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Text("Подробнее")
                        Image(systemName: "arrow.forward")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.primaryLitePurple)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .foregroundStyle(.primaryGrey1)
            }
            .padding()
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 5)
    }
}

#Preview {
    EventCard(
        imageName: "Hahaton",
        category: .hackathons,
        title: "Хакатон Сбера 2026",
        summary: "Создай инновационное решение за 48 часов.",
        color: .primaryLitePurple,
        dateText: "12 мая — 14 мая",
        participantCount: 142,
        locationName: "Минск, Беларусь",
        status: "АКТУАЛЬНО",
        reward: 5000
    )
}
