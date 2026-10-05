import Foundation
import Testing
import SuperAgeCore

@Suite("FitnessAge continuous chronological age")
struct FitnessAgeContinuousAgeTests {
    @Test("fractional outputs match independently blended pinned integer results", arguments: ContinuousAgeFixture.load().cases)
    fileprivate func fractionalOutputsMatchPinnedResults(_ testCase: ContinuousAgeCase) throws {
        let calculator = FitnessAgeCalculator()
        let result = calculator.calculate(testCase.input)
        try assertResultClose(result, testCase.expected, id: testCase.id)

        var anchor = testCase.input
        anchor.profile.chronologicalAge = testCase.lowerExpected.chronologicalAge
        #expect(calculator.calculate(anchor) == testCase.lowerExpected, "\(testCase.id) lower integer parity")
        anchor.profile.chronologicalAge = testCase.upperExpected.chronologicalAge
        #expect(calculator.calculate(anchor) == testCase.upperExpected, "\(testCase.id) upper integer parity")
    }

    @Test("birthday and reference-band transitions are continuous in every mode")
    func birthdayTransitionsAreContinuous() throws {
        let calculator = FitnessAgeCalculator()
        let configurations: [FitnessAgeConfiguration] = [
            .default,
            .compatibilityV1,
            FitnessAgeConfiguration(
                algorithmMode: .custom,
                domainWeights: FitnessAgeConfiguration.default.domainWeights,
                mapping: .init(maximumAgeDelta: 7.5, minimumDisplayAge: 21)
            )
        ]
        let metrics = FitnessAgeMetrics(
            restingHeartRate: 60, vo2Max: 38, heartRateVariability: 25,
            averageHeartRate: 72, respiratoryRate: 16,
            systolicBloodPressure: 128, diastolicBloodPressure: 82,
            oxygenSaturation: 96.5, maxHeartRate: 160,
            stepCount: 7_500, activeEnergy: 320, exerciseTime: 20,
            flightsClimbed: 9, sleepHours: 8.5,
            bodyFatPercentage: 24, leanBodyMass: 58, height: 176, bodyMassIndex: 27,
            walkingSteadiness: 0.84, walkingAsymmetry: 3.2,
            walkingDoubleSupport: 27, isSmoker: false
        )
        for configuration in configurations {
            for sex in [FitnessAgeBiologicalSex.male, .female] {
                for birthday in 19...90 {
                    var input = FitnessAgeInput(
                        profile: .init(chronologicalAge: birthday, biologicalSex: sex, focusDomains: [.activity, .cardiovascular]),
                        metrics: metrics,
                        configuration: configuration
                    )
                    let onBirthday = calculator.calculate(input)
                    input.profile.chronologicalAge = Double(birthday) - 0.000001
                    let before = calculator.calculate(input)
                    input.profile.chronologicalAge = Double(birthday) + 0.000001
                    let after = calculator.calculate(input)
                    #expect(abs(before.fitnessAge - onBirthday.fitnessAge) < 0.0001)
                    #expect(abs(after.fitnessAge - onBirthday.fitnessAge) < 0.0001)
                    #expect(abs(before.confidence - onBirthday.confidence) < 0.000001)
                    #expect(abs(after.confidence - onBirthday.confidence) < 0.000001)
                    #expect(before.metricsUsed == onBirthday.metricsUsed && after.metricsUsed == onBirthday.metricsUsed)
                    for domain in onBirthday.domainScores.keys {
                        let score = try #require(onBirthday.domainScores[domain]?.score)
                        #expect(abs(try #require(before.domainScores[domain]?.score) - score) < 0.0001)
                        #expect(abs(try #require(after.domainScores[domain]?.score) - score) < 0.0001)
                    }
                }
            }
        }
    }

    @Test("fractional profiles preserve adult eligibility and safely reject unsafe ages")
    func adultEligibilityAndInvalidAges() throws {
        let calculator = FitnessAgeCalculator()
        for age in [17.9999, -0.5, Double(Int.max), Double.greatestFiniteMagnitude, .infinity, -.infinity, .nan] {
            let profile = FitnessAgeProfile(chronologicalAge: age, biologicalSex: .male)
            #expect(!profile.isValidForCalculation)
            let result = calculator.calculate(.init(profile: profile, metrics: .init(vo2Max: 45)))
            let neutralAge = age.isFinite ? age : 0
            #expect(result.chronologicalAge == neutralAge)
            #expect(result.fitnessAge == neutralAge)
            #expect(result.domainScores.isEmpty)
            #expect(result.confidence == 0.1 && result.overallScore == 50)
            #expect(result.metricsUsed == 0 && result.totalPossibleMetrics == 0)
            _ = try JSONEncoder().encode(result)
        }
        #expect(FitnessAgeProfile(chronologicalAge: 18.0, biologicalSex: .male).isValidForCalculation)
        #expect(FitnessAgeProfile(chronologicalAge: 18.00001, biologicalSex: .female).isValidForCalculation)
    }

