import SwiftUI

struct MerchantRootView: View {
    @EnvironmentObject var store: RestaurantStore
    @AppStorage("userEmail") var userEmail = ""

    var body: some View {
        NavigationStack {
            if store.merchantRestaurant == nil {
                RestaurantPickerView()
            } else {
                MerchantDashboardView()
            }
        }
    }
}

// MARK: - Restaurant Picker
struct RestaurantPickerView: View {
    @EnvironmentObject var store: RestaurantStore
    @AppStorage("userEmail") var userEmail = ""

    @State private var searchText = ""

    private var filtered: [Restaurant] {
        if searchText.isEmpty { return store.restaurants }
        return store.restaurants.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.city.localizedCaseInsensitiveContains(searchText) ||
            $0.cuisine.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            Color(hex: "#F9F6F5").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    Text("Select Your Restaurant")
                        .font(.custom("Plus Jakarta Sans", size: 24)).fontWeight(.heavy)
                        .foregroundColor(Color(hex: "#2F2E2E"))
                    Text("Choose the restaurant you want to manage")
                        .font(.custom("Manrope", size: 13))
                        .foregroundColor(Color(hex: "#5C5B5B"))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 32)
                .padding(.bottom, 20)
                .padding(.horizontal, 20)

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(hex: "#787676"))
                        .font(.system(size: 15))
                    TextField("Search by name, city or cuisine...", text: $searchText)
                        .font(.custom("Manrope", size: 14))
                        .foregroundColor(Color(hex: "#2F2E2E"))
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(hex: "#FFFFFF"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color(hex: "#2F2E2E").opacity(0.05), radius: 6, x: 0, y: 2)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // List
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(filtered) { restaurant in
                            Button {
                                store.merchantRestaurant = restaurant
                                if store.businessHours[restaurant.id.uuidString] == nil {
                                    store.businessHours[restaurant.id.uuidString] = DayHours.defaults
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    CachedAsyncImage(url: URL(string: restaurant.imageURL)) { phase in
                                        switch phase {
                                        case .success(let img):
                                            img.resizable().scaledToFill()
                                        default:
                                            Color(hex: "#E5E2E1")
                                                .overlay(Image(systemName: "fork.knife")
                                                    .foregroundColor(Color(hex: "#787676")))
                                        }
                                    }
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(restaurant.name)
                                            .font(.custom("Plus Jakarta Sans", size: 15)).fontWeight(.bold)
                                            .foregroundColor(Color(hex: "#2F2E2E"))
                                            .lineLimit(1)
                                        Text(restaurant.cuisine)
                                            .font(.custom("Manrope", size: 12))
                                            .foregroundColor(Color(hex: "#5C5B5B"))
                                            .lineLimit(1)
                                        Text(restaurant.city)
                                            .font(.custom("Manrope", size: 11)).fontWeight(.semibold)
                                            .foregroundColor(Color(hex: "#A93000"))
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color(hex: "#AFACAC"))
                                }
                                .padding(14)
                                .background(Color(hex: "#FFFFFF"))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color(hex: "#2F2E2E").opacity(0.04), radius: 4, x: 0, y: 1)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationBarHidden(true)
    }
}
