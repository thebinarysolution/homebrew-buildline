# Changelog

All notable changes to BuildLine are recorded here. The project follows [semver](https://semver.org).
Accumulate changes under **Unreleased**; `scripts/release.sh` promotes that section to a versioned
release and uses it as the GitHub release notes.

<!-- NEXT: scripts/release.sh inserts the new version section directly below this line -->
## [Unreleased]

## [0.2.1] - 2026-06-17

## [0.2.0] - 2026-06-17

## [0.2.0] - 2026-06-17

- Android (Google Play) pipeline: `build` (Gradle `.aab`/`.apk`), `sign setup` (upload keystore),
  `ship` (testing tracks), and `submit` (production), gated by `--confirm`.
- README: per-platform "What's Required" boxes and an Android guide.

## [0.1.1] - 2026-06-16

- iOS pipeline end to end: `build`, `sign` (reproducible signing store), `test`, `ship`
  (TestFlight), and `submit` (App Store review).
- `buildline init`, `--json` output for CI, and the public Homebrew tap.
