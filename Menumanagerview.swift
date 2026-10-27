import SwiftUI
import PhotosUI

// MARK: - MenuManagerView
struct MenuManagerView: View {
    @EnvironmentObject var store: RestaurantStore
    @AppStorage("userEmail") var userEmail = ""
    @Environment(\.dismiss) var dismiss

    @State private var showAddDish       = false
    @State private var deletionItemId: UUID? = nil
    @State private var showDeleteConfirm = false
    @State private var editingPrices: [UUID: String] = [:]
    @State private var editingItem: MenuItem? = nil

    private var groupedItems: [(category: String, items: [MenuItem])] {
        guard let r = store.merchantRestaurant else { return [] }
        var seen = [String]()
        for item in r.menuItems {
            if !seen.contains(item.category) { seen.append(item.category) }
        }
        return seen.map { cat in
            (category: cat, items: r.menuItems.filter { $0.category == cat })
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#F9F6F5").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Color.clear.frame(height: 56)

                    if groupedItems.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 48))
                                .foregroundColor(Color(hex: "#AFACAC"))
                            Text("No menu items yet")
                                .font(.custom("Plus Jakarta Sans", size: 20)).fontWeight(.bold)
                                .foregroundColor(Color(hex: "#2F2E2E"))
                            Text("Tap \"Add New Dish\" to start building your menu.")
                                .font(.custom("Manrope", size: 14))
                                .foregroundColor(Color(hex: "#5C5B5B"))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    } else {
                        ForEach(groupedItems, id: \.category) { group in
                            categorySection(group.category, items: group.items)
                        }
                    }

                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)

            // Sticky bottom button
            VStack(spacing: 0) {
                Button { Analytics.tap("menu_manager", "add_new_dish"); showAddDish = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                        Text("Add New Dish")
                            .font(.custom("Plus Jakarta Sans", size: 16)).fontWeight(.heavy)
                    }
                    .foregroundColor(Color(hex: "#FFEFEB"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#A93000"), Color(hex: "#FF784D")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color(hex: "#A93000").opacity(0.35), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(Color(hex: "#F9F6F5").opacity(0.9).background(.ultraThinMaterial))
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                Button { Analytics.tap("menu_manager", "back"); dismiss() } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(hex: "#2F2E2E"))
                        .padding(8)
                }
                .padding(.leading, 4)
                Spacer()
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: "#942900"))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        )
                    Text("Menu Manager")
                        .font(.custom("Plus Jakarta Sans", size: 16)).fontWeight(.bold)
                        .foregroundColor(Color(hex: "#A93000"))
                }
                Spacer()
                Color.clear.frame(width: 44)
            }
            .frame(height: 56)
            .background(Color(hex: "#F9F6F5").opacity(0.85).background(.ultraThinMaterial))
            .overlay(alignment: .bottom) { Divider().opacity(0.15) }
        }
        .navigationBarHidden(true)
        .onAppear {
            Analytics.screen("menu_manager", ["item_count": store.merchantRestaurant?.menuItems.count ?? 0])
            if store.merchantRestaurant == nil {
                store.claimRestaurant(email: userEmail)
            }
        }
        .navigationDestination(isPresented: $showAddDish) {
            AddDishView { newItem in store.addMenuItem(newItem) }
        }
        .confirmationDialog("Delete this dish?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Analytics.track("menu_item_deleted", ["item_id": deletionItemId?.uuidString ?? ""])
                if let id = deletionItemId { store.removeMenuItemById(id) }
            }
            Button("Cancel", role: .cancel) { Analytics.tap("menu_manager", "delete_cancel") }
        }
        .sheet(item: $editingItem) { item in
            EditDishSheet(item: item) { updated in
                Analytics.track("menu_item_edited", ["item": updated.name, "category": updated.category, "price_changed": updated.price != item.price, "name_changed": updated.name != item.name])
                guard let rid = store.merchantRestaurant?.id else { return }
                if let idx = store.restaurants.firstIndex(where: { $0.id == rid }),
                   let itemIdx = store.restaurants[idx].menuItems.firstIndex(where: { $0.id == updated.id }) {
                    store.restaurants[idx].menuItems[itemIdx] = updated
                    store.merchantRestaurant?.menuItems = store.restaurants[idx].menuItems
                }
            }
        }
    }

    @ViewBuilder
    private func categorySection(_ category: String, items: [MenuItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline) {
                Text(category)
                    .font(.custom("Plus Jakarta Sans", size: 22)).fontWeight(.heavy)
                    .foregroundColor(Color(hex: "#2F2E2E"))
                Spacer()
                let badge = category == "Drinks" || category == "Beverages" ? "CRAFTED" : "\(items.count) ITEMS"
                Text(badge)
                    .font(.custom("Manrope", size: 10)).fontWeight(.bold)
                    .tracking(2)
                    .foregroundColor(Color(hex: "#4B5D70"))
            }
            .padding(.horizontal, 4)

            VStack(spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                    if idx == 0 && category == "Mains" {
                        heroCard(item: item)
                    } else {
                        standardCard(item: item, tinted: idx % 2 == 1)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func heroCard(item: MenuItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            CachedAsyncImage(url: URL(string: imageURL(item))) { phase in
                switch phase {
                case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                default: Color(hex: "#E5E2E1")
                }
            }
            .frame(maxWidth: .infinity).frame(height: 200).clipped()

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.custom("Plus Jakarta Sans", size: 15)).fontWeight(.bold)
                        .foregroundColor(Color(hex: "#2F2E2E"))
                    priceField(item: item, large: true)
                }
                Spacer()
                deleteBtn(item: item, circle: true)
            }
            .padding(12)
            .background(Color(hex: "#FFFFFF"))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color(hex: "#2F2E2E").opacity(0.06), radius: 8, x: 0, y: 2)
        .onTapGesture { Analytics.tap("menu_manager", "dish_card", ["item": item.name]); editingItem = item }
    }

    @ViewBuilder
    private func standardCard(item: MenuItem, tinted: Bool) -> some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: URL(string: imageURL(item))) { phase in
                switch phase {
                case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                default:
                    Color(hex: "#E5E2E1")
                        .overlay(Image(systemName: "fork.knife").foregroundColor(Color(hex: "#787676")))
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.custom("Plus Jakarta Sans", size: 14)).fontWeight(.bold)
                    .foregroundColor(Color(hex: "#2F2E2E")).lineLimit(1)
                priceField(item: item, large: false)
            }
            Spacer()
            deleteBtn(item: item, circle: false)
        }
        .padding(12)
        .background(tinted ? Color(hex: "#F3F0EF") : Color(hex: "#FFFFFF"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: tinted ? .clear : Color(hex: "#2F2E2E").opacity(0.04), radius: 4, x: 0, y: 1)
        .onTapGesture { Analytics.tap("menu_manager", "dish_card", ["item": item.name]); editingItem = item }
    }

    private func commitPrice(itemId: UUID, text: String) {
        let clean = text.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty, let rid = store.merchantRestaurant?.id,
              let idx = store.restaurants.firstIndex(where: { $0.id == rid }),
              let itemIdx = store.restaurants[idx].menuItems.firstIndex(where: { $0.id == itemId }) else { return }
        store.restaurants[idx].menuItems[itemIdx].price = "₹\(clean)"
        store.merchantRestaurant?.menuItems = store.restaurants[idx].menuItems
    }

    @ViewBuilder
    private func priceField(item: MenuItem, large: Bool) -> some View {
        HStack(spacing: 2) {
            Text("₹")
                .font(.custom("Manrope", size: 12)).fontWeight(.bold)
                .foregroundColor(Color(hex: "#A93000"))
            let binding = Binding<String>(
                get: { editingPrices[item.id] ?? item.price.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: "₹", with: "").trimmingCharacters(in: .whitespaces) },
                set: { editingPrices[item.id] = $0; commitPrice(itemId: item.id, text: $0) }
            )
            TextField("0.00", text: binding)
                .font(.custom("Manrope", size: large ? 14 : 12)).fontWeight(.bold)
                .foregroundColor(Color(hex: "#2F2E2E"))
                .keyboardType(.decimalPad)
                .frame(width: large ? 72 : 60)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color(hex: "#F3F0EF"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private func deleteBtn(item: MenuItem, circle: Bool) -> some View {
        Button {
            Analytics.tap("menu_manager", "delete_dish", ["item": item.name])
            deletionItemId = item.id
            showDeleteConfirm = true
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#787676").opacity(0.5))
                .padding(circle ? 10 : 8)
                .background(circle ? Color(hex: "#E5E2E1") : Color.clear)
                .clipShape(Circle())
        }
    }

    private func imageURL(_ item: MenuItem) -> String {
        let photos = store.merchantRestaurant?.photos ?? []
        let fallback = store.merchantRestaurant?.imageURL ?? ""
        switch item.category {
        case "Mains":               return photos[safe: 0] ?? fallback
        case "Starters":            return photos[safe: 1] ?? fallback
        case "Beverages", "Drinks": return photos[safe: 2] ?? fallback
        case "Desserts":            return photos[safe: 3] ?? fallback
        default:                    return photos[safe: 4] ?? fallback
        }
    }
}

// MARK: - AddDishView (redesigned)
struct AddDishView: View {
    var onAdd: (MenuItem) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var name        = ""
    @State private var price       = ""
    @State private var description = ""
    @State private var category    = "Main Course"
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var coverImage: UIImage? = nil

    private let categories = ["Main Course", "Starters", "Drinks", "Desserts", "Specials"]
    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && !price.isEmpty }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background glows
            Color(hex: "#F9F6F5").ignoresSafeArea()
            Circle()
                .fill(Color(hex: "#FF784D").opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 120, y: -200)
                .ignoresSafeArea()
            Circle()
                .fill(Color(hex: "#A93000").opacity(0.05))
                .frame(width: 250, height: 250)
                .blur(radius: 80)
                .offset(x: -100, y: 300)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Color.clear.frame(height: 8)

                    // Photo upload zone
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(hex: "#F3F0EF"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            Color(hex: "#AFACAC").opacity(0.3),
                                            style: StrokeStyle(lineWidth: 1.5, dash: [6])
                                        )
                                )
                                .frame(height: 180)

                            if let img = coverImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            } else {
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 64, height: 64)
                                            .shadow(color: Color(hex: "#2F2E2E").opacity(0.08), radius: 12)
                                        Image(systemName: "camera.badge.plus")
                                            .font(.system(size: 28, weight: .semibold))
                                            .foregroundColor(Color(hex: "#A93000"))
                                    }
                                    Text("Upload Cover Photo")
                                        .font(.custom("Plus Jakarta Sans", size: 15)).fontWeight(.bold)
                                        .foregroundColor(Color(hex: "#2F2E2E"))
                                    Text("MAIN IMAGE (HORIZONTAL)")
                                        .font(.custom("Manrope", size: 10)).fontWeight(.bold)
                                        .tracking(2)
                                        .foregroundColor(Color(hex: "#5C5B5B"))
                                }
                            }
                        }
                    }
                    .onChange(of: selectedPhoto) { _, new in
                        if new != nil { Analytics.tap("add_dish", "photo_selected") }
                        Task {
                            if let data = try? await new?.loadTransferable(type: Data.self),
                               let img = UIImage(data: data) {
                                coverImage = img
                            }
                        }
                    }

                    // Main info card
                    VStack(spacing: 20) {
                        // Dish name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DISH NAME")
                                .font(.custom("Manrope", size: 10)).fontWeight(.bold)
                                .tracking(2)
                                .foregroundColor(Color(hex: "#4B5D70"))
                            TextField("e.g. Truffle Infused Risotto", text: $name)
                                .font(.custom("Plus Jakarta Sans", size: 17)).fontWeight(.bold)
                                .foregroundColor(Color(hex: "#2F2E2E"))
                                .padding(16)
                                .background(Color(hex: "#FFFFFF"))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        // Price + Category row
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("PRICE")
                                    .font(.custom("Manrope", size: 10)).fontWeight(.bold)
                                    .tracking(2)
                                    .foregroundColor(Color(hex: "#4B5D70"))
                                HStack(spacing: 6) {
                                    Text("₹")
                                        .font(.custom("Plus Jakarta Sans", size: 16)).fontWeight(.bold)
                                        .foregroundColor(Color(hex: "#A93000"))
                                    TextField("0.00", text: $price)
                                        .font(.custom("Plus Jakarta Sans", size: 17)).fontWeight(.bold)
                                        .foregroundColor(Color(hex: "#2F2E2E"))
                                        .keyboardType(.decimalPad)
                                }
                                .padding(16)
                                .background(Color(hex: "#FFFFFF"))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .frame(maxWidth: .infinity)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("CATEGORY")
                                    .font(.custom("Manrope", size: 10)).fontWeight(.bold)
                                    .tracking(2)
                                    .foregroundColor(Color(hex: "#4B5D70"))
                                Menu {
                                    ForEach(categories, id: \.self) { cat in
                                        Button(cat) { Analytics.tap("add_dish", "category_selected", ["category": cat]); category = cat }
                                    }
                                } label: {
                                    HStack {
                                        Text(category)
                                            .font(.custom("Manrope", size: 14)).fontWeight(.semibold)
                                            .foregroundColor(Color(hex: "#2F2E2E"))
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Color(hex: "#787676"))
                                    }
                                    .padding(16)
                                    .background(Color(hex: "#FFFFFF"))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(20)
                    .background(Color(hex: "#F3F0EF"))
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DETAILED DESCRIPTION")
                            .font(.custom("Manrope", size: 10)).fontWeight(.bold)
                            .tracking(2)
                            .foregroundColor(Color(hex: "#4B5D70"))
                            .padding(.horizontal, 4)

                        ZStack(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Describe the ingredients, preparation method, and the sensory experience...")
                                    .font(.custom("Manrope", size: 14))
                                    .foregroundColor(Color(hex: "#AFACAC"))
                                    .padding(16)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $description)
                                .font(.custom("Manrope", size: 14))
                                .foregroundColor(Color(hex: "#2F2E2E"))
                                .frame(minHeight: 130)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .scrollContentBackground(.hidden)
                        }
                        .background(Color(hex: "#FFFFFF"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)

            // Bottom CTA
            Button {
                guard isValid else { return }
                let item = MenuItem(
                    name: name,
                    description: description.isEmpty ? "\(category) item" : description,
                    price: "₹\(price)",
                    category: category
                )
                Analytics.track("menu_item_added", ["item": name, "category": category, "price": price, "has_description": !description.isEmpty, "has_photo": coverImage != nil])
                onAdd(item)
                dismiss()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 16, weight: .bold))
                    Text("Save Dish to Menu")
                        .font(.custom("Plus Jakarta Sans", size: 16)).fontWeight(.bold)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(isValid ? Color(hex: "#FFEFEB") : Color(hex: "#787676"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    isValid
                    ? AnyShapeStyle(LinearGradient(
                        colors: [Color(hex: "#A93000"), Color(hex: "#C84010")],
                        startPoint: .leading, endPoint: .trailing))
                    : AnyShapeStyle(Color(hex: "#E5E2E1"))
                )
                .clipShape(Capsule())
                .shadow(color: isValid ? Color(hex: "#A93000").opacity(0.4) : .clear, radius: 16, x: 0, y: 6)
            }
            .disabled(!isValid)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        // Red top nav bar
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack(spacing: 12) {
                Button { Analytics.tap("add_dish", "back"); dismiss() } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .padding(8)
                }
                Text("Add New Dish")
                    .font(.custom("Plus Jakarta Sans", size: 18)).fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
            }
            .frame(height: 56)
            .padding(.horizontal, 8)
            .background(Color(hex: "#A93000"))
        }
        .navigationBarHidden(true)
        .trackScreen("add_dish")
    }
}

