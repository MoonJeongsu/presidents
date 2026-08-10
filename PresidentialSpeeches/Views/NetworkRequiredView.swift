import SwiftUI

struct NetworkRequiredView: View {
    let onConfirmExit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Network required")
                .font(.title2.weight(.semibold))
            Text("This app requires an internet connection. Please connect to the network and try again.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
            Button("OK", action: onConfirmExit)
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
