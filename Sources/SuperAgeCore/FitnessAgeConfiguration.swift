import Foundation

public enum FitnessAgeAlgorithmMode: String, Codable, Equatable, Sendable {
    case evidenceFirst
    case compatibilityV1
    case custom
}

public struct FitnessAgeMappingConfiguration: Codable, Equatable, Sendable {
    public var maximumAgeDelta: Double
    public var minimumDisplayAge: Double

    public static let evidenceFirst = FitnessAgeMappingConfiguration(
        maximumAgeDelta: 10,
        minimumDisplayAge: 18
    )

    public static let compatibilityV1 = FitnessAgeMappingConfiguration(
        maximumAgeDelta: 10,
        minimumDisplayAge: 18
    )

    public init(maximumAgeDelta: Double, minimumDisplayAge: Double) {
        self.maximumAgeDelta = max(0, maximumAgeDelta)
        self.minimumDisplayAge = max(0, minimumDisplayAge)
    }

    private enum CodingKeys: String, CodingKey {
        case maximumAgeDelta
        case minimumDisplayAge
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            maximumAgeDelta: try container.decodeIfPresent(Double.self, forKey: .maximumAgeDelta)
                ?? Self.evidenceFirst.maximumAgeDelta,
            minimumDisplayAge: try container.decodeIfPresent(Double.self, forKey: .minimumDisplayAge)
                ?? Self.evidenceFirst.minimumDisplayAge
        )
    }
}

public struct FitnessAgeConfiguration: Codable, Equatable, Sendable {
    public var domainWeights: [FitnessAgeDomain: Double]
    public var algorithmMode: FitnessAgeAlgorithmMode
    public var mapping: FitnessAgeMappingConfiguration

    public static let `default` = FitnessAgeConfiguration(
        algorithmMode: .evidenceFirst,
        domainWeights: Dictionary(
            uniqueKeysWithValues: FitnessAgeDomain.allCases.map { ($0, $0.defaultWeight) }
        ),
        mapping: .evidenceFirst
    )

    public static let compatibilityV1 = FitnessAgeConfiguration(
        algorithmMode: .compatibilityV1,
        domainWeights: Dictionary(
            uniqueKeysWithValues: FitnessAgeDomain.allCases.map { ($0, $0.defaultWeight) }
        ),
        mapping: .compatibilityV1
    )

    public init(
        algorithmMode: FitnessAgeAlgorithmMode = .evidenceFirst,
        domainWeights: [FitnessAgeDomain: Double],
        mapping: FitnessAgeMappingConfiguration = .evidenceFirst
    ) {
        self.algorithmMode = algorithmMode
        self.domainWeights = domainWeights
        self.mapping = mapping
    }

    private enum CodingKeys: String, CodingKey {
        case algorithmMode
        case domainWeights
        case mapping
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        algorithmMode = try container.decodeIfPresent(FitnessAgeAlgorithmMode.self, forKey: .algorithmMode)
            ?? .evidenceFirst
        let rawWeights = try container.decodeIfPresent([String: Double].self, forKey: .domainWeights) ?? [:]
        let decodedWeights = rawWeights.reduce(into: [FitnessAgeDomain: Double]()) { result, element in
            guard let domain = FitnessAgeDomain(rawValue: element.key) else { return }
            result[domain] = element.value
        }

        domainWeights = Self.default.domainWeights.merging(decodedWeights) { _, decoded in decoded }
        mapping = try container.decodeIfPresent(FitnessAgeMappingConfiguration.self, forKey: .mapping)
            ?? (algorithmMode == .compatibilityV1 ? .compatibilityV1 : .evidenceFirst)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let rawWeights = Dictionary(
            uniqueKeysWithValues: domainWeights.map { ($0.key.rawValue, $0.value) }
        )
        try container.encode(algorithmMode, forKey: .algorithmMode)
        try container.encode(rawWeights, forKey: .domainWeights)
        try container.encode(mapping, forKey: .mapping)
    }
}
