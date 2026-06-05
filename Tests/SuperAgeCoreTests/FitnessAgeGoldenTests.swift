import Foundation
import Testing
import SuperAgeCore

@Suite("FitnessAge golden parity")
struct FitnessAgeGoldenTests {
    @Test("calculator matches app-derived golden outputs", arguments: GoldenFixture.load().cases)
    func calculatorMatchesGoldenOutput(testCase: GoldenCase) throws {
        let result = FitnessAgeCalculator().calculate(testCase.input)

        assertClose(result.fitnessAge, testCase.expected.fitnessAge, "fitnessAge", testCase.id)
        assertClose(result.confidence, testCase.expected.confidence, "confidence", testCase.id)
        assertClose(result.overallScore, testCase.expected.overallScore, "overallScore", testCase.id)

        #expect(
            Set(result.domainScores.keys) == Set(testCase.expected.domainScores.keys),
            "\(testCase.id) domain key mismatch"
        )

        for (domain, expectedScore) in testCase.expected.domainScores {
            let actualScore = try #require(result.domainScores[domain]?.score)
            assertClose(actualScore, expectedScore, "\(domain.rawValue) domain score", testCase.id)
        }
    }

    private func assertClose(
        _ actual: Double,
        _ expected: Double,
        _ label: String,
        _ id: String,
        tolerance: Double = 0.01
    ) {
        #expect(
            abs(actual - expected) <= tolerance,
            "\(id) \(label) expected \(expected), got \(actual)"
        )
    }

    @Test("fixture decoding rejects empty case lists")
    func fixtureDecodingRejectsEmptyCaseLists() {
        let data = Data(#"{"cases":[]}"#.utf8)

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(GoldenFixture.self, from: data)
        }
    }

    @Test("fixture decoding rejects unknown expected domains")
    func fixtureDecodingRejectsUnknownExpectedDomains() {
        let data = Data("""
        {
          "fitnessAge": 42,
          "confidence": 0.8,
          "overallScore": 90,
          "domainScores": {
            "unknownDomain": 90
          }
        }
        """.utf8)

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(GoldenExpected.self, from: data)
        }
    }
}

struct GoldenFixture {
    let cases: [GoldenCase]

    static func load(
        fileID: String = #fileID,
        filePath: String = #filePath
    ) -> GoldenFixture {
        do {
            let fileURL = URL(fileURLWithPath: filePath)
            let fixtureURL = fileURL
                .deletingLastPathComponent()
                .appendingPathComponent("Fixtures")
                .appendingPathComponent("fitness_age_golden.json")
            let data = try Data(contentsOf: fixtureURL)
            return try JSONDecoder().decode(GoldenFixture.self, from: data)
        } catch {
            fatalError("\(fileID) failed to load fitness_age_golden.json: \(error)")
        }
    }
}

extension GoldenFixture: Decodable {
    private enum CodingKeys: String, CodingKey {
        case cases
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cases = try container.decode([GoldenCase].self, forKey: .cases)

        guard !cases.isEmpty else {
            throw DecodingError.dataCorruptedError(
                forKey: .cases,
                in: container,
                debugDescription: "Golden fixture must contain at least one case."
            )
        }
    }
}

struct GoldenCase: Decodable, Sendable {
    let id: String
    let input: FitnessAgeInput
    let expected: GoldenExpected
}

struct GoldenExpected: Sendable {
    let fitnessAge: Double
    let confidence: Double
    let overallScore: Double
    let domainScores: [FitnessAgeDomain: Double]
}

extension GoldenExpected: Decodable {
    private enum CodingKeys: String, CodingKey {
        case fitnessAge
        case confidence
        case overallScore
        case domainScores
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fitnessAge = try container.decode(Double.self, forKey: .fitnessAge)
        confidence = try container.decode(Double.self, forKey: .confidence)
        overallScore = try container.decode(Double.self, forKey: .overallScore)

        let rawDomainScores = try container.decode([String: Double].self, forKey: .domainScores)
        var decodedDomainScores: [FitnessAgeDomain: Double] = [:]

        for (rawDomain, score) in rawDomainScores {
            guard let domain = FitnessAgeDomain(rawValue: rawDomain) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .domainScores,
                    in: container,
                    debugDescription: "Unknown Fitness Age domain: \(rawDomain)."
                )
            }

            decodedDomainScores[domain] = score
        }

        domainScores = decodedDomainScores
    }
}
