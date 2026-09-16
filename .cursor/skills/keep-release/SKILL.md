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
* Semver in `CFBundleShortVersionString` and git tags (`v1.0.0`). `CFBundleVersion` is the integer build.
* `CODE_SIGN_IDENTITY = "-"` (ad hoc). No paid Apple Developer Program, so no Developer ID and no notarization.
* `ENABLE_HARDENED_RUNTIME = YES`.
* Sandbox in `Keep/Keep.entitlements`: network client, calendars, location, reminders.
* CI: `macos-14`, switch to Xcode 16 (default on that image is 15.4, which cannot compile Swift 6), Debug `test`, Release `build`, `derivedDataPath`, no signing secrets.
* Tag `v*.*.*` drafts a GitHub Release with an arm64 DMG and zip. `scripts/install.sh` downloads the zip (no `hdiutil` attach, which looks hung while checksumming).

Do not add App Store, Sparkle, or login items unless asked. Do not put certificates in the repo.

## What v1 actually ships

Unsigned (ad hoc) DMG on GitHub Releases plus a curl installer. The installer prefers `/Applications` when writable, else `~/Applications`, then `xattr -dr com.apple.quarantine`. That is not Gatekeeper approval. Safari downloaded DMGs still look damaged until quarantine is cleared.

When they enroll in the paid program, switch to Developer ID in CI. Until then, no signing secrets in GitHub Actions.

## When they ask to ship with Developer ID

1. Developer ID Application identity (not Apple Development, not `-`).
2. Leave hardened runtime on.
3. Keep entitlements to what Keep uses.
4. Archive with an explicit `derivedDataPath`. Export Developer ID.
5. `xcrun notarytool submit`, wait for Accepted, `xcrun stapler staple`.
6. Gatekeeper on a machine that did not just build it: `spctl -a -vv` and open from Finder.

Apple docs win for `notarytool` flags. Previous stapled app is the rollback. Git `main` is not what users launch.

If we have no dSYMs for that build, say so. Bump `CFBundleVersion` for a new notarized binary. Do not wipe intention in a settings migration.
