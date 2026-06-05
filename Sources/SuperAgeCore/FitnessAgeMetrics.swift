import Foundation

public struct FitnessAgeMetrics: Codable, Equatable, Sendable {
    /// Resting heart rate in beats per minute.
    public var restingHeartRate: Double?
    /// VO2 max in ml/kg/min.
    public var vo2Max: Double?
    /// Heart rate variability in milliseconds.
    public var heartRateVariability: Double?
    /// Average heart rate in beats per minute.
    public var averageHeartRate: Double?
    /// Respiratory rate in breaths per minute.
    public var respiratoryRate: Double?
    /// Systolic blood pressure in mmHg.
    public var systolicBloodPressure: Double?
    /// Diastolic blood pressure in mmHg.
    public var diastolicBloodPressure: Double?
    /// Oxygen saturation as a percentage on a 0...100 scale.
    public var oxygenSaturation: Double?
    /// Maximum observed heart rate in beats per minute.
    public var maxHeartRate: Double?
    /// Walking heart rate average in beats per minute.
    public var walkingHeartRateAverage: Double?

    /// Step count over the scoring window.
    public var stepCount: Double?
    /// Active energy in kilocalories.
    public var activeEnergy: Double?
    /// Exercise time in minutes.
    public var exerciseTime: Double?
    /// Flights climbed over the scoring window.
    public var flightsClimbed: Double?
    /// Six-minute walk test distance in meters.
    public var sixMinuteWalkTestDistance: Double?
    /// Stand hours over the scoring window.
    public var standHours: Double?
    /// Stair ascent speed in meters per second.
    public var stairAscentSpeed: Double?
    /// Stair descent speed in meters per second.
    public var stairDescentSpeed: Double?

    /// Sleep duration in hours.
    public var sleepHours: Double?
    /// Sleep score on a 0...100 scale.
    public var sleepScore: Int?
    /// Sleeping wrist temperature deviation in degrees Celsius.
    public var sleepingWristTemperatureDeviation: Double?

    /// Body fat percentage on a 0...100 scale.
    public var bodyFatPercentage: Double?
    /// Lean body mass in kilograms.
    public var leanBodyMass: Double?
    /// Height in centimeters.
    public var height: Double?
    /// Weight in kilograms.
    public var weight: Double?
    /// Body mass index in kg/m^2.
    public var bodyMassIndex: Double?
    /// Blood glucose in mg/dL.
    public var bloodGlucose: Double?

    /// Walking steadiness on a 0...1 scale.
    public var walkingSteadiness: Double?
    /// Walking asymmetry percentage on a 0...100 scale.
    public var walkingAsymmetry: Double?
    /// Walking double-support percentage on a 0...100 scale.
    public var walkingDoubleSupport: Double?
    public var isSmoker: Bool?
    /// Time in daylight in minutes.
    public var timeInDaylight: Double?

