import SwiftUI

struct AccountInfoView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: RestaurantStore
    @AppStorage("isLoggedIn") var isLoggedIn = true
    @AppStorage("userEmail") var userEmail = ""
    @AppStorage("userPhone") var userPhone = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#F2EFE9")
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    HStack {
                        Button(action: { Analytics.tap("merchant_account", "back"); dismiss() }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(Color(hex: "#C0392B"))
                                .font(.system(size: 18, weight: .medium))
                        }
                        Text("Dineflow")
                            .font(.custom("Georgia", size: 22))
                            .fontWeight(.bold)
                            .italic()
                            .foregroundColor(Color(hex: "#C0392B"))
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                    // Title
                    Text("Account Information")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                    // Section label
                    Text("RESTAURANT OWNER")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "#999999"))
                        .kerning(1.2)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    // Info cards
                    VStack(spacing: 12) {
                        if let restaurant = store.merchantRestaurant {
                            InfoRow(
                                icon: "fork.knife",
                                label: "RESTAURANT",
                                value: restaurant.name
                            )
                        }

                        InfoRow(
                            icon: "envelope",
                            label: "EMAIL ADDRESS",
                            value: userEmail.isEmpty ? "—" : userEmail
                        )

                        InfoRow(
                            icon: "iphone",
                            label: "PHONE NUMBER",
                            value: userPhone.isEmpty ? "—" : userPhone
                        )

                        NavigationLink(destination: BusinessHoursView()) {
                            InfoRow(
                                icon: "clock",
                                label: "OPERATIONS",
                                value: "Edit Restaurant Timing"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .simultaneousGesture(TapGesture().onEnded { Analytics.tap("merchant_account", "edit_restaurant_timing") })
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    // Logout button
                    Button(action: {
                        Analytics.track("logout", ["role": "merchant", "from": "merchant_account"])
                        store.merchantRestaurant = nil
                        isLoggedIn = false
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(Color(hex: "#C0392B"))
                            Text("Logout from Dineflow")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "#C0392B"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(hex: "#E8E4DD"))
                        .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
            .trackScreen("merchant_account")
        }
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#ECEAE4"))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "#C0392B"))
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "#999999"))
                    .kerning(1.0)
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(14)
    }
}



#Preview {
    AccountInfoView()
}
