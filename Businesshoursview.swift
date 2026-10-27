import SwiftUI

struct DaySchedule: Identifiable {
    let id = UUID()
    let name: String
    var isOpen: Bool
    var openTime: Date
    var closeTime: Date
}

struct BusinessHoursView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: RestaurantStore

    @State private var days: [DaySchedule] = {
        let cal = Calendar.current
        func time(_ h: Int, _ m: Int) -> Date {
            cal.date(bySettingHour: h, minute: m, second: 0, of: Date())!
        }
        return [
            DaySchedule(name: "Monday",    isOpen: true, openTime: time(9,0),  closeTime: time(22,0)),
            DaySchedule(name: "Tuesday",   isOpen: true, openTime: time(9,0),  closeTime: time(22,0)),
            DaySchedule(name: "Wednesday", isOpen: true, openTime: time(9,0),  closeTime: time(22,0)),
            DaySchedule(name: "Thursday",  isOpen: true, openTime: time(9,0),  closeTime: time(22,0)),
            DaySchedule(name: "Friday",    isOpen: true, openTime: time(10,0), closeTime: time(23,0)),
            DaySchedule(name: "Saturday",  isOpen: true, openTime: time(11,0), closeTime: time(0,0)),
            DaySchedule(name: "Sunday",    isOpen: true, openTime: time(10,0), closeTime: time(20,0)),
        ]
    }()

    private static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "hh:mm a"
        return f
    }()

    private func loadFromStore() {
        let saved = store.hoursForMerchant()
        guard saved.count == days.count else { return }
        for i in days.indices {
            days[i].isOpen = saved[i].isOpen
            days[i].openTime = saved[i].openDate
            days[i].closeTime = saved[i].closeDate
        }
    }

    private func saveToStore() {
        let out = days.map { d in
            DayHours(day: d.name, isOpen: d.isOpen,
                     openTime: Self.fmt.string(from: d.openTime),
                     closeTime: Self.fmt.string(from: d.closeTime),
                     openDate: d.openTime, closeDate: d.closeTime)
        }
        store.updateBusinessHours(out)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#F2EFE9").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Back button
                    Button(action: { Analytics.tap("business_hours", "back"); dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "#C0392B"))
                    }
                    .padding(.bottom, 20)

                    // Title
                    Text("Business hours")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.black)
                    Text("set your weekly operating time")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#888888"))
                        .padding(.top, 4)
                        .padding(.bottom, 24)

                    // Day cards
                    VStack(spacing: 14) {
                        ForEach($days) { $day in
                            DayCard(day: $day)
                        }
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }

            // Save button
            VStack(spacing: 8) {
                Button(action: {
                    Analytics.track("business_hours_saved", ["open_days": days.filter { $0.isOpen }.count, "closed_days": days.filter { !$0.isOpen }.count])
                    saveToStore()
                    dismiss()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Save Changes")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(hex: "#C0392B"))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 20)

                Text("CHANGES TAKE EFFECT IMMEDIATELY")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "#999999"))
                    .kerning(1.0)
                    .padding(.bottom, 12)
            }
            .background(Color(hex: "#F2EFE9"))
        }
        .navigationBarHidden(true)
        .trackScreen("business_hours")
        .onAppear { loadFromStore() }
    }
}

struct DayCard: View {
    @Binding var day: DaySchedule

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day name + toggle
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(day.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    Text(day.isOpen ? "OPEN FOR BUSINESS" : "CLOSED")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(day.isOpen ? Color(hex: "#C0392B") : Color(hex: "#999999"))
                        .kerning(0.5)
                }
                Spacer()
                Toggle("", isOn: $day.isOpen)
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#C0392B")))
                    .labelsHidden()
                    .onChange(of: day.isOpen) { _, open in
                        Analytics.tap("business_hours", "day_toggle", ["day": day.name, "open": open])
                    }
            }

            if day.isOpen {
                HStack(spacing: 12) {
                    TimePickerField(label: "OPENING TIME", time: $day.openTime)
                    TimePickerField(label: "CLOSING TIME", time: $day.closeTime)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: day.isOpen)
    }
}

struct TimePickerField: View {
    let label: String
    @Binding var time: Date
    @State private var showPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(hex: "#999999"))
                .kerning(0.8)

            Button(action: { Analytics.tap("business_hours", "time_picker_open", ["field": label]); showPicker = true }) {
                HStack(spacing: 8) {
                    Text(time.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black)
                    Spacer()
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#888888"))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(hex: "#F2EFE9"))
                .cornerRadius(10)
            }
            .sheet(isPresented: $showPicker) {
                VStack {
                    DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                    Button("Done") { Analytics.tap("business_hours", "time_picker_done", ["field": label]); showPicker = false }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#C0392B"))
                        .padding(.bottom, 20)
                }
                .presentationDetents([.height(280)])
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    BusinessHoursView().environmentObject(RestaurantStore.shared)
}
