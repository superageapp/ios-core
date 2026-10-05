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
    /// below 18 or not representable) receive a neutral result with `fitnessAge` equal
    /// to the chronological age, `overallScore` of `50`, and `confidence` of `0.1`.
    /// Non-finite ages use `0` in the neutral result so it remains JSON-encodable.
    /// Fractional ages interpolate the adjacent integer-age results, preserving the
    /// integer reference curves while making every adult birthday continuous.
    public func calculate(_ input: FitnessAgeInput) -> FitnessAgeResult {
        let age = input.profile.chronologicalAge
        guard input.profile.isValidForCalculation,
              let lowerAge = Int(exactly: age.rounded(.down)) else {
            return neutralResult(age: age.isFinite ? age : 0)
        }

        var lowerInput = input
        lowerInput.profile.chronologicalAge = Double(lowerAge)
        let lowerResult = calculateIntegerAge(lowerInput, age: lowerAge)
        let fraction = age - Double(lowerAge)
        guard fraction > 0 else { return lowerResult }

        // A Double with a fractional part is well within Int's integer range. Keep
        // the explicit guard so an integer conversion can never trap.
        guard lowerAge < Int.max else { return neutralResult(age: age) }
        var upperInput = input
        upperInput.profile.chronologicalAge = Double(lowerAge + 1)
        let upperResult = calculateIntegerAge(upperInput, age: lowerAge + 1)
        return interpolate(lowerResult, upperResult, fraction: fraction, age: age)
    }

    // Integer anchors retain the complete pre-0.5.0 algorithm and rounding order.
    private func calculateIntegerAge(_ input: FitnessAgeInput, age: Int) -> FitnessAgeResult {
        let filteredMetrics = input.metrics.filteringDisabledMetricIds(
            input.profile.effectiveDisabledMetricIds
        )
        let domainScores = FitnessAgeDomainScorer().domainScores(
            metrics: filteredMetrics,
            profile: input.profile,
            age: age
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
            chronologicalAge: age,
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

    private func neutralResult(age: Double) -> FitnessAgeResult {
        FitnessAgeResult(
            fitnessAge: age,
            chronologicalAge: age,
            confidence: 0.1,
            domainScores: [:],
            overallScore: 50,
            metricsUsed: 0,
            totalPossibleMetrics: 0
        )
    }

    private func interpolate(
        _ lower: FitnessAgeResult,
        _ upper: FitnessAgeResult,
        fraction: Double,
        age: Double
    ) -> FitnessAgeResult {
        var domainScores: [FitnessAgeDomain: FitnessAgeDomainScore] = [:]
        for domain in FitnessAgeDomain.allCases {
            switch (lower.domainScores[domain], upper.domainScores[domain]) {
            case let (lowerDomain?, upperDomain?):
                let score = blend(lowerDomain.score, upperDomain.score, fraction: fraction)
                // Most keys are observations and are identical at the anchors.
                // Age-derived lifestyle indicators use the same interpolation.
                var keyMetrics = lowerDomain.keyMetrics
                for (key, upperValue) in upperDomain.keyMetrics {
                    if let lowerValue = keyMetrics[key] {
                        keyMetrics[key] = blend(lowerValue, upperValue, fraction: fraction)
                    } else {
                        keyMetrics[key] = upperValue
                    }
                }
                domainScores[domain] = FitnessAgeDomainScore(
                    score: score,
                    percentile: max(0, min(100, 50 + ((score - 50) / 20) * 30)),
                    keyMetrics: keyMetrics,
                    dataQuality: blend(lowerDomain.dataQuality, upperDomain.dataQuality, fraction: fraction)
                )
            case let (domainScore?, nil), let (nil, domainScore?):
                // Presence currently depends only on input observations. If a future
                // instrument becomes age-specific, absence still is not score zero.
                domainScores[domain] = domainScore
            case (nil, nil):
                break
            }
        }

        return FitnessAgeResult(
            fitnessAge: blend(lower.fitnessAge, upper.fitnessAge, fraction: fraction),
            chronologicalAge: age,
            confidence: blend(lower.confidence, upper.confidence, fraction: fraction),
            domainScores: domainScores,
            overallScore: blend(lower.overallScore, upper.overallScore, fraction: fraction),
            metricsUsed: lower.metricsUsed,
            totalPossibleMetrics: lower.totalPossibleMetrics
        )
    }

    private func blend(_ lower: Double, _ upper: Double, fraction: Double) -> Double {
        // Preserve observations exactly rather than introducing rounding drift.
        lower == upper ? lower : lower + (upper - lower) * fraction
    }
}
