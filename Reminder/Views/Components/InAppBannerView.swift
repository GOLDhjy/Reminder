import SwiftUI

struct InAppBannerView: View {
    let banner: InAppBanner
    let onDismiss: () -> Void

    private var tint: Color {
        banner.kind == .timer ? AppColors.timer : AppColors.primary
    }

    private var iconName: String {
        banner.kind == .timer ? "timer" : "bell.fill"
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))
                    .frame(width: 36, height: 36)
                Image(systemName: iconName)
                    .foregroundColor(tint)
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(banner.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(banner.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
                    .font(.caption.weight(.semibold))
                    .padding(8)
                    .background(
                        Circle()
                            .fill(AppColors.cardBackground.opacity(0.8))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("关闭通知")
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppColors.cardElevated)
                .shadow(color: AppColors.shadow, radius: 14, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .onTapGesture {
            onDismiss()
        }
    }
}

