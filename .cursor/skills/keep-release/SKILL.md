---
name: keep-release
description: >-
  Keep distribution: Developer ID, notarization, stapling, Gatekeeper,
  entitlements, archives, dSYMs, CI signing secrets. Use when claiming
  shippable or changing signing. Green tests are not notarization.
---

# Keep release

Do not claim shippable because `xcodebuild test` passed.

## Repo today

* Bundle id `app.keep.desktop`.
* `CODE_SIGN_IDENTITY = "-"` (ad hoc).
* `ENABLE_HARDENED_RUNTIME = YES`.
* Sandbox in `Keep/Keep.entitlements`: network client, calendars, location, reminders.
* CI: `macos-15`, Debug `test`, Release `build`, `derivedDataPath`, no signing secrets.

Do not add App Store, Sparkle, or login items unless asked. Do not put certificates in the repo.

## When they ask to ship outside Xcode Run

1. Developer ID Application identity (not Apple Development, not `-`).
2. Leave hardened runtime on.
3. Keep entitlements to what Keep uses.
4. Archive with an explicit `derivedDataPath`. Export Developer ID.
5. `xcrun notarytool submit`, wait for Accepted, `xcrun stapler staple`.
6. Gatekeeper on a machine that did not just build it: `spctl -a -vv` and open from Finder.

Apple docs win for `notarytool` flags. Previous stapled app is the rollback. Git `main` is not what users launch.

If we have no dSYMs for that build, say so. Bump `CFBundleVersion` for a new notarized binary. Do not wipe intention in a settings migration.

Until they ask to notarize in CI: no signing secrets in GitHub Actions. Release job compiles only.
