import SwiftUI

struct GuideView: View {
    private let facts = [
        ("guide_segments", "53 segments", "A live-show virtual wheel with number, leaf, and bonus segments."),
        ("guide_bonus_rounds", "3 bonus rounds", "Lil' Blues, Big Oranges, and Huge Reds."),
        ("guide_rtp", "96.10% RTP", "The stated theoretical return to player."),
        ("guide_max_multiplier", "Up to x5,000", "The maximum multiplier listed for the game.")
    ]

    private let rounds = [
        ("guide_lil_blues", "Lil' Blues", "Low volatility", "Frequent small fish and smaller multipliers."),
        ("guide_big_oranges", "Big Oranges", "Medium volatility", "Medium fish with stronger potential rewards."),
        ("guide_huge_reds", "Huge Reds", "High volatility", "Large fish and the biggest multipliers, sometimes featuring a crane or helicopter.")
    ]

    var body: some View {
        ZStack {
            ScreenBackground(assetName: "background_guide")
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Game at a glance")
                        .font(.title2.bold())

                    ForEach(facts, id: \.1) { fact in
                        GuideRow(assetName: fact.0, title: fact.1, subtitle: fact.2)
                    }

                    Text("Bonus rounds")
                        .font(.title2.bold())
                        .padding(.top, 8)

                    ForEach(rounds, id: \.1) { round in
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 14) {
                                    AssetArtwork(name: round.0, scaling: .contain, cornerRadius: 12)
                                        .frame(width: 72, height: 72)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(round.1).font(.headline)
                                        Text(round.2)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppTheme.orange)
                                    }
                                }
                                Text(round.3)
                                    .foregroundStyle(.white.opacity(0.78))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    GlassCard {
                        Label("Game information is provided for educational and entertainment purposes.", systemImage: "info.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.78))
                    }
                }
                .foregroundStyle(.white)
                .padding()
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Angler's Guide")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct GuideRow: View {
    let assetName: String
    let title: String
    let subtitle: String

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                AssetArtwork(name: assetName, scaling: .contain, cornerRadius: 12)
                    .frame(width: 66, height: 66)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.74))
                }
                Spacer()
            }
            .foregroundStyle(.white)
        }
    }
}
