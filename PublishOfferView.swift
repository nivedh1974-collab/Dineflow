import SwiftUI

struct PublishOfferView: View {
    @EnvironmentObject var store: RestaurantStore
    @Environment(\.dismiss) var dismiss

    @State private var offerTitle  = ""
    @State private var details     = ""
    @State private var priceRange  = ""
    @State private var startTime   = Date()
    @State private var endTime     = Date().addingTimeInterval(7200)
    @State private var isBOGO      = false
    @State private var discount    = ""
    @State private var showSuccess = false

    private var discountValue: Int? {
        let t = discount.trimmingCharacters(in: .whitespaces)
        guard let v = Int(t), (1...100).contains(v) else { return nil }
        return v
    }
    private var discountOK: Bool { isBOGO || discountValue != nil }
    private var timeOK: Bool { endTime > startTime && endTime > Date() }
    private var hasRestaurant: Bool { store.merchantRestaurant != nil }

    var validationMessage: String? {
        if offerTitle.trimmingCharacters(in: .whitespaces).isEmpty { return nil }
        if !hasRestaurant { return "Select a restaurant before publishing." }
        if !discountOK { return "Enter a discount between 1 and 100, or turn on BOGO." }
        if !timeOK { return "End time must be after the start time." }
        return nil
    }

