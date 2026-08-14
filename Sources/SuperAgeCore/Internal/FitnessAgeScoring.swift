import Foundation

enum FitnessAgeScoring {
    enum ReferenceSex {
        case male
        case female
    }

    static func referenceSex(from sex: FitnessAgeBiologicalSex) -> ReferenceSex {
        sex == .female ? .female : .male
    }

    static func scoreMovementRegularity(stepCount: Double, age: Int) -> Double {
        let ageAdjustedTarget: Double

        switch age {
        case 0...30: ageAdjustedTarget = 10_000
        case 31...50: ageAdjustedTarget = 8_500
        case 51...65: ageAdjustedTarget = 7_500
        default: ageAdjustedTarget = 6_500
        }

        let ratio = stepCount / ageAdjustedTarget

        if ratio >= 1.2 {
            return 100.0
        } else if ratio >= 1.0 {
            return 85.0
        } else if ratio >= 0.8 {
            return 70.0
        } else if ratio >= 0.6 {
            return 55.0
        } else {
            return 40.0
        }
    }

    static func scoreActivityConsistency(stepCount: Double, activeEnergy: Double, age: Int) -> Double {
        let targetSteps: Double = age > 65 ? 7_000 : 8_000
        let stepScore = min(100.0, (stepCount / targetSteps) * 100.0)

        let targetEnergy: Double = age > 65 ? 200 : 300
        let energyScore = min(100.0, (activeEnergy / targetEnergy) * 100.0)

        return stepScore * 0.7 + energyScore * 0.3
    }

    static func scoreSedentaryTime(stepCount: Double, activeEnergy: Double) -> Double {
        let stepContribution = min(100.0, (stepCount / 10_000.0) * 70.0)
        let energyContribution = min(100.0, (activeEnergy / 400.0) * 30.0)

        return stepContribution + energyContribution
    }

    static func scoreSmokingStatus(isSmoker: Bool) -> Double {
        isSmoker ? 30.0 : 100.0
    }

    static func scoreWalkingSteadiness(steadiness: Double, age: Int) -> Double {
        let clampedSteadiness = max(0.0, min(1.0, steadiness))
        let baseScore: Double

        switch clampedSteadiness {
        case 0.90...1.0:
            baseScore = 100.0
        case 0.80..<0.90:
            baseScore = 85.0
        case 0.70..<0.80:
            baseScore = 70.0
        case 0.60..<0.70:
            baseScore = 55.0
        default:
            baseScore = max(20.0, clampedSteadiness * 75.0)
        }

        return applyAgeLeniency(score: baseScore, age: age)
    }

    static func scoreWalkingAsymmetry(asymmetry: Double, age: Int) -> Double {
        let ageTolerance: Double

        switch age {
        case 0...39:
            ageTolerance = 0.0
        case 40...54:
            ageTolerance = 0.5
        case 55...69:
            ageTolerance = 1.0
        default:
            ageTolerance = 1.5
        }

        let excellentThreshold = 2.0 + ageTolerance
        let goodThreshold = 4.0 + ageTolerance
        let fairThreshold = 6.0 + ageTolerance
        let poorThreshold = 8.0 + ageTolerance
        let baseScore: Double

        switch asymmetry {
        case ...excellentThreshold:
            baseScore = 100.0
        case ...goodThreshold:
            baseScore = 85.0
        case ...fairThreshold:
            baseScore = 70.0
        case ...poorThreshold:
            baseScore = 55.0
        default:
            baseScore = max(20.0, 55.0 - ((asymmetry - poorThreshold) * 4.0))
        }

        return applyAgeLeniency(score: baseScore, age: age)
    }

