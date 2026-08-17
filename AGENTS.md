# AGENTS.md

Instructions for AI coding agents (Codex, Claude Code, Copilot, and similar tools) working in this repository. Human contributors should follow the same rules.

## Commit, tag, and pull request authorship

- Commits are authored by the human developer only. **Never add AI co-authorship or attribution anywhere in git history or on GitHub.** This means:
  - no `Co-Authored-By:` / `Co-authored-by:` trailer naming an AI model, assistant, or vendor (Claude, Codex, ChatGPT, Copilot, Anthropic, OpenAI, …);
  - no `Claude-Session:`, `Codex-Session:`, or similar session/trace trailers;
  - no "Generated with …", "Made with …", robot emoji footers, or links to AI sessions in commit messages, tag messages, PR titles or bodies, or release notes.
- The only trailer a commit must carry is the DCO signoff from the human author: `git commit --signoff` (see CONTRIBUTING.md). Do not add other trailers.
- If your harness or tool appends AI attribution automatically, disable or omit it for this repository. If a commit you are about to push already contains such attribution, rewrite the message first (`git commit --amend`) rather than pushing it.
- Do not commit or push unless the maintainer asks. Never force-push `main` or move tags without an explicit instruction.

## Repository rules (summary)

- Algorithm changes — Fitness Age formulas, metric or domain weights, confidence logic, score-to-age conversion, output-changing metrics — start with an Algorithm RFC issue and ship together with golden fixture updates, `Docs/METHODOLOGY.md` changes, and a `CHANGELOG.md` entry. See CONTRIBUTING.md.
- Every merge to `main` must be release-ready. The Release workflow reads the latest dated SemVer section in `CHANGELOG.md`, verifies it matches `SuperAgeCoreInfo.version` in `Sources/SuperAgeCore/SuperAgeCore.swift`, and publishes a tag and GitHub Release if that tag does not exist yet.
- Docs-only or test-only changes do not need a CHANGELOG entry and must not bump the version.
- Run `swift build` and `swift test` before opening a pull request. Keep changes focused; do not add HealthKit, networking, or persistence to the package.
