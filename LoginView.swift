import SwiftUI

struct LoginView: View {
    @EnvironmentObject var store: RestaurantStore

    @AppStorage("isLoggedIn")    var isLoggedIn    = false
    @AppStorage("userEmail")     var storedEmail   = ""
    @AppStorage("userPhone")     var storedPhone   = ""
    @AppStorage("isMerchant")    var storedMerchant = false

    @State private var email          = ""
    @State private var phone          = ""
    @State private var password       = ""
    @State private var isMerchantMode = false
    @State private var showPassword   = false
    @State private var isLoading      = false
    @State private var errorMessage   = ""

    // Restaurant search
    @State private var restaurantQuery   = ""
    @State private var showSuggestions   = false
    @State private var selectedRestaurant: Restaurant? = nil

    private var suggestions: [Restaurant] {
        guard !restaurantQuery.isEmpty else { return [] }
        return store.restaurants.filter {
            $0.name.localizedCaseInsensitiveContains(restaurantQuery) ||
            $0.city.localizedCaseInsensitiveContains(restaurantQuery)
        }.prefix(5).map { $0 }
    }

    var body: some View {
        NavigationStack {
        ZStack {
            Color(hex: "#EDF2F7").ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text("Dineflow")
                        .font(.jakartaItalic(20))
                        .foregroundStyle(Color.dfPrimary)
                    Spacer()
                }
                .padding(.horizontal, Spacing.s10)
                .padding(.top, Spacing.s8)
                .padding(.bottom, Spacing.s6)

                Spacer()

                // Card
                VStack(alignment: .leading, spacing: 0) {

                    // Role toggle
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isMerchantMode.toggle()
                            Analytics.tap("login", "role_toggle", ["mode": isMerchantMode ? "merchant" : "diner"])
                            restaurantQuery = ""
                            selectedRestaurant = nil
                            showSuggestions = false
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isMerchantMode ? "storefront.fill" : "person.fill")
                                .font(.body.weight(.semibold))
                            Text(isMerchantMode ? "Login as Restaurant Owner" : "Login as Diner")
                                .font(.manrope(14, weight: .semibold))
                            Spacer()
                            Image(systemName: "arrow.2.circlepath")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(Color(hex: "#2B4FBE").opacity(0.85))
                        .padding(.horizontal, Spacing.s8)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#2B4FBE").opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .padding(.bottom, Spacing.s8)

                    // Title
                    Text(isMerchantMode
                         ? "Sign in to your\nRestaurant Dashboard"
                         : "Welcome\nto Dineflow")
                        .font(.custom("Manrope-ExtraBold", size: 28))
                        .foregroundStyle(Color(hex: "#2B4FBE"))
                        .lineSpacing(4)
                        .padding(.bottom, Spacing.s10)

                    // Restaurant picker — merchant only
                    if isMerchantMode {
                        fieldLabel("Restaurant Name")
                        restaurantSearchField
                            .padding(.bottom, Spacing.s6)
                    }

                    // Email
                    fieldLabel("Email Address")
                    inputField(icon: "envelope", placeholder: "name@example.com", text: $email, keyboard: .emailAddress)
                        .padding(.bottom, Spacing.s6)

                    // Phone
                    fieldLabel("Phone Number")
                    inputField(icon: "phone", placeholder: "+91 00000-00000", text: $phone, keyboard: .phonePad)
                        .padding(.bottom, Spacing.s6)

                    // Password
                    fieldLabel("Password")
                    passwordInputField
                        .padding(.bottom, Spacing.s4)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.dfLabelMd)
                            .foregroundStyle(Color.dfError)
                            .padding(.bottom, Spacing.s3)
                    }