    static func scoreWalkingDoubleSupport(doubleSupport: Double, age: Int) -> Double {
        let ageTolerance: Double

        switch age {
        case 0...39:
            ageTolerance = 0.0
        case 40...54:
            ageTolerance = 1.0
        case 55...69:
            ageTolerance = 2.0
        default:
            ageTolerance = 3.0
        }

        let excellentThreshold = 20.0 + ageTolerance
        let goodThreshold = 24.0 + ageTolerance
        let fairThreshold = 28.0 + ageTolerance
        let poorThreshold = 32.0 + ageTolerance
        let baseScore: Double

        switch doubleSupport {
        case ...excellentThreshold:
            baseScore = 100.0
        case ...goodThreshold:
            baseScore = 85.0
        case ...fairThreshold:
            baseScore = 70.0
        case ...poorThreshold:
            baseScore = 55.0
        default:
            baseScore = max(20.0, 55.0 - ((doubleSupport - poorThreshold) * 2.5))
        }

        return applyAgeLeniency(score: baseScore, age: age)
    }

    static func getAgeLeniencyMultiplier(age: Int) -> Double {
        switch age {
        case 0...30:
            return 1.01 + (Double(age - 18) / 12.0) * 0.03
        case 31...50:
            return 1.04 + (Double(age - 31) / 19.0) * 0.04
        case 51...65:
            return 1.08 + (Double(age - 51) / 14.0) * 0.06
        default:
            let seniorAge = min(age, 85)
            return 1.14 + (Double(seniorAge - 65) / 20.0) * 0.06
        }
    }

    static func applyAgeLeniency(score: Double, age: Int) -> Double {
        let multiplier = getAgeLeniencyMultiplier(age: age)
        let adjustedScore = score * multiplier

        return max(0.0, min(100.0, adjustedScore))
    }

    static func scoreVO2Max(vo2Max: Double, age: Int, sex: ReferenceSex) -> Double {
        let standards: [Int: [ReferenceSex: (excellent: Double, good: Double, acceptable: Double, minimum: Double)]] = [
            20: [.male: (51.1, 45.4, 41.7, 35.0), .female: (43.9, 39.5, 36.1, 30.0)],
            30: [.male: (48.3, 44.0, 40.5, 34.0), .female: (42.4, 37.8, 34.4, 28.0)],
            40: [.male: (46.4, 42.4, 38.5, 32.0), .female: (39.7, 36.3, 33.0, 27.0)],
            50: [.male: (43.4, 39.2, 35.6, 30.0), .female: (36.7, 33.0, 30.1, 24.0)],
            60: [.male: (39.5, 35.5, 32.3, 27.0), .female: (33.0, 30.0, 27.5, 22.0)],
            70: [.male: (36.7, 32.3, 29.4, 24.0), .female: (30.9, 28.1, 25.9, 20.0)]
        ]

        let ageGroup = (age / 10) * 10
        let clampedAge = min(70, max(20, ageGroup))

        guard let standard = standards[clampedAge]?[sex] else { return 50 }

        if vo2Max >= standard.excellent {
            return 100.0
        } else if vo2Max >= standard.good {
            let ratio = (vo2Max - standard.good) / (standard.excellent - standard.good)
            return 85.0 + (ratio * 15.0)
        } else if vo2Max >= standard.acceptable {
            let ratio = (vo2Max - standard.acceptable) / (standard.good - standard.acceptable)
            return 65.0 + (ratio * 20.0)
        } else if vo2Max >= standard.minimum {
            let ratio = (vo2Max - standard.minimum) / (standard.acceptable - standard.minimum)
            return 40.0 + (ratio * 25.0)
        } else {
            let ratio = vo2Max / standard.minimum
            return max(0, ratio * 40.0)
        }
    }

    static func scoreRestingHeartRate(heartRate: Double, age: Int, sex: ReferenceSex) -> Double {
        let baseScore: Double
        switch heartRate {
        case ..<40: baseScore = max(0, 100 - (40 - heartRate) * 4)
        case 40...60: baseScore = 100
        case 60...70: baseScore = 85
        case 70...80: baseScore = 65
        case 80...90: baseScore = 40
        default: baseScore = max(0, 40 - (heartRate - 90) * 2)
        }

        return applyAgeLeniency(score: baseScore, age: age)
    }

