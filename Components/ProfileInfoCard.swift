import SwiftUI

struct ProfileInfoCard: View {
    var icon: String
    var label: String
    var value: String

    var body: some View {
        HStack(spacing: Spacing.s6) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.dfSurfaceLow)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.dfPrimary)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(label.uppercased())
                    .font(.dfLabelSm)
                    .tracking(1.5)
                    .foregroundStyle(Color.dfOutline)
                Text(value)
                    .font(.dfBodyMd)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.dfOnSurface)
            }
            Spacer()
        }
        .padding(Spacing.s10)
        .background(Color.dfSurfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
        .cardShadow()
    }
}

#Preview {
    VStack(spacing: 12) {
        ProfileInfoCard(icon: "envelope", label: "Email Address", value: "user@example.com")
        ProfileInfoCard(icon: "iphone", label: "Phone", value: "+1 234 567 8901")
    }
    .padding()
    .background(Color.dfSurface)
}
