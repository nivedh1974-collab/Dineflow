import SwiftUI

struct ProfileView: View {
    @Binding var selectedTab: Int
    @AppStorage("isLoggedIn")    var isLoggedIn    = true
    @AppStorage("userEmail")     var userEmail     = ""
    @AppStorage("userPhone")     var userPhone     = ""
    @AppStorage("isMerchant")    var isMerchant    = false

    @State private var navigateToMerchant = false

    private var displayName: String {
        let prefix = userEmail.components(separatedBy: "@").first ?? "User"
        let parts  = prefix.components(separatedBy: CharacterSet(charactersIn: "._-"))
        return parts.map { $0.capitalized }.joined(separator: " ")
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.dfSurface.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 80)

                    VStack(spacing: Spacing.s10) {
                        avatarSection.padding(.top, Spacing.s8)

                        VStack(spacing: Spacing.s4) {
                            ProfileInfoCard(icon: "envelope", label: "Email Address",
                                           value: userEmail.isEmpty ? "—" : userEmail)
                            if !userPhone.isEmpty {
                                ProfileInfoCard(icon: "iphone", label: "Phone Number", value: userPhone)
                            }
                            ProfileInfoCard(
                                icon: isMerchant ? "storefront" : "person",
                                label: "Account Type",
                                value: isMerchant ? "Restaurant Owner" : "Diner")
                        }

                        // Merchant Dashboard shortcut
                        if isMerchant {
                            Button { Analytics.tap("profile", "open_merchant_dashboard"); navigateToMerchant = true } label: {
                                HStack(spacing: Spacing.s4) {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.body.weight(.semibold))
                                    Text("Open Merchant Dashboard")
                                        .font(.manrope(16, weight: .bold))
                                }
                                .foregroundStyle(Color.dfOnPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(LinearGradient.primaryGradient)
                                .clipShape(Capsule())
                                .primaryShadow()
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }

                        // Log out
                        Button {
                            Analytics.track("logout", ["role": isMerchant ? "merchant" : "diner"])
                            isLoggedIn = false
                        } label: {
                            HStack(spacing: Spacing.s4) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.body.weight(.semibold))
                                Text("Log Out").font(.manrope(16, weight: .bold))
                            }
                            .foregroundStyle(Color.dfError)
                            .frame(maxWidth: .infinity).padding(.vertical, 18)
                            .background(Color.dfSurfaceHighest.opacity(0.5))
                            .overlay(Capsule().stroke(Color.dfError.opacity(0.1), lineWidth: 1))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, Spacing.s10)
                    Color.clear.frame(height: 120)
                }
            }
            .scrollIndicators(.hidden)

            HStack {
                Button { Analytics.tap("profile", "brand_logo"); selectedTab = 0 } label: {
                    Text("Dineflow").font(.jakartaItalic(20)).foregroundStyle(Color.dfPrimary)
                }.buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, Spacing.s10).padding(.vertical, Spacing.s6)
            .background(.ultraThinMaterial)
        }
        .navigationBarHidden(true)
        .trackScreen("profile", ["role": isMerchant ? "merchant" : "diner"])
        .navigationDestination(isPresented: $navigateToMerchant) {
            MerchantDashboardView()
        }
    }

    private var avatarSection: some View {
        VStack(spacing: Spacing.s4) {
            ZStack {
                Circle()
                    .fill(LinearGradient.primaryGradient)
                    .frame(width: 88, height: 88)
                Text(initials)
                    .font(.jakarta(28, weight: .bold))
                    .foregroundStyle(Color.dfOnPrimary)
            }
            VStack(spacing: 4) {
                Text(displayName)
                    .font(.dfHeadlineMd).foregroundStyle(Color.dfOnSurface)
                Text(isMerchant ? "RESTAURANT OWNER" : "DINER MEMBER")
                    .font(.dfLabelSm).tracking(2).foregroundStyle(Color.dfSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var initials: String {
        let parts = displayName.components(separatedBy: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined()
    }
}

#Preview { NavigationStack { ProfileView(selectedTab: .constant(3)) } }
