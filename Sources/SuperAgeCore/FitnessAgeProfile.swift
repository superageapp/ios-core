import Foundation

public enum FitnessAgeBiologicalSex: String, Codable, Sendable {
    case male
    case female
    case intersex
    case unknown
}

public struct FitnessAgeProfile: Codable, Equatable, Sendable {
    /// Chronological age in whole years.
    public var chronologicalAge: Int
    public var biologicalSex: FitnessAgeBiologicalSex
    /// Domains removed from scoring, aggregation, confidence, and results.
    public var excludedDomains: Set<FitnessAgeDomain>
    /// Domains the host highlights; see the confidence modifiers in Docs/METHODOLOGY.md.
    public var focusDomains: Set<FitnessAgeDomain>
    /// Metric IDs to remove before scoring. See "Recognized disabled metric IDs" in
    /// Docs/METHODOLOGY.md for the exact strings; unrecognized IDs are ignored.
    public var disabledMetricIds: Set<String>

    /// Which movement instruments can be observed for this person.
    ///
    /// Defaults to `.ambulatory`, which applies every metric and leaves results identical
    /// to callers that never set it.
    public var mobilityContext: FitnessAgeMobilityContext

    /// Whether the profile can be scored.
    ///
    /// The algorithm is calibrated for adults. Profiles with a chronological age below 18
    /// are invalid for calculation and receive the neutral low-confidence result instead of
    /// a Fitness Age extrapolated from adult reference curves.
    public var isValidForCalculation: Bool {
        chronologicalAge >= 18
    }

    /// Metric IDs removed before scoring: the host-disabled set plus the metrics that the
    /// declared mobility context cannot observe.
    public var effectiveDisabledMetricIds: Set<String> {
        disabledMetricIds.union(mobilityContext.inapplicableMetricIds)
    }

    public init(
        chronologicalAge: Int,
        biologicalSex: FitnessAgeBiologicalSex,
        excludedDomains: Set<FitnessAgeDomain> = [],
        focusDomains: Set<FitnessAgeDomain> = [],
        disabledMetricIds: Set<String> = [],
        mobilityContext: FitnessAgeMobilityContext = .ambulatory
    ) {
        self.chronologicalAge = chronologicalAge
        self.biologicalSex = biologicalSex
        self.excludedDomains = excludedDomains
        self.focusDomains = focusDomains
        self.disabledMetricIds = disabledMetricIds
        self.mobilityContext = mobilityContext
    }

    private enum CodingKeys: String, CodingKey {
        case chronologicalAge
        case biologicalSex
        case excludedDomains
        case focusDomains
        case disabledMetricIds
        case mobilityContext
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        chronologicalAge = try container.decodeIfPresent(Int.self, forKey: .chronologicalAge) ?? 0
        biologicalSex = try container.decodeIfPresent(FitnessAgeBiologicalSex.self, forKey: .biologicalSex) ?? .unknown
        excludedDomains = try container.decodeIfPresent(Set<FitnessAgeDomain>.self, forKey: .excludedDomains) ?? []
        focusDomains = try container.decodeIfPresent(Set<FitnessAgeDomain>.self, forKey: .focusDomains) ?? []
        disabledMetricIds = try container.decodeIfPresent(Set<String>.self, forKey: .disabledMetricIds) ?? []
        mobilityContext = try container.decodeIfPresent(
            FitnessAgeMobilityContext.self,
            forKey: .mobilityContext
        ) ?? .ambulatory
    }
}
