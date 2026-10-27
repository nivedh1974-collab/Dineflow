import SwiftUI

struct FilterChip: View {
    var label: String
    var icon: String? = nil
    var isActive: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            Analytics.tap("filter_chip", label)
            action?()
        } label: {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption.weight(.semibold))
                }
                Text(label.uppercased())
                    .font(.dfLabelSm)
                    .tracking(1.2)
            }
            .foregroundStyle(isActive ? Color.dfOnSecondary : Color.dfOnSurfaceVariant)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(isActive ? Color.dfSecondary : Color.dfSurfaceHigh)
            .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    HStack {
        FilterChip(label: "Italian", isActive: true)
        FilterChip(label: "Sort", icon: "arrow.up.arrow.down", isActive: false)
        FilterChip(label: "Filter", icon: "slider.horizontal.3")
    }
    .padding()
    .background(Color.dfSurface)
}
