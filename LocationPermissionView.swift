import SwiftUI

struct LocationPermissionView: View {
    var onGranted: () -> Void

    @State private var glowPulse = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Illustration
            ZStack {
                Circle()
                    .fill(Color.dfPrimary.opacity(0.08))
                    .frame(width: 200, height: 200)
                    .scaleEffect(glowPulse ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: glowPulse)

                Circle()
                    .fill(Color.dfPrimaryContainer.opacity(0.15))
                    .frame(width: 140, height: 140)

                Image(systemName: "location.fill")
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundStyle(Color.dfPrimary)
            }
            .onAppear { glowPulse = true }

            Spacer().frame(height: Spacing.s12)

            // Copy
            VStack(spacing: Spacing.s4) {
                Text("Find What's Live\nNear You")
                    .font(.dfHeadlineLg)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.dfOnSurface)

                Text("Dineflow uses your location to surface live deals at restaurants nearby — updated in real time.")
                    .font(.dfBodyMd)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.dfOnSurfaceVariant)
                    .padding(.horizontal, Spacing.s12)
            }

            Spacer()

            // CTA stack
            VStack(spacing: Spacing.s4) {
                GradientButton(title: "Enable Location", icon: "location.fill") {
                    onGranted()
                }

                Button("Maybe Later") {
                    Analytics.tap("location_permission", "maybe_later")
                    onGranted()
                }
                .font(.dfBodyMd)
                .foregroundStyle(Color.dfOutline)
            }
            .padding(.horizontal, Spacing.s10)
            .padding(.bottom, 48)
        }
        .background(Color.dfSurface.ignoresSafeArea())
        .trackScreen("location_permission")
    }
}

#Preview {
    LocationPermissionView(onGranted: {})
}
