import Foundation

public struct FitnessAgeDomainScore: Codable, Equatable, Sendable {
    /// The domain score on a `0...100` scale.
    public var score: Double
    /// A synthetic relative-standing index derived affinely from `score`
    /// (`clamp(50 + (score - 50) * 1.5, 0, 100)`).
    ///
    /// This is not a measured population percentile; no reference distribution is
    /// consulted. See "Domain relative standing" in Docs/METHODOLOGY.md.
    public var percentile: Double
    /// The observed metric values (and derived values) that contributed to the score.
    public var keyMetrics: [String: Double]
    /// Reserved for future per-domain data-quality reporting; the calculator currently
    /// always emits `1.0`.
    public var dataQuality: Double

    public init(
        score: Double,
        percentile: Double,
        keyMetrics: [String: Double] = [:],
        dataQuality: Double = 1.0
    ) {
        self.score = score.clamped(to: 0...100)
        self.percentile = percentile.clamped(to: 0...100)
        self.keyMetrics = keyMetrics
        self.dataQuality = dataQuality.clamped(to: 0...1)
    }

    private enum CodingKeys: String, CodingKey {
        case score
        case percentile
        case keyMetrics
        case dataQuality
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            score: try container.decodeIfPresent(Double.self, forKey: .score) ?? 0,
            percentile: try container.decodeIfPresent(Double.self, forKey: .percentile) ?? 0,
            keyMetrics: try container.decodeIfPresent([String: Double].self, forKey: .keyMetrics) ?? [:],
            dataQuality: try container.decodeIfPresent(Double.self, forKey: .dataQuality) ?? 1.0
        )
    }
}

public struct FitnessAgeResult: Codable, Equatable, Sendable {
    /// The estimated Fitness Age in years.
    public var fitnessAge: Double
    /// The chronological age the estimate was computed against.
    public var chronologicalAge: Int
    /// Evidence completeness on a `0.1...1.0` scale; see Docs/METHODOLOGY.md.
    public var confidence: Double
    /// The scored domains; domains without observed metrics are absent.
    public var domainScores: [FitnessAgeDomain: FitnessAgeDomainScore]
    /// The weighted present-domain score on a `0...100` scale.
    public var overallScore: Double
    /// The number of distinct physical instruments observed across scored domains.
    ///
    /// The blood pressure pair counts as one instrument, the sleep inputs share one
    /// instrument, and the step- and energy-derived lifestyle composites count toward
    /// their source step and energy instruments.
    public var metricsUsed: Int
    /// The number of instruments that could have been observed for this input,
    /// after removing disabled metric IDs and excluded domains.
    public var totalPossibleMetrics: Int

    /// `fitnessAge - chronologicalAge`; negative values mean a younger Fitness Age.
    public var difference: Double {
        fitnessAge - Double(chronologicalAge)
    }

    public init(
        fitnessAge: Double,
        chronologicalAge: Int,
        confidence: Double,
        domainScores: [FitnessAgeDomain: FitnessAgeDomainScore],
        overallScore: Double,
        metricsUsed: Int,
        totalPossibleMetrics: Int
    ) {
        self.fitnessAge = fitnessAge
        self.chronologicalAge = chronologicalAge
        self.confidence = confidence.clamped(to: 0...1)
        self.domainScores = domainScores
        self.overallScore = overallScore.clamped(to: 0...100)
        self.metricsUsed = metricsUsed
        self.totalPossibleMetrics = totalPossibleMetrics
    }

    private enum CodingKeys: String, CodingKey {
        case fitnessAge
        case chronologicalAge
        case difference
        case confidence
        case domainScores
        case overallScore
        case metricsUsed
        case totalPossibleMetrics
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedFitnessAge = try container.decodeIfPresent(Double.self, forKey: .fitnessAge) ?? 0
        let decodedChronologicalAge = try container.decodeIfPresent(Int.self, forKey: .chronologicalAge) ?? 0
        let rawDomainScores = try container.decodeIfPresent(
            [String: FitnessAgeDomainScore].self,
            forKey: .domainScores
        ) ?? [:]
        let decodedDomainScores = rawDomainScores.reduce(into: [FitnessAgeDomain: FitnessAgeDomainScore]()) { result, element in
            guard let domain = FitnessAgeDomain(rawValue: element.key) else { return }
            result[domain] = element.value
        }

        fitnessAge = decodedFitnessAge
        chronologicalAge = decodedChronologicalAge
        confidence = (try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 0).clamped(to: 0...1)
        domainScores = decodedDomainScores
        overallScore = (try container.decodeIfPresent(Double.self, forKey: .overallScore) ?? 0).clamped(to: 0...100)
        metricsUsed = try container.decodeIfPresent(Int.self, forKey: .metricsUsed) ?? 0
        totalPossibleMetrics = try container.decodeIfPresent(Int.self, forKey: .totalPossibleMetrics) ?? 0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fitnessAge, forKey: .fitnessAge)
        try container.encode(chronologicalAge, forKey: .chronologicalAge)
        try container.encode(difference, forKey: .difference)
        try container.encode(confidence, forKey: .confidence)
        let rawDomainScores = Dictionary(
            uniqueKeysWithValues: domainScores.map { ($0.key.rawValue, $0.value) }
        )
        try container.encode(rawDomainScores, forKey: .domainScores)
        try container.encode(overallScore, forKey: .overallScore)
        try container.encode(metricsUsed, forKey: .metricsUsed)
        try container.encode(totalPossibleMetrics, forKey: .totalPossibleMetrics)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