    public init(
        restingHeartRate: Double? = nil,
        vo2Max: Double? = nil,
        heartRateVariability: Double? = nil,
        averageHeartRate: Double? = nil,
        respiratoryRate: Double? = nil,
        systolicBloodPressure: Double? = nil,
        diastolicBloodPressure: Double? = nil,
        oxygenSaturation: Double? = nil,
        maxHeartRate: Double? = nil,
        walkingHeartRateAverage: Double? = nil,
        stepCount: Double? = nil,
        activeEnergy: Double? = nil,
        exerciseTime: Double? = nil,
        flightsClimbed: Double? = nil,
        sixMinuteWalkTestDistance: Double? = nil,
        standHours: Double? = nil,
        stairAscentSpeed: Double? = nil,
        stairDescentSpeed: Double? = nil,
        sleepHours: Double? = nil,
        sleepScore: Int? = nil,
        sleepingWristTemperatureDeviation: Double? = nil,
        bodyFatPercentage: Double? = nil,
        leanBodyMass: Double? = nil,
        height: Double? = nil,
        weight: Double? = nil,
        bodyMassIndex: Double? = nil,
        bloodGlucose: Double? = nil,
        walkingSteadiness: Double? = nil,
        walkingAsymmetry: Double? = nil,
        walkingDoubleSupport: Double? = nil,
        isSmoker: Bool? = nil,
        timeInDaylight: Double? = nil
    ) {
        self.restingHeartRate = restingHeartRate
        self.vo2Max = vo2Max
        self.heartRateVariability = heartRateVariability
        self.averageHeartRate = averageHeartRate
        self.respiratoryRate = respiratoryRate
        self.systolicBloodPressure = systolicBloodPressure
        self.diastolicBloodPressure = diastolicBloodPressure
        self.oxygenSaturation = oxygenSaturation
        self.maxHeartRate = maxHeartRate
        self.walkingHeartRateAverage = walkingHeartRateAverage
        self.stepCount = stepCount
        self.activeEnergy = activeEnergy
        self.exerciseTime = exerciseTime
        self.flightsClimbed = flightsClimbed
        self.sixMinuteWalkTestDistance = sixMinuteWalkTestDistance
        self.standHours = standHours
        self.stairAscentSpeed = stairAscentSpeed
        self.stairDescentSpeed = stairDescentSpeed
        self.sleepHours = sleepHours
        self.sleepScore = sleepScore
        self.sleepingWristTemperatureDeviation = sleepingWristTemperatureDeviation
        self.bodyFatPercentage = bodyFatPercentage
        self.leanBodyMass = leanBodyMass
        self.height = height
        self.weight = weight
        self.bodyMassIndex = bodyMassIndex
        self.bloodGlucose = bloodGlucose
        self.walkingSteadiness = walkingSteadiness
        self.walkingAsymmetry = walkingAsymmetry
        self.walkingDoubleSupport = walkingDoubleSupport
        self.isSmoker = isSmoker
        self.timeInDaylight = timeInDaylight
    }

    private enum CodingKeys: String, CodingKey {
        case restingHeartRate
        case vo2Max
        case heartRateVariability
        case averageHeartRate
        case respiratoryRate
        case systolicBloodPressure
        case diastolicBloodPressure
        case oxygenSaturation
        case maxHeartRate
        case walkingHeartRateAverage
        case stepCount
        case activeEnergy
        case exerciseTime
        case flightsClimbed
        case sixMinuteWalkTestDistance
        case standHours
        case stairAscentSpeed
        case stairDescentSpeed
        case sleepHours
        case sleepScore
        case sleepingWristTemperatureDeviation
        case bodyFatPercentage
        case leanBodyMass
        case height
        case weight
        case bodyMassIndex
        case bloodGlucose
        case walkingSteadiness
        case walkingAsymmetry
        case walkingDoubleSupport
        case isSmoker
        case timeInDaylight
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        restingHeartRate = try container.decodeIfPresent(Double.self, forKey: .restingHeartRate)
        vo2Max = try container.decodeIfPresent(Double.self, forKey: .vo2Max)
        heartRateVariability = try container.decodeIfPresent(Double.self, forKey: .heartRateVariability)
        averageHeartRate = try container.decodeIfPresent(Double.self, forKey: .averageHeartRate)
        respiratoryRate = try container.decodeIfPresent(Double.self, forKey: .respiratoryRate)
        systolicBloodPressure = try container.decodeIfPresent(Double.self, forKey: .systolicBloodPressure)
        diastolicBloodPressure = try container.decodeIfPresent(Double.self, forKey: .diastolicBloodPressure)
        oxygenSaturation = try container.decodeIfPresent(Double.self, forKey: .oxygenSaturation)
        maxHeartRate = try container.decodeIfPresent(Double.self, forKey: .maxHeartRate)
        walkingHeartRateAverage = try container.decodeIfPresent(Double.self, forKey: .walkingHeartRateAverage)
        stepCount = try container.decodeIfPresent(Double.self, forKey: .stepCount)
        activeEnergy = try container.decodeIfPresent(Double.self, forKey: .activeEnergy)
        exerciseTime = try container.decodeIfPresent(Double.self, forKey: .exerciseTime)
        flightsClimbed = try container.decodeIfPresent(Double.self, forKey: .flightsClimbed)
        sixMinuteWalkTestDistance = try container.decodeIfPresent(Double.self, forKey: .sixMinuteWalkTestDistance)
        standHours = try container.decodeIfPresent(Double.self, forKey: .standHours)
        stairAscentSpeed = try container.decodeIfPresent(Double.self, forKey: .stairAscentSpeed)
        stairDescentSpeed = try container.decodeIfPresent(Double.self, forKey: .stairDescentSpeed)
        sleepHours = try container.decodeIfPresent(Double.self, forKey: .sleepHours)
        sleepScore = try container.decodeIfPresent(Int.self, forKey: .sleepScore)
        sleepingWristTemperatureDeviation = try container.decodeIfPresent(Double.self, forKey: .sleepingWristTemperatureDeviation)
        bodyFatPercentage = try container.decodeIfPresent(Double.self, forKey: .bodyFatPercentage)
        leanBodyMass = try container.decodeIfPresent(Double.self, forKey: .leanBodyMass)
        height = try container.decodeIfPresent(Double.self, forKey: .height)
        weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        bodyMassIndex = try container.decodeIfPresent(Double.self, forKey: .bodyMassIndex)
        bloodGlucose = try container.decodeIfPresent(Double.self, forKey: .bloodGlucose)
        walkingSteadiness = try container.decodeIfPresent(Double.self, forKey: .walkingSteadiness)
        walkingAsymmetry = try container.decodeIfPresent(Double.self, forKey: .walkingAsymmetry)
        walkingDoubleSupport = try container.decodeIfPresent(Double.self, forKey: .walkingDoubleSupport)
        isSmoker = try container.decodeIfPresent(Bool.self, forKey: .isSmoker)
        timeInDaylight = try container.decodeIfPresent(Double.self, forKey: .timeInDaylight)
    }
}

