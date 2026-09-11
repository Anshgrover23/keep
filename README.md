# Keep

A macOS menu bar app whose wallpaper is a living day: local light and weather, plus the next calendar item and one daily intention.

## Requirements

* macOS 14 and later
* Xcode 16 and later (Swift 6, Swift Testing)

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

See [Docs/Architecture.md](Docs/Architecture.md). `AppSession` coordinates injectable boundaries. Stages 1 to 8 are complete and frozen.

Keep runs as a menu bar agent with wallpaper beneath Finder, atmosphere from solar state and weather, calendar glance, pause, per display fullscreen, and Settings plus first run. CoreLocation Lab (deny, grant without relaunch, approximate weather with denied GPS) passed 11 Sep 2026. App Store shipping is not claimed.

## Privacy

Calendar, reminders, and location are optional. They are requested only from onboarding, Settings, or Lab. Never on every launch.

## License

MIT. See [LICENSE](LICENSE).
