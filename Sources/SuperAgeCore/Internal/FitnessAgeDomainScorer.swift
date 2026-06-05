import Foundation

struct FitnessAgeDomainScorer {
    private static let lifestyleMetricRawWeights: [(id: String, weight: Double)] = [
        ("movement_regularity", 0.18),
        ("activity_consistency", 0.16),
        ("sedentary_time", 0.10),
        ("smoking_status", 0.20),
        ("walking_steadiness", 0.16),
        ("walking_asymmetry", 0.10),
        ("double_support", 0.10)
    ]

    func domainScores(
        metrics: FitnessAgeMetrics,
        profile: FitnessAgeProfile
    ) -> [FitnessAgeDomain: FitnessAgeDomainScore] {
        let age = profile.chronologicalAge
        let sex = FitnessAgeScoring.referenceSex(from: profile.biologicalSex)
        var scores: [FitnessAgeDomain: FitnessAgeDomainScore] = [:]

        if let cardiovascular = calculateCardiovascularScore(metrics: metrics, age: age, sex: sex) {
            scores[.cardiovascular] = cardiovascular
        }

        if let activity = calculateActivityScore(metrics: metrics, age: age, sex: sex) {
            scores[.activity] = activity
        }

        if let recovery = calculateRecoveryScore(
            metrics: metrics,
            age: age,
            sex: sex,
            allowsSleepFallback: !profile.disabledMetricIds.contains("sleep")
        ) {
            scores[.recovery] = recovery
        }

        if let bodyComposition = calculateBodyCompositionScore(metrics: metrics, age: age, sex: sex) {
            scores[.bodyComposition] = bodyComposition
        }

        if let lifestyle = calculateLifestyleScore(metrics: metrics, age: age) {
            scores[.lifestyle] = lifestyle
        }

        for excludedDomain in profile.excludedDomains {
            scores[excludedDomain] = nil
        }

        return scores
    }

    private func calculateCardiovascularScore(
        metrics: FitnessAgeMetrics,
        age: Int,
        sex: FitnessAgeScoring.ReferenceSex
    ) -> FitnessAgeDomainScore? {
        var score = 0.0
        var totalWeight = 0.0
        var keyMetrics: [String: Double] = [:]

        if let maxHeartRate = metrics.maxHeartRate, maxHeartRate > 0 {
            score += FitnessAgeScoring.scoreMaxHeartRate(maxHR: maxHeartRate, age: age) * 0.18
            totalWeight += 0.18
            keyMetrics["maxHeartRate"] = maxHeartRate
        }

        if let vo2Max = metrics.vo2Max, vo2Max > 0 {
            score += FitnessAgeScoring.scoreVO2Max(vo2Max: vo2Max, age: age, sex: sex) * 0.42
            totalWeight += 0.42
            keyMetrics["vo2Max"] = vo2Max
        }

        if let averageHeartRate = metrics.averageHeartRate, averageHeartRate > 0 {
            score += FitnessAgeScoring.scoreAverageHeartRate(heartRate: averageHeartRate, age: age) * 0.05
            totalWeight += 0.05
            keyMetrics["averageHeartRate"] = averageHeartRate
        }

        if let systolic = metrics.systolicBloodPressure,
           let diastolic = metrics.diastolicBloodPressure,
           systolic > 0,
           diastolic > 0 {
            score += FitnessAgeScoring.scoreBloodPressure(systolic: systolic, diastolic: diastolic, age: age) * 0.20
            totalWeight += 0.20
            keyMetrics["systolicBP"] = systolic
            keyMetrics["diastolicBP"] = diastolic
            keyMetrics["meanArterialPressure"] = (systolic + (2 * diastolic)) / 3
        }

        if let respiratoryRate = metrics.respiratoryRate, respiratoryRate > 0 {
            score += FitnessAgeScoring.scoreRespiratoryRate(rate: respiratoryRate, age: age) * 0.10
            totalWeight += 0.10
            keyMetrics["respiratoryRate"] = respiratoryRate
        }

        if let oxygenSaturation = metrics.oxygenSaturation, oxygenSaturation > 0 {
            score += FitnessAgeScoring.scoreOxygenSaturation(spo2: oxygenSaturation, age: age) * 0.05
            totalWeight += 0.05
            keyMetrics["oxygenSaturation"] = oxygenSaturation
        }

        if let walkingHeartRateAverage = metrics.walkingHeartRateAverage,
           walkingHeartRateAverage > 0,
           let weight = opportunisticWeight(for: "walking_heart_rate_average") {
            score += FitnessAgeScoring.scoreWalkingHeartRateAverage(walkingHeartRateAverage, age: age) * weight
            totalWeight += weight
            keyMetrics["walkingHeartRateAverage"] = walkingHeartRateAverage
        }

        guard totalWeight > 0 else { return nil }

        let finalScore = score / totalWeight
        guard finalScore > 0 else { return nil }

        return FitnessAgeDomainScore(
            score: finalScore,
            percentile: calculatePercentileForAge(score: finalScore, age: age, domain: .cardiovascular),
            keyMetrics: keyMetrics
        )
    }