    static func scoreHRV(hrv: Double, age: Int, sex: ReferenceSex) -> Double {
        let ageAdjustedTarget: Double

        switch age {
        case 20...30: ageAdjustedTarget = 45
        case 31...40: ageAdjustedTarget = 38
        case 41...50: ageAdjustedTarget = 32
        case 51...60: ageAdjustedTarget = 27
        default: ageAdjustedTarget = 22
        }

        let ratio = hrv / ageAdjustedTarget

        let baseScore: Double
        if ratio >= 1.2 { baseScore = 100 }
        else if ratio >= 1.0 { baseScore = 85 }
        else if ratio >= 0.8 { baseScore = 65 }
        else if ratio >= 0.6 { baseScore = 40 }
        else { baseScore = max(0, ratio * 40) }

        return applyAgeLeniency(score: baseScore, age: age)
    }

    static func scoreRespiratoryRate(rate: Double, age: Int) -> Double {
        switch rate {
        case 12...16: return 100
        case 10..<12, 16..<18: return 85
        case 8..<10, 18..<20: return 70
        case 6..<8, 20...22: return 55
        default:
            return max(20, 55 - abs(rate - 15) * 3)
        }
    }

    static func scoreOxygenSaturation(spo2: Double, age: Int) -> Double {
        let baseScore: Double
        switch spo2 {
        case 97...:
            baseScore = 100
        case 95..<97:
            baseScore = 85
        case 93..<95:
            baseScore = 60
        case 90..<93:
            baseScore = 35
        case 88..<90:
            baseScore = 20
        default:
            baseScore = max(0, 20 - (88 - spo2) * 5)
        }

        let ageAdjustment: Double
        switch age {
        case 0...50: ageAdjustment = 1.0
        case 51...65: ageAdjustment = 1.05
        case 66...75: ageAdjustment = 1.08
        default: ageAdjustment = 1.10
        }

        return min(100, baseScore * ageAdjustment)
    }

    static func scoreMaxHeartRate(maxHR: Double, age: Int) -> Double {
        let tanakaReference = 208.0 - (0.7 * Double(age))
        let percentage = maxHR / tanakaReference

        let baseScore: Double
        if percentage >= 1.0 {
            baseScore = 100
        } else if percentage >= 0.95 {
            let ratio = (percentage - 0.95) / 0.05
            baseScore = 90 + (ratio * 10)
        } else if percentage >= 0.90 {
            let ratio = (percentage - 0.90) / 0.05
            baseScore = 80 + (ratio * 10)
        } else if percentage >= 0.85 {
            let ratio = (percentage - 0.85) / 0.05
            baseScore = 70 + (ratio * 10)
        } else if percentage >= 0.80 {
            let ratio = (percentage - 0.80) / 0.05
            baseScore = 60 + (ratio * 10)
        } else if percentage >= 0.75 {
            let ratio = (percentage - 0.75) / 0.05
            baseScore = 50 + (ratio * 10)
        } else {
            let ratio = percentage / 0.75
            baseScore = max(0, ratio * 50)
        }

        let ageAdjustment: Double
        switch age {
        case 0...40: ageAdjustment = 1.0
        case 41...50: ageAdjustment = 1.02
        case 51...60: ageAdjustment = 1.05
        case 61...70: ageAdjustment = 1.08
        default: ageAdjustment = 1.10
        }

        return min(100, baseScore * ageAdjustment)
    }

