import SwiftUI

struct DineflowTextField: View {
    var label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.dfLabelSm)
                .tracking(1.5)
                .foregroundStyle(Color.dfOutline)

            TextField(placeholder, text: $text)
                .font(.dfBodyMd)
                .foregroundStyle(Color.dfOnSurface)
                .keyboardType(keyboardType)
                .focused($isFocused)
                .padding(Spacing.s6)
                .background(Color.dfSurfaceLowest)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.lg)
                        .stroke(
                            isFocused ? Color.dfPrimary : Color.dfOutlineVariant.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        DineflowTextField(label: "Restaurant Name", text: .constant("Bistro Moderne"))
        DineflowTextField(label: "Discount %", text: .constant(""), placeholder: "e.g. 30")
    }
    .padding()
    .background(Color.dfSurface)
}