    @Test("integer payloads remain readable and fractional values round trip without rounding")
    func codableCompatibility() throws {
        let profile = try JSONDecoder().decode(
            FitnessAgeProfile.self,
            from: Data(#"{"chronologicalAge":42,"biologicalSex":"female"}"#.utf8)
        )
        #expect(profile.chronologicalAge == 42)
        let oldResult = try JSONDecoder().decode(
            FitnessAgeResult.self,
            from: Data(#"{"fitnessAge":39.5,"chronologicalAge":42,"difference":1234}"#.utf8)
        )
        #expect(oldResult.chronologicalAge == 42 && oldResult.difference == -2.5)
        var input = FitnessAgeInput(profile: profile, metrics: .init(restingHeartRate: 65, stepCount: 4_500))
        input.profile.chronologicalAge = 42.987654321
        let decodedInput = try JSONDecoder().decode(FitnessAgeInput.self, from: JSONEncoder().encode(input))
        #expect(decodedInput == input)
        let result = FitnessAgeCalculator().calculate(input)
        let decodedResult = try JSONDecoder().decode(FitnessAgeResult.self, from: JSONEncoder().encode(result))
        #expect(decodedResult == result)
        #expect(decodedResult.difference == decodedResult.fitnessAge - 42.987654321)
    }

    @Test("relative standing follows the blended domain score across clamp boundaries")
    func relativeStandingUsesBlendedScore() throws {
        let input = FitnessAgeInput(
            profile: .init(chronologicalAge: 30.5, biologicalSex: .male),
            metrics: .init(stepCount: 8_000)
        )
        let result = FitnessAgeCalculator().calculate(input)
        let activity = try #require(result.domainScores[.activity])
        let expected = max(0, min(100, 50 + ((activity.score - 50) / 20) * 30))
        #expect(activity.percentile == expected)
        // At age 30 this score's standing is not saturated; at 31 it is 100.
        // Blending the clamped standings would disagree with this result.
        #expect(activity.percentile != (99.8 + 100) / 2)
        #expect(activity.keyMetrics["stepCount"] == 8_000)
        #expect(result.metricsUsed == 1)
        #expect(result.domainScores[.recovery] == nil)
    }

    @Test("age-derived indicators are continuous while observations stay exact")
    func derivedIndicatorsAndMissingData() throws {
        let testCase = try #require(ContinuousAgeFixture.load().cases.first { $0.id == "assisted_partial_excluded_65" })
        let result = FitnessAgeCalculator().calculate(testCase.input)
        #expect(result.domainScores[.bodyComposition] == nil)
        #expect(result.domainScores[.cardiovascular] == nil)
        #expect(result.domainScores[.recovery]?.keyMetrics["sleepFallback"] == nil)
        #expect(result.domainScores[.recovery]?.keyMetrics["restingHeartRate"] == 60)
        #expect(result.domainScores[.recovery]?.keyMetrics["sleepingWristTemperatureDeviation"] == 0)
        #expect(result.metricsUsed == testCase.lowerExpected.metricsUsed)
        #expect(result.totalPossibleMetrics == testCase.upperExpected.totalPossibleMetrics)
        let focusCase = try #require(ContinuousAgeFixture.load().cases.first { $0.id == "focus_modifier_crossing_30" })
        let focusResult = FitnessAgeCalculator().calculate(focusCase.input)
        #expect(abs(focusResult.confidence - 0.738) < 0.0000000001)
        #expect(focusResult.confidence > focusCase.lowerExpected.confidence)
        #expect(focusResult.confidence < focusCase.upperExpected.confidence)
    }

    private func assertResultClose(_ result: FitnessAgeResult, _ expected: FitnessAgeResult, id: String) throws {
        let tolerance = 0.0000000001
        #expect(abs(result.fitnessAge - expected.fitnessAge) < tolerance, "\(id) Fitness Age")
        #expect(abs(result.chronologicalAge - expected.chronologicalAge) < tolerance, "\(id) chronological age")
        #expect(abs(result.confidence - expected.confidence) < tolerance, "\(id) confidence")
        #expect(abs(result.overallScore - expected.overallScore) < tolerance, "\(id) overall score")
        #expect(result.metricsUsed == expected.metricsUsed && result.totalPossibleMetrics == expected.totalPossibleMetrics)
        #expect(Set(result.domainScores.keys) == Set(expected.domainScores.keys))
        for (domain, expectedDomain) in expected.domainScores {
            let actual = try #require(result.domainScores[domain])
            #expect(abs(actual.score - expectedDomain.score) < tolerance, "\(id) \(domain) score")
            #expect(abs(actual.percentile - expectedDomain.percentile) < tolerance, "\(id) \(domain) relative standing")
            #expect(actual.dataQuality == expectedDomain.dataQuality)
            #expect(Set(actual.keyMetrics.keys) == Set(expectedDomain.keyMetrics.keys))
            for (key, expectedValue) in expectedDomain.keyMetrics {
                #expect(abs(try #require(actual.keyMetrics[key]) - expectedValue) < tolerance, "\(id) \(key)")
            }
        }
    }
}

private struct ContinuousAgeFixture: Decodable {
    let sourceRevision: String
    let cases: [ContinuousAgeCase]

    static func load() -> Self {
        guard let url = Bundle.module.url(forResource: "fitness_age_continuous_golden", withExtension: "json") else {
            fatalError("Continuous-age golden fixture is missing")
        }
        do {
            let fixture = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
            precondition(fixture.sourceRevision == "e1fec4603e67e63532c2c880105f68353b8fad84")
            precondition(!fixture.cases.isEmpty)
            return fixture
        } catch {
            fatalError("Cannot load continuous-age golden fixture: \(error)")
        }
    }
}

private struct ContinuousAgeCase: Decodable, Sendable {
    let id: String
    let input: FitnessAgeInput
    let lowerExpected: FitnessAgeResult
    let upperExpected: FitnessAgeResult
    let expected: FitnessAgeResult
}
