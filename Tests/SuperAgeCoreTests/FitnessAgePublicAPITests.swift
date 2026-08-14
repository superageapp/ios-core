import Testing
import Foundation
import SuperAgeCore

@Suite("FitnessAge public API")
struct FitnessAgePublicAPITests {
    @Test("calculator returns deterministic result for normalized Apple Health input")
    func calculatorReturnsDeterministicResult() {
        let input = FitnessAgeInput(
            profile: FitnessAgeProfile(
                chronologicalAge: 42,
                biologicalSex: .male
            ),
            metrics: FitnessAgeMetrics(
                restingHeartRate: 58,
                vo2Max: 45,
                heartRateVariability: 50,
                respiratoryRate: 15,
                stepCount: 10_000,
                activeEnergy: 600,
                exerciseTime: 45,
                sleepHours: 7.5,
                bodyMassIndex: 23.5
            )
        )

        let first = FitnessAgeCalculator().calculate(input)
        let second = FitnessAgeCalculator().calculate(input)

        #expect(input.configuration.algorithmMode == .evidenceFirst)
        #expect(abs(first.fitnessAge - 32.44677972027972) < 0.0001)
        #expect(first.fitnessAge > 0)
        #expect(first.confidence > 0)
        #expect(first.domainScores[.cardiovascular] != nil)
        #expect(first.domainScores[.activity] != nil)
        #expect(first.domainScores[.recovery] != nil)
        #expect(first.domainScores[.bodyComposition] != nil)
        #expect(first.domainScores[.lifestyle] != nil)
        #expect(first == second)
    }

    @Test("configuration decoding merges partial domain weights over defaults")
    func configurationDecodingMergesPartialDomainWeights() throws {
        let json = Data(#"{"domainWeights":{"activity":0.42,"unknown":0.99}}"#.utf8)

        let configuration = try JSONDecoder().decode(FitnessAgeConfiguration.self, from: json)

        #expect(configuration.algorithmMode == .evidenceFirst)
        #expect(configuration.mapping == .evidenceFirst)
        #expect(configuration.domainWeights[.activity] == 0.42)
        #expect(configuration.domainWeights[.cardiovascular] == FitnessAgeDomain.cardiovascular.defaultWeight)
        #expect(configuration.domainWeights[.recovery] == FitnessAgeDomain.recovery.defaultWeight)
        #expect(configuration.domainWeights[.bodyComposition] == FitnessAgeDomain.bodyComposition.defaultWeight)
        #expect(configuration.domainWeights[.lifestyle] == FitnessAgeDomain.lifestyle.defaultWeight)
    }

    @Test("configuration decoding rejects unknown algorithm modes")
    func configurationDecodingRejectsUnknownAlgorithmModes() {
        let json = Data(#"{"algorithmMode":"compatibility_v1"}"#.utf8)

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(FitnessAgeConfiguration.self, from: json)
        }
    }

    @Test("configuration decoding accepts explicit compatibility mode")
    func configurationDecodingAcceptsExplicitCompatibilityMode() throws {
        let json = Data(#"{"algorithmMode":"compatibilityV1"}"#.utf8)

        let configuration = try JSONDecoder().decode(FitnessAgeConfiguration.self, from: json)

        #expect(configuration.algorithmMode == .compatibilityV1)
        #expect(configuration.mapping == .compatibilityV1)
    }

    @Test("configuration exposes evidence-first default and compatibility mode")
    func configurationExposesAlgorithmModes() {
        #expect(FitnessAgeConfiguration.default.algorithmMode == .evidenceFirst)
        #expect(FitnessAgeConfiguration.default.mapping == .evidenceFirst)
        #expect(FitnessAgeConfiguration.default.mapping.maximumAgeDelta == 10)
        #expect(FitnessAgeConfiguration.default.mapping.minimumDisplayAge == 18)
        #expect(FitnessAgeConfiguration.compatibilityV1.algorithmMode == .compatibilityV1)
        #expect(FitnessAgeConfiguration.compatibilityV1.mapping == .compatibilityV1)
    }

    @Test("result codable uses raw string domain keys")
    func resultCodableUsesRawStringDomainKeys() throws {
        let result = FitnessAgeResult(
            fitnessAge: 40,
            chronologicalAge: 42,
            confidence: 0.7,
            domainScores: [
                .cardiovascular: FitnessAgeDomainScore(score: 88, percentile: 75)
            ],
            overallScore: 88,
            metricsUsed: 1,
            totalPossibleMetrics: 2
        )

        let data = try JSONEncoder().encode(result)
        let encoded = String(decoding: data, as: UTF8.self)
        let decoded = try JSONDecoder().decode(FitnessAgeResult.self, from: data)

        #expect(encoded.contains("\"cardiovascular\""))
        #expect(decoded.domainScores[.cardiovascular]?.score == 88)
        #expect(decoded.difference == -2)
    }

    @Test("missing decoded profile is explicit invalid input")
    func missingDecodedProfileIsExplicitInvalidInput() throws {
        let input = try JSONDecoder().decode(FitnessAgeInput.self, from: Data("{}".utf8))

        #expect(!input.profile.isValidForCalculation)
        #expect(input.profile.biologicalSex == .unknown)
        #expect(input.metrics == FitnessAgeMetrics())
        #expect(input.configuration == .default)
    }
}