                    // Login button
                    Button { Analytics.tap("login", "login_button", ["mode": isMerchantMode ? "merchant" : "diner"]); handleLogin() } label: {
                        HStack(spacing: Spacing.s4) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Login").font(.manrope(16, weight: .bold))
                                Image(systemName: "arrow.right.square.fill").font(.body.weight(.semibold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(hex: "#1E3A8A"))
                        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
                    }
                    .disabled(isLoading)
                    .buttonStyle(ScaleButtonStyle())

                    // Register new restaurant — merchant only
                    if isMerchantMode {
                        NavigationLink(destination: RegisterRestaurantView().environmentObject(store)) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Register a new restaurant")
                                    .font(.manrope(14, weight: .semibold))
                            }
                            .foregroundStyle(Color(hex: "#2B4FBE"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "#2B4FBE").opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
                        }
                        .padding(.top, 4)
                        .simultaneousGesture(TapGesture().onEnded { Analytics.tap("login", "register_restaurant_link") })
                    }
                }
                .padding(Spacing.s10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: Color.black.opacity(0.06), radius: 24, x: 0, y: 8)
                .padding(.horizontal, Spacing.s8)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .trackScreen("login")
        }
    }

    // MARK: - Restaurant search field
    @ViewBuilder
    private var restaurantSearchField: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: selectedRestaurant != nil ? "checkmark.circle.fill" : "magnifyingglass")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(selectedRestaurant != nil ? Color(hex: "#2B4FBE") : Color(hex: "#94A3B8"))
                    .frame(width: 20)
                TextField("Search restaurant name or city...", text: $restaurantQuery)
                    .font(.manrope(15))
                    .foregroundStyle(Color(hex: "#1A1A2E"))
                    .autocorrectionDisabled()
                    .onChange(of: restaurantQuery) { _, val in
                        selectedRestaurant = nil
                        showSuggestions = !val.isEmpty
                    }
                if selectedRestaurant != nil {
                    Button {
                        Analytics.tap("login", "clear_restaurant")
                        restaurantQuery = ""
                        selectedRestaurant = nil
                        showSuggestions = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(hex: "#94A3B8"))
                    }
                }
            }
            .padding(Spacing.s6)
            .background(selectedRestaurant != nil ? Color(hex: "#EBF0FF") : Color(hex: "#F1F5F9"))
            .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xl)
                    .stroke(selectedRestaurant != nil ? Color(hex: "#2B4FBE").opacity(0.4) : Color.clear, lineWidth: 1.5)
            )

            // Suggestions dropdown
            if showSuggestions && !suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(suggestions) { restaurant in
                        Button {
                            Analytics.tap("login", "restaurant_suggestion", ["restaurant": restaurant.name, "city": restaurant.city])
                            selectedRestaurant = restaurant
                            restaurantQuery = restaurant.name
                            showSuggestions = false
                        } label: {
                            HStack(spacing: 10) {
                                CachedAsyncImage(url: URL(string: restaurant.imageURL)) { phase in
                                    switch phase {
                                    case .success(let img): img.resizable().scaledToFill()
                                    default: Color(hex: "#E5E2E1")
                                    }
                                }
                                .frame(width: 36, height: 36)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(restaurant.name)
                                        .font(.manrope(14, weight: .semibold))
                                        .foregroundStyle(Color(hex: "#1A1A2E"))
                                    Text("\(restaurant.cuisine) · \(restaurant.city)")
                                        .font(.manrope(11))
                                        .foregroundStyle(Color(hex: "#94A3B8"))
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(PlainButtonStyle())

                        if restaurant.id != suggestions.last?.id {
                            Divider().padding(.leading, 58)
                        }
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                .padding(.top, 4)
            }

            // No results
            if showSuggestions && suggestions.isEmpty && !restaurantQuery.isEmpty {
                Text("No restaurant found for \"\(restaurantQuery)\"")
                    .font(.manrope(12))
                    .foregroundStyle(Color(hex: "#94A3B8"))
                    .padding(.top, 6)
                    .padding(.leading, 4)
            }
        }
    }

    // MARK: - Field helpers
    @ViewBuilder
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.manrope(14, weight: .bold))
            .foregroundStyle(Color(hex: "#1A1A2E"))
            .padding(.bottom, 6)
    }

    @ViewBuilder
    private func inputField(icon: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color(hex: "#94A3B8"))
                .frame(width: 20)
            TextField(placeholder, text: text)
                .font(.manrope(15))
                .foregroundStyle(Color(hex: "#1A1A2E"))
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(Spacing.s6)
        .background(Color(hex: "#F1F5F9"))
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
    }

    @ViewBuilder
    private var passwordInputField: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color(hex: "#94A3B8"))
                .frame(width: 20)
            Group {
                if showPassword {
                    TextField("Password", text: $password)
                } else {
                    SecureField("Password", text: $password)
                }
            }
            .font(.manrope(15))
            .foregroundStyle(Color(hex: "#1A1A2E"))
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            Spacer()
            Button { showPassword.toggle(); Analytics.tap("login", "toggle_password_visibility", ["visible": showPassword]) } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: "#94A3B8"))
            }
        }
        .padding(Spacing.s6)
        .background(Color(hex: "#F1F5F9"))
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
    }

    // MARK: - Login
    private func loginFailed(_ reason: String, _ message: String) {
        errorMessage = message
        Analytics.track("login_failed", ["reason": reason, "mode": isMerchantMode ? "merchant" : "diner"])
    }

    private func handleLogin() {
        errorMessage = ""
        let trimEmail    = email.trimmingCharacters(in: .whitespaces)
        let trimPhone    = phone.trimmingCharacters(in: .whitespaces)
        let trimPassword = password.trimmingCharacters(in: .whitespaces)

        guard !trimEmail.isEmpty    else { loginFailed("missing_email", "Please enter your email address."); return }
        guard !trimPassword.isEmpty else { loginFailed("missing_password", "Please enter your password."); return }

        if isMerchantMode && selectedRestaurant == nil {
            loginFailed("missing_restaurant", "Please select your restaurant.")
            return
        }

        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isLoading = false
            storedEmail    = trimEmail
            storedPhone    = trimPhone.isEmpty ? "" : trimPhone
            storedMerchant = isMerchantMode

            // Set merchant restaurant directly from selection
            if isMerchantMode, let restaurant = selectedRestaurant {
                store.merchantRestaurant = restaurant
                if store.businessHours[restaurant.id.uuidString] == nil {
                    store.businessHours[restaurant.id.uuidString] = DayHours.defaults
                }
            }

            Analytics.setRole(isMerchantMode ? "merchant" : "diner")
            Analytics.track("login_completed", [
                "role": isMerchantMode ? "merchant" : "diner",
                "restaurant": selectedRestaurant?.name ?? "",
                "has_phone": !trimPhone.isEmpty
            ])
            isLoggedIn = true
        }
    }
}

#Preview { LoginView().environmentObject(RestaurantStore.shared) }
