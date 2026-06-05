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
    public var excludedDomains: Set<FitnessAgeDomain>
    public var focusDomains: Set<FitnessAgeDomain>
    public var disabledMetricIds: Set<String>

    public var isValidForCalculation: Bool {
        chronologicalAge > 0
    }

    public init(
        chronologicalAge: Int,
        biologicalSex: FitnessAgeBiologicalSex,
        excludedDomains: Set<FitnessAgeDomain> = [],
        focusDomains: Set<FitnessAgeDomain> = [],
        disabledMetricIds: Set<String> = []
    ) {
        self.chronologicalAge = chronologicalAge
        self.biologicalSex = biologicalSex
        self.excludedDomains = excludedDomains
        self.focusDomains = focusDomains
        self.disabledMetricIds = disabledMetricIds
    }

    private enum CodingKeys: String, CodingKey {
        case chronologicalAge
        case biologicalSex
        case excludedDomains
        case focusDomains
        case disabledMetricIds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        chronologicalAge = try container.decodeIfPresent(Int.self, forKey: .chronologicalAge) ?? 0
        biologicalSex = try container.decodeIfPresent(FitnessAgeBiologicalSex.self, forKey: .biologicalSex) ?? .unknown
        excludedDomains = try container.decodeIfPresent(Set<FitnessAgeDomain>.self, forKey: .excludedDomains) ?? []
        focusDomains = try container.decodeIfPresent(Set<FitnessAgeDomain>.self, forKey: .focusDomains) ?? []
        disabledMetricIds = try container.decodeIfPresent(Set<String>.self, forKey: .disabledMetricIds) ?? []
    }
}
