# Contributing

Thank you for contributing to SuperAgeCore. This project is intended to be a small, reviewable Swift package for Fitness Age scoring from normalized Apple Health-derived signals.

## Contribution License

By submitting a pull request, issue, comment, patch, or other contribution, you agree that your contribution is licensed under the Apache License 2.0.

## DCO Signoff

SuperAgeCore uses the Developer Certificate of Origin (DCO). Every commit in a pull request must include a `Signed-off-by` trailer.

Use Git's signoff flag when committing:

```bash
git commit -s -m "your message"
```

The DCO check runs in CI and will fail pull requests with unsigned commits.

## Pull Requests

Normal pull requests are welcome for:

- Bug fixes
- Tests
- Documentation
- Behavior-preserving refactors
- CI improvements

Keep changes focused and include validation notes in the pull request description. For behavior changes, update tests and the changelog.

## Algorithm RFCs

Algorithm changes require an approved RFC before implementation. Open an Algorithm RFC issue before changing:

- Fitness Age formulas
- Metric weights
- Domain weights
- Confidence logic
- Score-to-age conversion
- Output-changing metrics

An RFC must include:

- Motivation
- Affected metrics and domains
- Expected output impact
- Updated tests
- Methodology documentation changes
- Changelog entry

After the RFC is approved, implementation pull requests should link back to the RFC and keep code, tests, methodology notes, and changelog updates together.
