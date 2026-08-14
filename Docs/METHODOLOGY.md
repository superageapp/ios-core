# Fitness Age Methodology

SuperAgeCore calculates Fitness Age from normalized Apple Health-derived signals supplied by a host app. It does not import HealthKit, query Apple Health, request permissions, collect data, store personal data, or send data to any server.

Host apps are responsible for consent, privacy disclosures, platform policy compliance, unit conversion, sampling windows, data quality filtering, and any regulatory obligations that apply to their product and market.

## Inputs and Domains

The calculator accepts `FitnessAgeInput`, which combines:

- `FitnessAgeProfile`: chronological age, biological sex, excluded domains, focus domains, disabled metric IDs, and mobility context.
- `FitnessAgeMetrics`: optional normalized metric values.
- `FitnessAgeConfiguration`: algorithm mode, domain weights, and mapping bounds.

The algorithm is calibrated for chronological ages 18 and over. Profiles with a lower age are invalid for calculation and return the neutral low-confidence result: Fitness Age equal to chronological age, overall score `50`, confidence `0.10`, and no domain scores.

The default domain weights are:

| Domain | Default weight |
| --- | ---: |
| `cardiovascular` | 0.28 |
| `activity` | 0.24 |
| `recovery` | 0.15 |
| `bodyComposition` | 0.18 |
| `lifestyle` | 0.15 |

## How Constants Are Classified

The implementation uses deterministic constants in six roles:

- **Reference ranges:** metric-specific ranges used to map normalized observations to a `0...100` score.
- **Metric weights:** local weights that describe how observed metrics contribute inside a domain.
- **Domain weights:** default weights that describe how present domains contribute to the overall score.
- **Normalization curves:** bounded transforms that convert raw values into comparable scores.
- **Fallback defaults:** documented continuity behavior used when a caller supplies related data but omits a metric required by the initial scoring schema.
- **Compatibility constants:** stable values retained so current SuperAgeCore results remain comparable across package revisions.

Constants are part of the public algorithm contract. Output-changing changes to them require an Algorithm RFC, updated tests, updated methodology documentation, and a changelog entry.

Custom configured domain weights are sanitized during aggregation:

```text
sanitizedWeight = min(0.40, max(0.0, configuredWeightOrDefault))
```

Only present domains participate in the final weighted average. If no domain has a score, the overall score defaults to `50`.

## Algorithm Modes

`FitnessAgeConfiguration.algorithmMode` selects how the package maps the
normalized score to Fitness Age.

| Mode | Intended use | Score-to-age behavior |
| --- | --- | --- |
| `evidenceFirst` | Public default for new integrations | Symmetric index mapping around chronological age |
| `compatibilityV1` | Result continuity for existing SuperAge integrations | Preserves the 0.1.x compatibility mapping and confidence adjustment |
| `custom` | Host apps that supply explicit mapping bounds | Uses the evidence-first formula with caller-supplied bounds |

`FitnessAgeConfiguration.default` uses `evidenceFirst`. Existing encoded
configurations that omit `algorithmMode` decode to `evidenceFirst`.
`FitnessAgeConfiguration.compatibilityV1` is available for hosts that need to
preserve previous display behavior while migrating.

## Missing Data and Disabled Inputs

Metric availability is intentionally sparse-compatible:

- `nil` metrics are omitted.
- Numeric `0` values are omitted unless a metric is explicitly zero-scorable. The current zero-scorable metric is `sleepingWristTemperatureDeviation`, where `0` means no observed deviation and maps to the top score for that metric.
- Boolean metrics are omitted only when `nil`; `isSmoker == false` is observed data and maps to the top score for that metric.
- A domain with no observed scorable metrics is omitted from `domainScores` and from weighted aggregation. A domain whose observed metrics compute a score of exactly `0` is observed data and is retained with score `0`.
- Unknown disabled metric IDs are ignored.

Sleep uses an explicit fallback to preserve deterministic continuity when a caller supplies other recovery data but no sleep observation:

- If `sleepScore > 0`, recovery uses `sleepScore` directly with local weight `0.50`.
- Else if `sleepHours > 0`, recovery scores sleep duration with local weight `0.50`.
- Else, if the `sleep` metric ID is not disabled and at least one other recovery metric is observed, recovery uses a synthetic `sleepFallback` score of `75` with local weight `0.50`.
- If `sleep` is disabled, `sleepHours`, `sleepScore`, and the synthetic fallback are all omitted.
- With no observed recovery metric at all, the fallback does not apply and the recovery domain is omitted, so an input with no observed metrics anywhere maps to chronological age instead of a synthetic result.