    static func scoreBloodPressure(systolic: Double, diastolic: Double, age: Int) -> Double {
        let baseScore: Double

        if systolic < 120 && diastolic < 80 {
            baseScore = 100
        } else if systolic < 130 && diastolic < 85 {
            baseScore = 85
        } else if systolic < 140 && diastolic < 90 {
            baseScore = 65
        } else if systolic < 160 && diastolic < 100 {
            baseScore = 40
        } else {
            baseScore = 20
        }

        let ageAdjustment: Double
        switch age {
        case 0...30: ageAdjustment = 1.0
        case 31...50: ageAdjustment = 1.05
        case 51...65: ageAdjustment = 1.10
        default: ageAdjustment = 1.15
        }

        return min(100, baseScore * ageAdjustment)
    }

    static func scoreStepCount(steps: Double, age: Int) -> Double {
        let target: Double

        switch age {
        case 0...30: target = 8_000
        case 31...50: target = 7_200
        case 51...65: target = 6_300
        default: target = 5_400
        }

        let ratio = steps / target

        let baseScore: Double
        if ratio >= 1.3 { baseScore = 100 }
        else if ratio >= 1.1 { baseScore = 90 }
        else if ratio >= 1.0 { baseScore = 80 }
        else if ratio >= 0.8 { baseScore = 65 }
        else if ratio >= 0.6 { baseScore = 45 }
        else if ratio >= 0.4 { baseScore = 25 }
        else { baseScore = max(0, ratio * 30) }

        return applyAgeLeniency(score: baseScore, age: age)
    }

    static func scoreActiveEnergy(calories: Double, age: Int, sex: ReferenceSex) -> Double {
        let target: Double

        switch (age, sex) {
        case (0...30, .male): target = 320
        case (0...30, .female): target = 230
        case (31...50, .male): target = 275
        case (31...50, .female): target = 185
        case (51...65, .male): target = 230
        case (51...65, .female): target = 155
        default: target = sex == .male ? 165 : 120
        }

        let ratio = calories / target

        if ratio >= 1.4 { return 100 }
        if ratio >= 1.2 { return 90 }
        if ratio >= 1.0 { return 75 }
        if ratio >= 0.8 { return 60 }
        if ratio >= 0.6 { return 40 }
        if ratio >= 0.4 { return 25 }
        return max(0, ratio * 35)
    }

    static func scoreExerciseTime(minutes: Double) -> Double {
        let weeklyMinutes = minutes * 7

        if weeklyMinutes >= 150 { return 100 }
        if weeklyMinutes >= 120 { return 80 }
        if weeklyMinutes >= 90 { return 60 }
        if weeklyMinutes >= 60 { return 40 }
        return max(0, (weeklyMinutes / 150) * 100)
    }

    static func scoreFlightsClimbed(flights: Double, age: Int) -> Double {
        let target: Double

        switch age {
        case 0...30: target = 12
        case 31...50: target = 10
        case 51...65: target = 8
        default: target = 6
        }

        let ratio = flights / target

        let baseScore: Double
        if ratio >= 1.5 { baseScore = 100 }
        else if ratio >= 1.2 { baseScore = 90 }
        else if ratio >= 1.0 { baseScore = 80 }
        else if ratio >= 0.7 { baseScore = 65 }
        else if ratio >= 0.4 { baseScore = 45 }
        else { baseScore = max(0, ratio * 60) }

        return applyAgeLeniency(score: baseScore, age: age)
    }

    static func scoreSleepDuration(hours: Double, age: Int) -> Double {
        let optimalRange: ClosedRange<Double> = age > 65 ? 7.0...8.0 : 7.0...9.0
        let idealMidpoint = (optimalRange.lowerBound + optimalRange.upperBound) / 2

        if optimalRange.contains(hours) {
            let distanceFromIdeal = abs(hours - idealMidpoint)
            return max(95.0, 100.0 - (distanceFromIdeal * 5.0))
        }

        let deviation = hours < optimalRange.lowerBound
            ? optimalRange.lowerBound - hours
            : hours - optimalRange.upperBound

        return max(30.0, 95.0 - deviation * 12.0)
    }

