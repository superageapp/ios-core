import Foundation

public struct FitnessAgeInput: Codable, Equatable, Sendable {
    public var profile: FitnessAgeProfile
    public var metrics: FitnessAgeMetrics
    public var configuration: FitnessAgeConfiguration

    public init(
        profile: FitnessAgeProfile,
        metrics: FitnessAgeMetrics,
        configuration: FitnessAgeConfiguration = .default
    ) {
        self.profile = profile
        self.metrics = metrics
        self.configuration = configuration
    }

    private enum CodingKeys: String, CodingKey {
        case profile
        case metrics
        case configuration
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profile = try container.decodeIfPresent(FitnessAgeProfile.self, forKey: .profile)
            ?? FitnessAgeProfile(chronologicalAge: 0, biologicalSex: .unknown)
        metrics = try container.decodeIfPresent(FitnessAgeMetrics.self, forKey: .metrics) ?? FitnessAgeMetrics()
        configuration = try container.decodeIfPresent(FitnessAgeConfiguration.self, forKey: .configuration) ?? .default
    }
}

public struct FitnessAgeCalculator: Sendable {
    public init() {}

    public func calculate(_ input: FitnessAgeInput) -> FitnessAgeResult {
        guard input.profile.isValidForCalculation else {
            return FitnessAgeResult(
                fitnessAge: Double(input.profile.chronologicalAge),
                chronologicalAge: input.profile.chronologicalAge,
                confidence: 0.1,
                domainScores: [:],
                overallScore: 50,
                metricsUsed: 0,
                totalPossibleMetrics: 0
            )
        }

        let filteredMetrics = input.metrics.filteringDisabledMetricIds(input.profile.disabledMetricIds)
        let domainScores = FitnessAgeDomainScorer().domainScores(
            metrics: filteredMetrics,
            profile: input.profile
        )
        let overallScore = FitnessAgeScoreAggregator.weightedScore(
            domainScores: domainScores,
            configuration: input.configuration
        )
        let confidence = FitnessAgeScoreAggregator.confidence(
            metrics: filteredMetrics,
            domainScores: domainScores,
            profile: input.profile,
            configuration: input.configuration
        )
        let fitnessAge = FitnessAgeScoreAggregator.fitnessAge(
            score: overallScore,
            chronologicalAge: input.profile.chronologicalAge,
            confidence: confidence,
            configuration: input.configuration
        )
        let metricsUsed = domainScores.values.reduce(0) { count, domainScore in
            count + domainScore.keyMetrics.count
        }
        let totalPossibleMetrics = Set(domainScores.values.flatMap { domainScore in
            domainScore.keyMetrics.keys
        }).count

        return FitnessAgeResult(
            fitnessAge: fitnessAge,
            chronologicalAge: input.profile.chronologicalAge,
            confidence: confidence,
            domainScores: domainScores,
            overallScore: overallScore,
            metricsUsed: metricsUsed,
            totalPossibleMetrics: totalPossibleMetrics
        )
    }
}
