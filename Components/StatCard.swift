import SwiftUI

struct StatCard: View {
    var label: String
    var value: String
    var icon: String
    var isPrimary: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label.uppercased())
                .font(.dfLabelSm)
                .tracking(1.5)
                .foregroundStyle(isPrimary ? Color.dfOnPrimary.opacity(0.8) : Color.dfSecondary)

            Spacer()

            HStack(alignment: .bottom) {
                Text(value)
                    .font(.dfDisplayLg)
                    .foregroundStyle(isPrimary ? Color.dfOnPrimary : Color.dfOnSurface)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Spacer()
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(isPrimary ? Color.dfOnPrimary : Color.dfPrimary)
            }
        }
        .padding(Spacing.s10)
        .frame(height: 160)
        .background(
            Group {
                if isPrimary {
                    LinearGradient.primaryGradient
                } else {
                    Color.dfSurfaceLowest
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
        .cardShadow()
    }
}

#Preview {
    VStack(spacing: 12) {
        StatCard(label: "Total Views", value: "1,284", icon: "eye.fill", isPrimary: true)
        StatCard(label: "Active Offers", value: "3", icon: "tag.fill")
    }
    .padding()
    .background(Color.dfSurface)
}
