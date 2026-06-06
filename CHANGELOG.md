# Changelog

SuperAgeCore follows semantic versioning.

Algorithm changes must note affected metrics, formulas, weights, confidence logic, and expected result drift.

## Unreleased

### Changed

- Removed cross-domain score adjustment from Fitness Age domain scores so each domain score reflects only observed metrics in that domain.
- Documented the bounded score-to-age mapping used by Fitness Age while keeping domain scores deterministic and unchanged by unrelated domains.
- Added explicit algorithm modes: `evidenceFirst` for the public default and `compatibilityV1` for existing SuperAge result continuity.
- Changed the default score-to-age mapping to a symmetric evidence-first index mapping. Existing golden fixtures opt into `compatibilityV1`.
- Corrected BMI methodology text so documentation matches the implementation.

## 0.1.0 - Unreleased

- Initial private preview.
- Implements the public Foundation-only Fitness Age scoring API with normalized host-supplied inputs and deterministic results.
- Adds initial Fitness Age domain scoring, weighted present-domain aggregation, confidence calculation, and score-to-age conversion.
- Adds golden parity tests and fixtures for Fitness Age, confidence, overall score, present domains, and domain scores.
- Documents initial Fitness Age domains, missing-data behavior, opportunistic Apple Health metrics, and contributor rules for algorithm changes.
- Apache-2.0 license, DCO signoff policy, CI workflows, and contributor documentation.