    private func calculateActivityScore(
        metrics: FitnessAgeMetrics,
        age: Int,
        sex: FitnessAgeScoring.ReferenceSex
    ) -> FitnessAgeDomainScore? {
        var score = 0.0
        var totalWeight = 0.0
        var keyMetrics: [String: Double] = [:]

        if let stepCount = metrics.stepCount, stepCount > 0 {
            score += FitnessAgeScoring.scoreStepCount(steps: stepCount, age: age) * 0.35
            totalWeight += 0.35
            keyMetrics["stepCount"] = stepCount
        }

        if let activeEnergy = metrics.activeEnergy, activeEnergy > 0 {
            score += FitnessAgeScoring.scoreActiveEnergy(calories: activeEnergy, age: age, sex: sex) * 0.30
            totalWeight += 0.30
            keyMetrics["activeEnergy"] = activeEnergy
        }

        if let exerciseTime = metrics.exerciseTime, exerciseTime > 0 {
            score += FitnessAgeScoring.scoreExerciseTime(minutes: exerciseTime) * 0.25
            totalWeight += 0.25
            keyMetrics["exerciseTime"] = exerciseTime
        }

        if let flightsClimbed = metrics.flightsClimbed, flightsClimbed > 0 {
            score += FitnessAgeScoring.scoreFlightsClimbed(flights: flightsClimbed, age: age) * 0.10
            totalWeight += 0.10
            keyMetrics["flightsClimbed"] = flightsClimbed
        }

        if let sixMinuteWalkTestDistance = metrics.sixMinuteWalkTestDistance,
           sixMinuteWalkTestDistance > 0,
           let weight = opportunisticWeight(for: "six_minute_walk_distance") {
            score += FitnessAgeScoring.scoreSixMinuteWalkDistance(sixMinuteWalkTestDistance, age: age) * weight
            totalWeight += weight
            keyMetrics["sixMinuteWalkTestDistance"] = sixMinuteWalkTestDistance
        }

        if let standHours = metrics.standHours,
           standHours > 0,
           let weight = opportunisticWeight(for: "stand_hours") {
            score += FitnessAgeScoring.scoreStandHours(standHours) * weight
            totalWeight += weight
            keyMetrics["standHours"] = standHours
        }

        if let stairAscentSpeed = metrics.stairAscentSpeed,
           stairAscentSpeed > 0,
           let weight = opportunisticWeight(for: "stair_ascent_speed") {
            score += FitnessAgeScoring.scoreStairAscentSpeed(stairAscentSpeed, age: age) * weight
            totalWeight += weight
            keyMetrics["stairAscentSpeed"] = stairAscentSpeed
        }

        if let stairDescentSpeed = metrics.stairDescentSpeed,
           stairDescentSpeed > 0,
           let weight = opportunisticWeight(for: "stair_descent_speed") {
            score += FitnessAgeScoring.scoreStairDescentSpeed(stairDescentSpeed, age: age) * weight
            totalWeight += weight
            keyMetrics["stairDescentSpeed"] = stairDescentSpeed
        }

        guard totalWeight > 0 else { return nil }

        let finalScore = score / totalWeight
        guard finalScore > 0 else { return nil }

        return FitnessAgeDomainScore(
            score: finalScore,
            percentile: calculatePercentileForAge(score: finalScore, age: age, domain: .activity),
            keyMetrics: keyMetrics
        )
    }

