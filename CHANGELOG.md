# Changelog

All notable changes to BuildLine are recorded here. The project follows [semver](https://semver.org).
Accumulate changes under **Unreleased**; `scripts/release.sh` promotes that section to a versioned
release and uses it as the GitHub release notes.

<!-- NEXT: scripts/release.sh inserts the new version section directly below this line -->
## [Unreleased]

## [0.3.0] - 2026-06-18

- **npm package platform** (first web/Node target): `build`, `ship` (publish under a prerelease
  dist-tag), and `submit --confirm` (promote to the production dist-tag). Auto-detected from
  `package.json`; provenance via OIDC in CI. Live-verified against npmjs.org.
- **`ship`/`test` skip gracefully when a scheme has no test target** instead of failing — no more
  forced `--skip-tests`.
- `ship` **warns when a TestFlight build is missing export compliance** (set
  `distribute.uses_nonexempt_encryption` to declare it).
- Docs: README npm section + user-framed **Status** table; clearer Homebrew tap-trust note.
- Release tooling: `scripts/release.sh` syncs the README + CHANGELOG to the public tap and promotes the
  changelog idempotently.

## [0.2.1] - 2026-06-17

- Android (Google Play) pipeline: `build` (Gradle `.aab`/`.apk`), `sign setup` (upload keystore),
  `ship` (testing tracks), and `submit` (production), all gated by `--confirm`.
- README: per-platform "What's Required" boxes and a full Android guide.

## [0.1.1] - 2026-06-16

- iOS pipeline end to end: `build`, `sign` (reproducible signing store), `test`, `ship`
  (TestFlight), and `submit` (App Store review).
- `buildline init`, `--json` output for CI, and the public Homebrew tap.