Disabled metric IDs are applied before scoring by clearing the mapped metric fields from the input copy. Excluded domains are applied after domain scoring and remove those domains from results, weighted aggregation, confidence domain completeness, and metric counts.

### Recognized Disabled Metric IDs

Metric IDs are exact strings; unrecognized IDs are ignored.

| Metric ID | Fields cleared |
| --- | --- |
| `resting_heartrate` | `restingHeartRate` |
| `vo2max` | `vo2Max` |
| `max_heart_rate` | `maxHeartRate` |
| `respiratory_rate` | `respiratoryRate` |
| `blood_pressure` | `systolicBloodPressure`, `diastolicBloodPressure` |
| `oxygen_saturation` | `oxygenSaturation` |
| `average_heart_rate` | `averageHeartRate` |
| `walking_heart_rate_average` | `walkingHeartRateAverage` |
| `steps` | `stepCount` |
| `calories` | `activeEnergy` |
| `exercise_time` | `exerciseTime` |
| `flights_climbed` | `flightsClimbed` |
| `six_minute_walk_distance` | `sixMinuteWalkTestDistance` |
| `stand_hours` | `standHours` |
| `stair_ascent_speed` | `stairAscentSpeed` |
| `stair_descent_speed` | `stairDescentSpeed` |
| `sleep` | `sleepHours`, `sleepScore`, and the synthetic sleep fallback |
| `sleeping_wrist_temperature` | `sleepingWristTemperatureDeviation` |
| `bmi` | `bodyMassIndex` |
| `body_fat` | `bodyFatPercentage` |
| `lean_mass` | `leanBodyMass` |
| `height` | `height` |
| `blood_glucose` | `bloodGlucose` |
| `smoking_status` | `isSmoker` |
| `walking_steadiness` | `walkingSteadiness` |
| `walking_asymmetry` | `walkingAsymmetry` |
| `double_support` | `walkingDoubleSupport` |
| `time_in_daylight` | `timeInDaylight` |

## Mobility Context and Instrument Applicability

Many Apple Health-derived metrics are produced by step and gait detection. When that detection cannot run, the host does not receive a low value: it receives a value that does not describe the person. Wearables have been reported as recording zero steps for someone walking with a walker. Scoring that as inactivity is a measurement error, not a fitness result.

`FitnessAgeProfile.mobilityContext` lets a host declare which movement instruments can be observed, so the calculator scores only applicable ones.

This is a measurement-applicability input. It is not a diagnosis, not a clinical classification, and not a statement about health status. It changes no threshold, curve, weight, or score.

| Context | Meaning |
| --- | --- |
| `ambulatory` | Walks unaided, or with a cane. Every movement instrument applies. This is the default. |
| `assistedMobility` | Uses a mobility aid that bears weight, such as a walker or crutches, or uses wheeled mobility. |

Metric applicability by context:

| Metric ID | `ambulatory` | `assistedMobility` |
| --- | :---: | :---: |
| `steps` | applies | not observable |
| `six_minute_walk_distance` | applies | not observable |
| `flights_climbed` | applies | not observable |
| `stair_ascent_speed` | applies | not observable |
| `stair_descent_speed` | applies | not observable |
| `walking_heart_rate_average` | applies | not observable |
| `walking_steadiness` | applies | not observable |
| `walking_asymmetry` | applies | not observable |
| `double_support` | applies | not observable |
| `stand_hours` | applies | applies |

Metrics that are not observable for the declared context are unioned with `disabledMetricIds` before scoring, so they follow exactly the documented removal path of a host-disabled metric: the field is cleared, the domain divides by the observed local weights that remain, and data quality averages over observed components only. Removing an inapplicable instrument is therefore identical to host-disabling its metric ID: scores, Fitness Age, confidence, and `metricsUsed` match an input that never supplied the value, while `totalPossibleMetrics` truthfully shrinks to the instruments observable for the declared context.

The lifestyle metrics `movement_regularity`, `activity_consistency`, and `sedentary_time` are derived from `stepCount`, so they drop out with it and require no separate mapping.

