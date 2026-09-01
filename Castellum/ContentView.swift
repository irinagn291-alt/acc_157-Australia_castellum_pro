import SwiftUI

/// Role: Presentation. Host. Onboarding cover, then the weir-first swipe.
struct ContentView: View {
    var store: WeirStore
    @State private var page: WeirPage = .dial
    @State private var hookConsumed = false
    @State private var booted = false
    @State private var showSpinner = false
    @Environment(\.scenePhase) private var scenePhase

    init(store: WeirStore = WeirStore.previewPopulated()) {
        self.store = store
    }

    var body: some View {
        ZStack {
            CisternInk.background.ignoresSafeArea()
            if booted {
                if store.onboardingComplete {
                    WeirHouseView(store: store, page: $page)
                } else {
                    CisternOnboardingView(store: store)
                }
            } else if showSpinner {
                ProgressView()
                    .tint(CisternInk.ink)
            }
        }
        .preferredColorScheme(.dark)
        .task { await boot() }
        .onChange(of: store.onboardingComplete) { _, done in
            if done { applyHook() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.settle()
            }
        }
        .task(id: scenePhase) {
            if scenePhase == .inactive || scenePhase == .background {
                await store.flush()
            }
        }
    }

    private func boot() async {
        let spinner = Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            if !Task.isCancelled {
                showSpinner = true
            }
        }
        await store.load()
        await store.seedDemoIfNeeded()
        store.settle()
        spinner.cancel()
        showSpinner = false
        booted = true
        applyHook()
    }

    private func applyHook() {
        guard let hook = ReviewHook.consume(
            arguments: ProcessInfo.processInfo.arguments,
            onboarded: store.onboardingComplete,
            consumed: &hookConsumed
        ) else { return }
        switch hook {
        case .today:
            page = .dial
        case .log:
            page = .history
        case .goals:
            page = .settings
        }
    }
}

#Preview {
    ContentView()
}
