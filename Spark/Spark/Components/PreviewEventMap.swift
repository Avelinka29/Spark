import SwiftUI

struct PreviewEventMap: View {
    let title: String
    let category: EventCategory
    let color: SparkColor
    let distance: String
    let openDetails: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "scope")
                .font(.system(size: 24))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(color.color)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 20, weight: .medium))
                    .lineLimit(2)

                Text("\(category.rawValue) • \(distance)")
                    .font(.system(size: 14))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.primaryWhite)

            Button(action: openDetails) {
                Label("Перейти", systemImage: "arrow.forward")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(color.color)
                    .clipShape(Capsule())
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .frame(height: 90)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    PreviewEventMap(
        title: "Хакатон",
        category: .hackathons,
        color: .litePurple,
        distance: "1,1 км",
        openDetails: {}
    )
}
