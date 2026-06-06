import Foundation

enum FitnessAgeScoreAggregator {
    static func weightedScore(
        domainScores: [FitnessAgeDomain: FitnessAgeDomainScore],
        configuration: FitnessAgeConfiguration
    ) -> Double {
        let weights = baseWeights(configuration: configuration)
        var totalScore = 0.0
        var totalWeight = 0.0

        for domain in FitnessAgeDomain.allCases {
            guard let domainScore = domainScores[domain] else { continue }

            let weight = weights[domain] ?? sanitizedWeight(for: domain, configuration: configuration)
            totalScore += domainScore.score * weight
            totalWeight += weight
        }

        return totalWeight > 0 ? totalScore / totalWeight : 50
    }

    static func confidence(
        metrics: FitnessAgeMetrics,
        domainScores: [FitnessAgeDomain: FitnessAgeDomainScore],
        profile: FitnessAgeProfile,
        configuration: FitnessAgeConfiguration
    ) -> Double {
        let confidenceNormalizationDomainCount = normalizationDomainCount(
            profile: profile,
            configuration: configuration
        )
        let domainCompleteness = Double(domainScores.count) / confidenceNormalizationDomainCount
        let weightedDataQuality = dataQuality(for: metrics)

        var confidence = (domainCompleteness * 0.6) + (weightedDataQuality * 0.4)

        if metrics.vo2Max != nil {
            confidence += 0.08
        }
        if metrics.restingHeartRate != nil {
            confidence += 0.04
        }
        if metrics.heartRateVariability != nil {
            confidence += 0.04
        }
        if metrics.systolicBloodPressure != nil && metrics.diastolicBloodPressure != nil {
            confidence += 0.03
        }

        if profile.biologicalSex == .unknown || profile.biologicalSex == .intersex {
            confidence *= 0.92
        }

        if !profile.focusDomains.isEmpty {
            let focusDomainsWithGoodData = profile.focusDomains.filter { domain in
                domainScores[domain]?.score ?? 0 > 80
            }
            if focusDomainsWithGoodData.count >= 2 {
                confidence *= 1.05
            }
        }

        return confidence.clamped(to: 0.1...1.0)
    }

    static func fitnessAge(
        score: Double,
        chronologicalAge: Int,
        confidence: Double,
        configuration: FitnessAgeConfiguration
    ) -> Double {
        switch configuration.algorithmMode {
        case .evidenceFirst, .custom:
            return evidenceFirstFitnessAge(
                score: score,
                chronologicalAge: chronologicalAge,
                mapping: configuration.mapping
            )
        case .compatibilityV1:
            return compatibilityFitnessAge(
                score: score,
                chronologicalAge: chronologicalAge,
                confidence: confidence
            )
        }
    }

    private static func normalizationDomainCount(
        profile: FitnessAgeProfile,
        configuration: FitnessAgeConfiguration
    ) -> Double {
        guard configuration.algorithmMode != .compatibilityV1 else {
            return 6.0
        }

        let enabledDomainCount = FitnessAgeDomain.allCases.filter { domain in
            !profile.excludedDomains.contains(domain)
        }.count

        return Double(max(1, enabledDomainCount))
    }

    private static func evidenceFirstFitnessAge(
        score: Double,
        chronologicalAge: Int,
        mapping: FitnessAgeMappingConfiguration
    ) -> Double {
        let normalizedScore = (score.clamped(to: 0...100) - 50.0) / 50.0
        let maximumAgeDelta = max(0, mapping.maximumAgeDelta)
        let proposedAge = Double(chronologicalAge) - (normalizedScore * maximumAgeDelta)
        let lowerBound = max(0, mapping.minimumDisplayAge)
        let upperBound = max(lowerBound, Double(chronologicalAge) + maximumAgeDelta)

        return proposedAge.clamped(to: lowerBound...upperBound)
    }

