import Foundation

public struct FitnessAgeConfiguration: Codable, Equatable, Sendable {
    public var domainWeights: [FitnessAgeDomain: Double]

    public static let `default` = FitnessAgeConfiguration(
        domainWeights: Dictionary(
            uniqueKeysWithValues: FitnessAgeDomain.allCases.map { ($0, $0.defaultWeight) }
        )
    )

    public init(domainWeights: [FitnessAgeDomain: Double]) {
        self.domainWeights = domainWeights
    }

    private enum CodingKeys: String, CodingKey {
        case domainWeights
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawWeights = try container.decodeIfPresent([String: Double].self, forKey: .domainWeights) ?? [:]
        let decodedWeights = rawWeights.reduce(into: [FitnessAgeDomain: Double]()) { result, element in
            guard let domain = FitnessAgeDomain(rawValue: element.key) else { return }
            result[domain] = element.value
        }

        domainWeights = Self.default.domainWeights.merging(decodedWeights) { _, decoded in decoded }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let rawWeights = Dictionary(
            uniqueKeysWithValues: domainWeights.map { ($0.key.rawValue, $0.value) }
        )
        try container.encode(rawWeights, forKey: .domainWeights)
    }
}
