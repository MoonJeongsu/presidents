import SwiftUI

struct PresidentListView: View {
    let presidents: [President]
    let onPresidentClick: (President) -> Void

    var body: some View {
        List(presidents) { president in
            Button {
                onPresidentClick(president)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(president.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if !president.years.isEmpty {
                        Text(president.years)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
        .navigationTitle("US Presidents")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .top) {
            Text("Select a president to browse speeches in chronological order.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
        }
        .safeAreaInset(edge: .bottom) {
            if AppConfig.showAds {
                Text("Ad banner placeholder")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(.systemGray6))
            }
        }
    }
}

struct PresidentListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PresidentListView(
                presidents: [
                    President(id: "1", name: "George Washington", years: "1732 - 1799"),
                ],
                onPresidentClick: { _ in }
            )
        }
    }
}
