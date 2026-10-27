import SwiftUI

struct GlassNavBar: View {
    var locationName: String = "Your Location"
    var onSearch: (() -> Void)? = nil
    var onTapBrand: (() -> Void)? = nil
    var onTapLocation: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            // Left: tappable location label
            Button {
                Analytics.tap("nav_bar", "location_pill", ["location": locationName])
                onTapLocation?()
            } label: {
                VStack(alignment: .leading, spacing: 1) {
                    Text("LOCATION")
                        .font(.dfLabelSm).tracking(1.5)
                        .foregroundStyle(Color.dfOnSurfaceVariant)
                    HStack(spacing: 2) {
                        Text(locationName)
                            .font(.dfHeadlineSm)
                            .foregroundStyle(Color.dfOnSurface)
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.dfPrimary)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(onTapLocation == nil)

            Spacer()

            // Centre: tappable brand wordmark
            Button {
                Analytics.tap("nav_bar", "brand_logo")
                onTapBrand?()
            } label: {
                Text("Dineflow")
                    .font(.jakartaItalic(22))
                    .foregroundStyle(Color.dfPrimary)
            }
            .buttonStyle(.plain)
            .disabled(onTapBrand == nil)

            Spacer()

            // Right: optional search icon OR balance spacer
            if let onSearch {
                Button(action: { Analytics.tap("nav_bar", "search_icon"); onSearch() }) {
                    Image(systemName: "magnifyingglass")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.dfOnSurface)
                }
            } else {
                Color.clear.frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, Spacing.s10)
        .padding(.top, Spacing.s4)
        .padding(.bottom, Spacing.s6)
        .background(.ultraThinMaterial)
    }
}

struct SimpleTitleNavBar: View {
    var title: String
    var onBack: (() -> Void)? = nil
    var body: some View {
        HStack {
            if let onBack {
                Button(action: { Analytics.tap("nav_bar", "back", ["title": title]); onBack() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.dfOnSurface)
                        .padding(10)
                        .background(Color.dfSurfaceLowest)
                        .clipShape(Circle())
                        .cardShadow()
                }
            }
            Spacer()
            Text(title).font(.jakarta(17, weight: .bold)).foregroundStyle(Color.dfOnSurface)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, Spacing.s6).padding(.vertical, Spacing.s4)
        .background(.ultraThinMaterial)
    }
}
