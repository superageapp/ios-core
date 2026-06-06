# Changelog

SuperAgeCore follows semantic versioning.

Algorithm changes must note affected metrics, formulas, weights, confidence logic, and expected result drift.

## Unreleased

## 0.1.0 - 2026-06-06

### Added

- Initial public preview of the Foundation-only Fitness Age scoring API with normalized host-supplied inputs and deterministic results.
- Added Fitness Age domain scoring, weighted present-domain aggregation, confidence calculation, and score-to-age conversion.
- Added golden parity tests and fixtures for Fitness Age, confidence, overall score, present domains, and domain scores.
- Documented Fitness Age domains, missing-data behavior, opportunistic Apple Health-derived metrics, and contributor rules for algorithm changes.
- Added Apache-2.0 license, DCO signoff policy, CI workflows, and contributor documentation.
- Added a manual GitHub Actions release workflow that validates SemVer input, requires a dated changelog section, runs Swift build/test, creates an annotated tag, and publishes a GitHub Release.
- Documented release and package pinning policy in the README.

### Changed

- Removed cross-domain score adjustment from Fitness Age domain scores so each domain score reflects only observed metrics in that domain.
- Documented the bounded score-to-age mapping used by Fitness Age while keeping domain scores deterministic and unchanged by unrelated domains.
- Added explicit algorithm modes: `evidenceFirst` for the public default and `compatibilityV1` for existing SuperAge result continuity.
- Changed the default score-to-age mapping to a symmetric evidence-first index mapping. Existing golden fixtures opt into `compatibilityV1`.
- Corrected BMI methodology text so documentation matches the implementation.
