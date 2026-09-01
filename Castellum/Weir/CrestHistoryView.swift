import SwiftUI

/// Role: Presentation. Days the weir overflowed into the bowl. Views only read the store.
struct CrestHistoryView: View {
    var store: WeirStore
    var openWell: () -> Void
    @State private var openedKey: DayKey?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(store: WeirStore = WeirStore.previewPopulated(), openWell: @escaping () -> Void = {}) {
        self.store = store
        self.openWell = openWell
    }

    var body: some View {
        Group {
            if let write = store.lastWriteError, store.crestRuns.isEmpty {
                fault(write)
            } else if store.crestRuns.isEmpty {
                vacant
            } else {
                board
            }
        }
        .background(CisternInk.background.ignoresSafeArea())
        .onAppear { openFirst() }
        .onChange(of: store.crestRuns) { _, _ in openFirst() }
    }

    private var vacant: some View {
        CisternVacant(
            image: "ctm_EmptyList",
            title: "Days the weir overflowed",
            line: "A crest day is counted when the weir overflows into the bowl.",
            actionTitle: pourTitle,
            action: openWell
        )
    }

    private func fault(_ write: String) -> some View {
        VStack(alignment: .leading, spacing: CisternInk.space(2)) {
            CisternFault(message: write) {
                Task { await store.flush() }
            }
            WeirLipButton(title: pourTitle, action: openWell)
        }
        .padding(CisternInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var board: some View {
        VStack(alignment: .leading, spacing: CisternInk.space(2)) {
            header
            if let write = store.lastWriteError {
                CisternFault(message: write) {
                    Task { await store.flush() }
                }
            }
            if isRegular {
                regularBoard
            } else {
                compactBoard
            }
            WeirLipButton(title: pourTitle, action: openWell)
        }
        .padding(CisternInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: CisternInk.space(1)) {
            Text("Days the weir overflowed")
                .cisternText(.house)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text("Tap a day, or pour again on the well.")
                .cisternText(.caption)
                .foregroundStyle(CisternInk.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var compactBoard: some View {
        VStack(alignment: .leading, spacing: CisternInk.space(2)) {
            if let run = openedRun {
                overflowWell(run)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                openedFigures(run)
            }
            dayStrip
        }
    }

    private var regularBoard: some View {
        HStack(alignment: .top, spacing: CisternInk.space(2)) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: CisternInk.space(1)) {
                    ForEach(store.crestRuns) { run in
                        dayLip(run, axis: .horizontal)
                    }
                }
            }
            .contentMargins(.bottom, CisternInk.space(1))
            .frame(maxWidth: 300)
            .frame(maxHeight: .infinity)
            if let run = openedRun {
                VStack(alignment: .leading, spacing: CisternInk.space(2)) {
                    overflowWell(run)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    openedFigures(run)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var dayStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: CisternInk.space(1)) {
                ForEach(store.crestRuns) { run in
                    dayLip(run, axis: .vertical)
                }
            }
        }
        .contentMargins(.bottom, CisternInk.space(1))
    }

    private func dayLip(_ run: CrestRun, axis: Axis) -> some View {
        let opened = run.dayKey == openedRun?.dayKey
        return Button {
            openedKey = run.dayKey
        } label: {
            Group {
                if axis == .vertical {
                    VStack(alignment: .leading, spacing: CisternInk.space(1)) {
                        overflowBar(run)
                            .frame(width: 72, height: 72)
                        Text(CisternFormat.day(run.dayKey))
                            .cisternText(.stamp)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                        Text(run.didHit ? "Mark reached" : "Crested")
                            .cisternText(.stamp)
                            .foregroundStyle(CisternInk.muted)
                            .lineLimit(1)
                    }
                    .padding(CisternInk.space(1))
                    .frame(width: 104, alignment: .topLeading)
                    .frame(minHeight: CisternInk.tap)
                } else {
                    HStack(alignment: .center, spacing: CisternInk.space(1)) {
                        overflowBar(run)
                            .frame(width: 44, height: 56)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(CisternFormat.day(run.dayKey))
                                .cisternText(.body)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text(run.didHit ? "Mark reached" : "Crested into the bowl")
                                .cisternText(.stamp)
                                .foregroundStyle(CisternInk.muted)
                                .lineLimit(2)
                        }
                        Spacer(minLength: CisternInk.space(1))
                        Text(CisternFormat.millilitres(run.bowlMillilitres))
                            .cisternText(.figure)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .padding(.horizontal, CisternInk.space(2))
                    .padding(.vertical, CisternInk.space(1))
                    .frame(maxWidth: .infinity, minHeight: CisternInk.tap, alignment: .leading)
                }
            }
            .background(CisternInk.surface)
            .overlay(Rectangle().stroke(opened ? CisternInk.accent : CisternInk.ink, lineWidth: opened ? 2 : 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(dayVoice(run))
        .accessibilityAddTraits(opened ? .isSelected : [])
    }

    private func overflowWell(_ run: CrestRun) -> some View {
        VesselWellHost(
            vessels: vessels(for: run),
            mark: store.mark,
            reduceMotion: reduceMotion,
            onPour: openWell
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(Rectangle().stroke(CisternInk.ink, lineWidth: 1))
        .accessibilityLabel(dayVoice(run))
    }

    private func openedFigures(_ run: CrestRun) -> some View {
        HStack(alignment: .top, spacing: CisternInk.space(1)) {
            figure(title: "Bowl", value: CisternFormat.millilitres(run.bowlMillilitres))
            figure(title: "Day", value: CisternFormat.day(run.dayKey))
            figure(
                title: run.didHit ? "Mark reached" : "Crested",
                value: CisternFormat.millilitres(store.mark?.bowlTarget ?? run.bowlMillilitres)
            )
        }
    }

    private func figure(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .cisternText(.stamp)
                .foregroundStyle(CisternInk.muted)
                .lineLimit(1)
            Text(value)
                .cisternText(.body)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: CisternInk.tap, alignment: .leading)
        .padding(CisternInk.space(1))
        .background(CisternInk.surface)
    }

    private func overflowBar(_ run: CrestRun) -> some View {
        GeometryReader { geo in
            let water = geo.size.height * bowlFraction(run)
            ZStack(alignment: .bottom) {
                CisternInk.background
                CisternInk.accent
                    .frame(height: max(4, water))
                Rectangle()
                    .stroke(CisternInk.ink, lineWidth: 1)
            }
        }
        .accessibilityHidden(true)
    }

    private var openedRun: CrestRun? {
        store.crestRuns.first { $0.dayKey == openedKey } ?? store.crestRuns.first
    }

    private var isRegular: Bool { horizontalSizeClass == .regular }

    private var pourTitle: String {
        "Pour " + CisternFormat.millilitres(PourVolume.crestMillilitres) + " on the well"
    }

    private func dayVoice(_ run: CrestRun) -> String {
        CisternFormat.day(run.dayKey)
            + ", "
            + CisternFormat.millilitres(run.bowlMillilitres)
            + (run.didHit ? ", mark reached" : ", crested into the bowl")
    }

    private func vessels(for run: CrestRun) -> WeirVessels {
        let mark = store.mark ?? .outset
        return WeirVessels(
            sump: SumpChamber(depthMillilitres: mark.sumpTarget, remainingMillilitres: 0),
            bowl: BodyBowl(millilitres: run.bowlMillilitres),
            weir: run.didHit ? .full : .cresting
        )
    }

    private func bowlFraction(_ run: CrestRun) -> CGFloat {
        if run.didHit { return 1 }
        let target = max(store.mark?.bowlTarget ?? 1, run.bowlMillilitres, 1)
        return min(0.92, max(0.12, CGFloat(run.bowlMillilitres) / CGFloat(target)))
    }

    private func openFirst() {
        if openedKey == nil {
            openedKey = store.crestRuns.first?.dayKey
        }
    }
}
