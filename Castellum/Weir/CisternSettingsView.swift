import SwiftUI

/// Role: Presentation. Weight and band write the mark and sump depth. ReviewScreen goals.
struct CisternSettingsView: View {
    var store: WeirStore
    @State private var weightText = ""
    @State private var band: ActivityBand = .none
    @State private var weightFault: String?
    @State private var confirmReset = false
    @State private var saving = false
    @FocusState private var weightFocused: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(store: WeirStore = WeirStore.previewPopulated()) {
        self.store = store
    }

    var body: some View {
        Group {
            if store.mark == nil, store.lastWriteError == nil {
                vacant
            } else {
                markBoard
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CisternInk.background.ignoresSafeArea())
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { weightFocused = false }
                    .cisternText(.body)
                    .frame(minHeight: CisternInk.tap)
            }
        }
        .onAppear { pullMark() }
        .onChange(of: store.mark) { _, _ in pullMark() }
        .scrollDismissesKeyboard(.interactively)
        .confirmationDialog(
            "Empty the cistern and every crest day?",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Reset all data", role: .destructive) {
                Task {
                    saving = true
                    await store.resetAllData()
                    pullMark()
                    saving = false
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var vacant: some View {
        CisternVacant(
            image: "ctm_EmptyHome",
            title: "Write today's mark",
            line: "Weight and an activity band write the mark and the sump depth.",
            actionTitle: "Write a quiet mark"
        ) {
            commit(DayMark.outset)
        }
    }

    private var markBoard: some View {
        Group {
            if isRegular {
                jobStack(flexible: true)
            } else {
                ViewThatFits(in: .vertical) {
                    jobStack(flexible: true)
                    ScrollView {
                        jobStack(flexible: false)
                    }
                }
            }
        }
    }

    private func jobStack(flexible: Bool) -> some View {
        VStack(alignment: .leading, spacing: CisternInk.space(2)) {
            header
            if let write = store.lastWriteError {
                CisternFault(message: write) {
                    Task { await store.flush() }
                }
            }
            if let weightFault {
                Text(weightFault)
                    .cisternText(.caption)
                    .foregroundStyle(CisternInk.ink)
            }
            if isRegular {
                HStack(alignment: .top, spacing: CisternInk.space(2)) {
                    VStack(alignment: .leading, spacing: CisternInk.space(2)) {
                        weightField
                        bandColumn
                        WeirLipButton(title: "Write today's mark", enabled: canWrite) {
                            saveMark()
                        }
                        contact
                        HStack(spacing: CisternInk.space(1)) {
                            outlineLip(title: "Re-run onboarding") {
                                store.reopenOnboarding()
                            }
                            outlineLip(title: "Reset all data") {
                                confirmReset = true
                            }
                            .disabled(saving)
                        }
                    }
                    .frame(maxWidth: 360)
                    VStack(alignment: .leading, spacing: CisternInk.space(2)) {
                        markWell
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        previewTiles
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: flexible ? .infinity : nil)
            } else {
                weightField
                bandColumn
                WeirLipButton(title: "Write today's mark", enabled: canWrite) {
                    saveMark()
                }
                markWell
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: CisternInk.space(18))
                    .frame(maxHeight: flexible ? .infinity : CisternInk.space(24))
                previewTiles
                contact
                HStack(spacing: CisternInk.space(1)) {
                    outlineLip(title: "Re-run onboarding") {
                        store.reopenOnboarding()
                    }
                    outlineLip(title: "Reset all data") {
                        confirmReset = true
                    }
                    .disabled(saving)
                }
            }
        }
        .padding(CisternInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: flexible ? .infinity : nil, alignment: .topLeading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: CisternInk.space(1)) {
            Text("Write today's mark")
                .cisternText(.house)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text("Weight and band, then save.")
                .cisternText(.caption)
                .foregroundStyle(CisternInk.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var weightField: some View {
        VStack(alignment: .leading, spacing: CisternInk.space(1)) {
            Text("Weight in kilograms")
                .cisternText(.caption)
                .foregroundStyle(CisternInk.muted)
            HStack(spacing: CisternInk.space(1)) {
                TextField("Weight", text: $weightText)
                    .keyboardType(.decimalPad)
                    .cisternText(.figure)
                    .focused($weightFocused)
                    .onChange(of: weightText) { _, next in
                        validate(next)
                    }
                    .accessibilityLabel("Weight in kilograms")
                Text("kg")
                    .cisternText(.caption)
                    .foregroundStyle(CisternInk.muted)
            }
            .padding(.horizontal, CisternInk.space(2))
            .frame(minHeight: CisternInk.tap)
            .background(CisternInk.surface)
            .overlay(Rectangle().stroke(CisternInk.ink, lineWidth: 1))
        }
    }

    private var bandColumn: some View {
        VStack(alignment: .leading, spacing: CisternInk.space(1)) {
            Text("Pick a band")
                .cisternText(.caption)
                .foregroundStyle(CisternInk.muted)
            ForEach(ActivityBand.allCases, id: \.self) { item in
                bandLip(item)
            }
        }
    }

    private func bandLip(_ item: ActivityBand) -> some View {
        Button {
            band = item
        } label: {
            HStack(alignment: .center, spacing: CisternInk.space(1)) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(WeirVoice.band(item))
                        .cisternText(.body)
                    Text(CisternFormat.millilitres(item.activityBonus) + " sump")
                        .cisternText(.stamp)
                        .foregroundStyle(CisternInk.muted)
                }
                Spacer(minLength: CisternInk.space(1))
                Text(band == item ? "Set" : "Pick")
                    .cisternText(.stamp)
                    .foregroundStyle(band == item ? CisternInk.ink : CisternInk.muted)
                    .frame(minHeight: CisternInk.tap)
            }
            .padding(.horizontal, CisternInk.space(2))
            .frame(maxWidth: .infinity, minHeight: CisternInk.tap, alignment: .leading)
            .background(CisternInk.surface)
            .overlay(Rectangle().stroke(band == item ? CisternInk.accent : CisternInk.ink, lineWidth: band == item ? 2 : 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(WeirVoice.band(item))
        .accessibilityAddTraits(band == item ? .isSelected : [])
    }

    private var markWell: some View {
        VesselWellHost(
            vessels: draftVessels,
            mark: draftMark ?? store.mark,
            reduceMotion: reduceMotion,
            onPour: {}
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(Rectangle().stroke(CisternInk.ink, lineWidth: 1))
        .accessibilityLabel("Sump fills first. Overflow crests into the bowl.")
    }

    private var previewTiles: some View {
        HStack(alignment: .top, spacing: CisternInk.space(1)) {
            figure(title: "Mark", value: CisternFormat.millilitres(draftMark?.goalMillilitres ?? 0))
            figure(title: "Sump", value: CisternFormat.millilitres(draftMark?.sumpTarget ?? 0))
            figure(title: "Bowl", value: CisternFormat.millilitres(draftMark?.bowlTarget ?? 0))
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
        .frame(maxWidth: .infinity, minHeight: CisternInk.tap, alignment: .leading)
        .padding(CisternInk.space(1))
        .background(CisternInk.surface)
    }

    private var contact: some View {
        Link(destination: WeirHop.contactURL) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Contact Castellum")
                    .cisternText(.body)
                Text(WeirHop.contactURL.absoluteString)
                    .cisternText(.stamp)
                    .foregroundStyle(CisternInk.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, CisternInk.space(2))
            .frame(maxWidth: .infinity, minHeight: CisternInk.tap, alignment: .leading)
            .background(CisternInk.surface)
            .overlay(Rectangle().stroke(CisternInk.ink, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Contact Castellum")
    }

    private func outlineLip(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .cisternText(.body)
                .frame(maxWidth: .infinity, minHeight: CisternInk.tap)
                .overlay(Rectangle().stroke(CisternInk.ink, lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var isRegular: Bool { horizontalSizeClass == .regular }

    private var draftMark: DayMark? {
        guard let kilograms = CisternFormat.parseKilograms(weightText) else { return nil }
        return DayMark(weightKg: kilograms, band: band)
    }

    private var draftVessels: WeirVessels {
        let mark = draftMark ?? store.mark ?? .outset
        let depth = mark.sumpTarget
        return WeirVessels(
            sump: SumpChamber(depthMillilitres: depth, remainingMillilitres: 0),
            bowl: BodyBowl(millilitres: 0),
            weir: .cresting
        )
    }

    private var canWrite: Bool {
        !saving && draftMark != nil
    }

    private func pullMark() {
        if let mark = store.mark {
            weightText = Self.weightDigits(mark.weightKg)
            band = mark.band
        } else {
            weightText = ""
            band = .none
        }
        weightFault = nil
    }

    private func validate(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            weightFault = nil
            return
        }
        if CisternFormat.parseKilograms(trimmed) == nil {
            weightFault = "Weight must be a positive number."
        } else {
            weightFault = nil
        }
    }

    private func saveMark() {
        guard let kilograms = CisternFormat.parseKilograms(weightText) else {
            weightFault = "Weight must be a positive number."
            return
        }
        commit(DayMark(weightKg: kilograms, band: band))
    }

    private func commit(_ mark: DayMark) {
        saving = true
        do {
            if store.mark == nil {
                try store.plant(mark)
            } else {
                try store.retune(mark)
            }
            weightFault = nil
        } catch let error as WeirRefusal {
            weightFault = WeirVoice.refusal(error)
        } catch {
            weightFault = String(describing: error)
        }
        saving = false
    }

    private static func weightDigits(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }
}