No domain collapses from the context alone. Under `assistedMobility`, activity remains scorable through `activeEnergy` and `exerciseTime`, and lifestyle remains scorable through `isSmoker` and `timeInDaylight`.

### Where the Boundaries Come From

- Step counting is described in measurement research as applicable only to ambulatory populations, with detection degrading further under slow or irregular gait (Suzuki et al., 2025).
- Weight-bearing walking aids break step detection rather than merely adding noise. Wrist and hip devices have been reported as showing poor validity in patients using gait aids, recording near-zero step counts during walker use, with agreement recovering only once the aid was no longer used (Kooner et al., 2024). Wrist step-count error during walker use has been reported at 31.2 percent (Jaworski et al., 2025). Wheeled mobility produces no steps at all, so both patterns share one context.
- Cane use is on the other side of that boundary. Wrist step counting during cane use has been reported at roughly two percent mean error, which is measurement noise, not inapplicability, so cane users are `ambulatory` (Jaworski et al., 2025).
- Gait-quality instruments derive from the same step and gait characterization, so they follow step counting rather than forming a separate tier.
- Hourly movement remains observable in every context, so `stand_hours` is never removed. On Apple Watch, wheelchair mode turns the Stand ring into a Roll ring that counts hours containing at least a minute of movement, against the same daily goal.
- Activity targets themselves are not context-specific. The WHO 2020 guidelines added recommendations for people living with chronic conditions or disability, so `activeEnergy` and `exerciseTime` remain the applicable activity instruments rather than being replaced by different targets (Bull et al., 2020).

### Deliberately Out of Scope

This mechanism removes instruments that cannot be observed. It does not adjust targets for conditions where the instrument works but the expected value is debated, such as fatigue-related or mental-health-related conditions: step count is measurable there, and changing its target without an evidence anchor would be a scoring change presented as an applicability change. Such an adjustment would require an Algorithm RFC and its own source anchors.

Energy-based instruments are not free of population-specific measurement error either: accelerometer-based energy-expenditure estimates in manual wheelchair users carry placement-dependent error, with waist placement reported as underestimating in prior work reviewed by Nightingale et al. (2015). SuperAgeCore consumes host-normalized values and does not correct for sensor placement.

Hosts remain responsible for how this value is collected and for the privacy and consent obligations that attach to it.

## Domain Metric Weights

Within each domain, observed metric scores are weighted locally, then normalized by the total observed local weight:

```text
domainScore = sum(metricScore * localWeight) / sum(observedLocalWeights)
```

### Cardiovascular

| Metric | Input field | Local weight |
| --- | --- | ---: |
| Maximum heart rate | `maxHeartRate` | 0.18 |
| VO2 max | `vo2Max` | 0.42 |
| Average heart rate | `averageHeartRate` | 0.05 |
| Blood pressure | `systolicBloodPressure` + `diastolicBloodPressure` | 0.20 |
| Respiratory rate | `respiratoryRate` | 0.10 |
| Oxygen saturation | `oxygenSaturation` | 0.05 |
| Walking heart rate average | `walkingHeartRateAverage` | 0.10 |

### Activity

| Metric | Input field | Local weight |
| --- | --- | ---: |
| Step count | `stepCount` | 0.35 |
| Active energy | `activeEnergy` | 0.30 |
| Exercise time | `exerciseTime` | 0.25 |
| Flights climbed | `flightsClimbed` | 0.10 |
| Six-minute walk test distance | `sixMinuteWalkTestDistance` | 0.18 |
| Stand hours | `standHours` | 0.08 |
| Stair ascent speed | `stairAscentSpeed` | 0.04 |
| Stair descent speed | `stairDescentSpeed` | 0.04 |

### Recovery

| Metric | Input field | Local weight |
| --- | --- | ---: |
| Sleep score, sleep duration, or sleep fallback | `sleepScore`, `sleepHours`, or `sleepFallback` | 0.50 |
| Heart rate variability | `heartRateVariability` | 0.30 |
| Resting heart rate | `restingHeartRate` | 0.20 |
| Sleeping wrist temperature deviation | `sleepingWristTemperatureDeviation` | 0.15 |

### Body Composition

