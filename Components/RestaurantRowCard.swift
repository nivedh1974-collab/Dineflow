import SwiftUI

struct RestaurantRowCard: View {
    var restaurant: Restaurant

    var body: some View {
        HStack(spacing: Spacing.s6) {
            // Thumbnail
            CachedAsyncImage(url: URL(string: restaurant.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Color.dfSurfaceLow
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))

            // Info
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(restaurant.name)
                        .font(.jakarta(16, weight: .bold))
                        .foregroundStyle(Color.dfOnSurface)
                        .lineLimit(1)
                    Spacer()
                    if restaurant.liveOffer != nil {
                        LiveBadge(label: "Live")
                            .scaleEffect(0.8, anchor: .trailing)
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.dfPrimaryContainer)
                    Text(String(format: "%.1f", restaurant.rating))
                        .font(.dfLabelMd)
                        .foregroundStyle(Color.dfOnSurface)
                    Text("(\(restaurant.reviewCount))")
                        .font(.dfLabelSm)
                        .foregroundStyle(Color.dfOutline)
                }

                HStack(spacing: Spacing.s3) {
                    Label(restaurant.cuisine, systemImage: "fork.knife")
                    Text("·")
                    Label(restaurant.distanceLabel, systemImage: "location")
                    Text("·")
                    Text(restaurant.priceLevelLabel)
                }
                .font(.dfLabelSm)
                .foregroundStyle(Color.dfOnSurfaceVariant)
                .lineLimit(1)
            }
        }
        .padding(Spacing.s6)
        .background(Color.dfSurfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
        .cardShadow()
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(Restaurant.allRestaurants.prefix(2)) { r in
            RestaurantRowCard(restaurant: r)
        }
    }
    .padding()
    .background(Color.dfSurface)
}