// MARK: - EditDishSheet
struct EditDishSheet: View {
    let item: MenuItem
    var onSave: (MenuItem) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var name: String
    @State private var price: String
    @State private var description: String
    @State private var category: String

    private let categories = ["Main Course", "Starters", "Mains", "Drinks", "Desserts", "Specials", "Beverages", "Breads", "Rice"]
    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && !price.isEmpty }

    init(item: MenuItem, onSave: @escaping (MenuItem) -> Void) {
        self.item = item
        self.onSave = onSave
        _name        = State(initialValue: item.name)
        _price       = State(initialValue: item.price.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: "₹", with: "").trimmingCharacters(in: .whitespaces))
        _description = State(initialValue: item.description)
        _category    = State(initialValue: item.category)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#F9F6F5").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Color.clear.frame(height: 8)

                    // Main info card
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DISH NAME")
                                .font(.custom("Manrope", size: 10)).fontWeight(.bold)
                                .tracking(2).foregroundColor(Color(hex: "#4B5D70"))
                            TextField("Dish name", text: $name)
                                .font(.custom("Plus Jakarta Sans", size: 17)).fontWeight(.bold)
                                .foregroundColor(Color(hex: "#2F2E2E"))
                                .padding(16)
                                .background(Color(hex: "#FFFFFF"))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("PRICE")
                                    .font(.custom("Manrope", size: 10)).fontWeight(.bold)
                                    .tracking(2).foregroundColor(Color(hex: "#4B5D70"))
                                HStack(spacing: 6) {
                                    Text("₹")
                                        .font(.custom("Plus Jakarta Sans", size: 16)).fontWeight(.bold)
                                        .foregroundColor(Color(hex: "#A93000"))
                                    TextField("0.00", text: $price)
                                        .font(.custom("Plus Jakarta Sans", size: 17)).fontWeight(.bold)
                                        .foregroundColor(Color(hex: "#2F2E2E"))
                                        .keyboardType(.decimalPad)
                                }
                                .padding(16)
                                .background(Color(hex: "#FFFFFF"))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }.frame(maxWidth: .infinity)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("CATEGORY")
                                    .font(.custom("Manrope", size: 10)).fontWeight(.bold)
                                    .tracking(2).foregroundColor(Color(hex: "#4B5D70"))
                                Menu {
                                    ForEach(categories, id: \.self) { cat in
                                        Button(cat) { Analytics.tap("edit_dish", "category_selected", ["category": cat]); category = cat }
                                    }
                                } label: {
                                    HStack {
                                        Text(category)
                                            .font(.custom("Manrope", size: 14)).fontWeight(.semibold)
                                            .foregroundColor(Color(hex: "#2F2E2E"))
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Color(hex: "#787676"))
                                    }
                                    .padding(16)
                                    .background(Color(hex: "#FFFFFF"))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }.frame(maxWidth: .infinity)
                        }
                    }
                    .padding(20)
                    .background(Color(hex: "#F3F0EF"))
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DESCRIPTION")
                            .font(.custom("Manrope", size: 10)).fontWeight(.bold)
                            .tracking(2).foregroundColor(Color(hex: "#4B5D70"))
                            .padding(.horizontal, 4)
                        ZStack(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Describe the dish...")
                                    .font(.custom("Manrope", size: 14))
                                    .foregroundColor(Color(hex: "#AFACAC"))
                                    .padding(16).allowsHitTesting(false)
                            }
                            TextEditor(text: $description)
                                .font(.custom("Manrope", size: 14))
                                .foregroundColor(Color(hex: "#2F2E2E"))
                                .frame(minHeight: 120)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .scrollContentBackground(.hidden)
                        }
                        .background(Color(hex: "#FFFFFF"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)

            // Save button
            Button {
                guard isValid else { return }
                var updated = item
                updated.name = name
                updated.price = "₹\(price)"
                updated.description = description
                updated.category = category
                onSave(updated)
                dismiss()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                    Text("Save Changes")
                        .font(.custom("Plus Jakarta Sans", size: 16)).fontWeight(.bold)
                }
                .foregroundColor(isValid ? Color(hex: "#FFEFEB") : Color(hex: "#787676"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    isValid
                    ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "#A93000"), Color(hex: "#C84010")], startPoint: .leading, endPoint: .trailing))
                    : AnyShapeStyle(Color(hex: "#E5E2E1"))
                )
                .clipShape(Capsule())
                .shadow(color: isValid ? Color(hex: "#A93000").opacity(0.4) : .clear, radius: 16, x: 0, y: 6)
            }
            .disabled(!isValid)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack(spacing: 12) {
                Button { Analytics.tap("edit_dish", "close"); dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white).padding(8)
                }
                Text("Edit Dish")
                    .font(.custom("Plus Jakarta Sans", size: 18)).fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
            }
            .frame(height: 56).padding(.horizontal, 8)
            .background(Color(hex: "#A93000"))
        }
        .navigationBarHidden(true)
        .trackScreen("edit_dish")
    }
}

#Preview { NavigationStack { MenuManagerView().environmentObject(RestaurantStore.shared) } }
