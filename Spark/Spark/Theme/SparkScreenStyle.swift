import SwiftUI

extension View {
    func sparkCard(padding: CGFloat = 16) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(Color.primary.opacity(0.07))
                    .allowsHitTesting(false)
            }
    }

    func sparkHero() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .foregroundStyle(.white)
            .background {
                RoundedRectangle(cornerRadius: 26).fill(
                    LinearGradient(
                        colors: [.primaryBlue, .primaryLitePurple, .primaryPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
    }
}

struct SparkTileIcon: View {
    let symbol: String

    var body: some View {
        Image(systemName: symbol)
            .font(.body.weight(.semibold))
            .foregroundStyle(.primaryLitePurple)
            .frame(width: 40, height: 40)
            .background(Color.primaryLitePurple.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            .accessibilityHidden(true)
    }
}

struct SparkEmptyRow: View {
    let title: String
    let detail: String
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SparkTileIcon(symbol: symbol)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.bold())
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .sparkCard()
    }
}

/// Shared introductory card for the discovery sheets.
struct SparkDiscoveryHero: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.headline)
                .frame(width: 42, height: 42)
                .background(.white.opacity(0.24), in: RoundedRectangle(cornerRadius: 13))
                .accessibilityHidden(true)
            Text(title).font(.title2.bold())
            Text(subtitle).font(.subheadline).fixedSize(horizontal: false, vertical: true)
        }
        .sparkHero()
    }
}

struct SparkDiscoveryEmpty: View {
    let title: String
    let detail: String
    let symbol: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SparkTileIcon(symbol: symbol)
            Text(title).font(.headline)
            Text(detail).font(.subheadline).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(actionTitle, systemImage: "arrow.right", action: action)
                .buttonStyle(.bordered)
                .tint(.primaryLitePurple)
                .frame(maxWidth: .infinity)
        }
        .sparkCard(padding: 20)
    }
}
