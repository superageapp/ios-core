# SuperAgeCore

SuperAgeCore is the reference Swift implementation of SuperAge Fitness Age scoring for normalized Apple Health-derived signals.

The package is designed for host apps that already have permission to read health and fitness data and can transform that data into stable, normalized inputs. SuperAgeCore is Foundation-only: it does not import HealthKit, request permissions, collect health data, store personal data, or send data to any server.

Host apps are responsible for user consent, privacy disclosures, health data access, platform policy compliance, and any regulatory obligations that apply to their product and market.

## Installation

For private preview or development before the first release tag, add SuperAgeCore
to your Swift package dependencies from `main`:

```swift
.package(url: "https://github.com/superageapp/ios-core.git", branch: "main")
```

After the first `0.1.0` preview tag is published, use the versioned dependency:

```swift
.package(url: "https://github.com/superageapp/ios-core.git", from: "0.1.0")
```

Then add `SuperAgeCore` as a dependency of the target that performs scoring.

## API

The scoring API uses explicit, normalized inputs supplied by a host app.

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

let fitnessAgeForDisplay = (result.fitnessAge * 10).rounded() / 10
let confidence = result.confidence
let domainScores = result.domainScores
```

## Methodology

See [Docs/METHODOLOGY.md](Docs/METHODOLOGY.md) for the initial Fitness Age domains, weights, missing-data behavior, opportunistic Apple Health metrics, scoring curves, confidence logic, score-to-age conversion, golden parity tests, and contributor rules for algorithm changes.

## Scope

SuperAgeCore focuses on deterministic Fitness Age scoring from normalized Apple Health-derived signals supplied by a host app. It does not own data collection, permission prompts, HealthKit queries, account systems, cloud sync, or user-facing medical interpretation.

Algorithm changes are handled through the repository RFC process before implementation so formula, weight, confidence, and output-changing metric updates can be reviewed with methodology and test evidence.

## Health Disclaimer

SuperAgeCore provides an informational fitness and wellness estimate only. It is not a diagnosis, medical device, treatment, clinical risk assessment, or substitute for professional medical advice.

Do not use SuperAgeCore outputs to diagnose, prevent, monitor, treat, or manage any disease or medical condition. Users should consult a qualified healthcare professional for health concerns, symptoms, or medical decisions.

## Contributing

Contributions are welcome under the rules in [CONTRIBUTING.md](CONTRIBUTING.md). All commits in pull requests must include a DCO signoff.

## License

SuperAgeCore is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for the full license text and [NOTICE](NOTICE) for attribution and trademark notices.
