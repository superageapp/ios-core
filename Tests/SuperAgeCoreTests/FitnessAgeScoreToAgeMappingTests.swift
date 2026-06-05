import Foundation
import Testing
@testable import SuperAgeCore

@Suite("FitnessAge score-to-age mapping")
struct FitnessAgeScoreToAgeMappingTests {
    @Test("score to age mapping is continuous around neutral score")
    func scoreToAgeMappingIsContinuousAroundNeutralScore() {
        let chronologicalAge = 45
        let scoreJustBelowNeutral = FitnessAgeScoreAggregator.fitnessAge(
            score: 49.999,
            chronologicalAge: chronologicalAge,
            confidence: 1.0
        )
        let neutralScore = FitnessAgeScoreAggregator.fitnessAge(
            score: 50.0,
            chronologicalAge: chronologicalAge,
            confidence: 1.0
        )
        let scoreJustAboveNeutral = FitnessAgeScoreAggregator.fitnessAge(
            score: 50.001,
            chronologicalAge: chronologicalAge,
            confidence: 1.0
        )

        #expect(abs(scoreJustBelowNeutral - neutralScore) < 0.01)
        #expect(abs(neutralScore - scoreJustAboveNeutral) < 0.01)
    }

    @Test("neutral score maps to chronological age")
    func neutralScoreMapsToChronologicalAge() {
        for chronologicalAge in [22, 35, 45, 64, 80] {
            let fitnessAge = FitnessAgeScoreAggregator.fitnessAge(
                score: 50,
                chronologicalAge: chronologicalAge,
                confidence: 1.0
            )

            #expect(abs(fitnessAge - Double(chronologicalAge)) < 0.0001)
        }
    }

    @Test(
        "score to age mapping stays inside documented age caps",
        arguments: ScoreToAgeMappingCase.documentedAgeCaps
    )
    fileprivate func scoreToAgeMappingStaysInsideDocumentedAgeCaps(_ testCase: ScoreToAgeMappingCase) {
        let fitnessAge = FitnessAgeScoreAggregator.fitnessAge(
            score: testCase.score,
            chronologicalAge: testCase.chronologicalAge,
            confidence: 1.0
        )

        #expect(fitnessAge >= testCase.minimumAge)
        #expect(fitnessAge <= testCase.maximumAge)
    }
}

private struct ScoreToAgeMappingCase: Sendable, CustomStringConvertible {
    let score: Double
    let chronologicalAge: Int
    let minimumAge: Double
    let maximumAge: Double

    var description: String {
        "score \(score), age \(chronologicalAge)"
    }

    static let documentedAgeCaps: [ScoreToAgeMappingCase] = [
        ScoreToAgeMappingCase(score: 0, chronologicalAge: 22, minimumAge: 18, maximumAge: 26),
        ScoreToAgeMappingCase(score: 100, chronologicalAge: 22, minimumAge: 18, maximumAge: 26),
        ScoreToAgeMappingCase(score: 0, chronologicalAge: 35, minimumAge: 27, maximumAge: 40),
        ScoreToAgeMappingCase(score: 100, chronologicalAge: 35, minimumAge: 27, maximumAge: 40),
        ScoreToAgeMappingCase(score: 0, chronologicalAge: 45, minimumAge: 35, maximumAge: 50),
        ScoreToAgeMappingCase(score: 100, chronologicalAge: 45, minimumAge: 35, maximumAge: 50),
        ScoreToAgeMappingCase(score: 0, chronologicalAge: 64, minimumAge: 54, maximumAge: 69),
        ScoreToAgeMappingCase(score: 100, chronologicalAge: 64, minimumAge: 54, maximumAge: 69),
        ScoreToAgeMappingCase(score: 0, chronologicalAge: 80, minimumAge: 70, maximumAge: 84),
        ScoreToAgeMappingCase(score: 100, chronologicalAge: 80, minimumAge: 70, maximumAge: 84)
    ]
}
