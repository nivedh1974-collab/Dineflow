import Foundation
import SwiftUI
import Combine
import CoreLocation

class RestaurantStore: ObservableObject {
    static let shared = RestaurantStore()

    @Published var restaurants: [Restaurant] = Restaurant.allRestaurants
    @Published var merchantRestaurant: Restaurant? = nil
    @Published var businessHours: [String: [DayHours]] = [:]

    init() {
        applyCachedPlaces()
    }

    // MARK: - Google Places photos
    /// Uses photos already looked up on earlier launches. No network.
    private func applyCachedPlaces() {
        for idx in restaurants.indices {
            if let info = PlacesService.shared.cached(name: restaurants[idx].name, city: restaurants[idx].city) {
                applyPlace(info, at: idx)
            }
        }
    }

    private func applyPlace(_ info: PlaceInfo, at idx: Int) {
        let urls = info.photoNames.map { PlacesService.shared.photoURL($0) }
        guard let first = urls.first else { return }
        restaurants[idx].imageURL = first
        restaurants[idx].photos = urls
        if let lat = info.lat, let lng = info.lng {
            restaurants[idx].coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        if let rating = info.rating { restaurants[idx].rating = rating }
        if let count = info.reviewCount { restaurants[idx].reviewCount = count }
        if let address = info.address { restaurants[idx].address = address }
    }

    /// Looks up photos for one city (about 20 restaurants), 4 at a time. Cached after the first run.
    @MainActor
    func refreshPlaces(forCity city: String) async {
        guard PlacesService.shared.isEnabled else { return }
        let targets = restaurants.filter {
            LocationManager.shared.normaliseCity($0.city) == city &&
            PlacesService.shared.needsLookup(name: $0.name, city: $0.city)
        }
        let jobs = targets.map { (id: $0.id, name: $0.name, city: $0.city, lat: $0.coordinate.latitude, lng: $0.coordinate.longitude) }
        var start = 0
        while start < jobs.count {
            let slice = Array(jobs[start..<min(start + 4, jobs.count)])
            start += 4
            await withTaskGroup(of: (UUID, PlaceInfo?).self) { group in
                for job in slice {
                    group.addTask {
                        (job.id, await PlacesService.shared.lookup(name: job.name, city: job.city, lat: job.lat, lng: job.lng))
                    }
                }
                for await (rid, info) in group {
                    if let info, let idx = restaurants.firstIndex(where: { $0.id == rid }) {
                        applyPlace(info, at: idx)
                        if merchantRestaurant?.id == rid { merchantRestaurant = restaurants[idx] }
                    }
                }
            }
        }
    }

    func claimRestaurant(email: String) {
        let prefix = email.components(separatedBy: "@").first?.lowercased() ?? ""
        if let match = restaurants.first(where: {
            $0.name.lowercased().contains(prefix) ||
            prefix.contains($0.name.lowercased().components(separatedBy: " ").first ?? "")
        }) {
            merchantRestaurant = match
        } else {
            merchantRestaurant = restaurants.first
        }
        if let r = merchantRestaurant, businessHours[r.id.uuidString] == nil {
            businessHours[r.id.uuidString] = DayHours.defaults
        }
    }

    func updateRestaurantName(_ name: String) {
        guard let id = merchantRestaurant?.id else { return }
        merchantRestaurant?.name = name
        if let idx = restaurants.firstIndex(where: { $0.id == id }) {
            restaurants[idx].name = name
        }
    }

    func addMenuItem(_ item: MenuItem) {
        guard let id = merchantRestaurant?.id else { return }
        merchantRestaurant?.menuItems.append(item)
        if let idx = restaurants.firstIndex(where: { $0.id == id }) {
            restaurants[idx].menuItems.append(item)
        }
    }

    func removeMenuItem(at offsets: IndexSet, from category: String) {
        guard let id = merchantRestaurant?.id else { return }
        var items = merchantRestaurant?.menuItems.filter { $0.category == category } ?? []
        items.remove(atOffsets: offsets)
        let otherItems = merchantRestaurant?.menuItems.filter { $0.category != category } ?? []
        merchantRestaurant?.menuItems = otherItems + items
        if let idx = restaurants.firstIndex(where: { $0.id == id }) {
            restaurants[idx].menuItems = otherItems + items
        }
    }

    func removeMenuItemById(_ itemId: UUID) {
        guard let id = merchantRestaurant?.id else { return }
        merchantRestaurant?.menuItems.removeAll { $0.id == itemId }
        if let idx = restaurants.firstIndex(where: { $0.id == id }) {
            restaurants[idx].menuItems.removeAll { $0.id == itemId }
        }
    }

    func publishOffer(_ offer: Offer) {
        guard let id = merchantRestaurant?.id else { return }
        if merchantRestaurant?.liveOffer == nil {
            merchantRestaurant?.liveOffer = offer
        } else {
            merchantRestaurant?.secondOffer = offer
        }
        if let idx = restaurants.firstIndex(where: { $0.id == id }) {
            if restaurants[idx].liveOffer == nil {
                restaurants[idx].liveOffer = offer
            } else {
                restaurants[idx].secondOffer = offer
            }
        }
    }

    func updateBusinessHours(_ hours: [DayHours]) {
        guard let id = merchantRestaurant?.id else { return }
        businessHours[id.uuidString] = hours
    }

    func hoursForMerchant() -> [DayHours] {
        guard let id = merchantRestaurant?.id else { return DayHours.defaults }
        return businessHours[id.uuidString] ?? DayHours.defaults
    }

    func todayHoursLabel() -> String {
        guard let id = merchantRestaurant?.id,
              let hours = businessHours[id.uuidString] else { return "Hours N/A" }
        let weekday = Calendar.current.component(.weekday, from: Date())
        let idx = weekday == 1 ? 6 : weekday - 2
        let day = hours[safe: idx] ?? hours[0]
        if !day.isOpen { return "Closed Today" }
        return "\(day.openTime) – \(day.closeTime)"
    }
}

struct DayHours: Identifiable {
    let id = UUID()
    var day: String
    var isOpen: Bool
    var openTime: String
    var closeTime: String
    var openDate: Date
    var closeDate: Date

    static let defaults: [DayHours] = [
        DayHours(day: "Monday",    isOpen: true, openTime: "09:00 AM", closeTime: "10:00 PM", openDate: Date.from(9, 0),  closeDate: Date.from(22, 0)),
        DayHours(day: "Tuesday",   isOpen: true, openTime: "09:00 AM", closeTime: "10:00 PM", openDate: Date.from(9, 0),  closeDate: Date.from(22, 0)),
        DayHours(day: "Wednesday", isOpen: true, openTime: "09:00 AM", closeTime: "10:00 PM", openDate: Date.from(9, 0),  closeDate: Date.from(22, 0)),
        DayHours(day: "Thursday",  isOpen: true, openTime: "09:00 AM", closeTime: "10:00 PM", openDate: Date.from(9, 0),  closeDate: Date.from(22, 0)),
        DayHours(day: "Friday",    isOpen: true, openTime: "10:00 AM", closeTime: "11:00 PM", openDate: Date.from(10, 0), closeDate: Date.from(23, 0)),
        DayHours(day: "Saturday",  isOpen: true, openTime: "11:00 AM", closeTime: "12:00 AM", openDate: Date.from(11, 0), closeDate: Date.from(0, 0)),
        DayHours(day: "Sunday",    isOpen: true, openTime: "10:00 AM", closeTime: "08:00 PM", openDate: Date.from(10, 0), closeDate: Date.from(20, 0)),
    ]
}

private extension Date {
    static func from(_ hour: Int, _ minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
