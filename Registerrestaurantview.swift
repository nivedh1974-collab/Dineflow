import SwiftUI
import CoreLocation

struct RegisterRestaurantView: View {
    @EnvironmentObject var store: RestaurantStore
    @Environment(\.dismiss) var dismiss
    @AppStorage("isLoggedIn")  var isLoggedIn  = false
    @AppStorage("isMerchant")  var isMerchant  = false
    @AppStorage("userEmail")   var storedEmail = ""
    @AppStorage("userPhone")   var storedPhone = ""

    @State private var step = 0

    // Step 0 — Credentials
    @State private var email    = ""
    @State private var phone    = ""
    @State private var password = ""
    @State private var showPassword = false

    // Step 1 — Restaurant basics
    @State private var name        = ""
    @State private var cuisine     = ""
    @State private var city        = ""
    @State private var address     = ""
    @State private var description = ""
    @State private var priceLevel  = 2

    // Step 2 — Done
    @State private var isLoading   = false
    @State private var errorMessage = ""

    private let priceLevels = ["₹0–250", "₹250–500", "₹500–750", "₹750–1000", "₹1000+"]
    private let cities = ["Kochi", "Bangalore", "Pune", "Chennai", "Mumbai", "Delhi", "Hyderabad", "Kolkata", "Ahmedabad", "Jaipur", "Chandigarh", "Goa", "Coimbatore", "Trivandrum", "Lucknow", "Indore", "Doha"]

    var body: some View {
        ZStack {
            Color(hex: "#F9F6F5").ignoresSafeArea()

            // Background glow
            Circle()
                .fill(Color(hex: "#FF784D").opacity(0.07))
                .frame(width: 300).blur(radius: 80)
                .offset(x: 120, y: -300).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        Analytics.tap("register_restaurant", "close", ["step": step])
                        if step < 2 { Analytics.track("registration_abandoned", ["step": step]) }
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "#2F2E2E"))
                            .padding(10)
                            .background(Color(hex: "#ECEAE4"))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Register Restaurant")
                        .font(.custom("Plus Jakarta Sans", size: 16)).fontWeight(.bold)
                        .foregroundColor(Color(hex: "#2F2E2E"))
                    Spacer()
                    Color.clear.frame(width: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)

                // Step indicator
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Capsule()
                            .fill(i <= step ? Color(hex: "#A93000") : Color(hex: "#E5E2E1"))
                            .frame(height: 4)
                            .animation(.spring(), value: step)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

