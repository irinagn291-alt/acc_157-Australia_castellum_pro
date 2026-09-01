import SwiftUI

/// Role: Presentation. Weir-first swipe. Vessels are page one; History and Settings page beside them.
struct WeirHouseView: View {
    var store: WeirStore
    @Binding var page: WeirPage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(store: WeirStore = WeirStore.previewPopulated(), page: Binding<WeirPage> = .constant(.dial)) {
        self.store = store
        self._page = page
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                WellDialView(store: store)
                    .tag(WeirPage.dial)
                CrestHistoryView(store: store) {
                    turn(.dial)
                }
                .tag(WeirPage.history)
                CisternSettingsView(store: store)
                    .tag(WeirPage.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            rail
        }
        .background(CisternInk.background.ignoresSafeArea())
    }

    private var rail: some View {
        HStack(spacing: 0) {
            ForEach(WeirPage.allCases) { item in
                Button {
                    turn(item)
                } label: {
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(page == item ? CisternInk.ink : CisternInk.muted)
                            .frame(width: page == item ? 28 : 10, height: 3)
                        Text(item.rail)
                            .cisternText(.stamp)
                            .foregroundStyle(page == item ? CisternInk.ink : CisternInk.muted)
                    }
                    .frame(maxWidth: .infinity, minHeight: CisternInk.tap)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.rail)
                .accessibilityAddTraits(page == item ? .isSelected : [])
            }
        }
        .padding(.horizontal, CisternInk.space(2))
        .background(CisternInk.background.ignoresSafeArea(edges: .bottom))
    }

    private func turn(_ next: WeirPage) {
        if reduceMotion {
            page = next
        } else {
            withAnimation(CisternInk.motion) { page = next }
        }
    }
}
