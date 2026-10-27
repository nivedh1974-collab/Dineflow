import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    private let manager = CLLocationManager()

    @Published var authStatus: CLAuthorizationStatus = .notDetermined
    @Published var userLocation: CLLocation? = nil
    @Published var userRegionName: String = "Your Location"
    @Published var detectedCity: String = ""
    @Published var isLocating: Bool = false

    // Manual city override (from picker)
    @Published var manualCityName: String = ""
    @Published var manualCityCoord: CLLocationCoordinate2D? = nil

    var displayCityName: String {
        manualCityName.isEmpty
            ? (userRegionName == "Your Location" ? "Select Location" : userRegionName)
            : manualCityName
    }

    var activeCityForFilter: String {
        manualCityName.isEmpty ? detectedCity : normaliseCity(manualCityName)
    }

    // The coordinate to centre the map on
    var activeMapCenter: CLLocationCoordinate2D? {
        if let manual = manualCityCoord { return manual }
        return userLocation?.coordinate
    }

    func setManualCity(name: String, coordinate: CLLocationCoordinate2D) {
        manualCityName = name
        manualCityCoord = coordinate
    }

    func clearManualCity() {
        manualCityName = ""
        manualCityCoord = nil
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authStatus = manager.authorizationStatus
        if authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways {
            fetchLocation()
        }
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    /// Fetch fresh GPS location — always resets userLocation first so onChange fires
    func fetchLocation() {
        guard authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways else { return }
        isLocating = true
        // Reset to nil first: guarantees onChange(of: userLocation) fires even if
        // the coordinate hasn't changed significantly since last fetch.
        userLocation = nil
        manager.startUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                self.fetchLocation()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last,
              loc.horizontalAccuracy >= 0,
              loc.horizontalAccuracy < 500 else { return }
        DispatchQueue.main.async {
            self.userLocation = loc          // triggers @Published → onChange in map view
            self.isLocating = false
            manager.stopUpdatingLocation()
            self.reverseGeocode(loc)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLocating = false
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self, let place = placemarks?.first else { return }
            DispatchQueue.main.async {
                let city = place.locality ?? place.subLocality ?? place.name ?? "Your Location"
                self.userRegionName = city
                self.detectedCity = self.normaliseCity(city)
            }
        }
    }

    func normaliseCity(_ city: String) -> String {
        let lower = city.lowercased()
        if lower.contains("kochi") || lower.contains("cochin") || lower.contains("ernakulam") || lower.contains("aluva") { return "Kochi" }
        if lower.contains("bangalore") || lower.contains("bengaluru") { return "Bangalore" }
        if lower.contains("pune") { return "Pune" }
        if lower.contains("chennai") || lower.contains("madras") { return "Chennai" }
        if lower.contains("mumbai") || lower.contains("bombay") { return "Mumbai" }
        if lower.contains("delhi") || lower.contains("new delhi") { return "Delhi" }
        if lower.contains("doha") || lower.contains("qatar") { return "Doha" }
        if lower.contains("hyderabad") || lower.contains("secunderabad") { return "Hyderabad" }
        if lower.contains("kolkata") || lower.contains("calcutta") { return "Kolkata" }
        if lower.contains("ahmedabad") { return "Ahmedabad" }
        if lower.contains("jaipur") { return "Jaipur" }
        if lower.contains("chandigarh") || lower.contains("mohali") || lower.contains("panchkula") { return "Chandigarh" }
        if lower.contains("goa") || lower.contains("panaji") || lower.contains("panjim") || lower.contains("margao") || lower.contains("mapusa") { return "Goa" }
        if lower.contains("coimbatore") || lower.contains("kovai") { return "Coimbatore" }
        if lower.contains("trivandrum") || lower.contains("thiruvananthapuram") { return "Trivandrum" }
        if lower.contains("lucknow") { return "Lucknow" }
        if lower.contains("indore") { return "Indore" }
        return city
    }

    func distance(to coordinate: CLLocationCoordinate2D) -> Double? {
        guard let userLoc = userLocation else { return nil }
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return userLoc.distance(from: target) / 1000.0
    }
}
