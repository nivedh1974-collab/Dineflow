import SwiftUI
import MapKit
import CoreLocation

struct LocationPickerView: View {
    var currentName: String
    var onSelect: (String, CLLocationCoordinate2D) -> Void

    @Environment(\.dismiss) var dismiss
    // Access shared LocationManager so we can call clearManualCity() + fetchLocation() directly
    @ObservedObject private var locationManager = LocationManager.shared

    @State private var searchText = ""
    @State private var results: [MKMapItem] = []
    @State private var isSearching = false
    @State private var pendingSearchLog: Task<Void, Never>? = nil

    private let popularCities: [(name: String, subtitle: String, lat: Double, lng: Double)] = [
        ("Doha",      "Qatar",               25.2854, 51.5310),
        ("Kochi",     "Kerala, India",        9.9312, 76.2673),
        ("Mumbai",    "Maharashtra, India",  19.0760, 72.8777),
        ("Delhi",     "New Delhi, India",    28.6139, 77.2090),
        ("Bangalore", "Karnataka, India",    12.9716, 77.5946),
        ("Chennai",   "Tamil Nadu, India",   13.0827, 80.2707),
        ("Hyderabad", "Telangana, India",    17.3850, 78.4867),
        ("Pune",      "Maharashtra, India",  18.5204, 73.8567),
        ("Kolkata",    "West Bengal, India",   22.5726, 88.3639),
        ("Ahmedabad",  "Gujarat, India",       23.0225, 72.5714),
        ("Jaipur",     "Rajasthan, India",     26.9124, 75.7873),
        ("Chandigarh", "Chandigarh, India",    30.7333, 76.7794),
        ("Goa",        "Goa, India",           15.4909, 73.8278),
        ("Coimbatore", "Tamil Nadu, India",    11.0168, 76.9558),
        ("Trivandrum", "Kerala, India",         8.5241, 76.9366),
        ("Lucknow",    "Uttar Pradesh, India", 26.8467, 80.9462),
        ("Indore",     "Madhya Pradesh, India",22.7196, 75.8577),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.dfOutlineVariant.opacity(0.5))
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Change Location")
                        .font(.dfHeadlineMd)
                        .foregroundStyle(Color.dfOnSurface)
                    Text("Restaurants update based on your selection")
                        .font(.dfLabelMd)
                        .foregroundStyle(Color.dfOnSurfaceVariant)
                }
                Spacer()
                Button { Analytics.tap("location_picker", "close"); dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.dfOnSurfaceVariant)
                        .padding(8)
                        .background(Color.dfSurfaceHigh)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, Spacing.s10)
            .padding(.vertical, Spacing.s8)

            // Search bar
            DineflowSearchBar(text: $searchText, placeholder: "Search city or neighbourhood...")
                .padding(.horizontal, Spacing.s10)
                .padding(.bottom, Spacing.s6)
                .onChange(of: searchText) { _, val in
                    searchLocations(query: val)
                    logSearch(val)
                }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Use Current GPS Location ──────────────────────────────
                    Button {
                        // 1. Wipe the manual override so activeCityForFilter
                        //    falls back to detectedCity (GPS-derived).
                        Analytics.tap("location_picker", "use_current_location")
                        Analytics.track("location_changed", ["method": "gps"])
                        locationManager.clearManualCity()
                        // 2. Kick off a fresh GPS fix + reverse-geocode.
                        locationManager.fetchLocation()
                        // 3. Notify parent (NearbyMapView) so it can re-centre
                        //    once the fix arrives via onChange(of: userLocation).
                        onSelect("", CLLocationCoordinate2D(latitude: 0, longitude: 0))
                        dismiss()
                    } label: {
                        HStack(spacing: Spacing.s6) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.dfPrimary.opacity(0.1))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "location.fill")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(Color.dfPrimary)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Use Current Location")
                                    .font(.dfBodyMd.weight(.semibold))
                                    .foregroundStyle(Color.dfPrimary)
                                // Show live-locating state so the user knows it's working
                                if locationManager.isLocating {
                                    HStack(spacing: 4) {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .tint(Color.dfPrimary)
                                        Text("Detecting…")
                                            .font(.dfLabelMd)
                                            .foregroundStyle(Color.dfOnSurfaceVariant)
                                    }
                                } else {
                                    Text(currentName)
                                        .font(.dfLabelMd)
                                        .foregroundStyle(Color.dfOnSurfaceVariant)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.dfOutlineVariant)
                        }
                        .padding(.horizontal, Spacing.s10)
                        .padding(.vertical, Spacing.s6)
                    }
                    .buttonStyle(.plain)

                    divider

                    if !results.isEmpty {
                        sectionLabel("RESULTS")
                        ForEach(results, id: \.self) { item in
                            locationRow(
                                name: item.name ?? "Unknown",
                                subtitle: item.placemark.locality ?? item.placemark.country ?? "",
                                coordinate: item.placemark.coordinate
                            )
                        }
                    } else if searchText.isEmpty {
                        sectionLabel("POPULAR CITIES")
                        ForEach(popularCities, id: \.name) { city in
                            locationRow(
                                name: city.name,
                                subtitle: city.subtitle,
                                coordinate: CLLocationCoordinate2D(latitude: city.lat, longitude: city.lng)
                            )
                        }
                    } else if isSearching {
                        HStack { Spacer(); ProgressView().padding(.top, Spacing.s12); Spacer() }
                    } else {
                        HStack {
                            Spacer()
                            VStack(spacing: Spacing.s4) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color.dfOutlineVariant)
                                    .padding(.top, 40)
                                Text("No results found")
                                    .font(.dfBodyMd).foregroundStyle(Color.dfOnSurfaceVariant)
                            }
                            Spacer()
                        }
                    }

                    Color.clear.frame(height: 40)
                }
            }
        }
        .background(Color.dfSurface.ignoresSafeArea())
        .trackScreen("location_picker")
    }

    // MARK: - Manual city row
    private func locationRow(name: String, subtitle: String, coordinate: CLLocationCoordinate2D) -> some View {
        Button {
            // Set the manual override, then notify parent to re-centre the map.
            Analytics.tap("location_picker", "city_row", ["city": name])
            Analytics.track("location_changed", ["method": searchText.isEmpty ? "popular_city" : "search_result", "city": name])
            locationManager.setManualCity(name: name, coordinate: coordinate)
            onSelect(name, coordinate)
            dismiss()
        } label: {
            HStack(spacing: Spacing.s6) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.dfSurfaceLow)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "mappin.and.ellipse")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.dfSecondary)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.dfBodyMd.weight(.semibold))
                        .foregroundStyle(Color.dfOnSurface)
                    Text(subtitle)
                        .font(.dfLabelMd)
                        .foregroundStyle(Color.dfOnSurfaceVariant)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dfOutlineVariant)
            }
            .padding(.horizontal, Spacing.s10)
            .padding(.vertical, Spacing.s6)
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Color.dfSurfaceLow.frame(height: 1)
            .padding(.horizontal, Spacing.s10)
            .padding(.vertical, 4)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.dfLabelSm).tracking(1.5)
            .foregroundStyle(Color.dfOutline)
            .padding(.horizontal, Spacing.s10)
            .padding(.top, Spacing.s8)
            .padding(.bottom, Spacing.s4)
    }

    // Logs one event per finished search, not one per keystroke.
    private func logSearch(_ text: String) {
        pendingSearchLog?.cancel()
        let q = text.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { return }
        pendingSearchLog = Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { return }
            Analytics.track("location_searched", ["query": q, "result_count": results.count])
        }
    }

    // MARK: - MapKit Search
    private func searchLocations(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else { results = []; return }
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed + " India"
        request.resultTypes = .address
        MKLocalSearch(request: request).start { response, _ in
            DispatchQueue.main.async {
                isSearching = false
                results = response?.mapItems.prefix(8).map { $0 } ?? []
            }
        }
    }
}

#Preview {
    LocationPickerView(currentName: "Downtown") { _, _ in }
}
