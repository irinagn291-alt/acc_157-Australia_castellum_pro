import SwiftUI
import UIKit

/// Role: Presentation. Twist leaf — sweat-sump weir. Home already shows the lower chamber.
struct SweatSumpView: View {
    var store: WeirStore
    @Environment(\.dismiss) private var dismiss

    init(store: WeirStore = WeirStore.previewPopulated()) {
        self.store = store
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CisternInk.space(2)) {
            HStack(spacing: CisternInk.space(1)) {
                Text("Sweat-sump weir")
                    .cisternText(.mark)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: CisternInk.space(1))
                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .cisternText(.body)
                        .padding(.horizontal, CisternInk.space(2))
                        .frame(minWidth: CisternInk.tap, minHeight: CisternInk.tap)
                        .overlay(Rectangle().stroke(CisternInk.ink, lineWidth: 1))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            if UIImage(named: "ctm_TwistHero") != nil {
                Image("ctm_TwistHero")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 280)
                    .accessibilityHidden(true)
            }
            Text("Activity writes a lower chamber of 0, 350, or 700 ml. A pour fills that sump first. Only overflow crests into the body bowl.")
                .cisternText(.body)
            HStack(alignment: .top, spacing: CisternInk.space(1)) {
                slab(title: "Sump left", value: CisternFormat.millilitres(store.vessels.sump.remainingMillilitres))
                slab(title: "Sump depth", value: CisternFormat.millilitres(store.mark?.sumpTarget ?? 0))
                slab(title: "Bowl", value: CisternFormat.millilitres(store.vessels.bowl.millilitres))
            }
            Text(WeirVoice.weir(store.vessels.weir))
                .cisternText(.figure)
            Text(WeirVoice.hatch(store.vessels.weir))
                .cisternText(.caption)
                .padding(.horizontal, CisternInk.space(1))
                .frame(minHeight: CisternInk.tap)
                .overlay(Rectangle().stroke(CisternInk.ink, lineWidth: 1))
            }
            .padding(CisternInk.space(2))
            .frame(maxWidth: 560, alignment: .leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .contentMargins(.bottom, CisternInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CisternInk.background.ignoresSafeArea())
    }

    private func slab(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .cisternText(.stamp)
                .foregroundStyle(CisternInk.muted)
                .lineLimit(1)
            Text(value)
                .cisternText(.figure)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(CisternInk.space(1))
        .background(CisternInk.surface)
    }
}