    private func calculateRecoveryScore(
        metrics: FitnessAgeMetrics,
        age: Int,
        sex: FitnessAgeScoring.ReferenceSex,
        allowsSleepFallback: Bool
    ) -> FitnessAgeDomainScore? {
        var score = 0.0
        var totalWeight = 0.0
        var keyMetrics: [String: Double] = [:]

        if let sleepScore = metrics.sleepScore, sleepScore > 0 {
            score += Double(sleepScore) * 0.5
            totalWeight += 0.5
            keyMetrics["sleepScore"] = Double(sleepScore)
        } else if let sleepHours = metrics.sleepHours, sleepHours > 0 {
            score += FitnessAgeScoring.scoreSleepDuration(hours: sleepHours, age: age) * 0.5
            totalWeight += 0.5
            keyMetrics["sleepHours"] = sleepHours
        } else if allowsSleepFallback {
            let fallbackSleepScore = 75.0
            score += fallbackSleepScore * 0.5
            totalWeight += 0.5
            keyMetrics["sleepFallback"] = fallbackSleepScore
        }

        if let heartRateVariability = metrics.heartRateVariability, heartRateVariability > 0 {
            score += FitnessAgeScoring.scoreHRV(hrv: heartRateVariability, age: age, sex: sex) * 0.3
            totalWeight += 0.3
            keyMetrics["heartRateVariability"] = heartRateVariability
        }

        if let restingHeartRate = metrics.restingHeartRate, restingHeartRate > 0 {
            score += FitnessAgeScoring.scoreRestingHeartRate(heartRate: restingHeartRate, age: age, sex: sex) * 0.2
            totalWeight += 0.2
            keyMetrics["restingHeartRate"] = restingHeartRate
        }

        if let sleepingWristTemperatureDeviation = metrics.sleepingWristTemperatureDeviation,
           let weight = opportunisticWeight(for: "sleeping_wrist_temperature") {
            score += FitnessAgeScoring.scoreSleepingWristTemperatureDeviation(sleepingWristTemperatureDeviation) * weight
            totalWeight += weight
            keyMetrics["sleepingWristTemperatureDeviation"] = sleepingWristTemperatureDeviation
        }

        guard totalWeight > 0 else { return nil }

        let finalScore = score / totalWeight
        guard finalScore > 0 else { return nil }

        return FitnessAgeDomainScore(
            score: finalScore,
            percentile: calculatePercentileForAge(score: finalScore, age: age, domain: .recovery),
            keyMetrics: keyMetrics
        )
    }

    private func calculateBodyCompositionScore(
        metrics: FitnessAgeMetrics,
        age: Int,
        sex: FitnessAgeScoring.ReferenceSex
    ) -> FitnessAgeDomainScore? {
        var score = 0.0
        var totalWeight = 0.0
        var keyMetrics: [String: Double] = [:]

        var hasBMI = false
        if let bodyMassIndex = metrics.bodyMassIndex, bodyMassIndex > 0 {
            score += FitnessAgeScoring.scoreBMI(bodyMassIndex: bodyMassIndex, age: age) * 0.5
            totalWeight += 0.5
            keyMetrics["bodyMassIndex"] = bodyMassIndex
            hasBMI = true
        }

        var hasBodyFat = false
        if let bodyFatPercentage = metrics.bodyFatPercentage, bodyFatPercentage > 0 {
            let bodyFatWeight = hasBMI ? 0.35 : 0.6
            score += FitnessAgeScoring.scoreBodyFatPercentage(
                bodyFat: bodyFatPercentage,
                age: age,
                sex: sex
            ) * bodyFatWeight
            totalWeight += bodyFatWeight
            keyMetrics["bodyFatPercentage"] = bodyFatPercentage
            hasBodyFat = true
        }

        if let leanBodyMass = metrics.leanBodyMass,
           let height = metrics.height,
           leanBodyMass > 0,
           height > 0 {
            let heightInMeters = height / 100
            let leanMassIndex = leanBodyMass / (heightInMeters * heightInMeters)
            let leanMassWeight = hasBMI && hasBodyFat ? 0.15 : 0.25
            score += FitnessAgeScoring.scoreLeanMassIndex(
                leanMassIndex: leanMassIndex,
                age: age,
                sex: sex
            ) * leanMassWeight
            totalWeight += leanMassWeight
            keyMetrics["leanMassIndex"] = leanMassIndex
        }

        if let bloodGlucose = metrics.bloodGlucose,
           bloodGlucose > 0,
           let weight = opportunisticWeight(for: "blood_glucose") {
            score += FitnessAgeScoring.scoreBloodGlucose(bloodGlucose) * weight
            totalWeight += weight
            keyMetrics["bloodGlucose"] = bloodGlucose
        }

        guard totalWeight > 0 else { return nil }

        let finalScore = score / totalWeight
        guard finalScore > 0 else { return nil }

        return FitnessAgeDomainScore(
            score: finalScore,
            percentile: calculatePercentileForAge(score: finalScore, age: age, domain: .bodyComposition),
            keyMetrics: keyMetrics
        )
    }

