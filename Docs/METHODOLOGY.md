# Fitness Age Methodology

SuperAgeCore calculates Fitness Age from normalized Apple Health-derived signals supplied by a host app. It does not import HealthKit, query Apple Health, request permissions, collect data, store personal data, or send data to any server.

Host apps are responsible for consent, privacy disclosures, platform policy compliance, unit conversion, sampling windows, data quality filtering, and any regulatory obligations that apply to their product and market.

## Inputs and Domains

The calculator accepts `FitnessAgeInput`, which combines:

- `FitnessAgeProfile`: chronological age, biological sex, excluded domains, focus domains, and disabled metric IDs.
- `FitnessAgeMetrics`: optional normalized metric values.
- `FitnessAgeConfiguration`: domain weights.

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

## Missing Data and Disabled Inputs

Metric availability is intentionally sparse-compatible:

- `nil` metrics are omitted.
- Numeric `0` values are omitted unless a metric is explicitly zero-scorable. The current zero-scorable metric is `sleepingWristTemperatureDeviation`, where `0` means no observed deviation and scores as favorable.
- Boolean metrics are omitted only when `nil`; `isSmoker == false` is observed data and scores as favorable.
- A domain with no observed scorable metrics is omitted from `domainScores` and from weighted aggregation, except for the documented recovery sleep fallback.
- Unknown disabled metric IDs are ignored.

Sleep uses an explicit fallback to preserve deterministic continuity when a caller supplies recovery data but no sleep observation:

- If `sleepScore > 0`, recovery uses `sleepScore` directly with local weight `0.50`.
- Else if `sleepHours > 0`, recovery scores sleep duration with local weight `0.50`.
- Else, if the `sleep` metric ID is not disabled, recovery uses a synthetic `sleepFallback` score of `75` with local weight `0.50`.
- If `sleep` is disabled, `sleepHours`, `sleepScore`, and the synthetic fallback are all omitted.

Disabled metric IDs are applied before scoring by clearing the mapped metric fields from the input copy. Excluded domains are applied after domain scoring and remove those domains from results, weighted aggregation, confidence domain completeness, and metric counts.

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

## Scoring Curves

Each metric is converted to a `0...100` score before domain aggregation. Most curves are piecewise thresholds with age or sex adjustments where applicable.

Reference curves use the female table when `biologicalSex == .female`; other values use the male table for metric-curve selection and receive separate confidence handling when the value is `unknown` or `intersex`. This is deterministic reference-curve handling, not a clinical sex-specific judgement.

### Shared Age Leniency

Some curves apply an age leniency multiplier and clamp to `0...100`:

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
| Oxygen saturation | Base score: 100 at 97...100%, 85 at 95...96.9, 60 at 93...94.9, 35 at 90...92.9, 20 at 88...89.9, otherwise `20 - (90 - SpO2) * 5` with floor 0. Age adjustment: 1.00 through 50, 1.05 at 51...65, 1.08 at 66...75, 1.10 after 75. |
| Walking heart rate average | Age-adjusted target upper bounds are 95, 100, 105, and 110 bpm for ages through 30, 31...50, 51...65, and 66+. Acceptable upper bounds are 115, 120, 125, and 130 bpm. Score is 100 at or below target, 75...100 between target and acceptable, then `75 - (value - acceptable) * 2` with floor 20. |

### Activity Curves

| Metric | Curve summary |
| --- | --- |
| Step count | Age targets are 8,000, 7,200, 6,300, and 5,400 for ages through 30, 31...50, 51...65, and 66+. Ratio scores: 100 at 1.3+, 90 at 1.1+, 80 at 1.0+, 65 at 0.8+, 45 at 0.6+, 25 at 0.4+, otherwise `ratio * 30`; then age leniency applies. |
| Active energy | Sex and age targets: male 320/275/230/165 kcal, female 230/185/155/120 kcal for the same age bands. Ratio scores: 100 at 1.4+, 90 at 1.2+, 75 at 1.0+, 60 at 0.8+, 40 at 0.6+, 25 at 0.4+, otherwise `ratio * 35`. |
| Exercise time | Converts daily minutes to weekly minutes. Scores 100 at 150+ weekly minutes, 80 at 120+, 60 at 90+, 40 at 60+, otherwise `(weeklyMinutes / 150) * 100`. |
| Flights climbed | Age targets are 12, 10, 8, and 6 flights. Ratio scores: 100 at 1.5+, 90 at 1.2+, 80 at 1.0+, 65 at 0.7+, 45 at 0.4+, otherwise `ratio * 60`; then age leniency applies. |
| Six-minute walk distance | Target is 500 m. Acceptable distance is 400, 390, 380, or 360 m by age band. Score is 100 at target+, 75...100 between acceptable and target, otherwise `(value / acceptable) * 75` with floor 20. |
| Stand hours | 100 at 10...16 hours, 82 at 8..<10 or 16...18, 65 at 6..<8 or 18...20, 45 at 4..<6 or 20...22, otherwise `45 - abs(value - 13) * 4` with floor 20. |
| Stair ascent speed | Targets are 0.90, 0.82, 0.72, and 0.62 m/s by age band. Acceptable minimums are 0.65, 0.60, 0.52, and 0.45 m/s. Score is 100 at target+, 75...100 between acceptable and target, otherwise `(value / acceptable) * 75` with floor 20; then age leniency applies. |
| Stair descent speed | Targets are 0.95, 0.87, 0.77, and 0.67 m/s by age band. Acceptable minimums are 0.70, 0.64, 0.56, and 0.48 m/s. Uses the same stair speed formula as ascent. |

