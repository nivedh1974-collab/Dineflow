import SwiftUI

// The merchant's "Preview" tab — shows exactly how their restaurant page
// looks to a diner. All data reads from RestaurantStore so edits reflect instantly.
struct MerchantRestaurantPreviewView: View {
    @EnvironmentObject var store: RestaurantStore
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: String = "All"
    @State private var currentPhotoIndex: Int   = 0
    @State private var selectedOffer: Offer?    = nil
    @State private var navigateToOffer          = false

    private var restaurant: Restaurant? { store.merchantRestaurant }

    private var allPhotos: [String] {
        guard let r = restaurant else { return [] }
        var urls = [r.imageURL]
        urls += r.photos.filter { $0 != r.imageURL }
        return urls
    }

    private var categories: [String] {
        guard let r = restaurant else { return [] }
        return ["All"] + Array(NSOrderedSet(array: r.menuItems.map { $0.category })) as? [String] ?? []
    }

    private var filteredItems: [MenuItem] {
        guard let r = restaurant else { return [] }
        return selectedCategory == "All" ? r.menuItems : r.menuItems.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.dfSurface.ignoresSafeArea()

            if let r = restaurant {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Hero image
                        heroImage

                        // White info card (floating over image)
                        infoCard(r)
                            .padding(.horizontal, Spacing.s6)
                            .offset(y: -24)

                        VStack(alignment: .leading, spacing: Spacing.s10) {
                            // Live offers horizontal scroll
                            if r.liveOffer != nil || r.secondOffer != nil {
                                liveOffersSection(r)
                            }
                            // Menu
                            menuSection(r)
                        }
                        .padding(.horizontal, Spacing.s6)
                        .padding(.top, Spacing.s4)
                        .padding(.bottom, 120)
                    }
                }
                .scrollIndicators(.hidden)
                .ignoresSafeArea(edges: .top)
            } else {
                VStack(spacing: Spacing.s6) {
                    Spacer()
                    Image(systemName: "storefront").font(.system(size: 48)).foregroundStyle(Color.dfOutlineVariant)
                    Text("No restaurant claimed").font(.dfHeadlineSm).foregroundStyle(Color.dfOnSurface)
                    Spacer()
                }
            }

            // Nav bar — back button + "Restaurant Page View" label + initials
            HStack {
                Button { Analytics.tap("merchant_preview", "back"); dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.dfPrimary)
                        .padding(10)
                        .background(Color.dfSurfaceLowest)
                        .clipShape(Circle())
                        .cardShadow()
                }
                .buttonStyle(.plain)
                Spacer()
                Text("Restaurant Page View")
                    .font(.jakarta(16, weight: .bold)).foregroundStyle(Color.dfPrimary)
                Spacer()
                Circle().fill(Color.dfSurfaceHigh).frame(width: 32, height: 32)
                    .overlay(Text(initials).font(.dfLabelMd).foregroundStyle(Color.dfSecondary))
            }
            .padding(.horizontal, Spacing.s6).padding(.vertical, Spacing.s5)
            .background(.ultraThinMaterial)
        }
        .navigationBarHidden(true)
        .trackScreen("merchant_preview")
        .navigationDestination(isPresented: $navigateToOffer) {
            if let offer = selectedOffer, let r = restaurant {
                OfferDetailView(offer: offer, restaurant: r)
            }
        }
    }

    // MARK: - Hero
    private var heroImage: some View {
        CachedAsyncImage(url: URL(string: restaurant?.imageURL ?? "")) { phase in
            switch phase {
            case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
            default: LinearGradient.primaryGradient
            }
        }
        .frame(height: 260).clipped()
    }

    // MARK: - Info Card (white floating card)
    private func infoCard(_ r: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(r.name).font(.jakarta(28, weight: .heavy)).foregroundStyle(Color.dfOnSurface)
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").font(.caption).foregroundStyle(Color.dfPrimary)
                        Text(String(format: "%.1f", r.rating)).font(.dfBodyMd.weight(.bold)).foregroundStyle(Color.dfPrimary)
                        Text("(\(r.reviewCount)+ Reviews)").font(.dfLabelMd).foregroundStyle(Color.dfPrimary)
                    }
                }
                Spacer()
                // Hours today chip
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill").font(.caption2.weight(.bold)).foregroundStyle(Color.dfPrimary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("HOURS TODAY").font(.system(size: 8, weight: .bold)).tracking(0.8).foregroundStyle(Color.dfOutline)
                        Text(store.todayHoursLabel()).font(.dfLabelMd.weight(.semibold)).foregroundStyle(Color.dfOnSurface)
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color.dfSurfaceLow)
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            }

            Text(r.description)
                .font(.dfBodyMd).foregroundStyle(Color.dfOnSurfaceVariant).lineSpacing(4).lineLimit(4)
        }
        .padding(Spacing.s6)
        .background(Color.dfSurfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
        .cardShadow()
    }

    // MARK: - Live Offers section
    private func liveOffersSection(_ r: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            Text("Live Offers").font(.jakarta(22, weight: .heavy)).foregroundStyle(Color.dfOnSurface)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.s4) {
                    if let offer = r.liveOffer {
                        offerCard(offer: offer, restaurant: r)
                    }
                    if let offer = r.secondOffer {
                        offerCard(offer: offer, restaurant: r)
                    }
                }
            }
        }
    }

    private func offerCard(offer: Offer, restaurant: Restaurant) -> some View {
        Button {
            Analytics.tap("merchant_preview", "offer_card", ["offer_title": offer.title])
            selectedOffer = offer
            navigateToOffer = true
        } label: {
            ZStack(alignment: .bottomLeading) {
                // Background gradient — warm for discount, cool for BOGO
                RoundedRectangle(cornerRadius: Radius.xl)
                    .fill(offer.isBOGO
                          ? LinearGradient(colors: [Color(hex: "#4b5d70"), Color(hex: "#3f5164")], startPoint: .topLeading, endPoint: .bottomTrailing)
                          : LinearGradient(colors: [Color(hex: "#c45200"), Color(hex: "#e06000")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 240, height: 180)

                VStack(alignment: .leading, spacing: Spacing.s4) {
                    // Category chip
                    if offer.isBOGO {
                        Text("BOGO DEAL").font(.dfLabelSm).tracking(1.2).foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 10).padding(.vertical, 4).background(.white.opacity(0.15)).clipShape(Capsule())
                    } else {
                        Text("CHEF'S TREAT").font(.dfLabelSm).tracking(1.2).foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 10).padding(.vertical, 4).background(.white.opacity(0.15)).clipShape(Capsule())
                    }

                    Text(offer.title.uppercased())
                        .font(.jakarta(20, weight: .heavy)).foregroundStyle(.white).lineLimit(2)

                    Text(offer.description)
                        .font(.dfLabelMd).foregroundStyle(.white.opacity(0.8)).lineLimit(2)

                    Spacer()

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ENDS IN").font(.dfLabelSm).tracking(1).foregroundStyle(.white.opacity(0.7))
                            Text(offer.timeRemainingLabel).font(.jakarta(16, weight: .bold)).foregroundStyle(.white)
                        }
                        Spacer()
                        Button { Analytics.tap("merchant_preview", "claim_now", ["offer_title": offer.title]) } label: {
                            Text("Claim Now").font(.manrope(12, weight: .bold)).foregroundStyle(offer.isBOGO ? Color.dfSecondary : Color.dfPrimary)
                                .padding(.horizontal, 14).padding(.vertical, 7).background(.white).clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Spacing.s6)
            }
            .frame(width: 240, height: 180)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Menu Section
    private func menuSection(_ r: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            HStack {
                Text("The Menu").font(.jakarta(22, weight: .heavy)).foregroundStyle(Color.dfOnSurface)
                Spacer()
                Text("Full Menu").font(.manrope(14, weight: .bold)).foregroundStyle(Color.dfPrimary)
            }

            // Category chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.s3) {
                    ForEach(categories, id: \.self) { cat in
                        FilterChip(label: cat, isActive: selectedCategory == cat) {
                            Analytics.tap("merchant_preview", "menu_category", ["category": cat])
                            selectedCategory = cat
                        }
                    }
                }
            }

            // 2-col grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.s4) {
                ForEach(filteredItems.prefix(8)) { item in
                    menuGridCard(item)
                }
            }
        }
    }

    private func menuGridCard(_ item: MenuItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomTrailing) {
                Color.dfSurfaceLow.frame(height: 100)
                    .overlay(Image(systemName: item.category == "Beverages" ? "cup.and.saucer.fill" : "fork.knife")
                        .font(.title).foregroundStyle(Color.dfOutlineVariant.opacity(0.4)))
                Button { Analytics.tap("merchant_preview", "menu_item_plus", ["item": item.name]) } label: {
                    Image(systemName: "plus").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 24, height: 24).background(Color.dfPrimary).clipShape(Circle())
                }
                .buttonStyle(.plain).padding(8)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name).font(.jakarta(13, weight: .bold)).foregroundStyle(Color.dfOnSurface).lineLimit(1)
                Text(item.price).font(.dfBodyMd.weight(.semibold)).foregroundStyle(Color.dfPrimary)
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
        }
        .background(Color.dfSurfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
        .cardShadow()
    }

    @AppStorage("userEmail") private var userEmail = ""
    private var initials: String {
        let prefix = userEmail.components(separatedBy: "@").first ?? "U"
        return String(prefix.prefix(1).uppercased())
    }
}

#Preview { NavigationStack { MerchantRestaurantPreviewView().environmentObject(RestaurantStore.shared) } }
