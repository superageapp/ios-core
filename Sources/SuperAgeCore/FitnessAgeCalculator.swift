import Foundation

/// The complete input for one Fitness Age calculation.
public struct FitnessAgeInput: Codable, Equatable, Sendable {
    /// Who is being scored: age, biological sex, and scoring boundaries.
    public var profile: FitnessAgeProfile
    /// The normalized metric observations supplied by the host.
    public var metrics: FitnessAgeMetrics
    /// Algorithm mode, domain weights, and score-to-age mapping bounds.
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

/// Computes a deterministic Fitness Age estimate from normalized host-supplied inputs.
public struct FitnessAgeCalculator: Sendable {
    public init() {}

    /// Calculates the Fitness Age result for the given input.
    ///
    /// The calculation is pure and deterministic: the same input always produces the
    /// same result. Profiles that are not valid for calculation (chronological age
    /// below 18) receive a neutral result with `fitnessAge` equal to the chronological
    /// age, `overallScore` of `50`, and `confidence` of `0.1`.
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

        let filteredMetrics = input.metrics.filteringDisabledMetricIds(
            input.profile.effectiveDisabledMetricIds
        )
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
        let metricsUsed = FitnessAgeInstrumentCatalog.observedInstrumentCount(
            domainScores: domainScores
        )
        let totalPossibleMetrics = FitnessAgeInstrumentCatalog.possibleInstrumentCount(
            profile: input.profile
        )

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
