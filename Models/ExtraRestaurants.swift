import Foundation
import CoreLocation

// Loads the demo restaurants from ExtraRestaurantData.json and turns them into Restaurant values.
// Restaurants, menus and offers here are sample data for the Dineflow demo.

private struct ExtraFile: Decodable {
    let menus: [String: [ExtraMenuItem]]
    let restaurants: [ExtraRestaurant]
}

private struct ExtraMenuItem: Decodable {
    let n: String
    let d: String
    let p: Int
    let c: String
}

private struct ExtraOffer: Decodable {
    let t: String
    let d: String
    let pct: Int
    let bogo: Bool
    let hrs: Int
}

private struct ExtraRestaurant: Decodable {
    let name: String
    let city: String
    let area: String
    let cuisine: String
    let menu: String
    let price: Int
    let lat: Double
    let lng: Double
    let rating: Double
    let reviews: Int
    let address: String
    let desc: String
    let offers: [ExtraOffer]
}

extension Restaurant {

    /// Stable fallback pictures until Google Places photos load (or if no API key is set).
    private static let fallbackImages = [
        "photo-1585937421612-70a008356fbe", "photo-1603894584373-5ac82b2ae398",
        "photo-1567188040759-fb8a883dc6d6", "photo-1596797038530-2c107229654b",
        "photo-1631452180539-96aca7d48617", "photo-1512621776951-a57141f2eefd",
        "photo-1565299585323-38d6b0865b47", "photo-1555396273-367ea4eb4db5",
        "photo-1544025162-d76694265947", "photo-1559339352-11d035aa65de",
        "photo-1414235077428-338989a2e8c0", "photo-1579871494447-9811cf80d66c"
    ]

    private static func fallbackGallery(for name: String) -> [String] {
        let start = abs(name.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }) % fallbackImages.count
        // 10 pictures, rotated per restaurant so neighbours do not look identical
        return (0..<10).map { i in
            "https://images.unsplash.com/\(fallbackImages[(start + i) % fallbackImages.count])?w=800"
        }
    }

    static let extraRestaurants: [Restaurant] = {
        guard let data = ExtraRestaurantData.json.data(using: .utf8),
              let file = try? JSONDecoder().decode(ExtraFile.self, from: data) else {
            return []
        }

        var regional: [String: [MenuItem]] = [:]
        for (key, items) in file.menus {
            regional[key] = MenuLib.beverages + items.map {
                MenuItem(name: $0.n, description: $0.d, price: "₹\($0.p)", category: $0.c)
            }
        }
        let legacy: [String: [MenuItem]] = [
            "north": MenuLib.northIndian,
            "south": MenuLib.southIndian,
            "italian": MenuLib.italian,
            "continental": MenuLib.continental,
            "multi": MenuLib.multiCuisine
        ]

        return file.restaurants.map { r in
            let rid = UUID()
            let menu = legacy[r.menu] ?? regional[r.menu] ?? MenuLib.multiCuisine
            let offers: [Offer] = r.offers.map {
                Offer(id: UUID(), title: $0.t, description: $0.d, discountPercent: $0.pct,
                      endsAt: Date().addingTimeInterval(Double($0.hrs) * 3600),
                      isBOGO: $0.bogo, restaurantId: rid)
            }
            let gallery = fallbackGallery(for: r.name)
            return Restaurant(
                id: rid, name: r.name, cuisine: r.cuisine, city: r.city,
                coordinate: CLLocationCoordinate2D(latitude: r.lat, longitude: r.lng),
                rating: r.rating, reviewCount: r.reviews, priceLevel: r.price,
                imageURL: gallery[0], photos: gallery,
                address: r.address, description: r.desc, menuItems: menu,
                liveOffer: offers.first, secondOffer: offers.count > 1 ? offers[1] : nil
            )
        }
    }()
}
