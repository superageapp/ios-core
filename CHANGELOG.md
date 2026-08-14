# Changelog

SuperAgeCore follows semantic versioning.

Algorithm changes must note affected metrics, formulas, weights, confidence logic, and expected result drift.

## Unreleased

## 0.4.0 - 2026-08-14

### Fixed

- Resting heart rate below 40 bpm no longer scores as perfect fitness. The curve previously routed bradycardia readings into the tachycardia formula, which the `0...100` clamp turned into a score of 100; readings below 40 now score `100 - (40 - heartRate) * 4` with floor 0, continuous at 40 bpm. Expected drift: only inputs with `restingHeartRate < 40`, which now score lower except where the age-adjusted score still saturates at 100 just below the boundary.
- Oxygen saturation bands are contiguous. Fractional readings in the former gaps (96.9-97, 94.9-95, 92.9-93, 89.9-90) fell into the below-88 penalty formula and could score up to 40 points below both neighbors; the sub-88 formula is also rebased to `20 - (88 - SpO2) * 5` so the curve is monotone. Expected drift: fractional SpO2 inputs inside the former gaps; readings in 84-88, which now score higher (both formulas floor at 0 from 84 down); and out-of-contract readings above 100, which now score 100.
- Time in daylight bands are contiguous. Fractional minutes in the former gaps (120-121 and 180-181) scored 45 instead of the neighboring band values. Expected drift: only fractional inputs inside those two gaps.
- A domain whose observed metrics compute a score of exactly 0 is retained with score 0 instead of being dropped from aggregation, so a worse reading can no longer improve the overall result. Expected drift: only inputs where every observed metric in a domain scores 0.
- Confidence increments and data-quality components now use the same observability rule as scoring: a supplied numeric 0 is an omitted observation. Previously `vo2Max = 0` still earned the `+0.08` confidence increment. Expected drift: confidence decreases for inputs that supply zero-valued key metrics, and in `compatibilityV1` mode the confidence-driven smoothing can shift the Fitness Age as well; the `zero_values_excluded` golden case moves from confidence 0.8 to 0.72 and from Fitness Age 30.63 to 30.48.
- The synthetic sleep fallback now requires at least one other observed recovery metric, matching its documented purpose of preserving continuity when a caller supplies recovery data without a sleep observation. An input with no observed metrics anywhere now maps to chronological age with confidence 0.28 instead of scoring a synthetic recovery-only domain 5 years younger. Expected drift: only inputs with no observed recovery metric.

### Changed

- Profiles with a chronological age below 18 are invalid for calculation and receive the neutral low-confidence result. The algorithm is calibrated for adults; extrapolating adult reference curves down to children and then flooring the display age at 18 was misleading.
- `metricsUsed` and `totalPossibleMetrics` now count distinct physical instruments truthfully: the blood pressure pair is one instrument, the sleep inputs share one instrument, the step- and energy-derived lifestyle composites count toward their source step and energy instruments, derived values do not count, and `totalPossibleMetrics` reports the instruments observable for the input after disabled metric IDs and excluded domains, instead of always equaling `metricsUsed`.
- `FitnessAgeResult.difference` is now a computed property, so it can no longer go stale when `fitnessAge` or `chronologicalAge` are mutated. The encoded JSON shape is unchanged.
- Renamed the `SuperAgeCore` namespace enum to `SuperAgeCoreInfo` so the type no longer shadows the module name, and updated `SuperAgeCoreInfo.version` to report the released version.
- Removed the unused `FitnessAgeMetrics.weight` field and the unused `weight` and `walking_speed` disabled-metric IDs; no scoring path ever read them.
- Golden coverage now includes female reference curves, the `evidenceFirst` mapping, a gait/clinical profile, and the focus-domain confidence modifier, in addition to the previous compatibility cases.

## 0.3.0 - 2026-08-10

### Changed

- Replaced the three-value mobility context with two values: `ambulatory` and `assistedMobility`. `assistedAmbulation` and `nonAmbulatory` are removed. Weight-bearing walking aids and wheeled mobility share one applicability boundary, because step and gait detection fails for both, so a separate case described no separate behavior.
- `stand_hours` is no longer removed by any context. On Apple Watch, wheelchair mode turns the Stand ring into a Roll ring that counts hours containing at least a minute of movement against the same daily goal, so the instrument remains observable. The 0.2.0 applicability table was wrong on this point.

Callers on 0.2.0 must map `assistedAmbulation` and `nonAmbulatory` to `assistedMobility`. Encoded profiles carrying a removed raw value decode to `ambulatory` through the existing `decodeIfPresent` default. Behavior for `ambulatory` is unchanged and golden fixtures are unchanged.

## 0.2.0 - 2026-08-10

### Added

- Added `FitnessAgeMobilityContext` and `FitnessAgeProfile.mobilityContext`, a measurement-applicability input that declares which movement instruments can be observed for a person. Metrics produced by step and gait detection are removed before scoring when the declared context cannot produce them, instead of reaching the calculator as a value that reads like inactivity.
- Added `FitnessAgeProfile.effectiveDisabledMetricIds`, exposing the host-disabled metric IDs unioned with the IDs the mobility context cannot observe.
- Documented mobility context, the per-context applicability table, where each boundary comes from, and what is deliberately out of scope, with source anchors for step-counting applicability, step detection under walking aids, walking-aid error magnitude, activity targets across mobility contexts, and wheeled-mobility measurement error.

No result drift for existing callers. `mobilityContext` defaults to `ambulatory`, which removes no metric; encoded profiles that omit the field decode to `ambulatory`. Golden fixtures are unchanged.

Affected metrics under a non-default context: `steps`, `six_minute_walk_distance`, `flights_climbed`, `stair_ascent_speed`, `stair_descent_speed`, `walking_heart_rate_average`, `walking_steadiness`, `walking_asymmetry`, `double_support`, and the step-derived lifestyle metrics `movement_regularity`, `activity_consistency`, and `sedentary_time`. `stand_hours` is additionally removed under `nonAmbulatory` only. No formula, curve, local weight, domain weight, or confidence rule changed. Removal reuses the existing disabled-metric path, so domains renormalize over the observed local weights that remain.

## 0.1.0 - 2026-06-06

### Added

- Initial public preview of the Foundation-only Fitness Age scoring API with normalized host-supplied inputs and deterministic results.
- Added Fitness Age domain scoring, weighted present-domain aggregation, confidence calculation, and score-to-age conversion.
- Added golden parity tests and fixtures for Fitness Age, confidence, overall score, present domains, and domain scores.
- Documented Fitness Age domains, missing-data behavior, opportunistic Apple Health-derived metrics, and contributor rules for algorithm changes.
- Added Apache-2.0 license, DCO signoff policy, CI workflows, and contributor documentation.
- Added a GitHub Actions release workflow that validates SemVer input, requires a dated changelog section, runs Swift build/test, creates an annotated tag, and publishes a GitHub Release automatically after merges to `main`.
- Documented release and package pinning policy in the README.

### Changed

- Removed cross-domain score adjustment from Fitness Age domain scores so each domain score reflects only observed metrics in that domain.
- Documented the bounded score-to-age mapping used by Fitness Age while keeping domain scores deterministic and unchanged by unrelated domains.
- Added explicit algorithm modes: `evidenceFirst` for the public default and `compatibilityV1` for existing SuperAge result continuity.
- Changed the default score-to-age mapping to a symmetric evidence-first index mapping. Existing golden fixtures opt into `compatibilityV1`.
- Corrected BMI methodology text so documentation matches the implementation.