                ScrollView {
                    VStack(spacing: 20) {
                        if step == 0 { credentialsStep }
                        else if step == 1 { restaurantStep }
                        else { doneStep }
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 20)
                }
                .scrollIndicators(.hidden)
            }

            // Bottom button
            if step < 2 {
                VStack {
                    Spacer()
                    Button { Analytics.tap("register_restaurant", step == 0 ? "continue" : "register_button", ["step": step]); handleNext() } label: {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(step == 0 ? "Continue" : "Register Restaurant")
                                    .font(.custom("Plus Jakarta Sans", size: 16)).fontWeight(.bold)
                                Image(systemName: step == 0 ? "arrow.right" : "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        .foregroundColor(Color(hex: "#FFEFEB"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#A93000"), Color(hex: "#C84010")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color(hex: "#A93000").opacity(0.35), radius: 12, x: 0, y: 6)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    .background(Color(hex: "#F9F6F5"))
                }
            }
        }
        .navigationBarHidden(true)
        .trackScreen("register_restaurant")
        .onChange(of: step) { _, s in
            Analytics.track("registration_step_viewed", ["step": s, "step_name": ["credentials", "restaurant_details", "done"][min(s, 2)]])
        }
    }

    // MARK: - Step 0: Credentials
    private var credentialsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Create Your Account")
                    .font(.custom("Plus Jakarta Sans", size: 22)).fontWeight(.heavy)
                    .foregroundColor(Color(hex: "#2F2E2E"))
                Text("You'll use these to log in as a restaurant owner.")
                    .font(.custom("Manrope", size: 13))
                    .foregroundColor(Color(hex: "#5C5B5B"))
            }

            fieldGroup {
                labeledField("EMAIL ADDRESS", icon: "envelope", placeholder: "name@example.com", text: $email, keyboard: .emailAddress)
                Divider().padding(.leading, 52)
                labeledField("PHONE NUMBER", icon: "phone", placeholder: "+91 00000-00000", text: $phone, keyboard: .phonePad)
                Divider().padding(.leading, 52)
                passwordRow
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.custom("Manrope", size: 12))
                    .foregroundColor(Color(hex: "#B31B25"))
                    .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Step 1: Restaurant Details
    private var restaurantStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Restaurant Details")
                    .font(.custom("Plus Jakarta Sans", size: 22)).fontWeight(.heavy)
                    .foregroundColor(Color(hex: "#2F2E2E"))
                Text("Tell us about your restaurant.")
                    .font(.custom("Manrope", size: 13))
                    .foregroundColor(Color(hex: "#5C5B5B"))
            }

            fieldGroup {
                labeledField("RESTAURANT NAME", icon: "fork.knife", placeholder: "e.g. The Grand Spice", text: $name)
                Divider().padding(.leading, 52)
                labeledField("CUISINE TYPE", icon: "flame", placeholder: "e.g. North Indian, Italian", text: $cuisine)
            }

            // City picker
            VStack(alignment: .leading, spacing: 8) {
                Text("CITY")
                    .font(.custom("Manrope", size: 10)).fontWeight(.bold)
                    .tracking(2).foregroundColor(Color(hex: "#4B5D70"))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(cities, id: \.self) { c in
                            Button { Analytics.tap("register_restaurant", "city_chip", ["city": c]); city = c } label: {
                                Text(c)
                                    .font(.custom("Manrope", size: 13)).fontWeight(.semibold)
                                    .foregroundColor(city == c ? Color(hex: "#FFEFEB") : Color(hex: "#2F2E2E"))
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(city == c ? Color(hex: "#A93000") : Color(hex: "#FFFFFF"))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            // Price level
            VStack(alignment: .leading, spacing: 8) {
                Text("PRICE RANGE")
                    .font(.custom("Manrope", size: 10)).fontWeight(.bold)
                    .tracking(2).foregroundColor(Color(hex: "#4B5D70"))
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { level in
                        Button { Analytics.tap("register_restaurant", "price_level", ["level": level]); priceLevel = level } label: {
                            Text(priceLevels[level - 1])
                                .font(.custom("Manrope", size: 10)).fontWeight(.bold)
                                .foregroundColor(priceLevel == level ? Color(hex: "#FFEFEB") : Color(hex: "#2F2E2E"))
                                .padding(.horizontal, 8).padding(.vertical, 6)
                                .background(priceLevel == level ? Color(hex: "#A93000") : Color(hex: "#FFFFFF"))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }

            fieldGroup {
                labeledField("ADDRESS", icon: "mappin", placeholder: "Full street address", text: $address)
            }

            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("DESCRIPTION")
                    .font(.custom("Manrope", size: 10)).fontWeight(.bold)
                    .tracking(2).foregroundColor(Color(hex: "#4B5D70"))
                ZStack(alignment: .topLeading) {
                    if description.isEmpty {
                        Text("Describe your restaurant, specialties, ambiance...")
                            .font(.custom("Manrope", size: 14))
                            .foregroundColor(Color(hex: "#AFACAC"))
                            .padding(14).allowsHitTesting(false)
                    }
                    TextEditor(text: $description)
                        .font(.custom("Manrope", size: 14))
                        .foregroundColor(Color(hex: "#2F2E2E"))
                        .frame(minHeight: 100)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .scrollContentBackground(.hidden)
                }
                .background(Color(hex: "#FFFFFF"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.custom("Manrope", size: 12))
                    .foregroundColor(Color(hex: "#B31B25"))
                    .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Step 2: Done
    private var doneStep: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)
            ZStack {
                Circle().fill(Color(hex: "#A93000").opacity(0.1)).frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(Color(hex: "#A93000"))
            }
            VStack(spacing: 8) {
                Text("Restaurant Registered!")
                    .font(.custom("Plus Jakarta Sans", size: 24)).fontWeight(.heavy)
                    .foregroundColor(Color(hex: "#2F2E2E"))
                Text("\(name) has been added to Dineflow.\nYou are now logged in as the owner.")
                    .font(.custom("Manrope", size: 14))
                    .foregroundColor(Color(hex: "#5C5B5B"))
                    .multilineTextAlignment(.center)
            }
            Button {
                Analytics.tap("register_restaurant", "go_to_dashboard")
                isLoggedIn = true
                isMerchant = true
            } label: {
                Text("Go to Dashboard")
                    .font(.custom("Plus Jakarta Sans", size: 16)).fontWeight(.bold)
                    .foregroundColor(Color(hex: "#FFEFEB"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(LinearGradient(colors: [Color(hex: "#A93000"), Color(hex: "#C84010")], startPoint: .leading, endPoint: .trailing))
                    .clipShape(Capsule())
                    .shadow(color: Color(hex: "#A93000").opacity(0.35), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Helpers
    @ViewBuilder
    private func fieldGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color(hex: "#FFFFFF"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func labeledField(_ label: String, icon: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#A93000"))
                .frame(width: 28)
                .padding(.leading, 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.custom("Manrope", size: 9)).fontWeight(.bold)
                    .tracking(1.5).foregroundColor(Color(hex: "#94A3B8"))
                TextField(placeholder, text: text)
                    .font(.custom("Manrope", size: 15)).fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#2F2E2E"))
                    .keyboardType(keyboard)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .padding(.vertical, 14)
            Spacer()
        }
    }

    @ViewBuilder
    private var passwordRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#A93000"))
                .frame(width: 28)
                .padding(.leading, 12)
            VStack(alignment: .leading, spacing: 2) {
                Text("PASSWORD")
                    .font(.custom("Manrope", size: 9)).fontWeight(.bold)
                    .tracking(1.5).foregroundColor(Color(hex: "#94A3B8"))
                Group {
                    if showPassword {
                        TextField("Create a password", text: $password)
                    } else {
                        SecureField("Create a password", text: $password)
                    }
                }
                .font(.custom("Manrope", size: 15)).fontWeight(.semibold)
                .foregroundColor(Color(hex: "#2F2E2E"))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            }
            .padding(.vertical, 14)
            Spacer()
            Button { showPassword.toggle(); Analytics.tap("register_restaurant", "toggle_password_visibility", ["visible": showPassword]) } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .foregroundColor(Color(hex: "#94A3B8"))
            }
            .padding(.trailing, 14)
        }
    }

    // MARK: - Logic
    private func fail(_ message: String) {
        errorMessage = message
        Analytics.track("registration_validation_failed", ["step": step, "message": message])
    }

    private func handleNext() {
        errorMessage = ""
        if step == 0 {
            guard !email.trimmingCharacters(in: .whitespaces).isEmpty else { fail("Please enter your email."); return }
            guard !password.trimmingCharacters(in: .whitespaces).isEmpty else { fail("Please enter a password."); return }
            step = 1
        } else if step == 1 {
            guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { fail("Please enter a restaurant name."); return }
            guard !cuisine.trimmingCharacters(in: .whitespaces).isEmpty else { fail("Please enter a cuisine type."); return }
            guard !city.isEmpty else { fail("Please select a city."); return }
            guard !address.trimmingCharacters(in: .whitespaces).isEmpty else { fail("Please enter an address."); return }

            isLoading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                isLoading = false

                // Create and register restaurant
                let newRestaurant = Restaurant(
                    id: UUID(),
                    name: name,
                    cuisine: cuisine,
                    city: city,
                    coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                    rating: 0.0,
                    reviewCount: 0,
                    priceLevel: priceLevel,
                    imageURL: "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800",
                    photos: [],
                    address: address,
                    description: description.isEmpty ? "\(cuisine) restaurant in \(city)." : description,
                    menuItems: [],
                    liveOffer: nil
                )

                store.restaurants.append(newRestaurant)
                store.merchantRestaurant = newRestaurant
                store.businessHours[newRestaurant.id.uuidString] = DayHours.defaults

                storedEmail = email.trimmingCharacters(in: .whitespaces)
                storedPhone = phone.trimmingCharacters(in: .whitespaces)

                Analytics.track("restaurant_registered", ["city": city, "cuisine": cuisine, "price_level": priceLevel, "has_description": !description.isEmpty])
                step = 2
            }
        }
    }
}
