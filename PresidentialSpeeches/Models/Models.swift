import Foundation

struct President: Identifiable, Hashable, Decodable {
    let id: String
    let name: String
    let years: String

    init(id: String, name: String, years: String) {
        self.id = id
        self.name = name
        self.years = years
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        years = try container.decodeIfPresent(String.self, forKey: .years) ?? ""
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, years
    }
}

struct SpeechSummary: Identifiable, Hashable, Decodable {
    let id: String
    let presidentId: String
    let title: String
    let date: String?
    let presidentName: String
}

struct SpeechDetail {
    let summary: SpeechSummary
    let body: String
}
