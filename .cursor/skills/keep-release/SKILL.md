---
name: keep-release
description: >-
  Keep distribution: Developer ID, notarization, notarytool, stapling,
  Gatekeeper, entitlements, hardened runtime, archives, dSYMs, version
  numbers, CI release builds, signing secrets, clean machine checks. Use when
  claiming shippable, changing signing, adding notary, or touching CI secrets.
  Do not claim shippable merely because xcodebuild test passes.
---

# Keep release

Owns distribution. `production-app` names release readiness. This file is the checklist. `keep-process` still forbids replacing architecture to “look shippable.”

> Do not claim "shippable" merely because `xcodebuild test` passes.

CI Debug tests and CI Release **compile** are build claims. They are not Developer ID, notary, or Gatekeeper.

## Current repo (do not “fix” as a drive by)

* Bundle id `app.keep.desktop`.
* `CODE_SIGN_IDENTITY = "-"` (ad hoc). Automatic style in the project file.
* `ENABLE_HARDENED_RUNTIME = YES`.
* Sandbox on in `Keep/Keep.entitlements`: network client, calendars, location, reminders.
* CI (`.github/workflows/ci.yml`): `macos-15`; Debug `test`; Release `build`; same `derivedDataPath`; **no signing secrets**.

Do not add App Store, Sparkle, or login items unless the user asked. Do not put certificates in the repo.

## Developer ID distribution

When the user asks to ship outside Xcode’s Run:

1. Developer ID Application identity (not Apple Development, not `-`).
2. Hardened runtime already on; do not turn it off to hide a notary failure.
3. Entitlements stay the minimum Keep needs. Do not add App Groups, iCloud, or outgoing network beyond client without a named reason.
4. Archive from Xcode or `xcodebuild archive` with an explicit `derivedDataPath`.
5. Export Developer ID (direct distribution), not Development.

Apple docs win for `notarytool` flags and staple semantics (TN3147 and current `man notarytool`). Keep product contract wins for whether we are shipping at all.

## Notarization

* `xcrun notarytool submit` the exported app or zip or pkg.
* Wait for `Accepted`.
* `xcrun stapler staple` the app.
* Gatekeeper validation on a machine that did not just build it: `spctl -a -vv` and open from Finder, not only from Xcode.

Clean machine verification: copy the stapled app to another Mac or a fresh user, confirm TCC prompts, wallpaper window, extra, and quit. Do not treat the developer’s already granted TCC as Gatekeeper proof.

## Archives and dSYMs

* Keep the archive and dSYMs with the version you notarized.
* Crash policy: if we have no dSYMs for that build, we cannot symbolicate. Say so. Do not pretend Console.app lines are a crash pipeline.
* Version and build numbers must bump for a new notarized build. Do not reuse `CFBundleVersion` for two different binaries.

## CI

Until the user asks to notarize in CI:

* No signing secrets in GitHub Actions.
* Release job compiles only.
* Do not add `xcodebuild test` under Release as a substitute for notary.

If CI signing is requested later: store identities in the secret store Apple and GitHub document; never echo them; never commit `.p12` or notary API keys.

## Rollback / recovery

* Previous stapled app is the rollback. Git `main` is not what users launch.
* Settings schema: `keep.schemaVersion`. New keys must tolerate missing values. Do not migrate by wiping intention.

## What not to say

Wrong: “Ready for distribution; CI is green.”
Right: “Debug tests and Release compile on `macos-15`. Signing is still ad hoc. Notary not run.”

## Related

`production-app` for runtime quality. `keep-process` five claims. Axiom or Apple code signing skills are specialists: reconcile entitlements with `Keep.entitlements` before copying their templates.