| Metric | Input field | Local weight |
| --- | --- | ---: |
| Body mass index | `bodyMassIndex` | 0.50 |
| Body fat percentage when BMI is present | `bodyFatPercentage` | 0.35 |
| Body fat percentage when BMI is absent | `bodyFatPercentage` | 0.60 |
| Lean mass index when BMI and body fat are present | `leanBodyMass` + `height` | 0.15 |
| Lean mass index otherwise | `leanBodyMass` + `height` | 0.25 |
| Blood glucose | `bloodGlucose` | 0.15 |

Lean mass index is derived as:

```text
leanMassIndex = leanBodyMassKg / (heightMeters * heightMeters)
```

### Lifestyle

| Metric | Required input | Local weight |
| --- | --- | ---: |
| Movement regularity | `stepCount` | 0.18 |
| Activity consistency | `stepCount` + `activeEnergy` | 0.16 |
| Sedentary score | `stepCount` + `activeEnergy` | 0.10 |
| Smoking status | `isSmoker` | 0.20 |
| Walking steadiness | `walkingSteadiness` | 0.16 |
| Walking asymmetry | `walkingAsymmetry` | 0.10 |
| Walking double support | `walkingDoubleSupport` | 0.10 |
| Time in daylight | `timeInDaylight` | 0.10 |

## Opportunistic Apple Health Metrics

The following Apple Health-derived metrics are opportunistic: they affect the algorithm when present, but their absence does not make an input invalid.

| Metric ID | Domain | Local weight |
| --- | --- | ---: |
| `walking_heart_rate_average` | `cardiovascular` | 0.10 |
| `six_minute_walk_distance` | `activity` | 0.18 |
| `stand_hours` | `activity` | 0.08 |
| `stair_ascent_speed` | `activity` | 0.04 |
| `stair_descent_speed` | `activity` | 0.04 |
| `sleeping_wrist_temperature` | `recovery` | 0.15 |
| `blood_glucose` | `bodyComposition` | 0.15 |
| `time_in_daylight` | `lifestyle` | 0.10 |

## Methodology Source Anchors

The package uses external references for threshold anchors where practical, then
uses package-specific interpolation to convert observations into a common
`0...100` scoring scale.

| Area | Source anchor | Package-specific layer |
| --- | --- | --- |
| Maximum heart rate | Tanaka, Monahan, and Seals age-predicted HRmax equation: https://pubmed.ncbi.nlm.nih.gov/11153730/ | Percentage bands and age adjustment |
| Physical activity | WHO adult physical activity recommendations: https://www.ncbi.nlm.nih.gov/books/NBK566046/ | Daily exercise-time scoring and activity-domain weights |
| BMI | CDC adult BMI categories and screening limitation: https://www.cdc.gov/bmi/adult-calculator/bmi-categories.html | Smooth scoring inside and outside category thresholds |
| Blood pressure | American Heart Association blood pressure categories: https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings | Score levels and age adjustment |
| VO2 max | FRIEND Registry cardiorespiratory fitness reference standards: https://pmc.ncbi.nlm.nih.gov/articles/PMC4919021/ | Decade buckets and interpolation between bands |
| Six-minute walk distance | Apple HealthKit six-minute walk distance behavior: https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifiersixminutewalktestdistance | Age bands and activity-domain weighting |
| Blood glucose | CDC and ADA fasting glucose thresholds: https://www.cdc.gov/diabetes/diabetes-testing/index.html and https://diabetes.org/about-diabetes/diagnosis | Score levels around normal, elevated, and high ranges |
| Sleep duration | National Sleep Foundation duration recommendations discussed in population research: https://pmc.ncbi.nlm.nih.gov/articles/PMC8201191/ | Midpoint scoring and duration deviation curve |
| Step counting applicability | Suzuki et al., JMIR Formative Research, 2025, stating that step counting applies only to ambulatory patients and degrades with irregular gait: https://pmc.ncbi.nlm.nih.gov/articles/PMC11999377/ | Mapping from mobility context to the set of unobservable metric IDs |
| Step detection under walking aids | Kooner et al., Journal of Orthopaedic Surgery and Research, 2024, reporting poor validity of wrist and hip activity monitors in patients using gait aids: https://pmc.ncbi.nlm.nih.gov/articles/PMC11247726/ | Placing walker and crutch use outside the ambulatory context |
| Walking aid error magnitude | Jaworski et al., International Journal of Environmental Research and Public Health, 2025, reporting 31.2 percent wrist step-count error with a walker and roughly two percent with a cane: https://pmc.ncbi.nlm.nih.gov/articles/PMC12294748/ | Keeping cane use inside the ambulatory context |
| Activity targets across mobility contexts | Bull et al., British Journal of Sports Medicine, 2020, WHO 2020 guidelines adding recommendations for people living with chronic conditions or disability: https://pubmed.ncbi.nlm.nih.gov/33239350/ | Keeping the same activity instruments and targets instead of substituting context-specific ones |
| Wheeled-mobility activity measurement error | Nightingale et al., PLoS One, 2015, on accelerometer placement and energy expenditure error in manual wheelchair users: https://pmc.ncbi.nlm.nih.gov/articles/PMC4425541/ | Documented limitation only; the package consumes host-normalized values |

