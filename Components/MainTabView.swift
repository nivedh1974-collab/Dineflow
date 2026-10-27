import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var store: RestaurantStore
    @State private var selectedTab = 0
    @State private var tab0Path = NavigationPath()
    @State private var tab1Path = NavigationPath()
    @State private var tab2Path = NavigationPath()
    @State private var tab3Path = NavigationPath()

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NavigationStack(path: $tab0Path) {
                    DiscoveryFeedView(selectedTab: $selectedTab)
                }.tag(0)
                NavigationStack(path: $tab1Path) {
                    SearchView(selectedTab: $selectedTab)
                }.tag(1)
                NavigationStack(path: $tab2Path) {
                    NearbyMapView(selectedTab: $selectedTab)
                }.tag(2)
                NavigationStack(path: $tab3Path) {
                    ProfileView(selectedTab: $selectedTab)
                }.tag(3)
            }
            .onAppear { UITabBar.appearance().isHidden = true }

            DineflowTabBar(selectedTab: Binding(
                get: { selectedTab },
                set: { newTab in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if newTab == selectedTab {
                            popToRoot(for: newTab)
                        } else {
                            selectedTab = newTab
                            popToRoot(for: newTab)
                        }
                    }
                }
            ))
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private func popToRoot(for tab: Int) {
        withAnimation {
            switch tab {
            case 0: tab0Path = NavigationPath()
            case 1: tab1Path = NavigationPath()
            case 2: tab2Path = NavigationPath()
            case 3: tab3Path = NavigationPath()
            default: break
            }
        }
    }
}

#Preview { MainTabView().environmentObject(RestaurantStore.shared) }
