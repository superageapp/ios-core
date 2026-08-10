# Changelog

SuperAgeCore follows semantic versioning.

Algorithm changes must note affected metrics, formulas, weights, confidence logic, and expected result drift.

## Unreleased

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