## Scoring Curves

Each metric is converted to a `0...100` score before domain aggregation. Most curves are piecewise thresholds with age or sex adjustments where applicable.

Reference curves use the female table when `biologicalSex == .female`; other values use the male table for metric-curve selection and receive separate confidence handling when the value is `unknown` or `intersex`. This is deterministic reference-curve handling, not a clinical sex-specific judgement.

### Shared Age Adjustment

Some curves apply an age adjustment multiplier and clamp to `0...100`:

| Age | Multiplier |
| --- | --- |
| 18...30 | `1.01 + ((age - 18) / 12) * 0.03` |
| 31...50 | `1.04 + ((age - 31) / 19) * 0.04` |
| 51...65 | `1.08 + ((age - 51) / 14) * 0.06` |
| 66+ | `1.14 + ((min(age, 85) - 65) / 20) * 0.06` |

### Cardiovascular Curves

| Metric | Curve summary |
| --- | --- |
| Maximum heart rate | Reference is Tanaka `208 - 0.7 * age`. Score is 100 at or above reference; then linearly steps through 90, 80, 70, 60, and 50 at 95%, 90%, 85%, 80%, and 75% of reference; below 75%, score is `(percentage / 0.75) * 50`. Age adjustment: 1.00 through 40, 1.02 at 41...50, 1.05 at 51...60, 1.08 at 61...70, 1.10 after 70. |
| VO2 max | Uses decade-bucket male/female reference tables for excellent, good, acceptable, and minimum values from ages 20, 30, 40, 50, 60, and 70. Score is 100 at excellent; 85...100 between good and excellent; 65...85 between acceptable and good; 40...65 between minimum and acceptable; below minimum, `(value / minimum) * 40`. |
| Average heart rate | 100 at 55...65 bpm, 90 at 65...75, 75 at 75...85, 55 at 85...95, 35 at 95...105, 85 below 55, and `35 - (heartRate - 105) * 2` above 105 clamped at 0. |
| Blood pressure | 100 below 120/80, 85 below 130/85, 65 below 140/90, 40 below 160/100, otherwise 20. Age adjustment: 1.00 through 30, 1.05 at 31...50, 1.10 at 51...65, 1.15 after 65. |
| Respiratory rate | 100 at 12...16, 85 at 10..<12 or 16..<18, 70 at 8..<10 or 18..<20, 55 at 6..<8 or 20...22, otherwise `55 - abs(rate - 15) * 3` with floor 20. |
| Oxygen saturation | Base score: 100 at 97%+, 85 at 95..<97, 60 at 93..<95, 35 at 90..<93, 20 at 88..<90, otherwise `20 - (88 - SpO2) * 5` with floor 0. Age adjustment: 1.00 through 50, 1.05 at 51...65, 1.08 at 66...75, 1.10 after 75. |
| Walking heart rate average | Age-adjusted target upper bounds are 95, 100, 105, and 110 bpm for ages through 30, 31...50, 51...65, and 66+. Acceptable upper bounds are 115, 120, 125, and 130 bpm. Score is 100 at or below target, 75...100 between target and acceptable, then `75 - (value - acceptable) * 2` with floor 20. |

### Activity Curves

