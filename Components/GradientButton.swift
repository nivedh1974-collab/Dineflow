import SwiftUI

struct GradientButton: View {
    var title: String
    var icon: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: { Analytics.tap("gradient_button", title); action() }) {
            HStack(spacing: Spacing.s3) {
                if let icon {
                    Image(systemName: icon)
                        .font(.body.weight(.bold))
                }
                Text(title)
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
}

#Preview {
    VStack {
        GradientButton(title: "Enable Location", icon: "location.fill") {}
        GradientButton(title: "Apply Filters") {}
    }
    .padding()
    .background(Color.dfSurface)
}
