# UAG Google Play Internal / Closed Test Readiness

Canonical Android package: `com.mobcorp.uagtradershub`.

This repository is prepared to produce a properly signed Android App Bundle (`.aab`) for Google Play Internal Testing or Closed Testing without committing signing secrets. The build tooling does **not** upload to Google Play, push Git, or deploy Firebase automatically.

## 1. Create the Play Console app

Create a new Google Play Console app for UAG and use the existing package identity `com.mobcorp.uagtradershub`. Do not reuse another application's package name. Enable Play App Signing when prompted.

## 2. Create an upload key locally

Create the upload keystore on the developer machine with `keytool`. Keep it outside the repository and back it up securely. A typical alias is `uag-upload`. Do not commit or share the keystore or passwords.

## 3. Configure local signing

Either copy `android/key.properties.example` to `android/key.properties` and fill the four values locally, or set all four environment variables for the current shell:

- `UAG_ANDROID_STORE_FILE`
- `UAG_ANDROID_STORE_PASSWORD`
- `UAG_ANDROID_KEY_ALIAS`
- `UAG_ANDROID_KEY_PASSWORD`

`android/key.properties`, `*.jks`, and `*.keystore` are already ignored by Git.

## 4. Build the Play test bundle

Run `scripts/build_play_internal_test.ps1`. The script validates signing, runs format/analyze/tests, and produces:

`build/app/outputs/bundle/release/app-release.aab`

It also prints the artifact SHA-256. It performs no upload or deployment.

## 5. Upload to Internal Testing first

Upload the generated `.aab` to the Google Play Internal Testing track, create the tester list, and use the official tester opt-in link. Move to Closed Testing when the build and tester flow are stable.

## 6. Update Android App Links after Play App Signing exists

Apps installed through Google Play are verified against the Play app-signing certificate. Copy the SHA-256 fingerprint shown in Google Play Console under App integrity, then run:

`scripts/set_play_app_signing_fingerprint.ps1 -Sha256Fingerprint "AA:BB:..."`

Review the resulting change to `web/.well-known/assetlinks.json`, then deploy Hosting only when explicitly approved.

## 7. Versioning

The current first-release value can remain `1.0.0+1` for the first upload. Every later Play upload must use a higher build number (`+2`, `+3`, and so on).

## iOS

The iOS bundle/Firebase identity still uses the existing placeholder configuration and is intentionally **not** changed by this Android Play-testing pass. Register the final iOS bundle ID in Firebase/Apple before changing runtime iOS identity so current Firebase configuration is not broken by a fabricated app registration.
