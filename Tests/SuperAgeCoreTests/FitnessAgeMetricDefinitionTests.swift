import Testing
import SuperAgeCore

@Suite("FitnessAge metric definitions")
struct FitnessAgeMetricDefinitionTests {
    @Test("default domain weights remain normalized and explicit")
    func defaultDomainWeightsRemainNormalizedAndExplicit() {
        let expected: [FitnessAgeDomain: Double] = [
            .cardiovascular: 0.28,
            .activity: 0.24,
            .recovery: 0.15,
            .bodyComposition: 0.18,
            .lifestyle: 0.15
        ]

        #expect(FitnessAgeConfiguration.default.domainWeights == expected)

        let totalWeight = expected.values.reduce(0.0, +)
        #expect(abs(totalWeight - 1.0) < 0.0001)

        for domain in FitnessAgeDomain.allCases {
            #expect(domain.defaultWeight == expected[domain])
        }
    }

    @Test("opportunistic Apple Health metrics keep current weights")
    func opportunisticMetricsKeepCurrentWeights() {
        let expected: [String: (FitnessAgeDomain, Double)] = [
            "walking_heart_rate_average": (.cardiovascular, 0.10),
            "six_minute_walk_distance": (.activity, 0.18),
            "stand_hours": (.activity, 0.08),
            "stair_ascent_speed": (.activity, 0.04),
            "stair_descent_speed": (.activity, 0.04),
            "sleeping_wrist_temperature": (.recovery, 0.15),
            "blood_glucose": (.bodyComposition, 0.15),
            "time_in_daylight": (.lifestyle, 0.10)
        ]

        #expect(Set(FitnessAgeMetricDefinitions.opportunisticAppleHealthMetrics.map(\.metricId)) == Set(expected.keys))

        for (metricId, expectation) in expected {
            let definition = FitnessAgeMetricDefinitions.definition(for: metricId)
            #expect(definition?.domain == expectation.0)
            #expect(definition?.nominalLocalWeight == expectation.1)
            #expect(definition?.affectsAlgorithm == true)
            #expect(definition?.requiresObservedData == true)
        }
    }

    @Test("disabled metrics are removed before scoring")
    func disabledMetricsAreRemovedBeforeScoring() {
        var metrics = FitnessAgeMetrics(
            vo2Max: 45,
            stepCount: 10_000,
            bloodGlucose: 96,
            timeInDaylight: 45
        )

        metrics.applyDisabledMetricIds(["vo2max", "blood_glucose", "time_in_daylight"])

        #expect(metrics.vo2Max == nil)
        #expect(metrics.stepCount == 10_000)
        #expect(metrics.bloodGlucose == nil)
        #expect(metrics.timeInDaylight == nil)
    }

    @Test("SuperAge app filtering map removes supported fields")
    func superAgeAppFilteringMapRemovesSupportedFields() {
        var metrics = FitnessAgeMetrics(
            restingHeartRate: 61,
            vo2Max: 44,
            averageHeartRate: 72,
            respiratoryRate: 15,
            systolicBloodPressure: 118,
            diastolicBloodPressure: 76,
            oxygenSaturation: 98,
            maxHeartRate: 182,
            walkingHeartRateAverage: 91,
            stepCount: 9_500,
            activeEnergy: 540,
            exerciseTime: 42,
            flightsClimbed: 12,
            sixMinuteWalkTestDistance: 470,
            standHours: 10,
            stairAscentSpeed: 0.52,
            stairDescentSpeed: 0.47,
            sleepHours: 7.4,
            sleepScore: 82,
            sleepingWristTemperatureDeviation: 0.1,
            bodyFatPercentage: 18,
            leanBodyMass: 62,
            height: 178,
            bodyMassIndex: 23.4,
            bloodGlucose: 92,
            walkingSteadiness: 0.93,
            walkingAsymmetry: 2.1,
            walkingDoubleSupport: 24,
            isSmoker: false,
            timeInDaylight: 48
        )

        metrics.applyDisabledMetricIds([
            "resting_heartrate",
            "vo2max",
            "max_heart_rate",
            "respiratory_rate",
            "oxygen_saturation",
            "average_heart_rate",
            "blood_pressure",
            "walking_heart_rate_average",
            "steps",
            "calories",
            "exercise_time",
            "flights_climbed",
            "six_minute_walk_distance",
            "stand_hours",
            "stair_ascent_speed",
            "stair_descent_speed",
            "sleep",
            "sleeping_wrist_temperature",
            "bmi",
            "body_fat",
            "lean_mass",
            "height",
            "blood_glucose",
            "smoking_status",
            "walking_steadiness",
            "walking_asymmetry",
            "double_support",
            "time_in_daylight"
        ])

        #expect(metrics.restingHeartRate == nil)
        #expect(metrics.vo2Max == nil)
        #expect(metrics.maxHeartRate == nil)
        #expect(metrics.respiratoryRate == nil)
        #expect(metrics.oxygenSaturation == nil)
        #expect(metrics.averageHeartRate == nil)
        #expect(metrics.systolicBloodPressure == nil)
        #expect(metrics.diastolicBloodPressure == nil)
        #expect(metrics.walkingHeartRateAverage == nil)
        #expect(metrics.stepCount == nil)
        #expect(metrics.activeEnergy == nil)
        #expect(metrics.exerciseTime == nil)
        #expect(metrics.flightsClimbed == nil)
        #expect(metrics.sixMinuteWalkTestDistance == nil)
        #expect(metrics.standHours == nil)
        #expect(metrics.stairAscentSpeed == nil)
        #expect(metrics.stairDescentSpeed == nil)
        #expect(metrics.sleepHours == nil)
        #expect(metrics.sleepScore == nil)
        #expect(metrics.sleepingWristTemperatureDeviation == nil)
        #expect(metrics.bodyMassIndex == nil)
        #expect(metrics.bodyFatPercentage == nil)
        #expect(metrics.leanBodyMass == nil)
        #expect(metrics.height == nil)
        #expect(metrics.bloodGlucose == nil)
        #expect(metrics.isSmoker == nil)
        #expect(metrics.walkingSteadiness == nil)
        #expect(metrics.walkingAsymmetry == nil)
        #expect(metrics.walkingDoubleSupport == nil)
        #expect(metrics.timeInDaylight == nil)
    }

    @Test("filtering disabled metrics leaves original value unchanged")
    func filteringDisabledMetricsLeavesOriginalValueUnchanged() {
        let original = FitnessAgeMetrics(
            restingHeartRate: 58,
            stepCount: 10_000,
            bloodGlucose: 96
        )

        let filtered = original.filteringDisabledMetricIds(["resting_heartrate", "blood_glucose"])

        #expect(original.restingHeartRate == 58)
        #expect(original.bloodGlucose == 96)
        #expect(filtered.restingHeartRate == nil)
        #expect(filtered.stepCount == 10_000)
        #expect(filtered.bloodGlucose == nil)
    }

    @Test("unknown disabled metric IDs are ignored")
    func unknownDisabledMetricIdsAreIgnored() {
        var metrics = FitnessAgeMetrics(
            restingHeartRate: 58,
            stepCount: 10_000
        )

        metrics.applyDisabledMetricIds(["not_a_supported_metric"])

        #expect(metrics.restingHeartRate == 58)
        #expect(metrics.stepCount == 10_000)
    }
}