| Metric | Curve summary |
| --- | --- |
| Step count | Age targets are 8,000, 7,200, 6,300, and 5,400 for ages through 30, 31...50, 51...65, and 66+. Ratio scores: 100 at 1.3+, 90 at 1.1+, 80 at 1.0+, 65 at 0.8+, 45 at 0.6+, 25 at 0.4+, otherwise `ratio * 30`; then age adjustment applies. |
| Active energy | Sex and age targets: male 320/275/230/165 kcal, female 230/185/155/120 kcal for the same age bands. Ratio scores: 100 at 1.4+, 90 at 1.2+, 75 at 1.0+, 60 at 0.8+, 40 at 0.6+, 25 at 0.4+, otherwise `ratio * 35`. |
| Exercise time | Converts daily minutes to weekly minutes. Scores 100 at 150+ weekly minutes, 80 at 120+, 60 at 90+, 40 at 60+, otherwise `(weeklyMinutes / 150) * 100`. |
| Flights climbed | Age targets are 12, 10, 8, and 6 flights. Ratio scores: 100 at 1.5+, 90 at 1.2+, 80 at 1.0+, 65 at 0.7+, 45 at 0.4+, otherwise `ratio * 60`; then age adjustment applies. |
| Six-minute walk distance | Target is 500 m. Acceptable distance is 400, 390, 380, or 360 m by age band. Score is 100 at target+, 75...100 between acceptable and target, otherwise `(value / acceptable) * 75` with floor 20. |
| Stand hours | 100 at 10...16 hours, 82 at 8..<10 or 16...18, 65 at 6..<8 or 18...20, 45 at 4..<6 or 20...22, otherwise `45 - abs(value - 13) * 4` with floor 20. |
| Stair ascent speed | Targets are 0.90, 0.82, 0.72, and 0.62 m/s by age band. Acceptable minimums are 0.65, 0.60, 0.52, and 0.45 m/s. Score is 100 at target+, 75...100 between acceptable and target, otherwise `(value / acceptable) * 75` with floor 20; then age adjustment applies. |
| Stair descent speed | Targets are 0.95, 0.87, 0.77, and 0.67 m/s by age band. Acceptable minimums are 0.70, 0.64, 0.56, and 0.48 m/s. Uses the same stair speed formula as ascent. |

### Recovery Curves

| Metric | Curve summary |
| --- | --- |
| Sleep score | Uses the supplied `0...100` score directly when positive. |
| Sleep duration | Optimal range is 7...9 hours through age 65 and 7...8 hours after 65. Within range, score is at least 95 and decreases by `5` per hour away from the midpoint. Outside range, score is `95 - deviationHours * 12` with floor 30. |
| Sleep fallback | Uses score 75 when sleep is missing and `sleep` is not disabled. |
| Heart rate variability | Age targets are 45, 38, 32, 27, and 22 ms for 20...30, 31...40, 41...50, 51...60, and all other ages. Ratio scores: 100 at 1.2+, 85 at 1.0+, 65 at 0.8+, 40 at 0.6+, otherwise `ratio * 40`; then age adjustment applies. |
| Resting heart rate | 100 at 40...60 bpm, 85 at 60...70, 65 at 70...80, 40 at 80...90, `100 - (40 - heartRate) * 4` below 40 with floor 0, otherwise `40 - (heartRate - 90) * 2` with floor 0; then age adjustment applies. |
| Sleeping wrist temperature deviation | Uses absolute deviation. Score is 100 through 0.15 C, 85 through 0.30 C, 65 through 0.45 C, 45 through 0.60 C, otherwise `45 - (deviation - 0.60) * 50` with floor 20. |

### Body Composition Curves

| Metric | Curve summary |
| --- | --- |
| Body mass index | Healthy range is 18.5...25.0 through age 65 and 20.0...27.0 after 65. Ideal is 22. Score is 100 within 1 BMI point of ideal, otherwise at least 95 within the healthy range. Above the upper healthy bound, score grades linearly to 60 at BMI 30, then to 35 at BMI 35, then continues downward with floor 0. Below the lower healthy bound, score grades from 75 at BMI 17 to the healthy floor score, then continues downward with floor 0. |
| Body fat percentage | Healthy ranges by age and sex: male 8...19, 11...22, 13...25, 15...28; female 16...24, 18...27, 21...30, 23...33. Score is 100 inside range, otherwise `100 - deviationFromNearestBound * 3` with floor 0. |
| Lean mass index | Target is 18 for male reference curves and 14 for female reference curves. `adjustedTarget = target * max(0.8, 1 - (age - 30) * 0.005)`. Score is `(leanMassIndex / adjustedTarget) * 85`, clamped to 0...100. |
| Blood glucose | 100 at 70...110 mg/dL, 82 at 60..<70 or 110...125, 60 at 50..<60 or 125...140, otherwise `60 - abs(value - 90) * 0.8` with floor 20. |

