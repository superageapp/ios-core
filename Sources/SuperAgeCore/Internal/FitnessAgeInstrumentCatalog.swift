import Foundation

/// The physical instruments the domain scorers can observe, used to report `metricsUsed`
/// and `totalPossibleMetrics` truthfully.
///
/// One slot per physical instrument: the blood pressure pair is one slot, the three sleep
/// inputs share one slot, and the step- and energy-derived lifestyle composites count
/// toward their source step and energy instruments instead of adding slots of their own.
/// Derived key metrics (`meanArterialPressure`, `sleepFallback`) never count as observed
/// instruments.
enum FitnessAgeInstrumentCatalog {
    struct Slot {
        /// The domains this instrument can feed; the slot stays observable while any of
        /// them is not excluded.
        let domains: Set<FitnessAgeDomain>
        /// Disabled metric IDs that remove this slot; the slot is unavailable when any of
        /// them is disabled for the input.
        let disablingMetricIds: Set<String>
        /// The `keyMetrics` keys whose presence proves this instrument was observed.
        let keyMetricKeys: Set<String>
    }

    static let slots: [Slot] = [
        Slot(domains: [.cardiovascular], disablingMetricIds: ["max_heart_rate"], keyMetricKeys: ["maxHeartRate"]),
        Slot(domains: [.cardiovascular], disablingMetricIds: ["vo2max"], keyMetricKeys: ["vo2Max"]),
        Slot(domains: [.cardiovascular], disablingMetricIds: ["average_heart_rate"], keyMetricKeys: ["averageHeartRate"]),
        Slot(domains: [.cardiovascular], disablingMetricIds: ["blood_pressure"], keyMetricKeys: ["systolicBP", "diastolicBP"]),
        Slot(domains: [.cardiovascular], disablingMetricIds: ["respiratory_rate"], keyMetricKeys: ["respiratoryRate"]),
        Slot(domains: [.cardiovascular], disablingMetricIds: ["oxygen_saturation"], keyMetricKeys: ["oxygenSaturation"]),
        Slot(domains: [.cardiovascular], disablingMetricIds: ["walking_heart_rate_average"], keyMetricKeys: ["walkingHeartRateAverage"]),
        Slot(
            domains: [.activity, .lifestyle],
            disablingMetricIds: ["steps"],
            keyMetricKeys: ["stepCount", "movement_regularity", "activity_consistency", "sedentary_score"]
        ),
        Slot(
            domains: [.activity, .lifestyle],
            disablingMetricIds: ["calories"],
            keyMetricKeys: ["activeEnergy", "activity_consistency", "sedentary_score"]
        ),
        Slot(domains: [.activity], disablingMetricIds: ["exercise_time"], keyMetricKeys: ["exerciseTime"]),
        Slot(domains: [.activity], disablingMetricIds: ["flights_climbed"], keyMetricKeys: ["flightsClimbed"]),
        Slot(domains: [.activity], disablingMetricIds: ["six_minute_walk_distance"], keyMetricKeys: ["sixMinuteWalkTestDistance"]),
        Slot(domains: [.activity], disablingMetricIds: ["stand_hours"], keyMetricKeys: ["standHours"]),
        Slot(domains: [.activity], disablingMetricIds: ["stair_ascent_speed"], keyMetricKeys: ["stairAscentSpeed"]),
        Slot(domains: [.activity], disablingMetricIds: ["stair_descent_speed"], keyMetricKeys: ["stairDescentSpeed"]),
        Slot(domains: [.recovery], disablingMetricIds: ["sleep"], keyMetricKeys: ["sleepScore", "sleepHours"]),
        Slot(domains: [.recovery], disablingMetricIds: [], keyMetricKeys: ["heartRateVariability"]),
        Slot(domains: [.recovery], disablingMetricIds: ["resting_heartrate"], keyMetricKeys: ["restingHeartRate"]),
        Slot(domains: [.recovery], disablingMetricIds: ["sleeping_wrist_temperature"], keyMetricKeys: ["sleepingWristTemperatureDeviation"]),
        Slot(domains: [.bodyComposition], disablingMetricIds: ["bmi"], keyMetricKeys: ["bodyMassIndex"]),
        Slot(domains: [.bodyComposition], disablingMetricIds: ["body_fat"], keyMetricKeys: ["bodyFatPercentage"]),
        Slot(domains: [.bodyComposition], disablingMetricIds: ["lean_mass", "height"], keyMetricKeys: ["leanMassIndex"]),
        Slot(domains: [.bodyComposition], disablingMetricIds: ["blood_glucose"], keyMetricKeys: ["bloodGlucose"]),
        Slot(domains: [.lifestyle], disablingMetricIds: ["smoking_status"], keyMetricKeys: ["smoking_status"]),
        Slot(domains: [.lifestyle], disablingMetricIds: ["walking_steadiness"], keyMetricKeys: ["walking_steadiness"]),
        Slot(domains: [.lifestyle], disablingMetricIds: ["walking_asymmetry"], keyMetricKeys: ["walking_asymmetry"]),
        Slot(domains: [.lifestyle], disablingMetricIds: ["double_support"], keyMetricKeys: ["double_support"]),
        Slot(domains: [.lifestyle], disablingMetricIds: ["time_in_daylight"], keyMetricKeys: ["timeInDaylight"])
    ]

    /// The number of instruments that remain observable for a profile after removing
    /// excluded domains and disabled metric IDs.
    static func possibleInstrumentCount(profile: FitnessAgeProfile) -> Int {
        let disabled = profile.effectiveDisabledMetricIds

        return slots.filter { slot in
            !slot.domains.isSubset(of: profile.excludedDomains)
                && slot.disablingMetricIds.isDisjoint(with: disabled)
        }.count
    }

    /// The number of distinct instruments observed in the given domain scores.
    static func observedInstrumentCount(
        domainScores: [FitnessAgeDomain: FitnessAgeDomainScore]
    ) -> Int {
        let observedKeys = Set(domainScores.values.flatMap { $0.keyMetrics.keys })

        return slots.filter { slot in
            !slot.keyMetricKeys.isDisjoint(with: observedKeys)
        }.count
    }
}
