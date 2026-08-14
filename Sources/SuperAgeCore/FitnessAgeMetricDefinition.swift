import Foundation

public struct FitnessAgeMetricDefinition: Sendable, Equatable {
    public let metricId: String
    public let domain: FitnessAgeDomain
    public let nominalLocalWeight: Double
    public let affectsAlgorithm: Bool
    public let requiresObservedData: Bool

    public init(
        metricId: String,
        domain: FitnessAgeDomain,
        nominalLocalWeight: Double,
        affectsAlgorithm: Bool,
        requiresObservedData: Bool
    ) {
        self.metricId = metricId
        self.domain = domain
        self.nominalLocalWeight = nominalLocalWeight
        self.affectsAlgorithm = affectsAlgorithm
        self.requiresObservedData = requiresObservedData
    }
}

public enum FitnessAgeMetricDefinitions {
    public static let opportunisticAppleHealthMetrics: [FitnessAgeMetricDefinition] = [
        .init(metricId: "walking_heart_rate_average", domain: .cardiovascular, nominalLocalWeight: 0.10, affectsAlgorithm: true, requiresObservedData: true),
        .init(metricId: "six_minute_walk_distance", domain: .activity, nominalLocalWeight: 0.18, affectsAlgorithm: true, requiresObservedData: true),
        .init(metricId: "stand_hours", domain: .activity, nominalLocalWeight: 0.08, affectsAlgorithm: true, requiresObservedData: true),
        .init(metricId: "stair_ascent_speed", domain: .activity, nominalLocalWeight: 0.04, affectsAlgorithm: true, requiresObservedData: true),
        .init(metricId: "stair_descent_speed", domain: .activity, nominalLocalWeight: 0.04, affectsAlgorithm: true, requiresObservedData: true),
        .init(metricId: "sleeping_wrist_temperature", domain: .recovery, nominalLocalWeight: 0.15, affectsAlgorithm: true, requiresObservedData: true),
        .init(metricId: "blood_glucose", domain: .bodyComposition, nominalLocalWeight: 0.15, affectsAlgorithm: true, requiresObservedData: true),
        .init(metricId: "time_in_daylight", domain: .lifestyle, nominalLocalWeight: 0.10, affectsAlgorithm: true, requiresObservedData: true)
    ]

    public static func definition(for metricId: String) -> FitnessAgeMetricDefinition? {
        opportunisticAppleHealthMetrics.first { $0.metricId == metricId }
    }
}
