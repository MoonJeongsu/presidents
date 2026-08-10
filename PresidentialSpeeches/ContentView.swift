import SwiftUI

private enum AppRoute: Hashable {
    case speeches(presidentId: String)
    case speech(speechId: String)
}

struct ContentView: View {
    let environment: AppEnvironment
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @State private var path = NavigationPath()

    var body: some View {
        Group {
            if networkMonitor.isConnected {
                NavigationStack(path: $path) {
                    PresidentListView(
                        presidents: environment.speechRepository.getPresidents(),
                        onPresidentClick: { president in
                            path.append(AppRoute.speeches(presidentId: president.id))
                        }
                    )
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case let .speeches(presidentId):
                            SpeechListRouteView(
                                environment: environment,
                                presidentId: presidentId,
                                onSpeechClick: { speech in
                                    path.append(AppRoute.speech(speechId: speech.id))
                                }
                            )
                        case let .speech(speechId):
                            SpeechDetailRouteView(
                                environment: environment,
                                speechId: speechId
                            )
                        }
                    }
                }
            } else {
                NetworkRequiredView {
                    exit(0)
                }
            }
        }
    }
}

private struct SpeechListRouteView: View {
    let environment: AppEnvironment
    let presidentId: String
    let onSpeechClick: (SpeechSummary) -> Void

    var body: some View {
        let president = environment.speechRepository.getPresident(presidentId)
        let speeches = environment.speechRepository.getSpeeches(presidentId: presidentId)

        SpeechListView(
            presidentName: president?.name ?? "Speeches",
            speeches: speeches,
            onSpeechClick: onSpeechClick
        )
    }
}

private struct SpeechDetailRouteView: View {
    let environment: AppEnvironment
    let speechId: String

    @State private var speechDetail: SpeechDetail?
    @State private var loadError: String?
    @State private var isLoading = true
    @StateObject private var viewModel: SpeechDetailViewModel

    init(environment: AppEnvironment, speechId: String) {
        self.environment = environment
        self.speechId = speechId
        _viewModel = StateObject(
            wrappedValue: SpeechDetailViewModel(
                translationRepository: environment.translationRepository,
                ttsRepository: environment.ttsRepository
            )
        )
    }

    var body: some View {
        SpeechDetailView(
            speech: speechDetail,
            isLoading: isLoading,
            loadError: loadError,
            viewModel: viewModel
        )
        .task(id: speechId) {
            await loadSpeech()
        }
    }

    @MainActor
    private func loadSpeech() async {
        isLoading = true
        loadError = nil
        speechDetail = nil

        guard NetworkUtils.isConnected else {
            loadError = "This app requires an internet connection. Please connect to the network and try again."
            isLoading = false
            return
        }

        if let detail = await environment.speechRepository.getSpeechDetail(speechId: speechId) {
            speechDetail = detail
        } else {
            loadError = await environment.speechRepository.getSpeechDetailError(speechId: speechId)
                ?? "Could not download the speech. Check your connection and try again."
        }
        isLoading = false
    }
}
