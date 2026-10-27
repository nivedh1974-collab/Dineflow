import SwiftUI

struct PulseDot: View {
    var color: Color = .white
    var size: CGFloat = 8

    @State private var pulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.35))
                .frame(width: size * 2, height: size * 2)
                .scaleEffect(pulsing ? 1.6 : 1.0)
                .opacity(pulsing ? 0 : 0.7)
            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.1).repeatForever(autoreverses: false)) {
                pulsing = true
            }
        }
    }
}

struct LiveBadge: View {
    var label: String = "Live Deal"

    var body: some View {
        HStack(spacing: 6) {
            PulseDot(color: .white, size: 6)
            Text(label.uppercased())
                .font(.dfLabelSm)
                .tracking(1.5)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.dfPrimary.opacity(0.9))
        .clipShape(Capsule())
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 20) {
            PulseDot()
            LiveBadge()
        }
    }
}
