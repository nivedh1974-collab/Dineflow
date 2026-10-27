import SwiftUI

struct FilterState {
    var selectedCuisines: Set<String> = []
    var selectedPriceRanges: Set<Int> = []   // priceLevel values 1-5
    var selectedDistance: String = "Any"
    var minRating: Double = 0

    var isActive: Bool {
        !selectedCuisines.isEmpty || !selectedPriceRanges.isEmpty ||
        selectedDistance != "Any" || minRating > 0
    }

    mutating func reset() {
        selectedCuisines = []
        selectedPriceRanges = []
        selectedDistance = "Any"
        minRating = 0
    }
}

struct FiltersView: View {
    @Binding var filterState: FilterState
    @Environment(\.dismiss) var dismiss

    let cuisines  = ["Italian", "Japanese", "Mexican", "Indian", "American", "Thai",
                     "French", "Chinese", "South Indian", "North Indian", "Continental", "Asian"]
    let priceOptions: [(label: String, level: Int)] = [
        ("₹0–250",     1),
        ("₹250–500",   2),
        ("₹500–750",   3),
        ("₹750–1000",  4),
        ("₹1000+",     5),
    ]
    let distances = ["Any", "0–2.5 km", "2.5–5 km", "5–7.5 km", "7.5–10 km", "10+ km"]

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.dfOutlineVariant.opacity(0.5))
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            HStack {
                Text("Filters")
                    .font(.dfHeadlineMd).foregroundStyle(Color.dfOnSurface)
                Spacer()
                Button("Reset") { Analytics.tap("filters", "reset"); filterState.reset() }
                    .font(.manrope(14, weight: .bold)).foregroundStyle(Color.dfPrimary)
            }
            .padding(.horizontal, Spacing.s10)
            .padding(.vertical, Spacing.s8)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s12) {

                    filterSection(title: "Cuisine") {
                        FlowLayout(spacing: Spacing.s3) {
                            ForEach(cuisines, id: \.self) { c in
                                FilterChip(label: c, isActive: filterState.selectedCuisines.contains(c)) {
                                    if filterState.selectedCuisines.contains(c) { filterState.selectedCuisines.remove(c) }
                                    else { filterState.selectedCuisines.insert(c) }
                                }
                            }
                        }
                    }

                    filterSection(title: "Price Range") {
                        FlowLayout(spacing: Spacing.s3) {
                            ForEach(priceOptions, id: \.level) { opt in
                                FilterChip(label: opt.label, isActive: filterState.selectedPriceRanges.contains(opt.level)) {
                                    if filterState.selectedPriceRanges.contains(opt.level) { filterState.selectedPriceRanges.remove(opt.level) }
                                    else { filterState.selectedPriceRanges.insert(opt.level) }
                                }
                            }
                        }
                    }

                    filterSection(title: "Distance") {
                        FlowLayout(spacing: Spacing.s3) {
                            ForEach(distances, id: \.self) { d in
                                FilterChip(label: d, isActive: filterState.selectedDistance == d) {
                                    filterState.selectedDistance = d
                                }
                            }
                        }
                    }

                    filterSection(title: "Minimum Rating") {
                        VStack(alignment: .leading, spacing: Spacing.s4) {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(Color.dfPrimaryContainer)
                                Text(filterState.minRating == 0 ? "Any rating" : String(format: "%.1f+", filterState.minRating))
                                    .font(.dfBodyMd.weight(.semibold))
                                    .foregroundStyle(Color.dfOnSurface)
                            }
                            Slider(value: $filterState.minRating, in: 0...5, step: 0.5)
                                .tint(Color.dfPrimary)
                                .onChange(of: filterState.minRating) { _, v in
                                    Analytics.tap("filters", "min_rating_slider", ["value": v])
                                }
                        }
                    }
                }
                .padding(.horizontal, Spacing.s10)
                .padding(.bottom, Spacing.s6)
            }

            GradientButton(title: "Apply Filters") { dismiss() }
                .padding(.horizontal, Spacing.s10)
                .padding(.vertical, Spacing.s6)
        }
        .background(Color.dfSurface.ignoresSafeArea())
        .trackScreen("filters")
    }

    @ViewBuilder
    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text(title.uppercased())
                .font(.dfLabelMd).tracking(1.5).foregroundStyle(Color.dfOutline)
            content()
        }
    }
}

// MARK: - FlowLayout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }.reduce(0) { $0 + $1 + spacing }
        return CGSize(width: proposal.width ?? 0, height: max(0, height - spacing))
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var x: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        for subview in subviews {
            let w = subview.sizeThatFits(.unspecified).width
            if x + w > maxWidth && !rows[rows.count - 1].isEmpty { rows.append([]); x = 0 }
            rows[rows.count - 1].append(subview)
            x += w + spacing
        }
        return rows
    }
}

#Preview { FiltersView(filterState: .constant(FilterState())).presentationDetents([.large]) }
