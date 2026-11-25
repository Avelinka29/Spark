import SwiftUI

struct ProfileHeader: View {
    let profile: UserProfile
    let avatarImage: UIImage?
    let canEditAvatar: Bool
    let onAvatarSelected: (Data) -> Void
    let onSettings: () -> Void
    let onEdit: () -> Void
    let onEditUsername: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                ProfileAvatar(
                    image: avatarImage,
                    canEdit: canEditAvatar,
                    onImageSelected: onAvatarSelected
                )
                Spacer()
                Button(action: onSettings) {
                    Image(systemName: "gearshape")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.16), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Настройки профиля")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(profile.name)
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                if !profile.region.isEmpty {
                    Label(profile.region, systemImage: "mappin")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.88))
                }
                if canEditAvatar {
                    Button(action: onEditUsername) {
                        Label(
                            profile.username.map { "@\($0)" } ?? "Добавить ник",
                            systemImage: "pencil"
                        )
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.plain)
                }
            }

            if !profile.bio.isEmpty {
                Text(profile.bio)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.88))
            }

            if canEditAvatar {
                Button(action: onEdit) {
                    Label("Редактировать профиль", systemImage: "person.crop.circle")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(13)
                        .foregroundStyle(Color(red: 0.16, green: 0.13, blue: 0.35))
                        .background(.white, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
        .sparkHero()
    }
}
