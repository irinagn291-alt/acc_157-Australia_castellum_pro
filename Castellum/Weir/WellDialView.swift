import SwiftUI
import UIKit

/// Role: Presentation. Dial — communicating vessels. Views call the store; they never assign the ADT.
struct WellDialView: View {
    var store: WeirStore
    @State private var pouring = false
    @State private var refusal: String?
    @State private var showSumpLeaf = false
    @State private var showCrest = false
    @State private var crestFlash: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(store: WeirStore = WeirStore.previewPopulated()) {
        self.store = store
    }

    var body: some View {
        Group {
            if store.mark == nil {
                vacant
            } else if isRegular {
                wellStack(flexible: true)
            } else {
                ViewThatFits(in: .vertical) {
                    wellStack(flexible: true)
                    ScrollView {
                        wellStack(flexible: false)
                    }
                }
            }
        }
        .background(CisternInk.background.ignoresSafeArea())
        .fullScreenCover(isPresented: $showSumpLeaf) {
            SweatSumpView(store: store)
        }
        .onDisappear { crestFlash?.cancel() }
    }

    private var vacant: some View {
        CisternVacant(
            image: "ctm_EmptyHome",
            title: "The well is dry",
            line: "The day just started. First pour fills the sump.",
            actionTitle: "Plant a quiet mark"
        ) {
            try? store.plant(.outset)
        }
    }

    private func wellStack(flexible: Bool) -> some View {
        VStack(spacing: CisternInk.space(1)) {
            header
            if let warning = store.warning {
                CisternFault(message: WeirVoice.warning(warning)) {
                    Task { await store.load() }
                }
            } else if let write = store.lastWriteError {
                CisternFault(message: write) {
                    Task { await store.flush() }
                }
            }
            if isRegular {
                HStack(alignment: .center, spacing: CisternInk.space(2)) {
                    vesselWell
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    VStack(alignment: .leading, spacing: CisternInk.space(2)) {
                        figures
                        twistLip
                        refusalLine
                        pourLip
                    }
                    .frame(width: 300)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                figures
                vesselWell
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(minHeight: CisternInk.space(28))
                twistLip
                refusalLine
                pourLip
            }
        }
        .padding(CisternInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: flexible ? .infinity : nil)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: CisternInk.space(1)) {
            HStack(alignment: .firstTextBaseline, spacing: CisternInk.space(1)) {
                Text("Fill the sump")
                    .cisternText(.mark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: CisternInk.space(1))
                Text(WeirVoice.hatch(store.vessels.weir))
                    .cisternText(.stamp)
                    .foregroundStyle(CisternInk.muted)
                    .frame(minHeight: CisternInk.tap)
            }
            HStack(spacing: CisternInk.space(1)) {
                Text(WeirVoice.weir(store.vessels.weir))
                    .cisternText(.caption)
                    .foregroundStyle(CisternInk.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: CisternInk.space(1))
                Text("Crest the weir")
                    .cisternText(.stamp)
                    .foregroundStyle(CisternInk.muted)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var isRegular: Bool { horizontalSizeClass == .regular }

    private var vesselWell: some View {
        ZStack {
            VesselWellHost(
                vessels: store.vessels,
                mark: store.mark,
                reduceMotion: reduceMotion,
                onPour: crest
            )
            if showCrest, UIImage(named: "ctm_SuccessMark") != nil {
                Image("ctm_SuccessMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: CisternInk.space(8), height: CisternInk.space(8))
                    .accessibilityHidden(true)
                    .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private var figures: some View {
        let tiles = Group {
            figure(
                title: "Sump left",
                value: CisternFormat.millilitres(store.vessels.sump.remainingMillilitres)
            )
            figure(
                title: "Bowl",
                value: CisternFormat.millilitres(store.vessels.bowl.millilitres)
            )
            figure(
                title: "Mark",
                value: CisternFormat.millilitres(store.mark?.goalMillilitres ?? 0)
            )
        }
        if isRegular {
            VStack(alignment: .leading, spacing: CisternInk.space(1)) { tiles }
        } else {
            HStack(alignment: .top, spacing: CisternInk.space(1)) { tiles }
        }
    }

    private var refusalLine: some View {
        Group {
            if let refusal {
                Text(refusal)
                    .cisternText(.caption)
                    .foregroundStyle(CisternInk.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var pourLip: some View {
        WeirLipButton(
            title: "Pour " + CisternFormat.millilitres(PourVolume.crestMillilitres),
            enabled: !pouring
        ) {
            crest()
        }
    }

    private func figure(title: String, value: String) -> some View {
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

    private var twistLip: some View {
        Button {
            showSumpLeaf = true
        } label: {
            HStack(spacing: CisternInk.space(1)) {
                Text("Sweat sump")
                    .cisternText(.body)
                Spacer(minLength: CisternInk.space(1))
                Text(CisternFormat.millilitres(store.mark?.sumpTarget ?? 0))
                    .cisternText(.caption)
                    .lineLimit(1)
                Text(store.vessels.weir == .openSump ? "Open" : "Dry")
                    .cisternText(.stamp)
                    .foregroundStyle(CisternInk.muted)
                    .frame(minHeight: CisternInk.tap)
            }
            .padding(.horizontal, CisternInk.space(2))
            .frame(maxWidth: .infinity, minHeight: CisternInk.tap, alignment: .leading)
            .background(CisternInk.surface)
            .overlay(Rectangle().stroke(CisternInk.accent, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open the sweat-sump weir")
    }

    private func crest() {
        guard !pouring else { return }
        pouring = true
        do {
            try store.crestPour()
            refusal = nil
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            flashCrest()
        } catch let error as WeirRefusal {
            refusal = WeirVoice.refusal(error)
        } catch {
            refusal = String(describing: error)
        }
        pouring = false
    }

    private func flashCrest() {
        crestFlash?.cancel()
        showCrest = true
        guard !reduceMotion else { return }
        crestFlash = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            showCrest = false
        }
    }
}
