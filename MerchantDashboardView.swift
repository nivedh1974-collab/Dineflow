import SwiftUI

struct MerchantDashboardView: View {
    @EnvironmentObject var store: RestaurantStore
    @AppStorage("userEmail") var userEmail = ""

    @State private var navigateToPublish  = false
    @State private var navigateToLiveFeed = false
    @State private var navigateToMenu     = false
    @State private var navigateToAccount  = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.dfSurface.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 88)

                    VStack(spacing: Spacing.s6) {
                        primaryActionCard

                        HStack(spacing: Spacing.s4) {
                            secondaryCard(
                                icon: "sensor.tag.radiowaves.forward.fill",
                                title: "Live Feed",
                                subtitle: "VIEW YOUR LISTINGS"
                            ) { Analytics.tap("merchant_dashboard", "live_feed"); navigateToLiveFeed = true }

                            secondaryCard(
                                icon: "fork.knife",
                                title: "Edit Menu",
                                subtitle: "UPDATE ITEMS"
                            ) { Analytics.tap("merchant_dashboard", "edit_menu"); navigateToMenu = true }
                        }
                        .frame(height: 200)

                        Button { Analytics.tap("merchant_dashboard", "account_information"); navigateToAccount = true } label: {
                            HStack(spacing: Spacing.s6) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.dfSecondary.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "person")
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(Color.dfSecondary)
                                    )
                                Text("Account Information")
                                    .font(.jakarta(16, weight: .bold))
                                    .foregroundStyle(Color.dfOnSurface)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.dfOutlineVariant)
                            }
                            .padding(Spacing.s6)
                            .background(Color.dfSurfaceLowest)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
                            .cardShadow()
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, Spacing.s6)
                    .padding(.top, Spacing.s8)

                    Color.clear.frame(height: 60)

                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.dfPrimary)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                        Text("Dineflow")
                            .font(.jakarta(13, weight: .heavy))
                            .foregroundStyle(Color.dfOnSurface)
                    }
                    .opacity(0.4)
                    .padding(.bottom, Spacing.s10)
                }
            }
            .scrollIndicators(.hidden)

            // Nav bar
            HStack(spacing: Spacing.s4) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.dfPrimaryDim)
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                    )
                VStack(alignment: .leading, spacing: 1) {
                    Text(store.merchantRestaurant?.name ?? "My Restaurant")
                        .font(.jakarta(18, weight: .heavy))
                        .foregroundStyle(Color.dfPrimary)
                    Text("RESTAURANT OWNER")
                        .font(.dfLabelSm)
                        .tracking(1.5)
                        .foregroundStyle(Color.dfOnSurfaceVariant)
                }
                Spacer()
            }
            .padding(.horizontal, Spacing.s6)
            .padding(.vertical, Spacing.s5)
            .background(.ultraThinMaterial)
        }
        .navigationBarHidden(true)
        .trackScreen("merchant_dashboard", ["restaurant": store.merchantRestaurant?.name ?? ""])
        .navigationDestination(isPresented: $navigateToPublish) {
            PublishOfferView()
        }
        .navigationDestination(isPresented: $navigateToLiveFeed) {
            MerchantRestaurantPreviewView()
        }
        .navigationDestination(isPresented: $navigateToMenu) {
            MenuManagerView()
        }
        .navigationDestination(isPresented: $navigateToAccount) {
            AccountInfoView()
        }
    }

    // MARK: - Primary hero card
    private var primaryActionCard: some View {
        Button { Analytics.tap("merchant_dashboard", "add_new_offer"); navigateToPublish = true } label: {
            ZStack(alignment: .bottomLeading) {
                LinearGradient.primaryGradient
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 140)
                    .blur(radius: 24)
                    .offset(x: 220, y: -20)
                VStack(alignment: .leading, spacing: Spacing.s10) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.18)).frame(width: 44, height: 44)
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color.dfOnPrimary)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add New Offer")
                            .font(.jakarta(26, weight: .heavy))
                            .foregroundStyle(Color.dfOnPrimary)
                        Text("LAUNCH A LIVE DEAL NOW")
                            .font(.dfLabelSm)
                            .tracking(1.5)
                            .foregroundStyle(Color.dfOnPrimary.opacity(0.7))
                    }
                }
                .padding(Spacing.s8)
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
        .primaryShadow()
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Secondary card
    private func secondaryCard(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient.primaryGradient
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 80)
                    .blur(radius: 16)
                    .offset(x: 80, y: -20)
                VStack(alignment: .leading, spacing: Spacing.s10) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.18)).frame(width: 40, height: 40)
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.dfOnPrimary)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.jakarta(18, weight: .bold))
                            .foregroundStyle(Color.dfOnPrimary)
                            .lineLimit(1)
                        Text(subtitle)
                            .font(.dfLabelSm)
                            .tracking(1.2)
                            .foregroundStyle(Color.dfOnPrimary.opacity(0.7))
                    }
                }
                .padding(Spacing.s6)
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
            .primaryShadow()
        }
        .buttonStyle(ScaleButtonStyle())
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        MerchantDashboardView()
            .environmentObject(RestaurantStore.shared)
    }
}
