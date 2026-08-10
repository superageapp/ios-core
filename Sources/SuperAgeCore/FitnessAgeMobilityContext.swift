import Foundation

/// Declares whether step and gait detection can produce valid values for the person being scored.
///
/// This is a measurement-applicability input, not a clinical classification and not a
/// diagnosis. Many Apple Health-derived metrics are produced by step and gait detection.
/// When that detection cannot run, the host does not receive a low value, it receives a
/// value that does not describe the person: wearables have been reported as recording zero
/// steps for someone walking with a walker. Without this declaration the calculator cannot
/// tell "the instrument did not apply" from "the person was inactive".
///
/// The context never changes a threshold, a curve, a weight, or a score. It only removes
/// metrics that cannot be observed, after which the existing domain normalization divides
/// by the observed local weights that remain.
public enum FitnessAgeMobilityContext: String, Codable, Sendable, CaseIterable {
    /// Walks unaided, or with a cane.
    ///
    /// Every movement instrument applies. Cane use belongs here: wrist step counting during
    /// cane use has been reported at roughly two percent mean error, which is measurement
    /// noise rather than an applicability boundary.
    case ambulatory

    /// Uses a mobility aid that bears weight, such as a walker or crutches, or uses wheeled mobility.
    ///
    /// Step and gait detection does not produce valid values for these movement patterns, so
    /// step-derived and gait-derived instruments do not apply. Hourly movement is still
    /// observable: on Apple Watch the Stand ring becomes a Roll ring in wheelchair mode and
    /// counts hours containing at least a minute of movement, so `stand_hours` is retained.
    case assistedMobility
}

public extension FitnessAgeMobilityContext {
    /// Metric IDs whose observation depends on step or gait detection this context does not produce.
    ///
    /// These IDs are unioned with `FitnessAgeProfile.disabledMetricIds` before scoring, so
    /// they follow exactly the same documented removal path as a host-disabled metric.
    var inapplicableMetricIds: Set<String> {
        switch self {
        case .ambulatory:
            return []
        case .assistedMobility:
            return Self.stepAndGaitDerivedMetricIds
        }
    }

    /// Instruments produced by step counting or gait characterization.
    static let stepAndGaitDerivedMetricIds: Set<String> = [
        "steps",
        "six_minute_walk_distance",
        "flights_climbed",
        "stair_ascent_speed",
        "stair_descent_speed",
        "walking_heart_rate_average",
        "walking_steadiness",
        "walking_asymmetry",
        "double_support"
    ]
}
