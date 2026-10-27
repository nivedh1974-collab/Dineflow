import SwiftUI

struct SearchView: View {
    @Binding var selectedTab: Int
    @State private var query = ""
    @State private var selectedRestaurant: Restaurant? = nil
    @State private var navigateToDetail = false
    @State private var pendingSearch: Task<Void, Never>? = nil

    // Real trending: actual city names, cuisines, and restaurant names from the data
    private let trending: [(icon: String, text: String)] = [
        ("mappin.and.ellipse", "Kochi"),
        ("mappin.and.ellipse", "Mumbai"),
        ("mappin.and.ellipse", "Delhi"),
        ("fork.knife",         "North Indian"),
        ("fork.knife",         "South Indian"),
        ("flame",              "BOGO deals"),
        ("building.2",         "Toit"),
        ("building.2",         "Indian Accent"),
        ("building.2",         "Bukhara"),
        ("cup.and.saucer",     "Cafe"),
    ]

    private let categories: [(icon: String, label: String, color: Color)] = [
        ("fork.knife",     "Italian",     Color.dfPrimary),
        ("fish",           "Japanese",    Color.dfSecondary),
        ("flame",          "Mexican",     Color(hex: "#e05c00")),
        ("leaf",           "Indian",      Color(hex: "#3a7d44")),
        ("cup.and.saucer", "Cafe",        Color(hex: "#5c4a2a")),
        ("wineglass",      "Fine Dining", Color(hex: "#6a1f6a")),
    ]

    private var searchResults: [Restaurant] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        let q = trimmed.lowercased()
        return Restaurant.allRestaurants.filter {
            $0.name.lowercased().contains(q) ||
            $0.cuisine.lowercased().contains(q) ||
            $0.city.lowercased().contains(q) ||
            $0.description.lowercased().contains(q)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.dfSurface.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear.frame(height: 100)

                    if query.trimmingCharacters(in: .whitespaces).isEmpty {
                        emptyState
                    } else if !searchResults.isEmpty {
                        resultsList
                    } else {
                        noResultsView
                    }

                    Color.clear.frame(height: 120)
                }
            }
            .scrollIndicators(.hidden)

            // Nav bar
            VStack(spacing: 0) {
                HStack {
                    Button { Analytics.tap("search", "brand_logo"); selectedTab = 0 } label: {
                        Text("Dineflow")
                            .font(.jakartaItalic(20))
                            .foregroundStyle(Color.dfPrimary)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, Spacing.s10)
                .padding(.top, Spacing.s6)
                .padding(.bottom, Spacing.s4)

                DineflowSearchBar(text: $query)
                    .padding(.horizontal, Spacing.s10)
                    .padding(.bottom, Spacing.s6)
            }
            .background(.ultraThinMaterial)
        }
        .navigationBarHidden(true)
        .trackScreen("search")
        .onChange(of: query) { _, newValue in
            pendingSearch?.cancel()
            let q = newValue.trimmingCharacters(in: .whitespaces)
            guard !q.isEmpty else { return }
            pendingSearch = Task {
                try? await Task.sleep(nanoseconds: 800_000_000)
                guard !Task.isCancelled else { return }
                Analytics.track("search_performed", [
                    "query": q,
                    "result_count": searchResults.count,
                    "has_results": !searchResults.isEmpty
                ])
            }
        }
        .navigationDestination(isPresented: $navigateToDetail) {
            if let r = selectedRestaurant {
                RestaurantDetailView(restaurant: r)
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.s10) {
            // Trending
            VStack(alignment: .leading, spacing: Spacing.s6) {
                sectionLabel("Trending Searches")
                    .padding(.horizontal, Spacing.s10)
                    .padding(.top, Spacing.s4)
                VStack(spacing: 0) {
                    ForEach(trending, id: \.text) { item in
                        Button {
                            Analytics.tap("search", "trending_item", ["term": item.text])
                            query = item.text
                        } label: {
                            HStack(spacing: Spacing.s6) {
                                ZStack {
                                    Circle()
                                        .fill(Color.dfSurfaceLow)
                                        .frame(width: 32, height: 32)
                                    Image(systemName: item.icon)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.dfPrimary)
                                }
                                Text(item.text)
                                    .font(.dfBodyMd)
                                    .foregroundStyle(Color.dfOnSurface)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(Color.dfOutlineVariant)
                            }
                            .padding(.vertical, Spacing.s4)
                            .padding(.horizontal, Spacing.s8)
                        }
                        .buttonStyle(.plain)
                        if item.text != trending.last?.text {
                            Color.dfSurfaceLow.frame(height: 1)
                                .padding(.horizontal, Spacing.s8)
                        }
                    }
                }
                .background(Color.dfSurfaceLowest)
                .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
                .cardShadow()
                .padding(.horizontal, Spacing.s10)
            }

            // Categories
            VStack(alignment: .leading, spacing: Spacing.s6) {
                sectionLabel("Browse by Cuisine")
                    .padding(.horizontal, Spacing.s10)
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                    spacing: Spacing.s4
                ) {
                    ForEach(categories, id: \.label) { cat in
                        Button {
                            Analytics.tap("search", "cuisine_tile", ["cuisine": cat.label])
                            query = cat.label
                        } label: {
                            VStack(spacing: Spacing.s3) {
                                RoundedRectangle(cornerRadius: Radius.lg)
                                    .fill(cat.color.opacity(0.12))
                                    .frame(height: 64)
                                    .overlay(
                                        Image(systemName: cat.icon)
                                            .font(.title2.weight(.semibold))
                                            .foregroundStyle(cat.color)
                                    )
                                Text(cat.label)
                                    .font(.dfLabelMd)
                                    .foregroundStyle(Color.dfOnSurface)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.s10)
            }
        }
        .padding(.top, Spacing.s8)
    }

    // MARK: - Results
    private var resultsList: some View {
        let count = searchResults.count
        let noun = count == 1 ? "result" : "results"
        let header = "\(count) \(noun) for \"\(query)\""
        return VStack(alignment: .leading, spacing: Spacing.s6) {
            sectionLabel(header)
                .padding(.horizontal, Spacing.s10)
            ForEach(searchResults) { r in
                Button {
                    Analytics.tap("search", "result_row", ["restaurant": r.name, "city": r.city])
                    Analytics.track("restaurant_viewed", ["restaurant": r.name, "city": r.city, "cuisine": r.cuisine, "source": "search"])
                    selectedRestaurant = r
                    navigateToDetail = true
                } label: {
                    RestaurantRowCard(restaurant: r)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Spacing.s10)
            }
        }
        .padding(.top, Spacing.s8)
    }

    // MARK: - No Results
    private var noResultsView: some View {
        let msg = "No results for \"\(query)\""
        return VStack(spacing: Spacing.s6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(Color.dfOutlineVariant)
            Text(msg)
                .font(.dfHeadlineSm)
                .foregroundStyle(Color.dfOnSurface)
                .multilineTextAlignment(.center)
            Text("Try a cuisine type, city, or restaurant name.")
                .font(.dfBodyMd)
                .foregroundStyle(Color.dfOnSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.s10)
        .padding(.top, 80)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.dfLabelMd)
            .tracking(1.2)
            .foregroundStyle(Color.dfOutline)
    }
}

#Preview {
    NavigationStack { SearchView(selectedTab: .constant(1)) }
}
