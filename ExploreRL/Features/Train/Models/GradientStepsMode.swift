import Foundation

enum GradientStepsMode: String, CaseIterable, Codable {
    case fixed
    case asCollectedSteps

    init(rawString: String) {
        switch rawString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "ascollectedsteps", "ascollected", "collected":
            self = .asCollectedSteps
        default:
            self = .fixed
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self)) ?? Self.fixed.rawValue
        self = Self(rawString: raw)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
