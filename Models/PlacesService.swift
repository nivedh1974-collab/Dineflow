import Foundation
import CoreLocation

/// Looks up each restaurant on Google Places (New) and returns its real photos,
/// rating and location. Results are cached on the device so each restaurant is
/// looked up once, not on every launch.
///
/// Setup: add a string key PLACES_API_KEY to Info.plist (value from your build settings,
/// never hard-coded in source). If the key is missing this file does nothing and the app
/// keeps its fallback photos.
struct PlaceInfo: Codable {
    var photoNames: [String]
    var lat: Double?
    var lng: Double?
    var rating: Double?
    var reviewCount: Int?
    var address: String?
    var fetchedAt: Date
}

final class PlacesService {
    static let shared = PlacesService()

    private let cacheKey = "places_cache_v1"
    private let maxAge: TimeInterval = 60 * 60 * 24 * 30   // photo references expire, refresh monthly
    private var cache: [String: PlaceInfo] = [:]
    private let queue = DispatchQueue(label: "places.cache")

    private var apiKey: String? {
        let key = Bundle.main.object(forInfoDictionaryKey: "PLACES_API_KEY") as? String
        guard let key, !key.isEmpty, !key.hasPrefix("$(") else { return nil }
        return key
    }

    var isEnabled: Bool { apiKey != nil }

    private init() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let saved = try? JSONDecoder().decode([String: PlaceInfo].self, from: data) {
            cache = saved
        }
    }

    private func id(_ name: String, _ city: String) -> String { "\(name)|\(city)" }

    func cached(name: String, city: String) -> PlaceInfo? {
        queue.sync { cache[id(name, city)] }
    }

    func needsLookup(name: String, city: String) -> Bool {
        guard isEnabled else { return false }
        guard let info = cached(name: name, city: city) else { return true }
        return Date().timeIntervalSince(info.fetchedAt) > maxAge
    }

    func photoURL(_ name: String, width: Int = 800) -> String {
        "https://places.googleapis.com/v1/\(name)/media?maxWidthPx=\(width)&key=\(apiKey ?? "")"
    }

    /// Returns nil when nothing matched or the request failed.
    func lookup(name: String, city: String, lat: Double, lng: Double) async -> PlaceInfo? {
        guard let key = apiKey,
              let url = URL(string: "https://places.googleapis.com/v1/places:searchText") else { return nil }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(key, forHTTPHeaderField: "X-Goog-Api-Key")
        req.setValue("places.displayName,places.location,places.rating,places.userRatingCount,places.formattedAddress,places.photos",
                     forHTTPHeaderField: "X-Goog-FieldMask")
        let body: [String: Any] = [
            "textQuery": "\(name), \(city)",
            "maxResultCount": 1,
            "locationBias": ["circle": [
                "center": ["latitude": lat, "longitude": lng],
                "radius": 15000.0
            ]]
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let place = (json["places"] as? [[String: Any]])?.first else { return nil }

        let photos = (place["photos"] as? [[String: Any]] ?? []).compactMap { $0["name"] as? String }.prefix(10)
        guard !photos.isEmpty else { return nil }
        let loc = place["location"] as? [String: Any]
        let info = PlaceInfo(
            photoNames: Array(photos),
            lat: loc?["latitude"] as? Double,
            lng: loc?["longitude"] as? Double,
            rating: place["rating"] as? Double,
            reviewCount: place["userRatingCount"] as? Int,
            address: place["formattedAddress"] as? String,
            fetchedAt: Date()
        )
        queue.sync { cache[id(name, city)] = info }
        persist()
        return info
    }

    private func persist() {
        let snapshot = queue.sync { cache }
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
}
