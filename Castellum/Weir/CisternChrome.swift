import SwiftUI
import UIKit

/// Role: Presentation. Full-width weir lip. Chrome lives inside the label.
struct WeirLipButton: View {
    var title: String
    var enabled: Bool = true
    var face: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: CisternInk.space(1)) {
                if let face, UIImage(named: face) != nil {
                    Image(face)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(CisternInk.font(.body))
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(CisternInk.background)
            .frame(maxWidth: .infinity, minHeight: CisternInk.tap)
            .background(enabled ? CisternInk.accent : CisternInk.muted)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(CisternInk.ink)
                    .frame(height: 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityAddTraits(.isButton)
    }
}

/// Role: Presentation. Full-page vacant well. CTA sits on the floor, not in a Spacer crumb.
struct CisternVacant: View {
    var image: String
    var title: String
    var line: String
    var actionTitle: String
    var action: () -> Void

    var body: some View {
        VStack(spacing: CisternInk.space(2)) {
            if UIImage(named: image) != nil {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 240, maxHeight: 240)
                    .accessibilityHidden(true)
            }
            Text(title)
                .cisternText(.mark)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text(line)
                .cisternText(.body)
                .foregroundStyle(CisternInk.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Spacer(minLength: CisternInk.space(2))
            WeirLipButton(title: actionTitle, action: action)
        }
        .padding(CisternInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CisternInk.background.ignoresSafeArea())
    }
}

/// Role: Presentation. Fault slab with a retry lip. States what failed.
struct CisternFault: View {
    var message: String
    var retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: CisternInk.space(1)) {
            Text(message)
                .cisternText(.body)
                .fixedSize(horizontal: false, vertical: true)
            WeirLipButton(title: "Retry the cistern", action: retry)
        }
        .padding(CisternInk.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CisternInk.surface)
        .overlay(Rectangle().stroke(CisternInk.ink, lineWidth: 1))
    }
}
