import Foundation

final class SpeechRepository {
    private let speechBodyFetcher: SpeechBodyFetcher
    private let presidents: [President]
    private let speechesByPresident: [String: [SpeechSummary]]

    init(speechBodyFetcher: SpeechBodyFetcher = SpeechBodyFetcher()) {
        self.speechBodyFetcher = speechBodyFetcher

        let presidentData = Self.loadResource(named: "presidents")
        let speechIndexData = Self.loadResource(named: "speeches_index")

        presidents = Self.parsePresidents(from: presidentData)
        let allSpeeches = Self.parseSpeechIndex(from: speechIndexData)
        speechesByPresident = Dictionary(grouping: allSpeeches, by: \.presidentId)
            .mapValues { speeches in
                speeches.sorted {
                    let leftDate = $0.date ?? "9999-12-31"
                    let rightDate = $1.date ?? "9999-12-31"
                    if leftDate == rightDate {
                        return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                    }
                    return leftDate < rightDate
                }
            }
    }

    func getPresidents() -> [President] {
        presidents
    }

    func getPresident(_ presidentId: String) -> President? {
        presidents.first { $0.id == presidentId }
    }

    func getSpeeches(presidentId: String) -> [SpeechSummary] {
        speechesByPresident[presidentId] ?? []
    }

    func getSpeechSummary(speechId: String) -> SpeechSummary? {
        speechesByPresident.values.flatMap { $0 }.first { $0.id == speechId }
    }

    func getSpeechDetail(speechId: String) async -> SpeechDetail? {
        guard let summary = getSpeechSummary(speechId: speechId) else { return nil }
        guard let body = try? await speechBodyFetcher.fetchBody(speechId: speechId) else { return nil }
        return SpeechDetail(summary: summary, body: body)
    }

    func getSpeechDetailError(speechId: String) async -> String? {
        guard getSpeechSummary(speechId: speechId) != nil else { return nil }
        do {
            _ = try await speechBodyFetcher.fetchBody(speechId: speechId)
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private static func loadResource(named name: String) -> Data {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            fatalError("Missing bundled resource: \(name).json")
        }
        return data
    }

    private static func parsePresidents(from data: Data) -> [President] {
        let decoder = JSONDecoder()
        return (try? decoder.decode([President].self, from: data)) ?? []
    }

    private static func parseSpeechIndex(from data: Data) -> [SpeechSummary] {
        let decoder = JSONDecoder()
        return (try? decoder.decode([SpeechSummary].self, from: data)) ?? []
    }
}