public extension FitnessAgeMetrics {
    mutating func applyDisabledMetricIds(_ disabledMetricIds: Set<String>) {
        for metricId in disabledMetricIds {
            switch metricId {
            case "resting_heartrate":
                restingHeartRate = nil
            case "vo2max":
                vo2Max = nil
            case "max_heart_rate":
                maxHeartRate = nil
            case "respiratory_rate":
                respiratoryRate = nil
            case "blood_pressure":
                systolicBloodPressure = nil
                diastolicBloodPressure = nil
            case "oxygen_saturation":
                oxygenSaturation = nil
            case "average_heart_rate":
                averageHeartRate = nil
            case "walking_heart_rate_average":
                walkingHeartRateAverage = nil
            case "steps":
                stepCount = nil
            case "calories":
                activeEnergy = nil
            case "exercise_time":
                exerciseTime = nil
            case "flights_climbed":
                flightsClimbed = nil
            case "six_minute_walk_distance":
                sixMinuteWalkTestDistance = nil
            case "stand_hours":
                standHours = nil
            case "stair_ascent_speed":
                stairAscentSpeed = nil
            case "stair_descent_speed":
                stairDescentSpeed = nil
            case "sleep":
                sleepHours = nil
                sleepScore = nil
            case "sleeping_wrist_temperature":
                sleepingWristTemperatureDeviation = nil
            case "bmi":
                bodyMassIndex = nil
            case "body_fat":
                bodyFatPercentage = nil
            case "lean_mass":
                leanBodyMass = nil
            case "height":
                height = nil
            case "weight":
                weight = nil
            case "blood_glucose":
                bloodGlucose = nil
            case "smoking_status":
                isSmoker = nil
            case "walking_steadiness":
                walkingSteadiness = nil
            case "walking_asymmetry":
                walkingAsymmetry = nil
            case "double_support":
                walkingDoubleSupport = nil
            case "time_in_daylight":
                timeInDaylight = nil
            case "walking_speed":
                break
            default:
                break
            }
        }
    }

    func filteringDisabledMetricIds(_ disabledMetricIds: Set<String>) -> FitnessAgeMetrics {
        var copy = self
        copy.applyDisabledMetricIds(disabledMetricIds)
        return copy
    }
}
