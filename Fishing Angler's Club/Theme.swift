import SwiftUI
import UIKit

enum AppTheme {
    static let sky = Color(red: 0.89, green: 0.95, blue: 0.99)
    static let deepIce = Color(red: 0.04, green: 0.10, blue: 0.16)
    static let navy = Color(red: 0.05, green: 0.16, blue: 0.25)
    static let orange = Color(red: 0.96, green: 0.48, blue: 0.15)
    static let emerald = Color(red: 0.08, green: 0.65, blue: 0.48)
    static let danger = Color(red: 0.86, green: 0.20, blue: 0.23)
    static let glass = Color.white.opacity(0.12)
}

enum AssetScaling {
    case cover
    case contain
    case fill
}

struct AssetArtwork: View {
    let name: String
    let scaling: AssetScaling
    var cornerRadius: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            if UIImage(named: name) != nil {
                image
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                fallback
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .accessibilityLabel("Artwork: \(name)")
    }

    @ViewBuilder
    private var image: some View {
        switch scaling {
        case .cover:
            Image(name).resizable().scaledToFill()
        case .contain:
            Image(name).resizable().scaledToFit()
        case .fill:
            Image(name).resizable()
        }
    }

    private var fallback: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [AppTheme.sky.opacity(0.28), AppTheme.navy.opacity(0.78)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.white.opacity(0.42), style: StrokeStyle(lineWidth: 1, dash: [5]))
            }
            .overlay {
                VStack(spacing: 6) {
                    Image(systemName: "photo")
                        .font(.title3)
                    Text(name)
                        .font(.caption2.monospaced())
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.55)
                        .padding(.horizontal, 8)
                }
                .foregroundStyle(.white.opacity(0.82))
            }
            .clipped()
    }
}

struct ScreenBackground: View {
    let assetName: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.sky, Color(red: 0.18, green: 0.44, blue: 0.62), AppTheme.deepIce],
                startPoint: .top,
                endPoint: .bottom
            )
            AssetArtwork(name: assetName, scaling: .fill)
                .opacity(0.32)
        }
        .ignoresSafeArea()
    }
}

struct GlassCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.white.opacity(0.18))
            }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                configuration.isPressed ? AppTheme.orange.opacity(0.72) : AppTheme.orange,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct AvatarView: View {
    let image: UIImage?
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                AssetArtwork(name: "profile_angler_avatar", scaling: .cover)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(.white.opacity(0.7), lineWidth: 2))
        .accessibilityLabel("Profile avatar")
    }
}

struct GlassPanelBackground: View {
    var cornerRadius: CGFloat = 16

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.white.opacity(0.18))
            }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(message)
        }
        .foregroundStyle(.white)
    }
}
