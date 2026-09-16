
<h1 align="center">Keep</h1>

<p align="center">
	Beautiful, living sky on the desktop. Quiet, and built for a Mac you already use.
</p>

<img width="1440" height="1080" alt="Keep App preview" src="https://github.com/user-attachments/assets/2f02d27f-590e-4313-93e2-156a25db00db" />

Keep is a macOS menu bar agent that shows the living sky on the wallpaper. It gives you local light, live weather, the next Calendar event, one intention for the day, and a quiet extra that stays in the menu bar.

Use Keep for mornings at the desk, long work blocks, a quiet day on Calendar, dusk on the glass, and any moment where looking up should still feel like looking outside.

## Requirements

* macOS 14 and later
* Apple Silicon
* Xcode 16 and later (Swift 6, Swift Testing)

## Install

There is no paid Apple Developer signing on this build. Apple did not notarize it. The installer copies Keep into Applications and clears quarantine so Finder can open it.

```bash
curl -fsSL https://raw.githubusercontent.com/Anshgrover23/keep/main/scripts/install.sh | bash
```

## Build and run

```bash
killall Keep 2>/dev/null
xcodebuild -project Keep.xcodeproj -scheme Keep -configuration Debug -derivedDataPath build/DerivedData
open build/DerivedData/Build/Products/Debug/Keep.app
```

Or open `Keep.xcodeproj` and run the Keep scheme. The app is a menu bar agent (`LSUIElement`). Quit from the menu extra.

## Test

```bash
xcodebuild -project Keep.xcodeproj -scheme Keep -configuration Debug -derivedDataPath build/DerivedData test
```

Lab (internal harness): menu extra → **Lab**. Pin midnight vs noon, fail next weather, pause, and hide desktop windows. Lab preview is not the wallpaper window.

## Architecture

See [Docs/Architecture.md](Docs/Architecture.md). `AppSession` coordinates injectable boundaries.

Keep is a menu bar agent with wallpaper beneath Finder, atmosphere from solar state and weather, calendar glance, pause, per display occupancy, and Settings plus first run. Signing is ad hoc. App Store shipping is not claimed.

## Privacy

Calendar, reminders, and location are optional. They are requested only from onboarding, Settings, or Lab. Never on every launch.

## License

MIT. See [LICENSE](LICENSE).
