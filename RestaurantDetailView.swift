import SwiftUI

struct RestaurantDetailView: View {
    var restaurant: Restaurant
    @Environment(\.dismiss) var dismiss
    @State private var isFavourited      = false
    @State private var selectedCategory: String = "All"
    @State private var currentPhotoIndex: Int   = 0
    @State private var selectedOffer: Offer?    = nil   // drives navigation to OfferDetailView
    @State private var navigateToOffer          = false

    private var categories: [String] {
        ["All"] + Array(Set(restaurant.menuItems.map { $0.category })).sorted()
    }

    private var filteredMenuItems: [MenuItem] {
        selectedCategory == "All"
            ? restaurant.menuItems
            : restaurant.menuItems.filter { $0.category == selectedCategory }
    }

    private var allPhotos: [String] {
        var urls = [restaurant.imageURL]
        urls += restaurant.photos.filter { $0 != restaurant.imageURL }
        return urls
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.dfSurface.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    photoGallery

                    VStack(alignment: .leading, spacing: Spacing.s10) {
                        quickStats
                        // Live offer banners — now tappable
                        if let offer = restaurant.liveOffer {
                            tappableOfferBanner(offer: offer)
                        }
                        if let offer = restaurant.secondOffer {
                            tappableOfferBanner(offer: offer)
                        }
                        aboutSection
                        menuSection
                    }
                    .padding(.horizontal, Spacing.s6)
                    .padding(.top, Spacing.s8)
                    .padding(.bottom, 120)
                }
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)

            // Back + favourite
            HStack {
                Button { Analytics.tap("restaurant_detail", "back", ["restaurant": restaurant.name]); dismiss() } label: {
                    Image(systemName: "chevron.left").font(.body.weight(.semibold))
                        .foregroundStyle(Color.dfOnSurface).padding(12)
                        .background(.ultraThinMaterial).clipShape(Circle()).cardShadow()
                }
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isFavourited.toggle() }
                    Analytics.track(isFavourited ? "restaurant_favourited" : "restaurant_unfavourited", ["restaurant": restaurant.name, "city": restaurant.city])
                } label: {
                    Image(systemName: isFavourited ? "heart.fill" : "heart")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(isFavourited ? Color.dfPrimary : Color.dfOnSurface)
                        .padding(12).background(.ultraThinMaterial).clipShape(Circle()).cardShadow()
                }
            }
            .padding(.horizontal, Spacing.s6).padding(.top, 56)
        }
        .navigationBarHidden(true)
        .onAppear {
            Analytics.screen("restaurant_detail", ["restaurant": restaurant.name, "city": restaurant.city, "has_live_offer": restaurant.liveOffer != nil, "menu_item_count": restaurant.menuItems.count])
        }
        .onChange(of: currentPhotoIndex) { _, idx in
            Analytics.tap("restaurant_detail", "photo_swiped", ["restaurant": restaurant.name, "index": idx])
        }
        .navigationDestination(isPresented: $navigateToOffer) {
            if let offer = selectedOffer {
                OfferDetailView(offer: offer, restaurant: restaurant)
            }
        }
    }

    // MARK: - Tappable Offer Banner
    private func tappableOfferBanner(offer: Offer) -> some View {
        Button {
            Analytics.tap("restaurant_detail", "offer_banner", ["restaurant": restaurant.name, "offer_title": offer.title])
            Analytics.track("offer_viewed", ["offer_id": offer.id.uuidString, "offer_title": offer.title, "restaurant": restaurant.name, "city": restaurant.city, "discount_percent": offer.discountPercent, "source": "restaurant_detail"])
            selectedOffer = offer
            navigateToOffer = true
        } label: {
            HStack(spacing: Spacing.s4) {
                PulseDot(color: Color.dfOnPrimary, size: 7)
                VStack(alignment: .leading, spacing: 3) {
                    Text("LIVE NOW · ENDS IN \(offer.timeRemainingLabel)")
                        .font(.dfLabelSm).tracking(1.2).foregroundStyle(Color.dfOnPrimary.opacity(0.8))
                    Text(offer.title)
                        .font(.jakarta(17, weight: .bold)).foregroundStyle(Color.dfOnPrimary).lineLimit(2)
                    if !offer.description.isEmpty {
                        Text(offer.description)
                            .font(.dfLabelMd).foregroundStyle(Color.dfOnPrimary.opacity(0.8)).lineLimit(1)
                    }
                }
                Spacer()
                VStack(spacing: 6) {
                    Text("\(offer.discountPercent)% OFF")
                        .font(.manrope(13, weight: .bold)).foregroundStyle(Color.dfPrimary)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.dfOnPrimary).clipShape(Capsule())
                    // "Tap for details" hint
                    Text("TAP FOR DETAILS")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(Color.dfOnPrimary.opacity(0.6))
                }
            }
            .padding(Spacing.s6)
            .background(LinearGradient.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
            .primaryShadow()
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Photo Gallery
    private var photoGallery: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPhotoIndex) {
                ForEach(Array(allPhotos.enumerated()), id: \.offset) { index, url in
                    ZStack(alignment: .bottomLeading) {
                        CachedAsyncImage(url: URL(string: url)) { phase in
                            switch phase {
                            case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                            default: Color.dfSurfaceLow
                            }
                        }
                        .frame(height: 320).frame(maxWidth: .infinity).clipped()

                        LinearGradient(
                            colors: [.black.opacity(0.75), .black.opacity(0.2), .clear],
                            startPoint: .bottom, endPoint: .top
                        )

                        if index == 0 {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(restaurant.city.uppercased()) · \(restaurant.cuisine.components(separatedBy: ", ").prefix(2).joined(separator: ", ").uppercased())")
                                    .font(.dfLabelMd).tracking(1.2).foregroundStyle(.white.opacity(0.75)).lineLimit(1)
                                Text(restaurant.name)
                                    .font(.dfHeadlineLg).foregroundStyle(.white).lineLimit(2)
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill").font(.caption).foregroundStyle(Color.dfPrimaryContainer)
                                    Text(String(format: "%.1f", restaurant.rating)).font(.dfBodyMd.weight(.bold)).foregroundStyle(.white)
                                    Text("(\(restaurant.reviewCount) reviews)").font(.dfLabelMd).foregroundStyle(.white.opacity(0.7))
                                }
                            }
                            .padding(.horizontal, Spacing.s6).padding(.bottom, Spacing.s10)
                        }
                    }
                    .frame(height: 320)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 320)

            HStack(spacing: 4) {
                Spacer()
                ForEach(0..<min(allPhotos.count, 8), id: \.self) { idx in
                    Circle()
                        .fill(idx == currentPhotoIndex ? Color.white : Color.white.opacity(0.5))
                        .frame(width: idx == currentPhotoIndex ? 8 : 5, height: idx == currentPhotoIndex ? 8 : 5)
                        .animation(.spring(response: 0.3), value: currentPhotoIndex)
                }
                Spacer()
                Text("\(currentPhotoIndex + 1)/\(allPhotos.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Capsule())
                    .padding(.trailing, Spacing.s6)
            }
            .padding(.bottom, Spacing.s6)
        }
        .frame(height: 320)
    }

    // MARK: - Quick Stats
    private var quickStats: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s3) {
                statPill(icon: "location.fill",   label: restaurant.distanceLabel)
                statPill(icon: "indianrupeesign", label: restaurant.priceLevelLabel)
                statPill(icon: "fork.knife",       label: restaurant.cuisine.components(separatedBy: ", ").first ?? "")
                statPill(icon: "clock",            label: "Open Now")
                statPill(icon: "photo.stack",      label: "\(allPhotos.count) Photos")
            }
        }
    }

    private func statPill(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.caption.weight(.semibold)).foregroundStyle(Color.dfPrimary)
            Text(label).font(.dfLabelMd).foregroundStyle(Color.dfOnSurface).lineLimit(1)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Color.dfSurfaceLow).clipShape(Capsule())
    }

    // MARK: - About
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("ABOUT").font(.dfLabelMd).tracking(1.5).foregroundStyle(Color.dfOutline)
            Text(restaurant.description)
                .font(.dfBodyLg).foregroundStyle(Color.dfOnSurfaceVariant).lineSpacing(5)
        }
    }

    // MARK: - Menu
    private var menuSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            HStack {
                Text("MENU").font(.dfLabelMd).tracking(1.5).foregroundStyle(Color.dfOutline)
                Spacer()
                Text("\(restaurant.menuItems.count) items").font(.dfLabelMd).foregroundStyle(Color.dfOnSurfaceVariant)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.s3) {
                    ForEach(categories, id: \.self) { cat in
                        FilterChip(label: cat, isActive: selectedCategory == cat) {
                            Analytics.tap("restaurant_detail", "menu_category", ["category": cat, "restaurant": restaurant.name])
                            selectedCategory = cat
                        }
                    }
                }
            }
            VStack(spacing: Spacing.s4) {
                ForEach(filteredMenuItems) { item in
                    menuItemRow(item)
                }
            }
        }
    }

    private func menuItemRow(_ item: MenuItem) -> some View {
        HStack(alignment: .top, spacing: Spacing.s4) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.dfSurfaceLow)
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: item.category == "Beverages" ? "cup.and.saucer" : "fork.knife")
                        .font(.body.weight(.semibold)).foregroundStyle(Color.dfOutline)
                )
                .fixedSize()
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name).font(.dfBodyMd.weight(.semibold)).foregroundStyle(Color.dfOnSurface)
                Text(item.description).font(.dfLabelMd).foregroundStyle(Color.dfOnSurfaceVariant).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                Text(item.category.uppercased()).font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(Color.dfSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(item.price).font(.jakarta(15, weight: .bold)).foregroundStyle(Color.dfPrimary).fixedSize()
        }
        .padding(Spacing.s4)
        .background(Color.dfSurfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl)).cardShadow()
    }
}

extension View {
    func flexibleSize(_ flexible: Bool) -> some View {
        self.fixedSize(horizontal: !flexible, vertical: !flexible)
    }
}

#Preview { NavigationStack { RestaurantDetailView(restaurant: Restaurant.allRestaurants[0]) } }
