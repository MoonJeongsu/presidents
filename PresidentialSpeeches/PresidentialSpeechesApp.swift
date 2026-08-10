import SwiftUI

@main
struct PresidentialSpeechesApp: App {
    @StateObject private var networkMonitor = NetworkMonitor()
    private let environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView(environment: environment)
                .environmentObject(networkMonitor)
        }
    }
}
