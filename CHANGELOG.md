# Changelog

All notable changes to BuildLine are recorded here. The project follows [semver](https://semver.org).
Accumulate changes under **Unreleased**; `scripts/release.sh` promotes that section to a versioned
release and uses it as the GitHub release notes.

<!-- NEXT: scripts/release.sh inserts the new version section directly below this line -->
## [Unreleased]

## [0.4.6] - 2026-07-09

- `ship` (iOS): **confirm the version before building** — on a terminal, show the marketing version
  (read from the project) and the next build number (from App Store Connect) and let the user accept
  (Enter) or type replacements, then pin them for the build. Mirrors the Android prompt: buildline
  auto-increments the build number but never the marketing version, so this is how you bump
  `1.5.7 → 1.5.8`. No prompt in CI (no TTY) or when reusing an archive.

## [0.4.5] - 2026-07-09

- `ship` (Android): **confirm the version before building** — on a terminal, show the resolved version
  code and the marketing version name and let the user accept (Enter) or type replacements, then pin
  them for the build. buildline auto-increments the numeric code but never the version *name*; this is
  how you bump `1.5.7 → 1.5.8`. No prompt in CI (no TTY) or when reusing a prebuilt artifact.

## [0.4.4] - 2026-07-09

- `ship` (Android): **reuse an existing `.aab`/`.apk`** instead of rebuilding (`--reuse-build` /
  `--new-build`, or a prompt on a TTY), and **delete the artifact after a successful upload**
  (`--keep-build` to keep it). A failed ship leaves the artifact for a fast `--reuse-build` retry.
- docs/warning: the version-code wiring now uses a **plain-Groovy `def` above `android {`** — the
  inline `versionCode (… ?: N) as Integer` form inside `defaultConfig` fails AGP evaluation with a
  *"Value is null"* error. The ship summary's hint now shows the robust form.

## [0.4.3] - 2026-07-09

- `ship` (Android): **warn when `build.gradle` hardcodes `versionCode`**, so a resolved version code
  that Gradle silently ignores (the app never bumps) is surfaced in the ship summary with the one-line
  fix, instead of shipping the same code every time. buildline already passes `-PversionCode` /
  `-PversionName`; this catches projects that don't read them. README documents the required wiring.

## [0.4.2] - 2026-07-09

- **`buildline sign import --keystore`** (Android): import an existing Play **upload keystore** into the
  encrypted store, so buildline signs with the key Play already trusts instead of the fresh one
  `sign setup` generates. It validates the keystore opens with your alias/password and prints the key's
  **SHA1** to confirm against Play App Signing. Fixes *"The Android App Bundle was signed with the wrong
  key"* for apps that already have a registered upload key. `sign import` is now platform-aware —
  `--p12` for iOS, `--keystore` for Android.

## [0.4.1] - 2026-07-01

- `ship`: **fix TestFlight "Missing Compliance" for real** — wait for App Store Connect to actually
  evaluate the build (its beta-detail state becomes `MISSING_EXPORT_COMPLIANCE`) before declaring
  export compliance, then confirm it clears. v0.4.0 patched the moment the build turned `VALID`, but a
  fast build reports `VALID` before Apple evaluates it, so the declaration didn't persist and the
  build stayed Missing Compliance. The `processing` step now waits out the real evaluation.
- **Store-passphrase prompt**: when `signing.storage.passphrase` can't be resolved, `build`/`ship`/
  `sign setup` prompt for it once, save it to the macOS Keychain, and point `buildline.yml` at
  `keychain:buildline-store-passphrase` — so later runs proceed without re-exporting it. In CI (no
  TTY) a missing passphrase stays a clear error. `sign setup --save-passphrase` also persists the ref.

## [0.4.0] - 2026-06-30

- `ship`: **fix TestFlight "Missing Compliance"** — the export-compliance declaration is now applied
  *after* the build finishes processing and confirmed to clear before the build is distributed. (A
  patch sent during processing did not persist, and changing `usesNonExemptEncryption` makes App Store
  Connect re-process the build, so the old approach left builds stuck Missing Compliance.) New
  `ship --exempt` / `--non-exempt` flags declare encryption use from the CLI.

## [0.3.1] - 2026-06-18

- `build`/`ship`: **reuse an existing `.xcarchive`** instead of re-archiving (`--reuse-archive` /
  `--new-archive`, or a prompt when a TTY) — skips the slow `xcodebuild archive`.
- `ship`: when no beta group is set, **choose a TestFlight group interactively** and save it to
  `buildline.yml`, instead of hand-typing the name.

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