    static func scoreWalkingHeartRateAverage(_ value: Double, age: Int) -> Double {
        let targetUpperBound: Double
        let acceptableUpperBound: Double

        switch age {
        case 0...30:
            targetUpperBound = 95
            acceptableUpperBound = 115
        case 31...50:
            targetUpperBound = 100
            acceptableUpperBound = 120
        case 51...65:
            targetUpperBound = 105
            acceptableUpperBound = 125
        default:
            targetUpperBound = 110
            acceptableUpperBound = 130
        }

        if value <= targetUpperBound { return 100 }
        if value <= acceptableUpperBound {
            let ratio = (value - targetUpperBound) / (acceptableUpperBound - targetUpperBound)
            return 100.0 - (ratio * 25.0)
        }

        return max(20.0, 75.0 - ((value - acceptableUpperBound) * 2.0))
    }

    static func scoreSixMinuteWalkDistance(_ value: Double, age: Int) -> Double {
        let targetDistance: Double = 500
        let acceptableDistance: Double

        switch age {
        case 0...30:
            acceptableDistance = 400
        case 31...50:
            acceptableDistance = 390
        case 51...65:
            acceptableDistance = 380
        default:
            acceptableDistance = 360
        }

        if value >= targetDistance { return 100 }
        if value >= acceptableDistance {
            let ratio = (value - acceptableDistance) / (targetDistance - acceptableDistance)
            return 75.0 + (ratio * 25.0)
        }

        return max(20.0, (value / acceptableDistance) * 75.0)
    }

    static func scoreStandHours(_ value: Double) -> Double {
        switch value {
        case 10...16:
            return 100
        case 8..<10, 16...18:
            return 82
        case 6..<8, 18...20:
            return 65
        case 4..<6, 20...22:
            return 45
        default:
            return max(20.0, 45.0 - (abs(value - 13.0) * 4.0))
        }
    }

    static func scoreStairAscentSpeed(_ value: Double, age: Int) -> Double {
        let target: Double
        let acceptableMin: Double

        switch age {
        case 0...30:
            target = 0.90
            acceptableMin = 0.65
        case 31...50:
            target = 0.82
            acceptableMin = 0.60
        case 51...65:
            target = 0.72
            acceptableMin = 0.52
        default:
            target = 0.62
            acceptableMin = 0.45
        }

        return scoreStairSpeed(value, age: age, target: target, acceptableMin: acceptableMin)
    }

    static func scoreStairDescentSpeed(_ value: Double, age: Int) -> Double {
        let target: Double
        let acceptableMin: Double

        switch age {
        case 0...30:
            target = 0.95
            acceptableMin = 0.70
        case 31...50:
            target = 0.87
            acceptableMin = 0.64
        case 51...65:
            target = 0.77
            acceptableMin = 0.56
        default:
            target = 0.67
            acceptableMin = 0.48
        }

        return scoreStairSpeed(value, age: age, target: target, acceptableMin: acceptableMin)
    }

    static func scoreStairSpeed(_ value: Double, age: Int, target: Double, acceptableMin: Double) -> Double {
        let baseScore: Double

        if value >= target {
            baseScore = 100.0
        } else if value >= acceptableMin {
            let ratio = (value - acceptableMin) / (target - acceptableMin)
            baseScore = 75.0 + (ratio * 25.0)
        } else {
            let ratio = value / acceptableMin
            baseScore = max(20.0, ratio * 75.0)
        }

        return applyAgeLeniency(score: baseScore, age: age)
    }

    static func scoreSleepingWristTemperatureDeviation(_ value: Double) -> Double {
        let absoluteDeviation = abs(value)

        switch absoluteDeviation {
        case ...0.15:
            return 100
        case ...0.30:
            return 85
        case ...0.45:
            return 65
        case ...0.60:
            return 45
        default:
            return max(20.0, 45.0 - ((absoluteDeviation - 0.60) * 50.0))
        }
    }

