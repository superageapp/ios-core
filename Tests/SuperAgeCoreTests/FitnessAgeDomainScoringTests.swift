import Testing
import SuperAgeCore

@Suite("FitnessAge domain scoring")
struct FitnessAgeDomainScoringTests {
    @Test("zero numeric metrics are excluded from key metrics")
    func zeroNumericMetricsAreExcluded() {
        let input = FitnessAgeInput(
            profile: FitnessAgeProfile(chronologicalAge: 40, biologicalSex: .male),
            metrics: FitnessAgeMetrics(
                vo2Max: 0,
                respiratoryRate: 15,
                maxHeartRate: 180,
                stepCount: 0,
                activeEnergy: 500
            )
        )

        let result = FitnessAgeCalculator().calculate(input)

        #expect(result.domainScores[.activity]?.keyMetrics["stepCount"] == nil)
        #expect(result.domainScores[.activity]?.keyMetrics["activeEnergy"] == 500)
        #expect(result.domainScores[.cardiovascular]?.keyMetrics["vo2Max"] == nil)
        #expect(result.domainScores[.cardiovascular]?.keyMetrics["maxHeartRate"] == 180)
    }

    @Test("sleep fallback is used when recovery has no sleep values")
    func sleepFallbackIsUsed() {
        let input = FitnessAgeInput(
            profile: FitnessAgeProfile(chronologicalAge: 40, biologicalSex: .male),
            metrics: FitnessAgeMetrics(
                restingHeartRate: 58,
                heartRateVariability: 45
            )
        )

        let result = FitnessAgeCalculator().calculate(input)

        #expect(result.domainScores[.recovery]?.keyMetrics["sleepFallback"] == 75)
        #expect(result.domainScores[.recovery]?.keyMetrics["heartRateVariability"] == 45)
        #expect(result.domainScores[.recovery]?.keyMetrics["restingHeartRate"] == 58)
    }

    @Test("opportunistic metrics contribute to their domains")
    func opportunisticMetricsContribute() {
        let input = FitnessAgeInput(
            profile: FitnessAgeProfile(chronologicalAge: 45, biologicalSex: .male),
            metrics: FitnessAgeMetrics(
                standHours: 10,
                sleepingWristTemperatureDeviation: 0,
                bloodGlucose: 96,
                timeInDaylight: 45
            )
        )

        let result = FitnessAgeCalculator().calculate(input)

        #expect(result.domainScores[.activity]?.keyMetrics["standHours"] == 10)
        #expect(result.domainScores[.recovery]?.keyMetrics["sleepingWristTemperatureDeviation"] == 0)
        #expect(result.domainScores[.bodyComposition]?.keyMetrics["bloodGlucose"] == 96)
        #expect(result.domainScores[.lifestyle]?.keyMetrics["timeInDaylight"] == 45)
    }

    @Test("disabled metric ids are removed before scoring")
    func disabledMetricIdsAreRemovedBeforeScoring() {
        let input = FitnessAgeInput(
            profile: FitnessAgeProfile(
                chronologicalAge: 45,
                biologicalSex: .male,
                disabledMetricIds: ["vo2max", "blood_glucose", "time_in_daylight"]
            ),
            metrics: FitnessAgeMetrics(
                vo2Max: 45,
                stepCount: 8_000,
                bloodGlucose: 96,
                timeInDaylight: 45
            )
        )

        let result = FitnessAgeCalculator().calculate(input)

        #expect(result.domainScores[.cardiovascular]?.keyMetrics["vo2Max"] == nil)
        #expect(result.domainScores[.activity]?.keyMetrics["stepCount"] == 8_000)
        #expect(result.domainScores[.bodyComposition]?.keyMetrics["bloodGlucose"] == nil)
        #expect(result.domainScores[.lifestyle]?.keyMetrics["timeInDaylight"] == nil)
    }

    @Test("disabled sleep metric does not add synthetic sleep fallback")
    func disabledSleepMetricDoesNotAddSyntheticSleepFallback() {
        let input = FitnessAgeInput(
            profile: FitnessAgeProfile(
                chronologicalAge: 45,
                biologicalSex: .male,
                disabledMetricIds: ["sleep"]
            ),
            metrics: FitnessAgeMetrics(
                restingHeartRate: 58,
                heartRateVariability: 45
            )
        )

        let result = FitnessAgeCalculator().calculate(input)

        #expect(result.domainScores[.recovery]?.keyMetrics["sleepFallback"] == nil)
        #expect(result.domainScores[.recovery]?.keyMetrics["heartRateVariability"] == 45)
        #expect(result.domainScores[.recovery]?.keyMetrics["restingHeartRate"] == 58)
    }

    @Test("excluded domains are removed from results")
    func excludedDomainsAreRemovedFromResults() {
        let input = FitnessAgeInput(
            profile: FitnessAgeProfile(
                chronologicalAge: 45,
                biologicalSex: .male,
                excludedDomains: [.activity]
            ),
            metrics: FitnessAgeMetrics(
                restingHeartRate: 58,
                heartRateVariability: 45,
                stepCount: 8_000,
                activeEnergy: 500
            )
        )

        let result = FitnessAgeCalculator().calculate(input)

        #expect(result.domainScores[.activity] == nil)
        #expect(result.domainScores[.recovery] != nil)
    }

    @Test("configured domain weights influence overall score")
    func configuredDomainWeightsInfluenceOverallScore() throws {
        let input = FitnessAgeInput(
            profile: FitnessAgeProfile(
                chronologicalAge: 45,
                biologicalSex: .male,
                excludedDomains: [.recovery, .bodyComposition, .lifestyle]
            ),
            metrics: FitnessAgeMetrics(
                vo2Max: 50,
                stepCount: 3_000
            ),
            configuration: FitnessAgeConfiguration(
                domainWeights: [
                    .cardiovascular: 1.0,
                    .activity: 0.0,
                    .recovery: 0.0,
                    .bodyComposition: 0.0,
                    .lifestyle: 0.0
                ]
            )
        )

        let result = FitnessAgeCalculator().calculate(input)
        let cardiovascularScore = try #require(result.domainScores[.cardiovascular]?.score)

        #expect(abs(result.overallScore - cardiovascularScore) < 0.0001)
    }

    @Test("excellent domains do not boost weaker domain scores")
    func excellentDomainsDoNotBoostWeakerDomainScores() throws {
        let profile = FitnessAgeProfile(
            chronologicalAge: 45,
            biologicalSex: .male,
            excludedDomains: [.recovery, .bodyComposition, .lifestyle]
        )
        let weakActivityMetrics = FitnessAgeMetrics(stepCount: 3_000)
        let weakActivityWithExcellentCardio = FitnessAgeMetrics(
            vo2Max: 50,
            stepCount: 3_000
        )

        let activityOnly = FitnessAgeCalculator().calculate(
            FitnessAgeInput(
                profile: profile,
                metrics: weakActivityMetrics
            )
        )
        let withExcellentCardio = FitnessAgeCalculator().calculate(
            FitnessAgeInput(
                profile: profile,
                metrics: weakActivityWithExcellentCardio
            )
        )

        let activityOnlyScore = try #require(activityOnly.domainScores[.activity]?.score)
        let activityScoreWithExcellentCardio = try #require(withExcellentCardio.domainScores[.activity]?.score)

        #expect(abs(activityOnlyScore - activityScoreWithExcellentCardio) < 0.0001)
    }
}
