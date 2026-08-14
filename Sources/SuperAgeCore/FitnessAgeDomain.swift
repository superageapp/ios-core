import Foundation

/// The Fitness Age scoring domains; see Docs/METHODOLOGY.md for the default weights.
public enum FitnessAgeDomain: String, CaseIterable, Codable, Sendable {
    case cardiovascular
    case activity
    case recovery
    case bodyComposition
    case lifestyle

    public var defaultWeight: Double {
        switch self {
        case .cardiovascular:
            0.28
        case .activity:
            0.24
        case .recovery:
            0.15
        case .bodyComposition:
            0.18
        case .lifestyle:
            0.15
        }
    }
}
