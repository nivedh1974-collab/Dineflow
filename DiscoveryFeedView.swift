import SwiftUI
import CoreLocation

enum SortOption: String, CaseIterable, Identifiable {
    case none          = "Default"
    case ratingHighLow = "Rating: High to Low"
    case priceLowHigh  = "Price: Low to High"
    case priceHighLow  = "Price: High to Low"
    var id: String { rawValue }
}

struct OfferSelection: Identifiable {
    let id = UUID()
    var offer: Offer
    var restaurant: Restaurant
}

struct DiscoveryFeedView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var store: RestaurantStore
    @StateObject private var locationManager = LocationManager.shared
    @State private var showFilters        = false
    @State private var showSortMenu       = false
    @State private var showAllOffers      = false
    @State private var filterState        = FilterState()
    @State private var sortOption: SortOption = .none
    @State private var selectedRestaurant: Restaurant?  = nil
    @State private var navigateToDetail   = false
    @State private var selectedOfferSelection: OfferSelection? = nil
    @State private var navigateToOffer    = false

    private var cityRestaurants: [Restaurant] {
        let city = locationManager.activeCityForFilter
        let base = city.isEmpty ? store.restaurants : store.restaurants.filter {
            locationManager.normaliseCity($0.city) == city
        }
        return base.map { r in
            var m = r
            if let loc = locationManager.userLocation {
                m.distanceKm = CLLocation(latitude: r.coordinate.latitude, longitude: r.coordinate.longitude)
                    .distance(from: loc) / 1000.0
            }
            return m
        }
    }

    private var liveRestaurants: [Restaurant] {
        cityRestaurants.filter { $0.liveOffer != nil || $0.secondOffer != nil }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.dfSurface.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear.frame(height: navBarHeight)
                    if locationManager.isLocating { locatingBanner.padding(.bottom, Spacing.s6) }
                    liveOffersSection.padding(.bottom, Spacing.s12)
                    filterChipsRow.padding(.bottom, Spacing.s8)
                    sectionHeader(
                        title: locationManager.activeCityForFilter.isEmpty
                            ? "Select a city to see restaurants"
                            : "Restaurants in \(locationManager.activeCityForFilter)"
                    )
                    .padding(.horizontal, Spacing.s10).padding(.bottom, Spacing.s6)
                    restaurantList
                    Text("Demo data: restaurants, menus, prices and offers are samples. Photos come from Google Places.")
                        .font(.dfLabelSm)
                        .foregroundStyle(Color.dfOnSurfaceVariant)
                        .padding(.horizontal, Spacing.s10).padding(.top, Spacing.s8)
                    Color.clear.frame(height: 120)
                }
            }
            .scrollIndicators(.hidden)

            GlassNavBar(
                locationName: locationManager.displayCityName,
                onSearch: nil,
                onTapBrand: { selectedTab = 0 },
                onTapLocation: { selectedTab = 2 }
            )
            .frame(maxWidth: .infinity)
        }
        .navigationBarHidden(true)
        .task(id: locationManager.activeCityForFilter) {
            let city = locationManager.activeCityForFilter
            if !city.isEmpty { await store.refreshPlaces(forCity: city) }
        }
        .onAppear {
            Analytics.track("feed_viewed", [
                "city": locationManager.activeCityForFilter,
                "live_offer_count": liveRestaurants.count
            ])
        }
        .onChange(of: showFilters) { _, isOpen in
            if !isOpen && filterState.isActive {
                Analytics.track("filter_applied", [
                    "type": "filters_sheet",
                    "cuisine_count": filterState.selectedCuisines.count,
                    "price_count": filterState.selectedPriceRanges.count,
                    "distance": filterState.selectedDistance,
                    "min_rating": filterState.minRating
                ])
            }
        }
        .sheet(isPresented: $showFilters) {
            FiltersView(filterState: $filterState).presentationDetents([.large]).presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAllOffers) {
            AllOffersView(offers: liveRestaurants, onSelectOffer: { selection in
                trackOfferViewed(offer: selection.offer, restaurant: selection.restaurant, source: "see_all")
                showAllOffers = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    selectedOfferSelection = selection; navigateToOffer = true
                }
            })
            .presentationDetents([.large]).presentationDragIndicator(.visible)
        }
        .confirmationDialog("Sort By", isPresented: $showSortMenu, titleVisibility: .visible) {
            ForEach(SortOption.allCases) { opt in
                Button(opt.rawValue) {
                    sortOption = opt
                    Analytics.track("filter_applied", ["type": "sort", "value": opt.rawValue])
                }
            }
            Button("Cancel", role: .cancel) { Analytics.tap("discovery_feed", "sort_cancel") }
        }
        .navigationDestination(isPresented: $navigateToDetail) {
            if let r = selectedRestaurant { RestaurantDetailView(restaurant: r) }
        }
        .navigationDestination(isPresented: $navigateToOffer) {
            if let s = selectedOfferSelection { OfferDetailView(offer: s.offer, restaurant: s.restaurant) }
        }
    }

    // MARK: - Analytics helpers
    private func trackOfferViewed(offer: Offer, restaurant: Restaurant, source: String) {
        Analytics.track("offer_viewed", [
            "offer_id": offer.id.uuidString,
            "offer_title": offer.title,
            "restaurant": restaurant.name,
            "city": restaurant.city,
            "discount_percent": offer.discountPercent,
            "source": source
        ])
    }

    private var navBarHeight: CGFloat {
        let w = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.windows.first
        return (w?.safeAreaInsets.top ?? 44) + 64
    }

    private var locatingBanner: some View {
        HStack(spacing: Spacing.s4) {
            ProgressView().tint(Color.dfPrimary)
            Text("Detecting your location…").font(.dfLabelMd).foregroundStyle(Color.dfOnSurfaceVariant)
            Spacer()
        }
        .padding(.horizontal, Spacing.s10).padding(.vertical, Spacing.s4).background(Color.dfSurfaceLow)
    }

    private var liveOffersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("RIGHT NOW").font(.dfLabelSm).tracking(1.5).foregroundStyle(Color.dfPrimary)
                    Text("Live Offers").font(.dfHeadlineLg).foregroundStyle(Color.dfOnSurface)
                }
                Spacer()
                Button("See all") {
                    Analytics.track("see_all_offers_tapped", ["offer_count": liveRestaurants.count])
                    showAllOffers = true
                }
                .font(.manrope(14, weight: .bold)).foregroundStyle(Color.dfPrimary)
            }
            .padding(.horizontal, Spacing.s10)

            if liveRestaurants.isEmpty {
                Text("No live offers near you right now.").font(.dfBodyMd).foregroundStyle(Color.dfOnSurfaceVariant).padding(.horizontal, Spacing.s10)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.s6) {
                        ForEach(liveRestaurants) { r in
                            if let offer = r.liveOffer {
                                Button {
                                    trackOfferViewed(offer: offer, restaurant: r, source: "feed_carousel")
                                    selectedOfferSelection = OfferSelection(offer: offer, restaurant: r); navigateToOffer = true
                                } label: { LiveDealCard(restaurant: r, offer: offer) }.buttonStyle(.plain)
                            }
                            if let offer = r.secondOffer {
                                Button {
                                    trackOfferViewed(offer: offer, restaurant: r, source: "feed_carousel")
                                    selectedOfferSelection = OfferSelection(offer: offer, restaurant: r); navigateToOffer = true
                                } label: { LiveDealCard(restaurant: r, offer: offer) }.buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.s10)
                }
            }
        }
    }

    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s3) {
                FilterChip(label: sortOption == .none ? "Sort" : "Sorted", icon: "arrow.up.arrow.down", isActive: sortOption != .none) { showSortMenu = true }
                FilterChip(label: filterState.isActive ? "Filtered" : "Filter", icon: "slider.horizontal.3", isActive: filterState.isActive) { showFilters = true }
                ForEach(availableCuisines, id: \.self) { c in
                    FilterChip(label: c, isActive: filterState.selectedCuisines.contains(c)) {
                        if filterState.selectedCuisines.contains(c) {
                            filterState.selectedCuisines.remove(c)
                            Analytics.track("filter_removed", ["type": "cuisine_chip", "value": c])
                        } else {
                            filterState.selectedCuisines.insert(c)
                            Analytics.track("filter_applied", ["type": "cuisine_chip", "value": c])
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.s10)
        }
    }

    private var availableCuisines: [String] {
        Array(Set(cityRestaurants.flatMap { $0.cuisine.components(separatedBy: ", ") })).sorted()
    }

    private var restaurantList: some View {
        VStack(spacing: Spacing.s6) {
            ForEach(sortedFilteredRestaurants) { r in
                Button {
                    Analytics.track("restaurant_viewed", [
                        "restaurant": r.name,
                        "city": r.city,
                        "cuisine": r.cuisine,
                        "source": "feed_list"
                    ])
                    selectedRestaurant = r; navigateToDetail = true
                } label: { RestaurantRowCard(restaurant: r) }
                .buttonStyle(.plain).padding(.horizontal, Spacing.s10)
            }
        }
    }

    private var sortedFilteredRestaurants: [Restaurant] {
        var list = cityRestaurants
        if !filterState.selectedCuisines.isEmpty {
            list = list.filter { r in !r.cuisine.components(separatedBy: ", ").filter { filterState.selectedCuisines.contains($0) }.isEmpty }
        }
        if !filterState.selectedPriceRanges.isEmpty { list = list.filter { filterState.selectedPriceRanges.contains($0.priceLevel) } }
        if filterState.selectedDistance != "Any" {
            let range = distanceRange(for: filterState.selectedDistance)
            list = list.filter { $0.distanceKm >= range.0 && $0.distanceKm < range.1 }
        }
        if filterState.minRating > 0 { list = list.filter { $0.rating >= filterState.minRating } }
        switch sortOption {
        case .none:          break
        case .ratingHighLow: list.sort { $0.rating > $1.rating }
        case .priceLowHigh:  list.sort { $0.priceLevel < $1.priceLevel }
        case .priceHighLow:  list.sort { $0.priceLevel > $1.priceLevel }
        }
        return list
    }

    private func distanceRange(for label: String) -> (Double, Double) {
        switch label {
        case "0–2.5 km": return (0, 2.5); case "2.5–5 km": return (2.5, 5)
        case "5–7.5 km": return (5, 7.5); case "7.5–10 km": return (7.5, 10)
        case "10+ km":   return (10, Double.infinity)
        default:         return (0, Double.infinity)
        }
    }

    private func sectionHeader(title: String) -> some View {
        Text(title).font(.dfHeadlineMd).foregroundStyle(Color.dfOnSurface)
    }
}

