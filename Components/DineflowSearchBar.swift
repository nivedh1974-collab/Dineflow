import SwiftUI

struct DineflowSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search restaurants, cuisines..."

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.s4) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.semibold))
                .foregroundStyle(isFocused ? Color.dfPrimary : Color.dfOutline)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            TextField(placeholder, text: $text)
                .font(.dfBodyMd)
                .foregroundStyle(Color.dfOnSurface)
                .focused($isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !text.isEmpty {
                Button {
                    Analytics.tap("search_bar", "clear_text")
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.dfOutline)
                        .font(.body)
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, Spacing.s6)
        .padding(.vertical, 14)
        .background(Color.dfSurfaceLowest)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.xl)
                .stroke(
                    isFocused ? Color.dfPrimary : Color.dfOutlineVariant.opacity(0.4),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    VStack {
        DineflowSearchBar(text: .constant(""))
        DineflowSearchBar(text: .constant("Bistro"))
    }
    .padding()
    .background(Color.dfSurface)
}
