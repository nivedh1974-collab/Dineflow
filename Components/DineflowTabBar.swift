import SwiftUI

struct DineflowTabBar: View {
    @Binding var selectedTab: Int

    private let items: [(icon: String, label: String)] = [
        ("house.fill",      "Home"),
        ("magnifyingglass", "Search"),
        ("mappin.and.ellipse", "Location"),
        ("person.fill",     "Profile"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<items.count, id: \.self) { i in
                Button {
                    Analytics.tap("tab_bar", items[i].label, ["reselect": selectedTab == i])
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = i
                    }
                } label: {
                    tabItem(index: i)
                }
                .buttonStyle(ScaleButtonStyle())
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.top, Spacing.s4)
        .padding(.bottom, 28)
        .background(
            RoundedRectangle(cornerRadius: Radius.xl)
                .fill(.regularMaterial)
                .shadow(color: Color.dfOnSurface.opacity(0.06), radius: 24, x: 0, y: -6)
        )
        .padding(.horizontal, Spacing.s6)
    }

    @ViewBuilder
    private func tabItem(index: Int) -> some View {
        let isSelected = selectedTab == index
        VStack(spacing: 3) {
            Image(systemName: items[index].icon)
                .font(.system(size: 18, weight: .semibold))
            Text(items[index].label)
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .textCase(.uppercase)
                .fixedSize()
                .lineLimit(1)
        }
        .foregroundStyle(isSelected ? Color.white : Color.dfSecondary)
        .padding(.vertical, 9)
        .padding(.horizontal, 14)
        .background(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: Radius.xl)
                        .fill(LinearGradient.primaryGradient)
                }
            }
        )
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Color.dfSurface.ignoresSafeArea()
        DineflowTabBar(selectedTab: .constant(0))
    }
}