### Lifestyle Curves

| Metric | Curve summary |
| --- | --- |
| Movement regularity | Age-adjusted step targets are 10,000, 8,500, 7,500, and 6,500. Ratio scores: 100 at 1.2+, 85 at 1.0+, 70 at 0.8+, 55 at 0.6+, otherwise 40. |
| Activity consistency | Target steps are 8,000 through age 65 and 7,000 after 65. Target active energy is 300 kcal through age 65 and 200 after 65. Score is `stepScore * 0.7 + energyScore * 0.3`, where each component is capped at 100. |
| Sedentary score | `min(100, steps / 10000 * 70) + min(100, activeEnergy / 400 * 30)`. |
| Smoking status | 100 when `isSmoker == false`, 30 when `isSmoker == true`. |
| Walking steadiness | Input is clamped to 0...1. Score is 100 at 0.90+, 85 at 0.80+, 70 at 0.70+, 55 at 0.60+, otherwise `steadiness * 75` with floor 20; then age adjustment applies. |
| Walking asymmetry | Thresholds are 2, 4, 6, and 8, plus age tolerance of 0 through 39, 0.5 at 40...54, 1.0 at 55...69, and 1.5 after 69. Scores are 100, 85, 70, and 55 through those thresholds; above poor, `55 - (asymmetry - poorThreshold) * 4` with floor 20; then age adjustment applies. |
| Walking double support | Thresholds are 20, 24, 28, and 32, plus age tolerance of 0 through 39, 1 at 40...54, 2 at 55...69, and 3 after 69. Scores are 100, 85, 70, and 55 through those thresholds; above poor, `55 - (doubleSupport - poorThreshold) * 2.5` with floor 20; then age adjustment applies. |
| Time in daylight | 100 at 30...120 minutes, linearly 70...100 at 15..<30, 85 above 120 through 180, 65 above 180 through 240, below 15 as `(value / 15) * 70` with floor 20, and 45 above 240. |

## Domain Relative Standing and Data Quality Fields

Each `FitnessAgeDomainScore` carries two auxiliary fields:

- `percentile` is a synthetic relative-standing index derived affinely from the domain score: `clamp(50 + (score - 50) * 1.5, 0, 100)`. It is not a measured population percentile and no reference distribution is consulted; scores of `83.34` or higher saturate at `100`.
- `dataQuality` is reserved for future per-domain data-quality reporting; the calculator currently always emits `1.0`.

`FitnessAgeResult` also reports instrument counts:

- `metricsUsed` is the number of distinct physical instruments observed across scored domains. The blood pressure pair counts as one instrument, the sleep inputs share one instrument, the step- and energy-derived lifestyle composites count toward their source step and energy instruments, and derived values such as mean arterial pressure or the synthetic sleep fallback do not count.
- `totalPossibleMetrics` is the number of physical instruments that could have been observed for the input, after removing disabled metric IDs and excluded domains. With no exclusions it is `28`.

## Overall Score, Confidence, and Fitness Age

Overall score uses weighted present-domain normalization. Domain scores are not adjusted based on performance in other domains.

```text
overallScore = sum(domainScore * sanitizedDomainWeight) / sum(presentSanitizedDomainWeights)
```

Confidence combines domain completeness and data quality:

```text
if algorithmMode == compatibilityV1:
    domainCompleteness = presentDomainCount / 6
else:
    domainCompleteness = presentDomainCount / enabledDomainCount

confidence = domainCompleteness * 0.6 + weightedDataQuality * 0.4
```

The fixed divisor in `compatibilityV1` is retained only for result continuity.
`evidenceFirst` and `custom` use the count of enabled public domains, with a
minimum divisor of `1`.

Data quality and the key-metric increments below use the same observability rule as scoring: a supplied numeric `0` is an omitted observation, not evidence.

Data quality includes these observed components:

| Observed metric | Quality | Weight |
| --- | ---: | ---: |
| `stepCount` | 0.85 | 0.23 |
| `activeEnergy` | 0.85 | 0.17 |
| `exerciseTime` | 0.85 | 0.17 |
| `sleepHours` or `sleepScore` | 0.85 | 0.23 |

