# SuperAgeCore

[![CI](https://github.com/superageapp/ios-core/actions/workflows/ci.yml/badge.svg)](https://github.com/superageapp/ios-core/actions/workflows/ci.yml)
[![DCO](https://github.com/superageapp/ios-core/actions/workflows/dco.yml/badge.svg)](https://github.com/superageapp/ios-core/actions/workflows/dco.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

Open-source Swift package for evidence-first Fitness Age (biological age) scoring in iOS, watchOS, macOS, and tvOS apps. It is the scoring engine behind the SuperAge app.

SuperAgeCore is a Foundation-only Swift package that turns normalized fitness and wellness signals into a deterministic Fitness Age estimate, confidence score, and domain-level breakdown. It is built for host apps that already own health-data access and want the scoring engine to stay small, auditable, testable, and privacy-preserving.

It does not import HealthKit, request permissions, collect health data, store personal data, or send data to any server.

## Why SuperAgeCore

- **Deterministic by design**: the same normalized inputs produce the same Fitness Age result.
- **Evidence-first default**: confidence reflects data completeness and quality; the one score-conditioned adjustment is the documented focus-domain modifier (see Docs/METHODOLOGY.md).
- **Transparent methodology**: domains, weights, scoring curves, source anchors, and compatibility rules are documented.
- **Host-owned privacy boundary**: apps provide normalized values; the package never touches user accounts, cloud sync, HealthKit authorization, or network transport.
- **Compatibility when needed**: existing SuperAge integrations can opt into the versioned `compatibilityV1` mode explicitly.

## Installation

For released builds, pin an exact version so algorithm updates cannot change results through package resolution alone:

```swift
.package(url: "https://github.com/superageapp/ios-core.git", exact: "0.4.0")
```

Use `main` only for unreleased development and preview integration:

```swift
.package(url: "https://github.com/superageapp/ios-core.git", branch: "main")
```

Then add `SuperAgeCore` as a dependency of the target that performs scoring.

## Quick Start

The scoring API uses explicit, normalized inputs supplied by the host app.

```swift
import SuperAgeCore

let input = FitnessAgeInput(
    profile: FitnessAgeProfile(
        chronologicalAge: 42,
        biologicalSex: .male
    ),
    metrics: FitnessAgeMetrics(
        restingHeartRate: 58,
        vo2Max: 45,
        heartRateVariability: 50,
        respiratoryRate: 15,
        stepCount: 10_000,
        activeEnergy: 600,
        exerciseTime: 45,
        sleepHours: 7.5,
        bodyMassIndex: 23.5
    )
)

let result = FitnessAgeCalculator().calculate(input)

let fitnessAge = (result.fitnessAge * 10).rounded() / 10
let confidence = result.confidence
let overallScore = result.overallScore
let domainScores = result.domainScores
```

`result.fitnessAge` is intended for informational fitness and wellness experiences. It is not a diagnosis or clinical risk estimate.

SuperAgeCore is calibrated for adults: profiles with a chronological age below 18 are invalid for calculation and return a neutral, low-confidence result instead of an estimate extrapolated from adult reference curves.

## Mobility Context

Many Apple Health-derived metrics are produced by step and gait detection. When that detection cannot run, the host does not receive a low value, it receives a value that does not describe the person: wearables have been reported as recording zero steps for someone walking with a walker. Declare the applicable instruments so those metrics are removed rather than scored as inactivity:

```swift
let profile = FitnessAgeProfile(
    chronologicalAge: 42,
    biologicalSex: .male,
    mobilityContext: .assistedMobility
)
```

`ambulatory` is the default and removes nothing; it covers unaided walking and cane use. `assistedMobility` covers walkers, crutches and wheeled mobility, and removes the step-derived and gait-derived instruments. Hourly movement is kept in both: on Apple Watch the Stand ring becomes a Roll ring in wheelchair mode. Domains renormalize over the instruments that remain, so no threshold, curve, or weight changes.

This is a measurement-applicability input, not a diagnosis or clinical classification. Hosts are responsible for how the value is collected and for the consent and privacy obligations that attach to it. See [Docs/METHODOLOGY.md](Docs/METHODOLOGY.md) for the per-context applicability table and source anchors.

## Algorithm Modes

`FitnessAgeConfiguration.default` uses the `evidenceFirst` algorithm mode. This mode derives confidence from data completeness and quality (plus the documented focus-domain modifier) and maps the normalized score symmetrically around chronological age.

Existing SuperAge integrations that need result continuity can opt into the versioned compatibility mode:

```swift
let input = FitnessAgeInput(
    profile: profile,
    metrics: metrics,
    configuration: .compatibilityV1
)
```

Custom host apps can also provide explicit domain weights and score-to-age mapping bounds through `FitnessAgeConfiguration`.

## Methodology

See [Docs/METHODOLOGY.md](Docs/METHODOLOGY.md) for:

- Fitness Age domains and weights
- supported normalized metrics
- missing-data behavior
- opportunistic Apple Health-derived metrics
- scoring curves and confidence logic
- score-to-age conversion
- golden parity tests
- source anchors
- contributor rules for algorithm changes

Algorithm changes are handled through the repository RFC process before implementation so formula, weight, confidence, and output-changing metric updates can be reviewed with methodology and test evidence.

## Release Policy

SuperAgeCore follows semantic versioning.

- Patch releases (`0.x.Y` increments) are for bug fixes, documentation, and test updates that do not intentionally change scoring output.
- Minor releases (`0.x.0`) may change formulas, weights, confidence logic, supported metrics, or expected results.
- Every output-changing release must describe affected metrics, formulas, weights, confidence behavior, and expected result drift in [CHANGELOG.md](CHANGELOG.md).
- Host apps should pin exact package versions and choose when to adopt algorithm changes.

Releases are created from GitHub Actions after the release workflow's build and test checks pass on macOS and Linux and the changelog section for that version is ready.

When a pull request is merged to `main`, the release workflow reads the latest dated SemVer section in `CHANGELOG.md`. If the matching tag does not exist, it runs the Swift checks, creates an annotated tag, and publishes a GitHub Release; if the tag already exists, the workflow skips publishing without failing. This means every merge to `main` is expected to be release-ready.

The release workflow can also be run manually from GitHub Actions for a specific version.

## Scope

SuperAgeCore focuses on deterministic Fitness Age scoring from normalized fitness and wellness signals supplied by a host app.

It does not own:

- HealthKit queries or authorization prompts
- data collection or wearable sync
- account systems or cloud storage
- personalized medical interpretation
- regulatory compliance for a host product

Host apps are responsible for user consent, privacy disclosures, health data access, platform policy compliance, and any regulatory obligations that apply to their product and market.

## Health Disclaimer

SuperAgeCore provides an informational fitness and wellness estimate only. It is not a diagnosis, medical device, treatment, clinical risk assessment, or substitute for professional medical advice.

Do not use SuperAgeCore outputs to diagnose, prevent, monitor, treat, or manage any disease or medical condition. Users should consult a qualified healthcare professional for health concerns, symptoms, or medical decisions.

## Useful Links

- [SuperAge website](https://www.superage.app) — the biological age app for iPhone and Apple Watch, powered by SuperAgeCore
- [SuperAge on the App Store](https://apps.apple.com/app/id6751951815) — download the app for iOS
- [Methodology](Docs/METHODOLOGY.md) — Fitness Age domains, weights, scoring curves, confidence logic, and source anchors
- [Changelog](CHANGELOG.md) — release notes and expected result drift for every version
- [Contributing guide](CONTRIBUTING.md) — DCO signoff and the Algorithm RFC process
- [Issues](https://github.com/superageapp/ios-core/issues) — bug reports, questions, and Algorithm RFC proposals

## Contributing

Contributions are welcome under the rules in [CONTRIBUTING.md](CONTRIBUTING.md). All commits in pull requests must include a DCO signoff:

```bash
git commit --signoff
```

Formula, weight, confidence, or output-changing metric updates should start with an Algorithm RFC issue.

## License

SuperAgeCore is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for the full license text and [NOTICE](NOTICE) for attribution and trademark notices.
