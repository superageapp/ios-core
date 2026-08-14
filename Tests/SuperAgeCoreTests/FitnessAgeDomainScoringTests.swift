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

    @Test("input with no observed metrics maps to chronological age")
    func inputWithNoObservedMetricsMapsToChronologicalAge() {
        let result = FitnessAgeCalculator().calculate(
            FitnessAgeInput(
                profile: FitnessAgeProfile(chronologicalAge: 42, biologicalSex: .male),
                metrics: FitnessAgeMetrics()
            )
        )

        #expect(result.domainScores.isEmpty)
        #expect(result.overallScore == 50)
        #expect(result.fitnessAge == 42)
        #expect(result.metricsUsed == 0)
        #expect(abs(result.confidence - 0.28) < 0.0001)
    }

    @Test("profiles below adult calibration age receive the neutral result")
    func profilesBelowAdultCalibrationAgeReceiveTheNeutralResult() {
        for age in [0, 10, 17] {
            let result = FitnessAgeCalculator().calculate(
                FitnessAgeInput(
                    profile: FitnessAgeProfile(chronologicalAge: age, biologicalSex: .male),
                    metrics: FitnessAgeMetrics(restingHeartRate: 60, stepCount: 9_000)
                )
            )

            #expect(result.fitnessAge == Double(age))
            #expect(result.overallScore == 50)
            #expect(result.confidence == 0.1)
            #expect(result.domainScores.isEmpty)
        }
    }

    @Test("a domain whose observed metrics score zero stays in the result")
    func domainWhoseObservedMetricsScoreZeroStaysInTheResult() throws {
        let withZeroScoringBodyFat = FitnessAgeCalculator().calculate(
            FitnessAgeInput(
                profile: FitnessAgeProfile(chronologicalAge: 42, biologicalSex: .male),
                metrics: FitnessAgeMetrics(stepCount: 9_000, bodyFatPercentage: 60)
            )
        )
        let withHighBodyFat = FitnessAgeCalculator().calculate(
            FitnessAgeInput(
                profile: FitnessAgeProfile(chronologicalAge: 42, biologicalSex: .male),
                metrics: FitnessAgeMetrics(stepCount: 9_000, bodyFatPercentage: 55)
            )
        )

        let zeroScore = try #require(withZeroScoringBodyFat.domainScores[.bodyComposition]?.score)
        #expect(zeroScore == 0)
        #expect(withZeroScoringBodyFat.overallScore <= withHighBodyFat.overallScore)
        #expect(withZeroScoringBodyFat.fitnessAge >= withHighBodyFat.fitnessAge)
    }

    @Test("supplied zero values do not change confidence or scores")
    func suppliedZeroValuesDoNotChangeConfidenceOrScores() {
        let base = FitnessAgeInput(
            profile: FitnessAgeProfile(chronologicalAge: 40, biologicalSex: .male),
            metrics: FitnessAgeMetrics(
                restingHeartRate: 58,
                heartRateVariability: 45,
                maxHeartRate: 180,
                activeEnergy: 500
            )
        )
        var zeroPadded = base
        zeroPadded.metrics.vo2Max = 0
        zeroPadded.metrics.stepCount = 0
        zeroPadded.metrics.sleepScore = 0

        let baseResult = FitnessAgeCalculator().calculate(base)
        let zeroPaddedResult = FitnessAgeCalculator().calculate(zeroPadded)

        #expect(baseResult.confidence == zeroPaddedResult.confidence)
        #expect(baseResult.overallScore == zeroPaddedResult.overallScore)
        #expect(baseResult.fitnessAge == zeroPaddedResult.fitnessAge)
    }

    @Test("configured domain weights are capped at 0.40 during aggregation")
    func configuredDomainWeightsAreCappedDuringAggregation() throws {
        let metrics = FitnessAgeMetrics(
            vo2Max: 50,
            stepCount: 3_000
        )
        let result = FitnessAgeCalculator().calculate(
            FitnessAgeInput(
                profile: FitnessAgeProfile(chronologicalAge: 45, biologicalSex: .male),
                metrics: metrics,
                configuration: FitnessAgeConfiguration(
                    domainWeights: [
                        .cardiovascular: 5.0,
                        .activity: 0.24,
                        .recovery: 0.0,
                        .bodyComposition: 0.0,
                        .lifestyle: 0.0
                    ]
                )
            )
        )

        let cardiovascular = try #require(result.domainScores[.cardiovascular]?.score)
        let activity = try #require(result.domainScores[.activity]?.score)
        let cappedExpectation = (cardiovascular * 0.40 + activity * 0.24) / 0.64
        let uncappedExpectation = (cardiovascular * 5.0 + activity * 0.24) / 5.24

        #expect(abs(result.overallScore - cappedExpectation) < 0.0001)
        #expect(abs(result.overallScore - uncappedExpectation) > 0.1)
    }

    @Test("instrument counts deduplicate composite and paired inputs")
    func instrumentCountsDeduplicateCompositeAndPairedInputs() {
        let stepsOnly = FitnessAgeCalculator().calculate(
            FitnessAgeInput(
                profile: FitnessAgeProfile(chronologicalAge: 42, biologicalSex: .male),
                metrics: FitnessAgeMetrics(stepCount: 9_000)
            )
        )
        let stepsAndEnergy = FitnessAgeCalculator().calculate(
            FitnessAgeInput(
                profile: FitnessAgeProfile(chronologicalAge: 42, biologicalSex: .male),
                metrics: FitnessAgeMetrics(stepCount: 9_000, activeEnergy: 500)
            )
        )
        let bloodPressurePair = FitnessAgeCalculator().calculate(
            FitnessAgeInput(
                profile: FitnessAgeProfile(chronologicalAge: 42, biologicalSex: .male),
                metrics: FitnessAgeMetrics(systolicBloodPressure: 118, diastolicBloodPressure: 76)
            )
        )

        // The lifestyle composites derived from steps and energy count toward their
        // source instruments, and the blood pressure pair is one instrument.
        #expect(stepsOnly.metricsUsed == 1)
        #expect(stepsAndEnergy.metricsUsed == 2)
        #expect(bloodPressurePair.metricsUsed == 1)
        #expect(stepsOnly.totalPossibleMetrics == 28)
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
