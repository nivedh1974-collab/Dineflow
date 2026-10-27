import SwiftUI
import MapKit
import CoreLocation

struct NearbyMapView: View {
    @Binding var selectedTab: Int
    @StateObject private var locationManager = LocationManager.shared
    @EnvironmentObject var store: RestaurantStore
    @State private var selectedRestaurant: Restaurant? = nil
    @State private var navigateToDetail = false
    @State private var showLocationPicker = false

    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20.5937, longitude: 78.9629),
        span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15)
    )

    private var restaurantsToShow: [Restaurant] {
        let city = locationManager.activeCityForFilter
        return city.isEmpty ? [] : store.restaurants.filter { locationManager.normaliseCity($0.city) == city }
    }

    var body: some View {
        ZStack(alignment: .top) {
            switch locationManager.authStatus {
            case .notDetermined:               permissionPrompt
            case .denied, .restricted:         deniedView
            case .authorizedWhenInUse, .authorizedAlways: mapContent
            @unknown default:                  permissionPrompt
            }
        }
        .navigationBarHidden(true)
        .trackScreen("location_map")
        .onChange(of: locationManager.authStatus) { _, status in
            Analytics.track("location_permission_result", ["status": Self.statusLabel(status)])
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(
                currentName: locationManager.displayCityName,
                onSelect: { name, coord in
                    if name.isEmpty {
                        // GPS path: LocationPickerView already called clearManualCity()
                        // and fetchLocation(). Map will re-centre via
                        // onChange(of: locationManager.userLocation) below.
                    } else {
                        // Manual city pick: LocationPickerView already called setManualCity().
                        // Re-centre immediately using the known coordinate.
                        centreMap(on: coord, span: 0.06)
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .navigationDestination(isPresented: $navigateToDetail) {
            if let r = selectedRestaurant { RestaurantDetailView(restaurant: r) }
        }
        // Re-centre whenever live GPS location updates
        .onChange(of: locationManager.userLocation) { _, newLocation in
            guard locationManager.manualCityCoord == nil,
                  let loc = newLocation else { return }
            centreMap(on: loc.coordinate, span: 0.05)
        }
        // Re-centre when manual city changes
        .onChange(of: locationManager.manualCityName) { _, name in
            guard !name.isEmpty, let coord = locationManager.manualCityCoord else { return }
            centreMap(on: coord, span: 0.06)
        }
    }

    private static func statusLabel(_ s: CLAuthorizationStatus) -> String {
        switch s {
        case .authorizedWhenInUse: return "allowed_when_in_use"
        case .authorizedAlways:    return "allowed_always"
        case .denied:              return "denied"
        case .restricted:          return "restricted"
        default:                   return "not_determined"
        }
    }

    private func centreMap(on coord: CLLocationCoordinate2D, span: Double) {
        withAnimation(.easeInOut(duration: 0.5)) {
            mapRegion = MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
            )
        }
    }

    // MARK: - Permission Prompt
    private var permissionPrompt: some View {
        ZStack {
            Color.dfSurface.ignoresSafeArea()
            VStack(spacing: Spacing.s8) {
                Spacer()
                ZStack {
                    Circle().fill(Color.dfPrimary.opacity(0.08)).frame(width: 180)
                    Circle().fill(Color.dfPrimaryContainer.opacity(0.15)).frame(width: 120)
                    Image(systemName: "map.fill").font(.system(size: 52, weight: .semibold)).foregroundStyle(Color.dfPrimary)
                }
                VStack(spacing: Spacing.s4) {
                    Text("Restaurants Near You")
                        .font(.dfHeadlineLg).multilineTextAlignment(.center).foregroundStyle(Color.dfOnSurface)
                    Text("Allow location access to discover live deals and restaurants on the map around you.")
                        .font(.dfBodyMd).multilineTextAlignment(.center).foregroundStyle(Color.dfOnSurfaceVariant)
                        .padding(.horizontal, Spacing.s12)
                }
                Spacer()
                VStack(spacing: Spacing.s4) {
                    GradientButton(title: "Allow Location Access", icon: "location.fill") {
                        Analytics.track("location_permission_requested", ["source": "map"])
                        locationManager.requestPermission()
                    }
                    Text("Your location is only used to find nearby restaurants.")
                        .font(.system(size: 11)).foregroundStyle(Color.dfOutline).multilineTextAlignment(.center)
                }
                .padding(.horizontal, Spacing.s10).padding(.bottom, 48)
            }
        }
    }

    // MARK: - Denied
    private var deniedView: some View {
        ZStack {
            Color.dfSurface.ignoresSafeArea()
            VStack(spacing: Spacing.s6) {
                Image(systemName: "location.slash.fill").font(.system(size: 48)).foregroundStyle(Color.dfOutlineVariant)
                Text("Location Access Denied").font(.dfHeadlineSm).foregroundStyle(Color.dfOnSurface)
                Text("Please enable location in Settings to see restaurants near you.")
                    .font(.dfBodyMd).foregroundStyle(Color.dfOnSurfaceVariant)
                    .multilineTextAlignment(.center).padding(.horizontal, Spacing.s12)
                Button("Open Settings") {
                    Analytics.tap("location_map", "open_settings")
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.manrope(15, weight: .bold)).foregroundStyle(Color.dfPrimary).padding(.top, Spacing.s4)
            }
        }
    }

    // MARK: - Map Content
    private var mapContent: some View {
        ZStack(alignment: .top) {
            Map(coordinateRegion: $mapRegion,
                showsUserLocation: true,
                annotationItems: restaurantsToShow) { restaurant in
                MapAnnotation(coordinate: restaurant.coordinate) {
                    restaurantPin(restaurant)
                }
            }
            .ignoresSafeArea(edges: .top)

            mapNavBar

            if !restaurantsToShow.isEmpty {
                VStack { Spacer(); nearbyCardsStrip }
            } else if locationManager.isLocating {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: Spacing.s4) {
                            ProgressView().tint(Color.dfPrimary)
                            Text("Finding your location…").font(.dfLabelMd).foregroundStyle(Color.dfOnSurface)
                        }
                        .padding(Spacing.s6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, 120)
                        Spacer()
                    }
                }
            } else if locationManager.activeCityForFilter.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button { Analytics.tap("location_map", "select_city_prompt"); showLocationPicker = true } label: {
                            HStack(spacing: Spacing.s4) {
                                Image(systemName: "mappin.and.ellipse")
                                Text("Select a city to see restaurants").font(.dfLabelMd)
                            }
                            .foregroundStyle(Color.dfPrimary)
                            .padding(Spacing.s6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        }
                        .padding(.bottom, 120)
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Nav Bar
    private var mapNavBar: some View {
        HStack(alignment: .center, spacing: Spacing.s4) {
            Button { Analytics.tap("location_map", "location_pill"); showLocationPicker = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption.weight(.bold)).foregroundStyle(Color.dfPrimary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("LOCATION").font(.dfLabelSm).tracking(1.5).foregroundStyle(Color.dfOnSurfaceVariant)
                        HStack(spacing: 3) {
                            Text(locationManager.displayCityName)
                                .font(.dfHeadlineSm).foregroundStyle(Color.dfOnSurface).lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold)).foregroundStyle(Color.dfPrimary)
                        }
                    }
                }
            }.buttonStyle(.plain)

            Spacer()

            Button { Analytics.tap("location_map", "brand_logo"); selectedTab = 0 } label: {
                Text("Dineflow").font(.jakartaItalic(20)).foregroundStyle(Color.dfPrimary)
            }.buttonStyle(.plain)

            Spacer()

            Button { Analytics.tap("location_map", "change_button"); showLocationPicker = true } label: {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill").font(.body.weight(.semibold))
                    Text("Change").font(.manrope(12, weight: .bold))
                }
                .foregroundStyle(Color.dfPrimary)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Color.dfSurfaceLowest.opacity(0.9))
                .clipShape(Capsule()).cardShadow()
            }
        }
        .padding(.horizontal, Spacing.s6).padding(.vertical, Spacing.s6)
        .background(.ultraThinMaterial)
    }

    // MARK: - Pin
    private func restaurantPin(_ restaurant: Restaurant) -> some View {
        Button {
            Analytics.tap("location_map", "map_pin", ["restaurant": restaurant.name, "has_live_offer": restaurant.liveOffer != nil])
            Analytics.track("restaurant_viewed", ["restaurant": restaurant.name, "city": restaurant.city, "cuisine": restaurant.cuisine, "source": "map_pin"])
            selectedRestaurant = restaurant
            navigateToDetail = true
        } label: {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(restaurant.liveOffer != nil
                              ? LinearGradient.primaryGradient
                              : LinearGradient(colors: [Color.dfSurfaceLowest], startPoint: .top, endPoint: .bottom))
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.dfOnSurface.opacity(0.15), radius: 8, x: 0, y: 4)
                    Image(systemName: "fork.knife")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(restaurant.liveOffer != nil ? Color.white : Color.dfPrimary)
                    if restaurant.liveOffer != nil {
                        PulseDot(color: .white, size: 5).offset(x: 14, y: -14)
                    }
                }
                Triangle()
                    .fill(restaurant.liveOffer != nil ? Color.dfPrimary : Color.dfSurfaceLowest)
                    .frame(width: 10, height: 6)
            }
        }.buttonStyle(.plain)
    }

    // MARK: - Bottom Cards
    private var nearbyCardsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s4) {
                ForEach(restaurantsToShow) { r in
                    Button {
                        Analytics.tap("location_map", "nearby_card", ["restaurant": r.name])
                        Analytics.track("restaurant_viewed", ["restaurant": r.name, "city": r.city, "cuisine": r.cuisine, "source": "map_card"])
                        selectedRestaurant = r
                        navigateToDetail = true
                    } label: {
                        nearbyCard(r)
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.s6).padding(.vertical, Spacing.s6)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
        .padding(.horizontal, Spacing.s4).padding(.bottom, 110)
    }

    private func nearbyCard(_ r: Restaurant) -> some View {
        HStack(spacing: Spacing.s4) {
            CachedAsyncImage(url: URL(string: r.imageURL)) { phase in
                switch phase {
                case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                default: Color.dfSurfaceLow
                }
            }
            .frame(width: 52, height: 52).clipShape(RoundedRectangle(cornerRadius: Radius.lg))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(r.name).font(.jakarta(13, weight: .bold)).foregroundStyle(Color.dfOnSurface).lineLimit(1)
                    if r.liveOffer != nil { Circle().fill(Color.dfPrimary).frame(width: 6, height: 6) }
                }
                Text(r.cuisine).font(.dfLabelSm).tracking(1).foregroundStyle(Color.dfOnSurfaceVariant).lineLimit(1)
                HStack(spacing: 3) {
                    Image(systemName: "star.fill").font(.system(size: 8)).foregroundStyle(Color.dfPrimaryContainer)
                    Text(String(format: "%.1f", r.rating)).font(.system(size: 10, weight: .semibold)).foregroundStyle(Color.dfOnSurface)
                }
            }
        }
        .padding(Spacing.s4).frame(width: 210)
        .background(Color.dfSurfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl)).cardShadow()
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

#Preview { NavigationStack { NearbyMapView(selectedTab: .constant(2)) } }