// MARK: - All Offers Sheet
struct AllOffersView: View {
    var offers: [Restaurant]
    var onSelectOffer: (OfferSelection) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.dfOutlineVariant.opacity(0.5)).frame(width: 40, height: 4).padding(.top, 12).padding(.bottom, Spacing.s6)
            HStack {
                Text("Live Offers").font(.dfHeadlineMd).foregroundStyle(Color.dfOnSurface)
                Spacer()
                Button { Analytics.tap("all_offers", "close"); dismiss() } label: {
                    Image(systemName: "xmark").font(.body.weight(.semibold)).foregroundStyle(Color.dfOnSurfaceVariant)
                        .padding(8).background(Color.dfSurfaceHigh).clipShape(Circle())
                }
            }
            .padding(.horizontal, Spacing.s10).padding(.bottom, Spacing.s8)

            ScrollView {
                VStack(spacing: Spacing.s6) {
                    ForEach(offers) { r in
                        if let offer = r.liveOffer   { offerCard(offer: offer, restaurant: r) }
                        if let offer = r.secondOffer { offerCard(offer: offer, restaurant: r) }
                    }
                }
                .padding(.bottom, Spacing.s12)
            }
        }
        .background(Color.dfSurface.ignoresSafeArea())
    }

    private func offerCard(offer: Offer, restaurant: Restaurant) -> some View {
        Button { onSelectOffer(OfferSelection(offer: offer, restaurant: restaurant)) } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    CachedAsyncImage(url: URL(string: restaurant.imageURL)) { phase in
                        switch phase {
                        case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                        default: Color.dfSurfaceLow
                        }
                    }
                    .frame(height: 180).clipped()
                    LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                    LiveBadge().padding(Spacing.s6)
                }
                .frame(height: 180)
                VStack(alignment: .leading, spacing: 6) {
                    Text(offer.title).font(.jakarta(18, weight: .bold)).foregroundStyle(Color.dfOnSurface)
                    Text(restaurant.name).font(.dfBodyMd).foregroundStyle(Color.dfOnSurfaceVariant)
                    HStack(spacing: Spacing.s4) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock").font(.caption2.weight(.bold))
                            Text("Ends in \(offer.timeRemainingLabel)").font(.dfLabelMd)
                        }.foregroundStyle(Color.dfPrimary)
                        Spacer()
                        Text("\(offer.discountPercent)% OFF")
                            .font(.manrope(12, weight: .bold)).foregroundStyle(Color.dfOnPrimary)
                            .padding(.horizontal, 10).padding(.vertical, 4).background(Color.dfPrimary).clipShape(Capsule())
                    }
                }
                .padding(Spacing.s6)
            }
            .background(Color.dfSurfaceLowest).clipShape(RoundedRectangle(cornerRadius: Radius.xl)).cardShadow()
        }
        .buttonStyle(.plain).padding(.horizontal, Spacing.s6)
    }
}

#Preview {
    NavigationStack {
        DiscoveryFeedView(selectedTab: .constant(0))
            .environmentObject(RestaurantStore.shared)
    }
}