    static func scoreBloodGlucose(_ value: Double) -> Double {
        switch value {
        case 70...110:
            return 100
        case 60..<70, 110...125:
            return 82
        case 50..<60, 125...140:
            return 60
        default:
            return max(20.0, 60.0 - (abs(value - 90.0) * 0.8))
        }
    }

    static func scoreTimeInDaylight(_ value: Double) -> Double {
        switch value {
        case ..<15:
            return max(20.0, (value / 15.0) * 70.0)
        case 15..<30:
            return 70.0 + ((value - 15.0) / 15.0) * 30.0
        case 30...120:
            return 100
        case 120...180:
            return 85
        case 180...240:
            return 65
        default:
            return 45.0
        }
    }

    static func scoreBodyFatPercentage(bodyFat: Double, age: Int, sex: ReferenceSex) -> Double {
        let healthyRange: ClosedRange<Double>

        switch (age, sex) {
        case (0...30, .male): healthyRange = 8...19
        case (0...30, .female): healthyRange = 16...24
        case (31...50, .male): healthyRange = 11...22
        case (31...50, .female): healthyRange = 18...27
        case (51...65, .male): healthyRange = 13...25
        case (51...65, .female): healthyRange = 21...30
        default: healthyRange = sex == .male ? 15...28 : 23...33
        }

        if healthyRange.contains(bodyFat) { return 100 }

        let deviation = min(abs(bodyFat - healthyRange.lowerBound), abs(bodyFat - healthyRange.upperBound))
        return max(0, 100 - deviation * 3)
    }

    static func scoreBMI(bodyMassIndex: Double, age: Int) -> Double {
        let idealBMI: Double = 22.0
        let lowerHealthyBMI: Double = age > 65 ? 20.0 : 18.5
        let upperHealthyBMI: Double = age > 65 ? 27.0 : 25.0
        let healthyFloorScore = 95.0

        if bodyMassIndex >= lowerHealthyBMI && bodyMassIndex <= upperHealthyBMI {
            let distanceFromIdeal = abs(bodyMassIndex - idealBMI)
            if distanceFromIdeal <= 1.0 {
                return 100.0
            }
            return max(healthyFloorScore, 100.0 - ((distanceFromIdeal - 1.0) * 5.0))
        }

        if bodyMassIndex > upperHealthyBMI {
            if bodyMassIndex <= 30.0 {
                let ratio = (bodyMassIndex - upperHealthyBMI) / (30.0 - upperHealthyBMI)
                return healthyFloorScore - (ratio * (healthyFloorScore - 60.0))
            }
            if bodyMassIndex <= 35.0 {
                return 60.0 - ((bodyMassIndex - 30.0) * 5.0)
            }
            return max(0.0, 35.0 - ((bodyMassIndex - 35.0) * 5.0))
        }

        if bodyMassIndex >= 17.0 {
            let ratio = (bodyMassIndex - 17.0) / (lowerHealthyBMI - 17.0)
            return 75.0 + (ratio * (healthyFloorScore - 75.0))
        }

        return max(0.0, 75.0 - ((17.0 - bodyMassIndex) * 15.0))
    }

    static func scoreLeanMassIndex(leanMassIndex: Double, age: Int, sex: ReferenceSex) -> Double {
        let target: Double = sex == .male ? 18 : 14
        let ageAdjustment = max(0.8, 1.0 - (Double(age - 30) * 0.005))
        let adjustedTarget = target * ageAdjustment

        let ratio = leanMassIndex / adjustedTarget
        return min(100, max(0, ratio * 85))
    }

    static func scoreAverageHeartRate(heartRate: Double, age: Int) -> Double {
        switch heartRate {
        case 55...65: return 100
        case 65...75: return 90
        case 75...85: return 75
        case 85...95: return 55
        case 95...105: return 35
        default:
            if heartRate < 55 {
                return 85
            }
            return max(0, 35 - (heartRate - 105) * 2)
        }
    }
}