### Recovery Curves

| Metric | Curve summary |
| --- | --- |
| Sleep score | Uses the supplied `0...100` score directly when positive. |
| Sleep duration | Optimal range is 7...9 hours through age 65 and 7...8 hours after 65. Within range, score is at least 95 and decreases by `5` per hour away from the midpoint. Outside range, score is `95 - deviationHours * 12` with floor 30. |
| Sleep fallback | Uses score 75 when sleep is missing and `sleep` is not disabled. |
| Heart rate variability | Age targets are 45, 38, 32, 27, and 22 ms for 20...30, 31...40, 41...50, 51...60, and all other ages. Ratio scores: 100 at 1.2+, 85 at 1.0+, 65 at 0.8+, 40 at 0.6+, otherwise `ratio * 40`; then age leniency applies. |
| Resting heart rate | 100 at 40...60 bpm, 85 at 60...70, 65 at 70...80, 40 at 80...90, otherwise `40 - (heartRate - 90) * 2` with floor 0; then age leniency applies. |
| Sleeping wrist temperature deviation | Uses absolute deviation. Score is 100 through 0.15 C, 85 through 0.30 C, 65 through 0.45 C, 45 through 0.60 C, otherwise `45 - (deviation - 0.60) * 50` with floor 20. |

### Body Composition Curves

| Metric | Curve summary |
| --- | --- |
| Body mass index | Optimal range is 18.5...24.9 through age 65 and 20...27 after 65. Ideal is 22. Score is 100 within 1 BMI point of ideal, otherwise 95...100 within range. Scores overweight BMI 25...29.9 as `85 - (BMI - 25) * 5` with floor 60, BMI 30...34.9 as `60 - (BMI - 30) * 5` with floor 35, BMI 17...18.4 as `75 - (18.5 - BMI) * 8` with floor 50, and all other values as `35 - abs(BMI - 22) * 3` with floor 0. |
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
| Walking steadiness | Input is clamped to 0...1. Score is 100 at 0.90+, 85 at 0.80+, 70 at 0.70+, 55 at 0.60+, otherwise `steadiness * 75` with floor 20; then age leniency applies. |
| Walking asymmetry | Thresholds are 2, 4, 6, and 8, plus age tolerance of 0 through 39, 0.5 at 40...54, 1.0 at 55...69, and 1.5 after 69. Scores are 100, 85, 70, and 55 through those thresholds; above poor, `55 - (asymmetry - poorThreshold) * 4` with floor 20; then age leniency applies. |
| Walking double support | Thresholds are 20, 24, 28, and 32, plus age tolerance of 0 through 39, 1 at 40...54, 2 at 55...69, and 3 after 69. Scores are 100, 85, 70, and 55 through those thresholds; above poor, `55 - (doubleSupport - poorThreshold) * 2.5` with floor 20; then age leniency applies. |
| Time in daylight | 100 at 30...120 minutes, linearly 70...100 at 15..<30, 85 at 121...180, 65 at 181...240, below 15 as `(value / 15) * 70` with floor 20, and 45 above 240. |

## Overall Score, Confidence, and Fitness Age

Overall score uses weighted present-domain normalization. Domain scores are not adjusted based on performance in other domains.

```text
overallScore = sum(domainScore * sanitizedDomainWeight) / sum(presentSanitizedDomainWeights)
```

Confidence combines domain completeness and data quality using a fixed six-domain normalization divisor so confidence stays comparable across sparse input sets:

```text
domainCompleteness = presentDomainCount / 6
confidence = domainCompleteness * 0.6 + weightedDataQuality * 0.4
```

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

Fitness Age conversion first clamps overall score to `0...100`, then maps the bounded score to an age difference with a continuous curve at score `50`:

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

The base age is clamped by chronological-age group:

| Chronological age | Younger cap | Older cap |
| --- | ---: | ---: |
| 18...25 | 5 years | 4 years |
| 26...35 | 8 years | 5 years |
| 36...50 | 10 years | 5 years |
| 51...65 | 10 years | 5 years |
| Other valid ages | 10 years | 4 years |

The final age is never below `18`.

Confidence-conditioned rounding applies only when confidence is between `0.5` and `0.9`, peaking at `0.7`:

```text
if confidence <= 0.7:
    normalized = (confidence - 0.5) / 0.2
else:
    normalized = 1 - ((confidence - 0.7) / 0.2)

smoothFactor = (1 - cos(normalized * pi)) / 2
```

If `baseAge` is older than chronological age, the rounded age is reduced by `smoothFactor * 0.4`, but not below chronological age. If `baseAge` is younger than or equal to chronological age, the rounded age is reduced by `smoothFactor * 0.3`.

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