    private func calculateLifestyleScore(metrics: FitnessAgeMetrics, age: Int) -> FitnessAgeDomainScore? {
        var totalScore = 0.0
        var totalWeight = 0.0
        var keyMetrics: [String: Double] = [:]

        for metric in Self.lifestyleMetricRawWeights {
            let metricType = metric.id
            guard let metricScore = calculateLifestyleMetricScore(for: metricType, metrics: metrics, age: age),
                  metric.weight > 0 else {
                continue
            }

            totalScore += metricScore * metric.weight
            totalWeight += metric.weight

            switch metricType {
            case "movement_regularity":
                keyMetrics["movement_regularity"] = metricScore
            case "activity_consistency":
                keyMetrics["activity_consistency"] = metricScore
            case "sedentary_time":
                keyMetrics["sedentary_score"] = metricScore
            case "smoking_status":
                keyMetrics["smoking_status"] = metricScore
            case "walking_steadiness":
                if let steadiness = metrics.walkingSteadiness {
                    keyMetrics["walking_steadiness"] = steadiness * 100
                }
            case "walking_asymmetry":
                if let asymmetry = metrics.walkingAsymmetry {
                    keyMetrics["walking_asymmetry"] = asymmetry
                }
            case "double_support":
                if let doubleSupport = metrics.walkingDoubleSupport {
                    keyMetrics["double_support"] = doubleSupport
                }
            default:
                break
            }
        }

        if let timeInDaylight = metrics.timeInDaylight,
           timeInDaylight > 0,
           let weight = opportunisticWeight(for: "time_in_daylight") {
            totalScore += FitnessAgeScoring.scoreTimeInDaylight(timeInDaylight) * weight
            totalWeight += weight
            keyMetrics["timeInDaylight"] = timeInDaylight
        }

        guard totalWeight > 0 else { return nil }

        let finalScore = max(0, min(100, totalScore / totalWeight))
        guard finalScore > 0 else { return nil }

        return FitnessAgeDomainScore(
            score: finalScore,
            percentile: calculatePercentileForAge(score: finalScore, age: age, domain: .lifestyle),
            keyMetrics: keyMetrics
        )
    }

    private func calculateLifestyleMetricScore(
        for metricType: String,
        metrics: FitnessAgeMetrics,
        age: Int
    ) -> Double? {
        switch metricType {
        case "movement_regularity":
            if let stepCount = metrics.stepCount, stepCount > 0 {
                return FitnessAgeScoring.scoreMovementRegularity(stepCount: stepCount, age: age)
            }

        case "activity_consistency":
            if let stepCount = metrics.stepCount,
               let activeEnergy = metrics.activeEnergy,
               stepCount > 0,
               activeEnergy > 0 {
                return FitnessAgeScoring.scoreActivityConsistency(
                    stepCount: stepCount,
                    activeEnergy: activeEnergy,
                    age: age
                )
            }

        case "sedentary_time":
            if let stepCount = metrics.stepCount,
               let activeEnergy = metrics.activeEnergy,
               stepCount > 0,
               activeEnergy > 0 {
                return FitnessAgeScoring.scoreSedentaryTime(stepCount: stepCount, activeEnergy: activeEnergy)
            }

        case "smoking_status":
            if let isSmoker = metrics.isSmoker {
                return FitnessAgeScoring.scoreSmokingStatus(isSmoker: isSmoker)
            }

        case "walking_steadiness":
            if let walkingSteadiness = metrics.walkingSteadiness, walkingSteadiness > 0 {
                return FitnessAgeScoring.scoreWalkingSteadiness(steadiness: walkingSteadiness, age: age)
            }

        case "walking_asymmetry":
            if let walkingAsymmetry = metrics.walkingAsymmetry, walkingAsymmetry > 0 {
                return FitnessAgeScoring.scoreWalkingAsymmetry(asymmetry: walkingAsymmetry, age: age)
            }

        case "double_support":
            if let walkingDoubleSupport = metrics.walkingDoubleSupport, walkingDoubleSupport > 0 {
                return FitnessAgeScoring.scoreWalkingDoubleSupport(doubleSupport: walkingDoubleSupport, age: age)
            }

        default:
            break
        }

        return nil
    }

    private func calculatePercentileForAge(score: Double, age: Int, domain: FitnessAgeDomain) -> Double {
        let normalizedScore = (score - 50) / 20
        let percentile = 50 + (normalizedScore * 30)
        return max(0, min(100, percentile))
    }

    private func opportunisticWeight(for metricId: String) -> Double? {
        FitnessAgeMetricDefinitions.definition(for: metricId)?.nominalLocalWeight
    }
}
