import SwiftUI
import UIKit

/// Role: Presentation. Four plates. Skip still writes a quiet outset mark.
struct CisternOnboardingView: View {
    var store: WeirStore
    @State private var page = 0
    @State private var weightText = "70"
    @State private var band: ActivityBand = .none
    @State private var weightFault: String?
    @FocusState private var weightFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(store: WeirStore = WeirStore.previewVacant()) {
        self.store = store
    }

    var body: some View {
        VStack(spacing: 0) {
            pageBlock
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            floor
        }
        .padding(.horizontal, CisternInk.space(2))
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
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    private var pageBlock: some View {
        switch page {
        case 0:
            plate(
                image: "ctm_Onboarding1",
                title: "The cistern house",
                line: "A lower sump holds sweat. An upper bowl holds the body. The weir sits between them."
            )
        case 1:
            plate(
                image: "ctm_Onboarding2",
                title: "Crest the weir",
                line: "A pour fills the sump first. Only overflow crests into the bowl. A night chug cannot jump an open sump."
            )
        case 2:
            plate(
                image: "ctm_Onboarding3",
                title: "Crest-runs stay",
                line: "History counts days the weir overflowed. The mark is weight and band, never a typed goal."
            )
        default:
            markPlate
        }
    }

    private var markPlate: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CisternInk.space(2)) {
                if UIImage(named: "ctm_Onboarding3") != nil {
                    Image("ctm_Onboarding3")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .accessibilityHidden(true)
                }
                Text("Your day mark")
                    .cisternText(.mark)
                Text("Weight and an activity band write the weir. Still, active, or intense is a sump depth — 0, 350, or 700 ml.")
                    .cisternText(.body)
                    .foregroundStyle(CisternInk.muted)
                TextField("Weight", text: $weightText)
                    .keyboardType(.decimalPad)
                    .cisternText(.figure)
                    .padding(.horizontal, CisternInk.space(2))
                    .frame(minHeight: CisternInk.tap)
                    .background(CisternInk.surface)
                    .overlay(Rectangle().stroke(CisternInk.ink, lineWidth: 1))
                    .focused($weightFocused)
                    .onChange(of: weightText) { _, next in
                        let trimmed = next.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty || CisternFormat.parseKilograms(trimmed) != nil {
                            weightFault = nil
                        } else {
                            weightFault = "Weight must be a positive number."
                        }
                    }
                    .accessibilityLabel("Weight in kilograms")
                ForEach(ActivityBand.allCases, id: \.self) { item in
                    Button {
                        band = item
                    } label: {
                        HStack {
                            Text(WeirVoice.band(item))
                                .cisternText(.body)
                            Spacer()
                            Text(CisternFormat.millilitres(item.activityBonus))
                                .cisternText(.stamp)
                            Text(band == item ? "Set" : "Open")
                                .cisternText(.stamp)
                                .foregroundStyle(band == item ? CisternInk.ink : CisternInk.muted)
                                .frame(minHeight: CisternInk.tap)
                        }
                        .padding(.horizontal, CisternInk.space(2))
                        .frame(maxWidth: .infinity, minHeight: CisternInk.tap)
                        .background(CisternInk.surface)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                if let weightFault {
                    Text(weightFault)
                        .cisternText(.caption)
                }
            }
            .padding(.top, CisternInk.space(2))
        }
    }

    private var floor: some View {
        VStack(spacing: CisternInk.space(1)) {
            WeirLipButton(title: page < 3 ? "Next" : "Open the well") {
                if page < 3 {
                    if reduceMotion {
                        page += 1
                    } else {
                        withAnimation(CisternInk.motion) { page += 1 }
                    }
                } else {
                    finish(skip: false)
                }
            }
            Button {
                finish(skip: true)
            } label: {
                Text("Skip")
                    .cisternText(.body)
                    .frame(maxWidth: .infinity, minHeight: CisternInk.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Skip")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CisternInk.space(2))
    }

    private func plate(image: String, title: String, line: String) -> some View {
        VStack(alignment: .leading, spacing: CisternInk.space(2)) {
            if UIImage(named: image) != nil {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 320)
                    .accessibilityHidden(true)
            }
            Text(title)
                .cisternText(.mark)
            Text(line)
                .cisternText(.body)
                .foregroundStyle(CisternInk.muted)
            Spacer(minLength: 0)
        }
        .padding(.top, CisternInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func finish(skip: Bool) {
        let mark: DayMark
        if skip {
            mark = .outset
        } else if let kilograms = CisternFormat.parseKilograms(weightText) {
            mark = DayMark(weightKg: kilograms, band: band)
        } else {
            weightFault = "Weight must be a positive number."
            return
        }
        do {
            if store.mark == nil {
                try store.plant(mark)
            } else if !skip {
                try store.retune(mark)
            }
            store.markOnboardingComplete()
        } catch let error as WeirRefusal {
            weightFault = WeirVoice.refusal(error)
        } catch {
            weightFault = String(describing: error)
        }
    }
}
