# BuildLine

**One config file, zero setup, app in the store.** BuildLine is a single-binary CLI that takes an
iOS app from source to TestFlight and the App Store — build, code signing, tests, upload, and
submission — driven by one `buildline.yml`. It wraps `xcodebuild` and the App Store Connect API.

This repository is BuildLine's **Homebrew tap** — it distributes the compiled macOS binary. (The
source is private.)

## Install

```sh
brew tap thebinarysolution/buildline
brew install buildline
```

The first time you install from a third-party tap, Homebrew asks you to trust it (a one-time
supply-chain safety prompt):

```sh
brew trust thebinarysolution/buildline
```

Then `buildline --version` should print `buildline version 0.1.0`. The binary is universal (Intel +
Apple Silicon) and macOS-only.

## Get started in 2 minutes

From your app's directory (the one containing the `.xcodeproj` or `.xcworkspace`):

```sh
buildline init        # discovers the project/scheme/bundle id, writes buildline.yml
buildline build       # produces .buildline/export/<App>.ipa, signed with Xcode automatic signing
```

That's a signed `.ipa` from one command — no credentials needed yet.

## The full pipeline

Everything past `build` talks to App Store Connect, so you need a **App Store Connect API key** (a
`.p8` with the **App Manager** or **Admin** role — create one at App Store Connect → Users and Access
→ Integrations). Fill in the `signing:` section that `init` left commented in `buildline.yml`, then:

```sh
export BUILDLINE_STORE_PASSPHRASE='a-strong-passphrase'   # encrypts your signing store
buildline sign setup    # creates the cert + profile at Apple, stores them AES-256-GCM encrypted
buildline ship          # test → build → upload to TestFlight → assign a beta group
buildline submit        # stage App Store metadata + screenshots (add --confirm to send for review)
```

## `buildline.yml`

Only `app` and `ios` are needed to `build`; each later section unlocks a command. **Secrets are never
written in this file** — you give a *reference* (see below).

```yaml
app:
  name: My App
  bundle_id: com.example.myapp

ios:
  scheme: MyApp                 # auto-discovered if there is only one

signing:                        # buildline sign setup (reproducible signing)
  team_id: ABCDE12345
  asc_key:
    key_id: 2X9R4HXF34
    issuer_id: 57246542-96fe-1a63-e053-0824d011072a
    key: keychain:buildline-asc-key
  storage:
    git: git@github.com:you/your-signing-store.git   # or: path: ../signing-store
    passphrase: env:BUILDLINE_STORE_PASSPHRASE

distribute:                     # buildline ship (TestFlight)
  beta_groups: ["External Testers"]
  uses_nonexempt_encryption: false

submit:                         # buildline submit (App Store)
  primary_locale: en-US
  release_type: manual
```

### Secrets are references, never values

A secret never appears in `buildline.yml`; BuildLine resolves a reference at runtime and never logs
or stores the value in plaintext:

| Reference | Resolves to | Best for |
|-----------|-------------|----------|
| `env:NAME` | the environment variable `NAME` | CI |
| `file:/path` | the file's contents | a `.p8` / passphrase on disk (`chmod 600`) |
| `keychain:SERVICE` | a macOS Keychain item | a dev machine (encrypted at rest) |

The only key BuildLine *stores* is your signing certificate's private key — always AES-256-GCM
encrypted in the signing store (safe to keep in a private git repo, the Fastlane `match` model).

## Providing your App Store Connect API key

1. In App Store Connect → **Users and Access → Integrations → App Store Connect API**, create a key
   with the **App Manager** (or Admin) role. **Download the `.p8` once** — Apple lets you download it
   a single time — and note the **Key ID**; copy the **Issuer ID** shown above the keys table.
2. Put the `key_id` and `issuer_id` in `buildline.yml` (these are identifiers, not secrets):
   ```yaml
   signing:
     asc_key:
       key_id: 2X9R4HXF34
       issuer_id: 57246542-96fe-1a63-e053-0824d011072a
       key: <one of the references below>   # NEVER paste the key text here
   ```
3. Hand BuildLine the `.p8` via a reference — pick one:

   **macOS Keychain** (recommended on a dev machine — encrypted at rest):
   ```sh
   security add-generic-password -U -a buildline -s buildline-asc-key \
     -w "$(cat ~/Downloads/AuthKey_2X9R4HXF34.p8)"
   ```
   → `key: keychain:buildline-asc-key`

   **A file on disk:**
   ```sh
   mkdir -p ~/private_keys && mv ~/Downloads/AuthKey_2X9R4HXF34.p8 ~/private_keys/
   chmod 600 ~/private_keys/AuthKey_*.p8
   ```
   → `key: file:~/private_keys/AuthKey_2X9R4HXF34.p8`

   **An environment variable** (best for CI — your runner's secret store holds the PEM):
   ```sh
   export ASC_KEY_P8="$(cat AuthKey_2X9R4HXF34.p8)"
   ```
   → `key: env:ASC_KEY_P8`

The **store passphrase** works the same way: `passphrase: env:BUILDLINE_STORE_PASSPHRASE` with
`export BUILDLINE_STORE_PASSPHRASE=…`, or stash it in the Keychain like the key above.

Verify the credentials resolve and reach Apple with `buildline sign status` (or just run
`buildline sign setup`).

## Commands

| Command | What it does |
|---------|--------------|
| `buildline init` | Discover the project and write a starter `buildline.yml`. |
| `buildline build` | `xcodebuild archive` + export → a signed `.ipa`. |
| `buildline test` | `xcodebuild test` on a simulator, with a failure summary. |
| `buildline sign setup` | Create/fetch the cert + profile at Apple, store them encrypted. |
| `buildline ship` | test → build number → sign → archive → export → upload → TestFlight group. |
| `buildline submit` | Push metadata + screenshots, prepare the version, attach the build; `--confirm` submits for review. |

Run any command with `--help`. Add `--json` to any command for machine-readable CI output.

## Requirements

- macOS with **Xcode**.
- An **App Store Connect API key** for anything past `build`.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Refusing to load formula … untrusted tap` | `brew trust thebinarysolution/buildline` |
| `No profiles for '<id>' were found` | run `buildline sign setup`, or remove `signing:` to let Xcode sign automatically. |
| `App Store Connect rejected the API key (401)` | check `signing.asc_key`; the key needs App Manager/Admin. |
| `no app record for <id>` | create the app once at App Store Connect → Apps → ＋ (the API can't create app records). |
| `multiple schemes found` | set `ios.scheme`, or pass `--scheme` to `init`. |
