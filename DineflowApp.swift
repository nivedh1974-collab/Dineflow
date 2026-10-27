import SwiftUI

@main
struct DineflowApp: App {
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @AppStorage("isMerchant") var isMerchant = false

    @StateObject private var store = RestaurantStore.shared

    init() {
        Analytics.start()
        Analytics.track("app_opened")
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isLoggedIn {
                    if isMerchant {
                        MerchantRootView()
                            .environmentObject(store)
                    } else {
                        MainTabView()
                            .environmentObject(store)
                    }
                } else {
                    LoginView()
                        .environmentObject(store)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isLoggedIn)
            .animation(.easeInOut(duration: 0.3), value: isMerchant)
            .onAppear {
                Analytics.setRole(isMerchant ? "merchant" : "diner")
            }
            .onChange(of: isMerchant) { _, newValue in
                Analytics.setRole(newValue ? "merchant" : "diner")
            }
        }
    }
}
