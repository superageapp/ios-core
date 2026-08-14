import Testing
@testable import SuperAgeCore

@Suite("FitnessAge scoring curves")
struct FitnessAgeScoringCurveTests {
    @Test("resting heart rate below 40 is not scored as perfect fitness")
    func restingHeartRateBelowFortyIsNotScoredAsPerfect() {
        let severeBradycardia = FitnessAgeScoring.scoreRestingHeartRate(heartRate: 25, age: 40, sex: .male)
        let healthy = FitnessAgeScoring.scoreRestingHeartRate(heartRate: 55, age: 40, sex: .male)

        #expect(severeBradycardia < 50)
        #expect(severeBradycardia < healthy)
    }

    @Test("resting heart rate score decreases monotonically below 40 bpm")
    func restingHeartRateScoreDecreasesMonotonicallyBelowFortyBpm() {
        var previous = FitnessAgeScoring.scoreRestingHeartRate(heartRate: 40, age: 40, sex: .male)

        for heartRate in stride(from: 39.5, through: 20.0, by: -0.5) {
            let score = FitnessAgeScoring.scoreRestingHeartRate(heartRate: heartRate, age: 40, sex: .male)
            #expect(score <= previous, "score for RHR \(heartRate) exceeds score for a higher reading")
            previous = score
        }

        // Deep in the bradycardia range the clamp cannot mask the formula:
        // base 100 - (40 - 30) * 4 = 60, times the age-40 leniency multiplier.
        let atThirty = FitnessAgeScoring.scoreRestingHeartRate(heartRate: 30, age: 40, sex: .male)
        let expected = 60.0 * FitnessAgeScoring.getAgeLeniencyMultiplier(age: 40)
        #expect(abs(atThirty - expected) < 0.0001)
    }

    @Test("oxygen saturation bands are contiguous for fractional readings")
    func oxygenSaturationBandsAreContiguousForFractionalReadings() {
        // Age 40 applies no age adjustment, so the base bands are observable directly.
        #expect(FitnessAgeScoring.scoreOxygenSaturation(spo2: 96.95, age: 40) == 85)
        #expect(FitnessAgeScoring.scoreOxygenSaturation(spo2: 94.95, age: 40) == 60)
        #expect(FitnessAgeScoring.scoreOxygenSaturation(spo2: 92.95, age: 40) == 35)
        #expect(FitnessAgeScoring.scoreOxygenSaturation(spo2: 89.95, age: 40) == 20)
        #expect(abs(FitnessAgeScoring.scoreOxygenSaturation(spo2: 87.9, age: 40) - 19.5) < 0.0001)
    }

    @Test("oxygen saturation score never improves as the reading drops")
    func oxygenSaturationScoreNeverImprovesAsTheReadingDrops() {
        var previous = Double.infinity

        for reading in stride(from: 100.0, through: 80.0, by: -0.05) {
            let score = FitnessAgeScoring.scoreOxygenSaturation(spo2: reading, age: 40)
            #expect(score <= previous, "score for SpO2 \(reading) exceeds score for a higher reading")
            previous = score
        }
    }

    @Test("time in daylight bands are contiguous for fractional minutes")
    func timeInDaylightBandsAreContiguousForFractionalMinutes() {
        #expect(FitnessAgeScoring.scoreTimeInDaylight(120) == 100)
        #expect(FitnessAgeScoring.scoreTimeInDaylight(120.5) == 85)
        #expect(FitnessAgeScoring.scoreTimeInDaylight(180) == 85)
        #expect(FitnessAgeScoring.scoreTimeInDaylight(180.5) == 65)
        #expect(FitnessAgeScoring.scoreTimeInDaylight(240) == 65)
        #expect(FitnessAgeScoring.scoreTimeInDaylight(240.5) == 45)
    }
}