    var isFormValid: Bool {
        !offerTitle.trimmingCharacters(in: .whitespaces).isEmpty && hasRestaurant && discountOK && timeOK
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.dfSurface.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s10) {
                    Color.clear.frame(height: 72)

                    VStack(alignment: .leading, spacing: Spacing.s3) {
                        Text("Blast a Live Offer").font(.jakarta(36, weight: .heavy)).foregroundStyle(Color.dfOnSurface)
                        Text("Create urgency. Set a mood. Reach your local audience instantly.")
                            .font(.dfBodyMd).foregroundStyle(Color.dfSecondary)
                    }

                    // Title + details card
                    VStack(spacing: Spacing.s8) {
                        fieldGroup(label: "OFFER TITLE") {
                            TextField("e.g. Midnight Mixology Madness", text: $offerTitle)
                                .font(.jakarta(17, weight: .bold)).foregroundStyle(Color.dfOnSurface)
                                .padding(Spacing.s6).background(Color.dfSurfaceLowest)
                                .overlay(RoundedRectangle(cornerRadius: Radius.lg).stroke(Color.dfOutlineVariant.opacity(0.15), lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                        }
                        fieldGroup(label: "DETAILS") {
                            ZStack(alignment: .topLeading) {
                                if details.isEmpty {
                                    Text("Tell them what's happening right now...")
                                        .font(.dfBodyMd).foregroundStyle(Color.dfOutlineVariant.opacity(0.6))
                                        .padding(.horizontal, Spacing.s6).padding(.top, Spacing.s6)
                                }
                                TextEditor(text: $details)
                                    .font(.dfBodyMd).foregroundStyle(Color.dfOnSurface)
                                    .frame(minHeight: 90).padding(.horizontal, Spacing.s4).padding(.vertical, Spacing.s4)
                                    .scrollContentBackground(.hidden)
                            }
                            .background(Color.dfSurfaceLowest)
                            .overlay(RoundedRectangle(cornerRadius: Radius.lg).stroke(Color.dfOutlineVariant.opacity(0.15), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                        }
                    }
                    .padding(Spacing.s8).background(Color.dfSurfaceLow).clipShape(RoundedRectangle(cornerRadius: Radius.xl))

                    // Price + Upload row
                    HStack(alignment: .top, spacing: Spacing.s4) {
                        VStack(spacing: Spacing.s6) {
                            HStack(spacing: 5) {
                                Image(systemName: "indianrupeesign.circle").font(.caption.weight(.semibold)).foregroundStyle(Color.dfSecondary)
                                Text("PRICE OR PRICE RANGE").font(.dfLabelSm).tracking(1.2).foregroundStyle(Color.dfSecondary)
                            }
                            TextField("e.g. ₹500–750", text: $priceRange)
                                .font(.jakarta(15, weight: .bold)).foregroundStyle(Color.dfOnSurface)
                                .padding(Spacing.s6).background(Color.dfSurfaceLowest)
                                .overlay(RoundedRectangle(cornerRadius: Radius.lg).stroke(Color.dfOutlineVariant.opacity(0.15), lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))

                            // Discount %
                            HStack(spacing: 5) {
                                Image(systemName: "percent").font(.caption.weight(.semibold)).foregroundStyle(Color.dfSecondary)
                                Text("DISCOUNT %").font(.dfLabelSm).tracking(1.2).foregroundStyle(Color.dfSecondary)
                            }
                            TextField("e.g. 30", text: $discount)
                                .font(.jakarta(15, weight: .bold)).foregroundStyle(Color.dfOnSurface)
                                .keyboardType(.numberPad)
                                .padding(Spacing.s6).background(Color.dfSurfaceLowest)
                                .overlay(RoundedRectangle(cornerRadius: Radius.lg).stroke(Color.dfOutlineVariant.opacity(0.15), lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                        }
                        .padding(Spacing.s6).frame(maxWidth: .infinity).background(Color.dfSurfaceLow).clipShape(RoundedRectangle(cornerRadius: Radius.xl))

                        VStack(spacing: 8) {
                            Image(systemName: "camera.badge.plus").font(.title2.weight(.semibold)).foregroundStyle(Color.dfPrimaryContainer)
                            Text("UPLOAD LIVE VIBE").font(.dfLabelSm).tracking(1.2).foregroundStyle(Color.dfSecondary)
                            Text("Coming soon").font(.system(size: 9)).italic().foregroundStyle(Color.dfOutline).multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity).frame(minHeight: 120)
                        .padding(Spacing.s6).background(Color.dfSurfaceLow)
                        .overlay(RoundedRectangle(cornerRadius: Radius.xl).stroke(Color.dfOutlineVariant.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6])))
                        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
                    }

                    // BOGO toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("BOGO OFFER").font(.dfLabelSm).tracking(1.5).foregroundStyle(Color.dfSecondary)
                            Text("Buy one get one free").font(.dfBodyMd).foregroundStyle(Color.dfOnSurface)
                        }
                        Spacer()
                        Toggle("", isOn: $isBOGO).labelsHidden().tint(Color.dfPrimary)
                    }
                    .padding(Spacing.s6).background(Color.dfSurfaceLow).clipShape(RoundedRectangle(cornerRadius: Radius.xl))

                    // Time validity
                    VStack(alignment: .leading, spacing: Spacing.s8) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "clock").font(.caption.weight(.semibold)).foregroundStyle(Color.dfSecondary)
                                Text("TIME VALIDITY").font(.dfLabelSm).tracking(1.5).foregroundStyle(Color.dfSecondary)
                            }
                            Spacer()
                            Text("LIVE NOW").font(.dfLabelSm).tracking(1.2).foregroundStyle(Color.dfPrimary)
                                .padding(.horizontal, 12).padding(.vertical, 5).background(Color.dfPrimary.opacity(0.1)).clipShape(Capsule())
                        }
                        HStack(spacing: Spacing.s6) {
                            timeField(label: "START", time: $startTime)
                            timeField(label: "END",   time: $endTime)
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.s3) {
                                presetChip("Active for 2 Hours") {
                                    Analytics.track("offer_duration_preset_used", ["preset": "2_hours"])
                                    endTime = startTime.addingTimeInterval(2 * 3600)
                                }
                                presetChip("End at Midnight") {
                                    Analytics.track("offer_duration_preset_used", ["preset": "midnight"])
                                    endTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: Date()) ?? Date()
                                }
                                presetChip("Flash Deal (30m)") {
                                    Analytics.track("offer_duration_preset_used", ["preset": "flash_30m"])
                                    endTime = startTime.addingTimeInterval(30 * 60)
                                }
                            }
                        }
                    }
                    .padding(Spacing.s8).background(Color.dfSurfaceLow).clipShape(RoundedRectangle(cornerRadius: Radius.xl))

                    // Publish CTA
                    GradientButton(title: "Publish Now", icon: nil) {
                        guard isFormValid else { return }
                        let discountInt = discountValue ?? 0
                        let offer = Offer(
                            id: UUID(),
                            title: offerTitle,
                            description: details,
                            discountPercent: discountInt,
                            endsAt: endTime,
                            isBOGO: isBOGO,
                            restaurantId: store.merchantRestaurant?.id ?? UUID()
                        )
                        store.publishOffer(offer)
                        Analytics.track("offer_published", [
                            "is_bogo": isBOGO,
                            "discount_percent": discountInt,
                            "has_details": !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                            "has_price": !priceRange.trimmingCharacters(in: .whitespaces).isEmpty,
                            "city": store.merchantRestaurant?.city ?? "unknown"
                        ])
                        withAnimation { showSuccess = true }
                    }
                    .opacity(isFormValid ? 1 : 0.5).disabled(!isFormValid)

                    if let msg = validationMessage {
                        Text(msg).font(.manrope(12, weight: .semibold)).foregroundStyle(Color(hex: "#C0392B"))
                    }

                    Button { dismiss() } label: {
                        HStack(spacing: Spacing.s3) {
                            Image(systemName: "fork.knife").font(.body.weight(.semibold))
                            Text("View your restaurant page").font(.manrope(14, weight: .bold))
                        }
                        .foregroundStyle(Color.dfSecondary).frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color.dfSurfaceLow)
                        .overlay(Capsule().stroke(Color.dfSecondary.opacity(0.2), lineWidth: 1.5))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, Spacing.s6)
            }
            .scrollIndicators(.hidden)

            // Top bar
            HStack {
                Button {
                    if !showSuccess {
                        Analytics.track("publish_offer_abandoned", [
                            "had_title": isFormValid,
                            "had_details": !details.isEmpty
                        ])
                    }
                    dismiss()
                } label: {
                    Image(systemName: "xmark").font(.body.weight(.semibold)).foregroundStyle(Color.dfSecondary)
                        .padding(10).background(Color.dfSurfaceLow).clipShape(Circle())
                }.buttonStyle(.plain)
                Spacer()
                Text("Dineflow").font(.jakartaItalic(22)).foregroundStyle(Color.dfPrimary)
                Spacer()
                Circle().fill(Color.dfSurfaceHigh).frame(width: 40, height: 40)
                    .overlay(Image(systemName: "person.fill").font(.body).foregroundStyle(Color.dfSecondary))
            }
            .padding(.horizontal, Spacing.s6).padding(.vertical, Spacing.s5).background(.ultraThinMaterial)

            if showSuccess { successOverlay }
        }
        .navigationBarHidden(true)
        .onAppear {
            Analytics.track("publish_offer_started")
        }
        .onChange(of: offerTitle) { oldValue, newValue in
            if oldValue.isEmpty && !newValue.isEmpty {
                Analytics.track("offer_title_entered")
            }
        }
    }

    @ViewBuilder
    private func fieldGroup<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.dfLabelSm).tracking(1.5).foregroundStyle(Color.dfSecondary)
            content()
        }
    }

    private func timeField(label: String, time: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.dfLabelSm).tracking(1.5).foregroundStyle(Color.dfOutline)
            DatePicker("", selection: time, displayedComponents: .hourAndMinute).labelsHidden().tint(Color.dfPrimary)
                .padding(Spacing.s4).background(Color.dfSurfaceLowest)
                .overlay(RoundedRectangle(cornerRadius: Radius.lg).stroke(Color.dfOutlineVariant.opacity(0.15), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        }
        .frame(maxWidth: .infinity)
    }

    private func presetChip(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.dfLabelMd).foregroundStyle(Color.dfOnSurface)
                .padding(.horizontal, 14).padding(.vertical, 9).background(Color.dfSurfaceHighest.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        }.buttonStyle(ScaleButtonStyle())
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: Spacing.s8) {
                ZStack {
                    Circle().fill(Color.dfPrimaryContainer.opacity(0.2)).frame(width: 100, height: 100)
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 56)).foregroundStyle(Color.dfPrimary)
                }
                VStack(spacing: Spacing.s4) {
                    Text("Offer Published!").font(.dfHeadlineMd).foregroundStyle(Color.dfOnSurface)
                    Text("Your live offer is now visible to nearby diners.")
                        .font(.dfBodyMd).foregroundStyle(Color.dfOnSurfaceVariant).multilineTextAlignment(.center)
                }
                GradientButton(title: "Done") { dismiss() }
            }
            .padding(Spacing.s10).background(Color.dfSurface).clipShape(RoundedRectangle(cornerRadius: Radius.xl))
            .padding(.horizontal, Spacing.s10)
        }
        .transition(.opacity)
    }
}

#Preview { NavigationStack { PublishOfferView().environmentObject(RestaurantStore.shared) } }
