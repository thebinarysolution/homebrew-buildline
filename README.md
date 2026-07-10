# BuildLine

<!-- RELEASE -->**Latest release:** [v0.4.7](https://github.com/thebinarysolution/homebrew-buildline/releases/tag/v0.4.7) · [changelog](CHANGELOG.md)<!-- /RELEASE -->

**One config file, zero setup, app in the store.** BuildLine is a single-binary CLI that takes an
iOS or Android app — or an npm package — from source to its store/registry, driven by one
`buildline.yml`. The same verbs (`build` → `ship` → `submit`) run on every platform; only the
destination changes (App Store / Play / the npm registry). The platform is auto-detected from the
repo. The value is orchestration and developer experience, not reinventing the toolchains. **Jump to
[Android](#android-google-play) or [npm](#npm-package-registry).**

```sh
buildline init     # discover the project, write buildline.yml
buildline build    # archive + export a signed .ipa
buildline sign setup   # make code signing reproducible on any machine
buildline ship     # test, upload to TestFlight, assign a beta group
buildline submit   # push metadata + screenshots, send for App Store review
```

## Requirements

- **iOS:** macOS with Xcode (the toolchain BuildLine shells out to). For anything past `build`, an
  **App Store Connect API key** (`.p8`) with the **App Manager** or **Admin** role — create one at App
  Store Connect → Users and Access → Integrations.
- **Android:** **JDK 17+** and a **Gradle project**; for anything past `build`, a **Google Play
  service account** (and the Android SDK build-tools if you build APKs). See
  [Android (Google Play)](#android-google-play).
- **npm:** **Node.js** + a package manager (npm/pnpm/yarn/bun) and a `package.json`; to publish, an
  **npm automation token**. See [npm (package registry)](#npm-package-registry).
- **Go 1.25+** to build the binary (a prebuilt release/Homebrew tap is available).

## Install

```sh
brew tap thebinarysolution/buildline
brew trust thebinarysolution/buildline   # one-time — see note below
brew install buildline
```

Modern Homebrew (6.x) requires you to explicitly **trust any third-party tap** the first time, as a
supply-chain safeguard — without `brew trust` you'll get *"Refusing to load formula … from untrusted
tap."* This is a per-user, one-time step for every non-core tap (not specific to BuildLine).

The source is private; Homebrew installs the prebuilt macOS binary (universal — Intel + Apple
Silicon). From a source checkout you can also `make build` (or `make install`). Cutting a release is
documented in docs/RELEASING.md.

<!--
  CONVENTION: every platform section opens with a star-bordered "WHAT'S REQUIRED — <platform>"
  blockquote box (see iOS and Android below). When the Web pipeline ships, add the SAME box at the
  top of a "## Web" section — same star border, same "have these ready before you start" framing,
  same emoji-bulleted prerequisites with a "→ setup" link and a toolchain-check line.
-->

## iOS (App Store)

> ⭐️ ⭐️ ⭐️ **WHAT'S REQUIRED — iOS** ⭐️ ⭐️ ⭐️
>
> Have these ready **before you start**. `build` alone needs only the first; each later command adds one line.
>
> - 🖥️ **macOS with Xcode** — the toolchain BuildLine drives.
> - 🔑 **An App Store Connect API key** (`.p8`, **App Manager** or **Admin** role) — for anything past `build`. → [setup](#providing-your-app-store-connect-api-key)
> - 📱 **The app already created** in App Store Connect — the API cannot create the app record; do it once in the UI.
> - 🔒 **A store passphrase** (an `env:`/`file:`/`keychain:` reference) — encrypts the signing store used by `sign setup` / `ship` / `submit`.
>
> _Toolchain check:_ `xcodebuild -version`.

## Quickstart (5 minutes)

From your app's directory (the one containing the `.xcodeproj` or `.xcworkspace`):

```sh
buildline init        # writes a minimal buildline.yml (app name, bundle id, scheme)
buildline build       # produces .buildline/export/<App>.ipa, signed with whatever Xcode has
```

That's the whole of milestone 1 — a signed `.ipa` from one command. To make signing reproducible on
any machine (a fresh laptop or a CI runner), fill in the `signing:` section (`init` leaves a
commented template) and run:

```sh
export BUILDLINE_STORE_PASSPHRASE='a-strong-passphrase'   # encrypts the signing store
buildline sign setup    # creates the cert + profile at Apple, stores them AES-256-GCM encrypted
buildline build         # now builds with manual signing from the store
```

Then TestFlight, then the App Store:

```sh
buildline ship                 # test → build → upload → wait for processing → beta group
buildline submit               # stage metadata/screenshots + version (does NOT submit)
buildline submit --confirm     # actually send for App Store review
```

A few conveniences on `ship`: before building, it **shows the marketing version and next build number
and lets you confirm or change them** (press Enter to accept, or type e.g. `1.5.8`) — buildline
auto-bumps the numeric build number but leaves the marketing version to you; if a `.xcarchive` already
exists it offers to **reuse it** instead of re-running the slow `xcodebuild archive` (`--reuse-archive`
/ `--new-archive` to skip the prompt); and if `distribute.beta_groups` isn't set, it **lists your
TestFlight groups and saves your choice** to `buildline.yml`. To clear TestFlight's "Missing Compliance", pass `buildline ship --exempt` (most
apps — only standard HTTPS/TLS) or set `distribute.uses_nonexempt_encryption: false`; `ship` waits for
the build to finish processing, declares export compliance, and **confirms the build has left Missing
Compliance before distributing it** (the declaration is applied post-processing because Apple re-runs
processing when it changes). The zero-race alternative is to set `ITSAppUsesNonExemptEncryption` in your
Info.plist, so the build self-declares during its first processing and never goes Missing Compliance.

## `buildline.yml` reference

Only `app` and `ios` are needed to `build`. Each later section unlocks a command. **Secrets are
never written here** — they are *references* (see below).

```yaml
app:
  name: My App
  bundle_id: com.example.myapp

ios:
  scheme: MyApp                 # auto-discovered if there is only one
  # configuration: Release      # default
  # marketing_version: "1.2.0"  # default: read from the project (MARKETING_VERSION)
  # build_number: "42"          # default: auto = (latest build at Apple) + 1

signing:                        # buildline sign setup / reproducible signing
  team_id: ABCDE12345
  cert_type: distribution       # distribution (default) | development
  asc_key:
    key_id: 2X9R4HXF34
    issuer_id: 57246542-96fe-1a63-e053-0824d011072a
    key: keychain:buildline-asc-key     # a SECRET REF (see below)
  storage:
    git: git@github.com:you/your-signing-store.git   # or: path: ../signing-store
    passphrase: env:BUILDLINE_STORE_PASSPHRASE        # a SECRET REF

distribute:                     # buildline ship (TestFlight)
  beta_groups: ["External Testers"]
  uses_nonexempt_encryption: false   # clears "Missing Compliance" (or pass ship --exempt)

submit:                         # buildline submit (App Store)
  primary_locale: en-US
  release_type: manual          # manual | after_approval | scheduled
  review:
    contact_email: you@example.com
    demo_account_password: env:DEMO_PASSWORD   # a SECRET REF, if your app needs a login
```

## Secrets are references, never values

A secret never appears in `buildline.yml`. You give a **reference** that BuildLine resolves at
runtime; the resolved value is never logged, never written to disk in plaintext, and never put in
the event stream:

| Reference | Resolves to | Best for |
|-----------|-------------|----------|
| `env:NAME` | the environment variable `NAME` | CI (your secret manager injects it) |
| `file:/path` (or `file:~/p`) | the file's contents | a `.p8` or passphrase on disk (`chmod 600`) |
| `keychain:SERVICE` | a macOS Keychain generic password | a dev machine (encrypted at rest) |

The **signing certificate's private key** — the one Apple won't re-issue — is the only key BuildLine
stores, and it is always AES-256-GCM encrypted (PBKDF2 from your store passphrase). The signing store
is a directory or git repo that holds only encrypted blobs plus non-secret metadata, so it is safe to
keep in a private repo shared across machines (the Fastlane `match` model).

## Providing your App Store Connect API key

1. App Store Connect → **Users and Access → Integrations → App Store Connect API** → create a key with
   the **App Manager** (or Admin) role. **Download the `.p8` once** (Apple allows it a single time) and
   note the **Key ID**; copy the **Issuer ID** above the keys table.
2. Put `key_id` and `issuer_id` in `buildline.yml` (identifiers, not secrets); the `.p8` itself is a
   reference — pick one:

   **macOS Keychain** (recommended on a dev machine — encrypted at rest):
   ```sh
   security add-generic-password -U -a buildline -s buildline-asc-key \
     -w "$(cat ~/Downloads/AuthKey_2X9R4HXF34.p8)"
   ```
   → `key: keychain:buildline-asc-key`

   **A file** (`chmod 600`): `key: file:~/private_keys/AuthKey_2X9R4HXF34.p8`

   **An env var** (CI): `export ASC_KEY_P8="$(cat AuthKey_2X9R4HXF34.p8)"` → `key: env:ASC_KEY_P8`

The store passphrase is provided the same way (`passphrase: env:BUILDLINE_STORE_PASSPHRASE`, etc.).
Verify with `buildline sign status`. On a dev machine you don't have to export it every session: if
the reference can't be resolved, `build`/`ship`/`sign setup` **prompt for it once, save it to the
macOS Keychain, and rewrite `signing.storage.passphrase` to `keychain:buildline-store-passphrase`** so
later runs just proceed (in CI — no TTY — a missing passphrase is a clear error instead).

## Commands

| Command | What it does |
|---------|--------------|
| `buildline init` | Discover the project and write a starter `buildline.yml`. |
| `buildline build` | `xcodebuild archive` + `-exportArchive` → a signed `.ipa`. |
| `buildline test` | `xcodebuild test` on a simulator, with a failure summary. |
| `buildline sign setup` | Create/fetch the cert + profile at Apple, store them encrypted, push. |
| `buildline sign status` | Compare the local store against App Store Connect. |
| `buildline sign import --p12 <f>` | Import an existing identity into the store. |
| `buildline ship` | test → resolve build number → sign → archive → export → upload → poll → clear export compliance → beta group. `--exempt`/`--non-exempt` declare encryption use. |
| `buildline submit` | Push metadata + screenshots, prepare the version, attach the build; `--confirm` sends it for review. |

On an **Android** project the same commands run the Gradle + Google Play equivalents
([Android](#android-google-play)); on an **npm** package they publish to the registry
([npm](#npm-package-registry)). Run any command with `--help` for its flags.

## Continuous integration

- **`--json`** on any command emits one JSON event per line on stdout (`kind`, `step`, `message`,
  `error`, `durationMs`, `time`) — add `-v` to include streamed tool output. Human summaries are
  suppressed so the stream stays parseable.
- **Non-interactive by design**: only `buildline init` ever prompts, and every prompt has a flag
  (`--scheme`, `--name`, `--force`), so nothing hangs without a TTY.
- **Secrets via `env:`** on CI (your runner's secret store), e.g. the `.p8` in `BUILDLINE_ASC_KEY_P8`
  and the store passphrase in `BUILDLINE_STORE_PASSPHRASE`.
- **Exit codes**: `0` on success, `1` on any failure.

## Metadata & screenshots (for `buildline submit`)

Store-listing content lives in the repo (the Fastlane `deliver` layout):

```
metadata/
  categories.yml                 # primary: PRODUCTIVITY  (required for a first submission)
  en-US/
    name.txt  description.txt  keywords.txt  support_url.txt  privacy_url.txt
  screenshots/
    en-US/APP_IPHONE_67/01_home.png        # exact display-type token; NN_ prefix = order
```

Note the display-type tokens lag the marketing names: iPhone 6.9" is `APP_IPHONE_67`, iPad 13" is
`APP_IPAD_PRO_3GEN_129`. `buildline submit` validates the token and lists the valid ones on a typo.

## Android (Google Play)

> ⭐️ ⭐️ ⭐️ **WHAT'S REQUIRED — Android** ⭐️ ⭐️ ⭐️
>
> Have these ready **before you start**. `build` alone needs only the first two; each later command adds one line.
>
> - ☕ **JDK 17+** (`keytool`, `jarsigner`) — plus the **Android SDK build-tools** (`apksigner`) only if you set `output: apk`. An `.aab` is signed with `jarsigner`.
> - 🐘 **A Gradle project** (a `gradlew` at the repo root).
> - 🔑 **A Google Play service account** with the Play Android Developer API enabled and release access granted. → [setup](#providing-the-play-service-account-key)
> - 📱 **The Play app already created**, with **Play App Signing** enabled — BuildLine manages only the *upload key*; Google holds the app signing key.
> - 🔒 **A store passphrase** (an `env:`/`file:`/`keychain:` reference) — encrypts the upload-keystore store used by `sign setup` / `ship`.
>
> _Toolchain check:_ `keytool -version` (or `java -version`).

BuildLine covers Android the same way it covers iOS: **one config, the same commands.** The platform
is auto-detected (`gradlew`/`settings.gradle` ⇒ Android, an Xcode project ⇒ iOS) or pinned with
`platform: android`. It wraps the **Gradle wrapper** and the **Google Play Developer API**, so a
release never needs the Play Console.

```sh
# write buildline.yml from the template below, then:
buildline sign setup           # generate the upload keystore, store it AES-256-GCM encrypted
buildline build                # ./gradlew bundleRelease → a signed .aab
buildline ship                 # build → sign → upload → assign to a testing track (internal)
buildline submit               # stage the production release + listing (does NOT publish)
buildline submit --confirm     # actually release to production
```

### `buildline.yml` — the `android` section

`app.package_name` + `android` are all you need to `build`; each later sub-section unlocks a command,
exactly like iOS. **Secrets are references, never values** (see
[above](#secrets-are-references-never-values)).

```yaml
app:
  name: My App
  package_name: com.example.myapp   # the Android applicationId

platform: android                   # optional — auto-detected from gradlew

android:
  module: app                       # Gradle module (default: app)
  variant: release                  # default: release
  gradlew: ./gradlew                # default
  output: bundle                    # bundle = .aab (default) | apk
  # version_name: "1.2.0"           # default: from the project/manifest
  # version_code: "42"              # default: auto = (highest code at Play) + 1

  signing:                          # buildline sign setup / build signing
    store: keystore                 # logical keystore name in the encrypted store
    key_alias: upload
    keystore_password: env:BL_KEYSTORE_PASSWORD   # SECRET REF
    key_password:      env:BL_KEY_PASSWORD        # SECRET REF; default = keystore_password
    storage:                        # the SAME encrypted-store model as iOS
      git: git@github.com:you/your-android-store.git   # or: path: ../android-store
      passphrase: env:BUILDLINE_STORE_PASSPHRASE       # SECRET REF

  play:                             # Play Developer API credential
    service_account_json: file:~/secrets/play-sa.json  # SECRET REF → the SA JSON

  distribute:                       # buildline ship (testing track)
    track: internal                 # internal (default) | alpha | beta | <custom>
    release_status: completed       # draft | inProgress | halted | completed
    # user_fraction: 0.1            # required iff release_status is inProgress/halted
    release_notes:
      en-US: "Bug fixes."

  submit:                           # buildline submit (production)
    track: production               # default
    metadata_dir: play              # the metadata-in-repo tree (default: play)
    release_status: completed       # draft | inProgress | halted | completed
    # user_fraction: 0.2            # required iff release_status is inProgress/halted (staged rollout)
    changes_not_sent_for_review: false   # true = commit but hold for manual review in Console
    # countries: ["US", "GB"]       # optional country targeting
```

### Auto-incrementing the version code

buildline resolves the next version code (`highest at Play + 1`) and passes it to Gradle as
`-PversionCode` / `-PversionName` — **but that only takes effect if your `build.gradle` reads those
properties.** A hardcoded `versionCode 1` (the React Native / Android template default) silently
ignores it, so every upload carries the same code and never bumps. Wire it in
`android/app/build.gradle` — compute the values in **plain Groovy above `android {`**. Do **not** use
the inline `versionCode (… ?: N) as Integer` form inside `defaultConfig`: the AGP DSL parser chokes on
it with a *"Value is null"* evaluation error. This form is robust:

```gradle
def resolvedVersionCode = (project.findProperty("versionCode") ?: "1").toString().toInteger()
def resolvedVersionName = (project.findProperty("versionName") ?: "1.0").toString()

android {
  defaultConfig {
    versionCode resolvedVersionCode
    versionName resolvedVersionName
  }
}
```

(Kotlin DSL: `val resolvedVersionCode = (findProperty("versionCode") as String? ?: "1").toInt()`, then
`versionCode = resolvedVersionCode`.) `ship` warns in its summary if it detects a hardcoded
`versionCode`, so you're not left wondering why the number never moves. Alternatively, pin
`android.version_code` in `buildline.yml` and manage it yourself.

**Confirming the version before a ship.** buildline auto-increments the numeric *version code*, but
the *version name* (marketing version, e.g. `1.5.7`) is a human decision it never bumps on its own. So
on a terminal, `ship` shows both and lets you accept or change them before building:

```
buildline will ship this release — press Enter to accept a value, or type a new one:
  version name [1.5.7]: 1.5.8
  version code [58]:
```

Press Enter to keep a value, or type a new one (e.g. bump the version name to `1.5.8`). In CI (no TTY)
there's no prompt — the version code auto-resolves and the version name stays as configured.

### Reusing the build & cleanup

`ship` mirrors iOS's archive reuse. If an `.aab`/`.apk` already exists (e.g. a previous `ship` failed
*after* building), it offers to **reuse it** instead of re-running the slow Gradle build —
`--reuse-build` / `--new-build` skip the prompt (CI builds fresh unless `--reuse-build`). After a
**successful upload the artifact is deleted** so it can't be reused stale; pass `--keep-build` to keep
it. Net effect: a normal ship builds → uploads → cleans up, while a failed ship leaves the `.aab` for a
fast `buildline ship --reuse-build` retry.

### Providing the Play service-account key

There are **two separate permission screens**, and the confusing one — Google Cloud's IAM "role" — is
the one you **skip**. Access for publishing is granted in the **Play Console**, not in Google Cloud.

1. **Enable the API** — [console.cloud.google.com/apis/library/androidpublisher.googleapis.com](https://console.cloud.google.com/apis/library/androidpublisher.googleapis.com)
   → select your project → **Enable** the *Google Play Android Developer API*.
2. **Create the service account** — [console.cloud.google.com/iam-admin/serviceaccounts](https://console.cloud.google.com/iam-admin/serviceaccounts)
   → **Create service account** → name it → on the **"Grant this service account access to project
   (optional)"** step, leave the role **blank** and click **Continue → Done** — *no Cloud IAM role is
   needed for publishing.* Then open the account → **Keys → Add key → Create new key → JSON** and
   download it. (The email looks like `name@project-id.iam.gserviceaccount.com`.)
3. **Grant Play permissions** — [play.google.com/console → Users and permissions](https://play.google.com/console/u/0/developers/users-and-permissions)
   → **Invite new user** → paste the service-account email → under **App permissions**, grant it to
   *your app* and enable:
   - **Release to testing tracks** + **Manage testing tracks and edit tester lists** — for `ship`
   - **Release to production, exclude devices, and use Play App Signing** — for `submit`
   - **Manage store presence** — for `submit` metadata/screenshots
   - **View app information and download bulk reports (read-only)** — to read app data / resolve version codes

   (Simplest for first setup: grant **Admin (all permissions)** for that one app, confirm the pipeline
   works, then narrow to the list above.) Permission changes can take a few minutes to propagate.
4. Reference the JSON in `buildline.yml` (same model as the ASC key) — pick one:
   - **A file** (`chmod 600`): `service_account_json: file:~/secrets/play-sa.json`
   - **An env var** (CI): `export PLAY_SA_JSON="$(cat play-sa.json)"` → `service_account_json: env:PLAY_SA_JSON`

The JSON is resolved in memory only — never logged, never written in plaintext, never in the event
stream.

### The upload keystore

`buildline sign setup` generates a PKCS12 upload keystore (`keytool`, RSA-2048, ~27-year validity) the
first time and reuses it after, storing it as one AES-256-GCM blob in the same encrypted store as iOS
certs. The two passwords come from your secret refs and are passed to the signer through the
environment, never on the command line.

```sh
export BUILDLINE_STORE_PASSPHRASE='a-strong-passphrase'   # encrypts the store
export BL_KEYSTORE_PASSWORD='the-keystore-password'
buildline sign setup     # creates (or reuses) keystores/keystore/upload.keystore — encrypted, pushed
```

One-time Play step the API can't do for you: **register the upload key with Play App Signing** (Play
Console → your app → *Test and release → Setup → App signing*). New apps are usually enrolled at
creation, and Play registers the upload certificate from your first signed upload.

#### Already have an upload key? Import it

If your app was **already published** (or the upload key was generated elsewhere), Play App Signing has
a specific upload key registered, and it **rejects any build signed with a different key**:

```
The Android App Bundle was signed with the wrong key.
Found: SHA1 <buildline's generated key>, expected: SHA1 <your registered upload key>
```

`sign setup` generates a *new* key, which is wrong for an existing app — you must sign with the
**registered** one. Point `android.signing.{key_alias,keystore_password,key_password}` at that
keystore's values, then import it:

```sh
buildline sign import --keystore /path/to/upload-keystore.jks
```

buildline validates the keystore opens with your alias/password and prints its **SHA1** — confirm it
matches the fingerprint under *Play Console → App integrity → App signing → Upload key certificate*
before you `ship`. (Lost the keystore entirely? Use Play Console's **upload key reset** instead —
Google reviews it, then buildline's generated key becomes the registered one.)

### Metadata & screenshots (for `buildline submit`)

Store-listing content lives in the repo (the Fastlane *supply* layout), under
`android.submit.metadata_dir` (default `play/`):

```
play/
  en-US/
    title.txt               # ≤ 30 chars
    short_description.txt    # ≤ 80 chars
    full_description.txt     # ≤ 4000 chars
    video.txt                # optional
    changelogs/
      42.txt                 # release notes for version code 42 (used when release_notes is unset)
    images/
      phoneScreenshots/01.png    # the subdir name IS the Play image type
      featureGraphic/main.png
      icon/icon.png
```

Image subdirectory names must be exact Play image types: `phoneScreenshots`, `sevenInchScreenshots`,
`tenInchScreenshots`, `tvScreenshots`, `wearScreenshots`, `icon`, `featureGraphic`, `tvBanner`. Images
are sha1-idempotent — a set already matching at Play is skipped, so re-running `submit` is cheap.

### The Android commands

| Command | What it does on an Android project |
|---------|------------------------------------|
| `buildline build` | `./gradlew :<module>:bundleRelease` → a signed `.aab` (or `.apk` with `output: apk`). |
| `buildline sign setup` | Generate/reuse the upload keystore, store it encrypted, push. |
| `buildline ship` | resolve version code → build → sign → open a Play *edit* → upload → assign to the testing track → commit. |
| `buildline submit` | stage the production release + store listing/images; **`--confirm`** commits it (without it, the edit is validated then discarded — nothing is published). |

`ship` always commits (testing tracks have no review gate); `submit` is `--confirm`-gated, mirroring
iOS. A failed run or Ctrl-C discards the open Play edit, so nothing is left half-staged. `--cancel` is
iOS-only; to pull an Android release, halt or replace it in the Play Console.

## npm (package registry)

> ⭐️ ⭐️ ⭐️ **WHAT'S REQUIRED — npm** ⭐️ ⭐️ ⭐️
>
> Have these ready **before you start**. `build` alone needs only the first two.
>
> - 📦 **Node.js + a package manager** (npm / pnpm / yarn / bun — auto-detected from the lockfile).
> - 📄 **A `package.json`** with a `name` and `version` (the package identity comes from here, not `app:`).
> - 🔑 **An npm automation token** with publish rights to your package/scope, as a secret ref. → [setup](#providing-the-npm-token)
> - 🏷️ **A scope you own** for a scoped package (e.g. `@you/lib`) — published with `--access public`.
>
> _Toolchain check:_ `node -v && npm -v`.

The store becomes the **registry**: `ship` publishes under a prerelease **dist-tag** (the TestFlight
analog), and `submit --confirm` promotes that *exact* version to the production tag — a dist-tag move,
never a re-publish (npm versions are immutable). The package is auto-detected from `package.json`.

```sh
# bump the version in package.json, then:
buildline build                # install deps + run the build script
buildline ship                 # publish <name>@<version> under the beta dist-tag
buildline submit               # preview the promotion (does NOT move latest)
buildline submit --confirm     # move the latest dist-tag to this version
```

### `buildline.yml` — the `npm` section

`package.json` + the `npm` section are all you need. **Secrets are references, never values** (see
[above](#secrets-are-references-never-values)).

```yaml
platform: npm                 # optional — auto-detected from package.json

npm:
  package_manager: auto       # auto (default) | npm | pnpm | yarn | bun
  build: true                 # run the "build" script before publish (default true)
  registry: https://registry.npmjs.org
  access: public              # public (default) | restricted (scoped packages)
  provenance: true            # add npm provenance when an OIDC issuer is present (CI)
  token: env:NPM_TOKEN        # SECRET REF — automation token, never inline
  ship:   { tag: beta }       # prerelease dist-tag (default beta)
  submit: { tag: latest }     # production dist-tag (default latest)
```

### Providing the npm token

1. **npmjs.com → your avatar → Access Tokens → Generate New Token → Granular Access Token** (or a
   classic **Automation** token). Grant **Read and write** to the package or scope you'll publish.
2. Reference it (same model as the other platforms) — pick one:
   - **macOS Keychain** (dev machine): `security add-generic-password -U -a buildline -s buildline-npm-token -w "npm_xxx"` → `token: keychain:buildline-npm-token`
   - **A file** (`chmod 600`): `token: file:~/.secrets/npm-token`
   - **An env var** (CI): `export NPM_TOKEN=npm_xxx` → `token: env:NPM_TOKEN`

The token is resolved in memory and written only to a temporary `0600` `.npmrc` that is shredded after
the run — never logged, never on the command line.

### The npm commands

| Command | What it does on an npm package |
|---------|--------------------------------|
| `buildline build` | install dependencies + run the `build` script (via the detected package manager). |
| `buildline ship` | publish `<name>@<version>` under the **`beta`** dist-tag (refuses if that version is already published). |
| `buildline submit` | promote that exact version to the **`latest`** dist-tag; **`--confirm`** applies it (without it, the move is previewed only). |

**Provenance** (`npm publish --provenance`) is added automatically when BuildLine detects an OIDC
issuer (GitHub Actions / a sigstore id-token); off-CI it publishes without it and says so. `--cancel`
isn't supported — to undo, move the dist-tag back with `npm dist-tag`.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `No profiles for '<id>' were found` | run `buildline sign setup`, or remove the `signing:` section to let Xcode sign automatically. |
| `wrong store passphrase` | `BUILDLINE_STORE_PASSPHRASE` (or your `passphrase:` ref) doesn't match the store. |
| `App Store Connect rejected the API key (401)` | check `signing.asc_key.{key_id,issuer_id}` and that the `.p8` resolves; the key needs App Manager/Admin. |
| `no app record for <id>` | create the app once at App Store Connect → Apps → ＋ (the API cannot create app records). |
| `this build number is already on App Store Connect` | bump `ios.build_number` or let it auto-increment. |
| Build **still shows "Missing Compliance"** in TestFlight even with `--exempt` / `uses_nonexempt_encryption` | your app ships a **hand-maintained `Info.plist`** (common with React Native). Xcode's *"App Uses Non-Exempt Encryption"* **build setting is NOT merged into a manual plist**, so every build ships with no declaration. Add the key **`ITSAppUsesNonExemptEncryption`** as a real Boolean **`false`** directly in that `Info.plist`, then confirm on the built app: `/usr/libexec/PlistBuddy -c "Print :ITSAppUsesNonExemptEncryption" <App>.app/Info.plist` prints `false`. (RN can strip it on `pod install` — re-assert it in a Podfile `post_install` hook if it vanishes.) |
| `multiple schemes found` | set `ios.scheme`, or pass `--scheme` to `init`. |
| `found both an Xcode project and a Gradle project` | set `platform: ios` or `platform: android` in `buildline.yml`. |
| Play `permission denied` (401/403) | grant the service account release access in Play Console → Users and permissions, and confirm the app exists. |
| `this version code already exists at Play` | bump `android.version_code` or let it auto-increment. |
| Play rejects the bundle as not signed by the expected key | the `.aab` must be signed with the upload key registered in Play App Signing — run `buildline sign setup` and register that key. |
| npm: `<pkg>@<v> is already published` | bump `version` in `package.json` (npm versions are immutable). |
| npm: `is not on the registry yet — run buildline ship` | `submit` only promotes an already-published version; run `buildline ship` first. |
| npm: `403 Forbidden` / `ENEEDAUTH` on publish | the `npm.token` lacks publish rights to the package/scope, or a scoped package needs `access: public`. |

## Status

BuildLine ships **iOS** (App Store Connect / TestFlight), **Android** (Google Play), and **npm**
packages today; a containerized-service platform and a self-hosted **Web** dashboard are planned.

| Platform | build | signing / provenance | beta / prerelease | production release |
|----------|:-----:|:--------------------:|:-----------------:|:------------------:|
| iOS      |  ✅   |  ✅ cert/profile      | ✅ TestFlight     | ✅ App Store       |
| Android  |  ✅   |  ✅ upload key        | ✅ Play tracks    | ✅ Play production |
| npm      |  ✅   |  ✅ provenance (OIDC) | ✅ `beta` tag     | ✅ `latest` tag    |
| Web      |  —    |  —                    |       —           |    planned         |

A few things worth knowing before you lean on it:

- **npm** is verified end-to-end against the live registry (publish under `beta`, promote to `latest`);
  it's still young, so eyeball your first real publish.
- **Android is new** and not yet exercised against a live Google Play account — try it on a
  non-critical app first.
- **`buildline init` scaffolds iOS only** for now; for Android/npm, copy the template above.
- **App Store age rating:** set it once in the App Store Connect UI — `submit` does not yet fill the
  2025 age-rating questionnaire.
- **npm provenance** needs a CI OIDC issuer (GitHub Actions); off-CI, `ship` publishes without it.
