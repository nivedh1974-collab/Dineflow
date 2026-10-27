import SwiftUI

struct LiveDealCard: View {
    var restaurant: Restaurant
    var offer: Offer

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image section
            ZStack(alignment: .topLeading) {
                CachedAsyncImage(url: URL(string: restaurant.imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .failure:
                        Color.dfSurfaceLow
                            .overlay(Image(systemName: "fork.knife").font(.largeTitle).foregroundStyle(Color.dfOutline))
                    default:
                        Color.dfSurfaceLow
                            .overlay(ProgressView())
                    }
                }
                .frame(height: 220)
                .clipped()

                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.2), .black.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Live badge top-left
                LiveBadge()
                    .padding(Spacing.s6)

                // Timer badge bottom-left
                VStack {
                    Spacer()
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2.weight(.bold))
                            Text("ENDS IN \(offer.timeRemainingLabel)")
                                .font(.dfLabelSm)
                                .tracking(1)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.15))
                        .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
                        .clipShape(Capsule())
                        Spacer()
                    }
                    .padding(Spacing.s6)
                }
            }
            .frame(height: 220)

            // Text info
            VStack(alignment: .leading, spacing: 4) {
                // Restaurant name
                HStack(spacing: 4) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.dfPrimary)
                    Text(restaurant.name)
                        .font(.dfLabelMd)
                        .tracking(0.5)
                        .foregroundStyle(Color.dfPrimary)
                }
                Text(offer.title)
                    .font(.jakarta(20, weight: .bold))
                    .foregroundStyle(Color.dfOnSurface)
                    .lineLimit(2)
                Text(offer.description)
                    .font(.dfBodyMd)
                    .foregroundStyle(Color.dfOnSurfaceVariant)
                    .lineLimit(2)
            }
            .padding(Spacing.s6)
        }
        .frame(width: min(UIScreen.main.bounds.width * 0.85, 380))
        .background(Color.dfSurfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
        .cardShadow()
    }
}

#Preview {
    if let r = Restaurant.allRestaurants.first, let o = r.liveOffer {
        ScrollView(.horizontal) {
            LiveDealCard(restaurant: r, offer: o)
                .padding()
        }
        .background(Color.dfSurface)
    }
}