If none of those components are observed, data quality defaults to `0.70`.

Confidence then receives key metric increments:

| Observed metric | Confidence increment |
| --- | ---: |
| `vo2Max` | +0.08 |
| `restingHeartRate` | +0.04 |
| `heartRateVariability` | +0.04 |
| Blood pressure pair | +0.03 |

Additional confidence modifiers:

- `unknown` or `intersex` biological sex multiplies confidence by `0.92`.
- If at least two `focusDomains` have domain scores above `80`, confidence is multiplied by `1.05`.
- Final confidence is clamped to `0.10...1.00`.

### Evidence-First Score-to-Age Mapping

`evidenceFirst` and `custom` first clamp overall score to `0...100`, then map
the bounded score symmetrically around chronological age:

```text
boundedScore = clamp(score, 0, 100)
normalizedScore = (boundedScore - 50) / 50
proposedAge = chronologicalAge - (normalizedScore * maximumAgeDelta)
fitnessAge = clamp(proposedAge, minimumDisplayAge, chronologicalAge + maximumAgeDelta)
```

Default mapping bounds are:

| Field | Default |
| --- | ---: |
| `maximumAgeDelta` | 10 years |
| `minimumDisplayAge` | 18 years |

Under the default mapping, score `50` maps to chronological age, score `100`
maps to 10 years younger before the adult lower bound, and score `0` maps to 10
years older.

### Compatibility V1 Score-to-Age Mapping

`compatibilityV1` preserves the original SuperAgeCore 0.1.x score-to-age mapping
for hosts that need result continuity. It first clamps overall score to
`0...100`, then maps the bounded score to an age difference with a continuous
curve at score `50`:

```text
boundedScore = clamp(score, 0, 100)

if boundedScore >= 50:
    progress = (boundedScore - 50) / 50
    ageDifference = -(progress * 2.0) - (progress * progress * 8.5)
else:
    progress = (50 - boundedScore) / 50
    ageDifference = progress * 3.75

baseAge = chronologicalAge + ageDifference
```

The compatibility base age is clamped by chronological-age group:

| Chronological age | Younger cap | Older cap |
| --- | ---: | ---: |
| 18...25 | 5 years | 4 years |
| 26...35 | 8 years | 5 years |
| 36...50 | 10 years | 5 years |
| 51...65 | 10 years | 5 years |
| Other valid ages | 10 years | 4 years |

The compatibility final age is never below `18`.

The compatibility adjustment applies only when confidence is between `0.5` and
`0.9`, peaking at `0.7`:

```text
if confidence <= 0.7:
    normalized = (confidence - 0.5) / 0.2
else:
    normalized = 1 - ((confidence - 0.7) / 0.2)

smoothFactor = (1 - cos(normalized * pi)) / 2
```

If `baseAge` is older than chronological age, the adjusted age is reduced by
`smoothFactor * 0.4`, but not below chronological age. If `baseAge` is younger
than or equal to chronological age, the adjusted age is reduced by
`smoothFactor * 0.3`.

## Golden Parity and Contributor Rules

`Tests/SuperAgeCoreTests/FitnessAgeGoldenTests.swift` loads `Tests/SuperAgeCoreTests/Fixtures/fitness_age_golden.json` and verifies Fitness Age, confidence, overall score, present domains, and domain scores within a `0.01` tolerance.

Any output-changing algorithm change requires:

- An approved Algorithm RFC before implementation.
- Updated fixtures and golden tests.
- Updated methodology documentation.
- A changelog entry that describes affected metrics, formulas, weights, confidence logic, and expected result drift.

Output-changing changes include Fitness Age formulas, metric curves, local metric weights, domain weights, missing-data behavior, confidence logic, score-to-age conversion, and adding or removing algorithm-affecting metrics.

## Limitations and Health Disclaimer

SuperAgeCore provides an informational fitness and wellness estimate only. It is not a clinical diagnosis, medical device, treatment, clinical risk assessment, or substitute for professional medical advice.

Do not use SuperAgeCore outputs to diagnose, prevent, monitor, treat, or manage any disease or medical condition. Users should consult a qualified healthcare professional for health concerns, symptoms, or medical decisions.
