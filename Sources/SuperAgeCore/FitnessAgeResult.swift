import Foundation

public struct FitnessAgeDomainScore: Codable, Equatable, Sendable {
    public var score: Double
    public var percentile: Double
    public var keyMetrics: [String: Double]
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
    public var fitnessAge: Double
    public var chronologicalAge: Int
    public var difference: Double
    public var confidence: Double
    public var domainScores: [FitnessAgeDomain: FitnessAgeDomainScore]
    public var overallScore: Double
    public var metricsUsed: Int
    public var totalPossibleMetrics: Int

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
        difference = fitnessAge - Double(chronologicalAge)
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
        let decodedDifference = try container.decodeIfPresent(Double.self, forKey: .difference)
            ?? (decodedFitnessAge - Double(decodedChronologicalAge))
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
        difference = decodedDifference
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
