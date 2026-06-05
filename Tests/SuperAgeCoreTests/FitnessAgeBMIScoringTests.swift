import Testing
@testable import SuperAgeCore

@Suite("FitnessAge BMI scoring")
struct FitnessAgeBMIScoringTests {
    @Test("BMI scoring is smooth around healthy thresholds")
    func bmiScoringIsSmoothAroundHealthyThresholds() {
        let adultAtUpperThreshold = FitnessAgeScoring.scoreBMI(bodyMassIndex: 25.0, age: 40)
        let adultJustBelowUpperThreshold = FitnessAgeScoring.scoreBMI(bodyMassIndex: 24.9, age: 40)
        let adultRoundedToUpperThreshold = FitnessAgeScoring.scoreBMI(bodyMassIndex: 24.95, age: 40)
        let adultJustAboveUpperThreshold = FitnessAgeScoring.scoreBMI(bodyMassIndex: 25.1, age: 40)
        let adultJustBelowLowerThreshold = FitnessAgeScoring.scoreBMI(bodyMassIndex: 18.4, age: 40)
        let adultAtLowerThreshold = FitnessAgeScoring.scoreBMI(bodyMassIndex: 18.5, age: 40)
        let olderAdultAtUpperThreshold = FitnessAgeScoring.scoreBMI(bodyMassIndex: 27.0, age: 70)
        let olderAdultJustAboveUpperThreshold = FitnessAgeScoring.scoreBMI(bodyMassIndex: 27.1, age: 70)
        let olderAdultJustBelowLowerThreshold = FitnessAgeScoring.scoreBMI(bodyMassIndex: 19.9, age: 70)
        let olderAdultAtLowerThreshold = FitnessAgeScoring.scoreBMI(bodyMassIndex: 20.0, age: 70)

        #expect(abs(adultJustBelowUpperThreshold - adultAtUpperThreshold) <= 1.0,
                "BMI 25.0 should not be sharply worse than BMI 24.9")
        #expect(abs(adultRoundedToUpperThreshold - adultAtUpperThreshold) <= 1.0,
                "BMI values rounded to 25.0 should not fall into a scoring gap")
        #expect(adultRoundedToUpperThreshold >= adultJustAboveUpperThreshold,
                "A BMI just above 25 should not score better than a BMI just below 25")
        #expect(adultAtUpperThreshold >= adultJustAboveUpperThreshold,
                "A BMI just above 25 should not score better than BMI 25")
        #expect(abs(adultAtLowerThreshold - adultJustBelowLowerThreshold) <= 3.0,
                "BMI just below the healthy lower threshold should degrade smoothly")
        #expect(abs(olderAdultAtUpperThreshold - olderAdultJustAboveUpperThreshold) <= 3.0,
                "Older-adult BMI just above the healthy upper threshold should degrade smoothly")
        #expect(abs(olderAdultAtLowerThreshold - olderAdultJustBelowLowerThreshold) <= 3.0,
                "Older-adult BMI just below the healthy lower threshold should degrade smoothly")
    }
}
