import SwiftUI

struct OfferDetailView: View {
    var offer: Offer
    var restaurant: Restaurant

    @Environment(\.dismiss) var dismiss
    @State private var claimed = false
    @State private var showClaimAnimation = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.dfSurface.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: Hero image with gradient overlay
                    heroSection

                    VStack(alignment: .leading, spacing: Spacing.s10) {

                        // Offer headline block
                        offerHeadline

                        // Key details grid
                        detailsGrid

                        // Restaurant info card
                        restaurantCard

                        // About this offer
                        aboutSection

                        // Claim button
                        claimButton

                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, Spacing.s6)
                    .padding(.top, Spacing.s8)
                }
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)

            // Back button
            HStack {
                Button { Analytics.tap("offer_detail", "back", ["offer_id": offer.id.uuidString]); dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.dfOnSurface)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .cardShadow()
                }
                Spacer()
                // Share button
                Button { Analytics.tap("offer_detail", "share", ["offer_id": offer.id.uuidString, "restaurant": restaurant.name]) } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.dfOnSurface)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .cardShadow()
                }
            }
            .padding(.horizontal, Spacing.s6)
            .padding(.top, 56)
        }
        .navigationBarHidden(true)
        .onAppear {
            Analytics.screen("offer_detail", ["offer_id": offer.id.uuidString, "offer_title": offer.title, "restaurant": restaurant.name, "city": restaurant.city, "discount_percent": offer.discountPercent, "is_bogo": offer.isBOGO])
        }
    }

    // MARK: - Hero
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            CachedAsyncImage(url: URL(string: restaurant.imageURL)) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().aspectRatio(contentMode: .fill)
                default:
                    LinearGradient.primaryGradient
                }
            }
            .frame(height: 280)
            .clipped()

            // Gradient scrim
            LinearGradient(
                colors: [.black.opacity(0.75), .black.opacity(0.3), .clear],
                startPoint: .bottom, endPoint: .top
            )

            // Live badge + timer
            VStack(alignment: .leading, spacing: Spacing.s3) {
                LiveBadge(label: "Live Deal")

                Text(offer.title)
                    .font(.jakarta(28, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(3)

                HStack(spacing: Spacing.s4) {
                    // Countdown chip
                    HStack(spacing: 5) {
                        Image(systemName: "clock")
                            .font(.caption2.weight(.bold))
                        Text("ENDS IN \(offer.timeRemainingLabel)")
                            .font(.dfLabelSm).tracking(1)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(.white.opacity(0.15))
                    .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 1))
                    .clipShape(Capsule())

                    // Discount badge
                    Text("\(offer.discountPercent)% OFF")
                        .font(.manrope(12, weight: .bold))
                        .foregroundStyle(Color.dfPrimary)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, Spacing.s6)
            .padding(.bottom, Spacing.s8)
        }
        .frame(height: 280)
    }

    // MARK: - Offer Headline
    private var offerHeadline: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            // Restaurant label
            HStack(spacing: 5) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.dfPrimary)
                Text(restaurant.name.uppercased())
                    .font(.dfLabelMd).tracking(1.2)
                    .foregroundStyle(Color.dfPrimary)
            }

            Text(offer.title)
                .font(.jakarta(26, weight: .heavy))
                .foregroundStyle(Color.dfOnSurface)

            if !offer.description.isEmpty {
                Text(offer.description)
                    .font(.dfBodyLg)
                    .foregroundStyle(Color.dfOnSurfaceVariant)
                    .lineSpacing(4)
            }
        }
    }

    // MARK: - Details Grid
    private var detailsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.s4) {
            detailTile(icon: "tag.fill",         label: "DISCOUNT",   value: "\(offer.discountPercent)% OFF")
            detailTile(icon: "clock.fill",        label: "ENDS IN",    value: offer.timeRemainingLabel)
            detailTile(icon: "arrow.2.squarepath", label: "OFFER TYPE", value: offer.isBOGO ? "BOGO" : "Discount")
            detailTile(icon: "mappin.circle.fill", label: "LOCATION",   value: restaurant.city)
        }
    }

    private func detailTile(icon: String, label: String, value: String) -> some View {
        HStack(spacing: Spacing.s4) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.dfPrimary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.dfLabelSm).tracking(1.2)
                    .foregroundStyle(Color.dfOutline)
                Text(value)
                    .font(.dfBodyMd.weight(.semibold))
                    .foregroundStyle(Color.dfOnSurface)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(Spacing.s6)
        .background(Color.dfSurfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
        .cardShadow()
    }

    // MARK: - Restaurant Card
    private var restaurantCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("RESTAURANT")
                .font(.dfLabelSm).tracking(1.5).foregroundStyle(Color.dfOutline)

            HStack(spacing: Spacing.s6) {
                CachedAsyncImage(url: URL(string: restaurant.imageURL)) { phase in
                    switch phase {
                    case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                    default: Color.dfSurfaceLow
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))

                VStack(alignment: .leading, spacing: 4) {
                    Text(restaurant.name)
                        .font(.jakarta(16, weight: .bold))
                        .foregroundStyle(Color.dfOnSurface)
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.dfPrimaryContainer)
                        Text(String(format: "%.1f", restaurant.rating))
                            .font(.dfLabelMd)
                            .foregroundStyle(Color.dfOnSurface)
                        Text("·").foregroundStyle(Color.dfOutlineVariant)
                        Text(restaurant.cuisine.components(separatedBy: ", ").prefix(2).joined(separator: ", "))
                            .font(.dfLabelMd)
                            .foregroundStyle(Color.dfOnSurfaceVariant)
                            .lineLimit(1)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.caption2)
                            .foregroundStyle(Color.dfOutline)
                        Text(restaurant.address)
                            .font(.dfLabelSm)
                            .foregroundStyle(Color.dfOutline)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            .padding(Spacing.s6)
            .background(Color.dfSurfaceLowest)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
            .cardShadow()
        }
    }

    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("ABOUT THIS OFFER")
                .font(.dfLabelSm).tracking(1.5).foregroundStyle(Color.dfOutline)

            VStack(alignment: .leading, spacing: Spacing.s6) {
                offerTermRow(icon: "checkmark.circle.fill", text: "Valid today only while the offer is live")
                offerTermRow(icon: "checkmark.circle.fill", text: "Show this screen to your server when seated")
                offerTermRow(icon: "checkmark.circle.fill", text: "Cannot be combined with other offers")
                if offer.isBOGO {
                    offerTermRow(icon: "checkmark.circle.fill", text: "Buy one item, get one of equal or lesser value free")
                } else {
                    offerTermRow(icon: "checkmark.circle.fill", text: "\(offer.discountPercent)% off applied at checkout")
                }
                offerTermRow(icon: "xmark.circle.fill",    text: "Not valid on public holidays", isNegative: true)
            }
            .padding(Spacing.s6)
            .background(Color.dfSurfaceLowest)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
            .cardShadow()
        }
    }

    private func offerTermRow(icon: String, text: String, isNegative: Bool = false) -> some View {
        HStack(alignment: .top, spacing: Spacing.s4) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(isNegative ? Color.dfError.opacity(0.7) : Color.dfPrimary)
                .frame(width: 20)
            Text(text)
                .font(.dfBodyMd)
                .foregroundStyle(isNegative ? Color.dfOnSurfaceVariant : Color.dfOnSurface)
            Spacer()
        }
    }

    // MARK: - Claim Button
    private var claimButton: some View {
        Group {
            if claimed {
                HStack(spacing: Spacing.s4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.dfPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Offer Claimed!")
                            .font(.manrope(16, weight: .bold))
                            .foregroundStyle(Color.dfOnSurface)
                        Text("Show this to your server")
                            .font(.dfLabelMd)
                            .foregroundStyle(Color.dfOnSurfaceVariant)
                    }
                    Spacer()
                    Text("\(offer.discountPercent)% OFF")
                        .font(.manrope(14, weight: .bold))
                        .foregroundStyle(Color.dfOnPrimary)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color.dfPrimary)
                        .clipShape(Capsule())
                }
                .padding(Spacing.s6)
                .background(Color.dfSurfaceLowest)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.xl)
                        .stroke(Color.dfPrimary.opacity(0.3), lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
                .cardShadow()
                .transition(.scale.combined(with: .opacity))
            } else {
                GradientButton(title: "Claim This Offer", icon: "bolt.fill") {
                    Analytics.track("offer_claimed", ["offer_id": offer.id.uuidString, "offer_title": offer.title, "restaurant": restaurant.name, "city": restaurant.city, "discount_percent": offer.discountPercent, "is_bogo": offer.isBOGO])
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        claimed = true
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: claimed)
    }
}

#Preview {
    if let r = Restaurant.allRestaurants.first, let o = r.liveOffer {
        NavigationStack {
            OfferDetailView(offer: o, restaurant: r)
        }
    }
}
