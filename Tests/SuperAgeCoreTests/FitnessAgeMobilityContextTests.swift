import Testing
import Foundation
import SuperAgeCore

@Suite("FitnessAge mobility context")
struct FitnessAgeMobilityContextTests {
    private static func metrics() -> FitnessAgeMetrics {
        FitnessAgeMetrics(
            restingHeartRate: 58,
            vo2Max: 45,
            heartRateVariability: 50,
            respiratoryRate: 15,
            walkingHeartRateAverage: 100,
            stepCount: 10_000,
            activeEnergy: 600,
            exerciseTime: 45,
            flightsClimbed: 10,
            sixMinuteWalkTestDistance: 480,
            standHours: 12,
            stairAscentSpeed: 0.8,
            stairDescentSpeed: 0.85,
            sleepHours: 7.5,
            bodyMassIndex: 23.5,
            walkingSteadiness: 0.9,
            walkingAsymmetry: 1.5,
            walkingDoubleSupport: 22,
            isSmoker: false,
            timeInDaylight: 60
        )
    }

    private static func profile(
        _ context: FitnessAgeMobilityContext
    ) -> FitnessAgeProfile {
        FitnessAgeProfile(
            chronologicalAge: 42,
            biologicalSex: .male,
            mobilityContext: context
        )
    }

    @Test("ambulatory is the default and leaves results unchanged")
    func ambulatoryIsDefaultAndDoesNotChangeResults() {
        let implicitProfile = FitnessAgeProfile(chronologicalAge: 42, biologicalSex: .male)
        #expect(implicitProfile.mobilityContext == .ambulatory)
        #expect(implicitProfile.effectiveDisabledMetricIds.isEmpty)

        let implicit = FitnessAgeCalculator().calculate(
            FitnessAgeInput(profile: implicitProfile, metrics: Self.metrics())
        )
        let explicit = FitnessAgeCalculator().calculate(
            FitnessAgeInput(profile: Self.profile(.ambulatory), metrics: Self.metrics())
        )

        #expect(implicit == explicit)
    }

    @Test("assisted ambulation removes step and gait derived instruments but keeps standing")
    func assistedAmbulationRemovesStepAndGaitDerivedInstruments() {
        let removed = FitnessAgeMobilityContext.assistedAmbulation.inapplicableMetricIds

        #expect(removed == [
            "steps",
            "six_minute_walk_distance",
            "flights_climbed",
            "stair_ascent_speed",
            "stair_descent_speed",
            "walking_heart_rate_average",
            "walking_steadiness",
            "walking_asymmetry",
            "double_support"
        ])
        // Standing remains observable with a walker or crutches.
        #expect(!removed.contains("stand_hours"))
    }

    @Test("non ambulatory additionally removes standing instruments")
    func nonAmbulatoryAdditionallyRemovesStandingInstruments() {
        let removed = FitnessAgeMobilityContext.nonAmbulatory.inapplicableMetricIds

        #expect(removed.isSuperset(of: FitnessAgeMobilityContext.assistedAmbulation.inapplicableMetricIds))
        #expect(removed.contains("stand_hours"))
        #expect(removed.subtracting(
            FitnessAgeMobilityContext.assistedAmbulation.inapplicableMetricIds
        ) == ["stand_hours"])
    }

    @Test("cane use is not an applicability boundary")
    func caneUseIsNotAnApplicabilityBoundary() {
        // Wrist step counting during cane use is reported at roughly two percent mean
        // error, which is noise, not inapplicability. Cane users are `ambulatory`.
        #expect(FitnessAgeMobilityContext.ambulatory.inapplicableMetricIds.isEmpty)
    }

    @Test("non ambulatory keeps every domain scorable on applicable instruments")
    func nonAmbulatoryKeepsEveryDomainScorable() {
        let result = FitnessAgeCalculator().calculate(
            FitnessAgeInput(profile: Self.profile(.nonAmbulatory), metrics: Self.metrics())
        )

        // Activity survives on active energy and exercise time; lifestyle on smoking
        // status and time in daylight. No domain collapses because of the context alone.
        #expect(result.domainScores[.cardiovascular] != nil)
        #expect(result.domainScores[.activity] != nil)
        #expect(result.domainScores[.recovery] != nil)
        #expect(result.domainScores[.bodyComposition] != nil)
        #expect(result.domainScores[.lifestyle] != nil)
    }

    @Test("inapplicable instruments are removed rather than scored as zero")
    func inapplicableInstrumentsAreRemovedRatherThanScoredAsZero() {
        let profile = Self.profile(.nonAmbulatory)

        // Same person, same applicable observations: one input simply omits the metrics
        // the context cannot observe. Removing an instrument must be identical to never
        // having supplied it, otherwise absence would be read as a low result.
        var applicableOnly = Self.metrics()
        applicableOnly.stepCount = nil
        applicableOnly.flightsClimbed = nil
        applicableOnly.sixMinuteWalkTestDistance = nil
        applicableOnly.standHours = nil
        applicableOnly.stairAscentSpeed = nil
        applicableOnly.stairDescentSpeed = nil
        applicableOnly.walkingHeartRateAverage = nil
        applicableOnly.walkingSteadiness = nil
        applicableOnly.walkingAsymmetry = nil
        applicableOnly.walkingDoubleSupport = nil

        let contextDriven = FitnessAgeCalculator().calculate(
            FitnessAgeInput(profile: profile, metrics: Self.metrics())
        )
        let omitted = FitnessAgeCalculator().calculate(
            FitnessAgeInput(
                profile: FitnessAgeProfile(chronologicalAge: 42, biologicalSex: .male),
                metrics: applicableOnly
            )
        )

        #expect(abs(contextDriven.overallScore - omitted.overallScore) < 0.0001)
        #expect(abs(contextDriven.fitnessAge - omitted.fitnessAge) < 0.0001)
    }

    @Test("context composes with host disabled metric ids")
    func contextComposesWithHostDisabledMetricIds() {
        let profile = FitnessAgeProfile(
            chronologicalAge: 42,
            biologicalSex: .male,
            disabledMetricIds: ["vo2max"],
            mobilityContext: .nonAmbulatory
        )

        #expect(profile.effectiveDisabledMetricIds.contains("vo2max"))
        #expect(profile.effectiveDisabledMetricIds.contains("steps"))
        #expect(profile.disabledMetricIds == ["vo2max"])
    }

    @Test("profile decoding defaults mobility context to ambulatory")
    func profileDecodingDefaultsMobilityContextToAmbulatory() throws {
        let legacy = Data(#"{"chronologicalAge":42,"biologicalSex":"male"}"#.utf8)
        let decoded = try JSONDecoder().decode(FitnessAgeProfile.self, from: legacy)

        #expect(decoded.mobilityContext == .ambulatory)

        let explicit = Data(
            #"{"chronologicalAge":42,"biologicalSex":"male","mobilityContext":"nonAmbulatory"}"#.utf8
        )
        let decodedExplicit = try JSONDecoder().decode(FitnessAgeProfile.self, from: explicit)

        #expect(decodedExplicit.mobilityContext == .nonAmbulatory)
    }

    @Test("profile round trips through Codable")
    func profileRoundTripsThroughCodable() throws {
        let profile = Self.profile(.assistedAmbulation)
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(FitnessAgeProfile.self, from: data)

        #expect(decoded == profile)
    }
}