    private static func compatibilityFitnessAge(
        score: Double,
        chronologicalAge: Int,
        confidence: Double
    ) -> Double {
        let baseAge = compatibilityMappedFitnessAge(score: score, chronologicalAge: chronologicalAge)
        let smoothFactor = compatibilitySmoothingFactor(confidence: confidence)

        guard smoothFactor > 0.01 else {
            return baseAge
        }

        return compatibilityAdjustedAge(
            age: baseAge,
            chronologicalAge: chronologicalAge,
            smoothFactor: smoothFactor
        )
    }

    private static func baseWeights(configuration: FitnessAgeConfiguration) -> [FitnessAgeDomain: Double] {
        Dictionary(
            uniqueKeysWithValues: FitnessAgeDomain.allCases.map { domain in
                (domain, sanitizedWeight(for: domain, configuration: configuration))
            }
        )
    }

    private static func sanitizedWeight(
        for domain: FitnessAgeDomain,
        configuration: FitnessAgeConfiguration
    ) -> Double {
        min(0.40, max(0.0, configuration.domainWeights[domain] ?? domain.defaultWeight))
    }

    private static func dataQuality(for metrics: FitnessAgeMetrics) -> Double {
        var qualityComponents: [(quality: Double, weight: Double)] = []

        if metrics.stepCount != nil {
            qualityComponents.append((0.85, 0.23))
        }
        if metrics.activeEnergy != nil {
            qualityComponents.append((0.85, 0.17))
        }
        if metrics.exerciseTime != nil {
            qualityComponents.append((0.85, 0.17))
        }
        if metrics.sleepHours != nil || metrics.sleepScore != nil {
            qualityComponents.append((0.85, 0.23))
        }

        guard !qualityComponents.isEmpty else {
            return 0.7
        }

        let totalWeight = qualityComponents.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else {
            return 0.7
        }

        return qualityComponents.reduce(0.0) { partial, component in
            partial + (component.quality * component.weight)
        } / totalWeight
    }

    private static func compatibilitySmoothingFactor(confidence: Double) -> Double {
        let peak = 0.7
        let lowerBound = 0.5
        let upperBound = 0.9

        guard confidence > lowerBound && confidence < upperBound else {
            return 0.0
        }

        let normalizedPosition: Double
        if confidence <= peak {
            normalizedPosition = (confidence - lowerBound) / (peak - lowerBound)
        } else {
            normalizedPosition = 1.0 - (confidence - peak) / (upperBound - peak)
        }

        return (1.0 - cos(normalizedPosition * .pi)) / 2.0
    }

    private static func compatibilityAdjustedAge(
        age: Double,
        chronologicalAge: Int,
        smoothFactor: Double
    ) -> Double {
        let ageDifference = age - Double(chronologicalAge)

        if ageDifference > 0 {
            let reduction = smoothFactor * 0.4
            return max(Double(chronologicalAge), age - reduction)
        } else {
            let enhancement = smoothFactor * 0.3
            return age - enhancement
        }
    }

    private static func compatibilityMappedFitnessAge(score: Double, chronologicalAge: Int) -> Double {
        let boundedScore = score.clamped(to: 0...100)
        let ageDifference: Double

        if boundedScore >= 50 {
            let progress = (boundedScore - 50) / 50
            ageDifference = -(progress * 2.0) - (progress * progress * 8.5)
        } else {
            let progress = (50 - boundedScore) / 50
            ageDifference = progress * 3.75
        }

        let proposedAge = Double(chronologicalAge) + ageDifference
        let maxYoungerYears: Double
        let maxOlderYears: Double

        switch chronologicalAge {
        case 18...25:
            maxYoungerYears = 5.0
            maxOlderYears = 4.0
        case 26...35:
            maxYoungerYears = 8.0
            maxOlderYears = 5.0
        case 36...50:
            maxYoungerYears = 10.0
            maxOlderYears = 5.0
        case 51...65:
            maxYoungerYears = 10.0
            maxOlderYears = 5.0
        default:
            maxYoungerYears = 10.0
            maxOlderYears = 4.0
        }

        let minRealisticAge = Double(chronologicalAge) - maxYoungerYears
        let maxRealisticAge = Double(chronologicalAge) + maxOlderYears
        let clampedAge = proposedAge.clamped(to: minRealisticAge...maxRealisticAge)
        return max(18.0, clampedAge)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
