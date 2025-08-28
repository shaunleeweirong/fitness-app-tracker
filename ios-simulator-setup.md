# iOS Simulator Setup Guide

## Quick Start

### Prerequisites
- Flutter SDK 3.35.1+
- Xcode 16.4+
- iOS Simulator

```bash
flutter doctor  # Verify installation
flutter devices # Check available simulators
```

## Setup & Run Commands

### For This Project (iPhone 16)
```bash
# Navigate to project
cd "/Users/leeshaun/Desktop/empty folder/first_fitness_test_app"

# Boot iPhone 16 simulator
xcrun simctl boot 5DA4B52F-5EF0-4C65-B044-80691655D7CE
open -a Simulator

# Run fitness tracker app
flutter run -d 5DA4B52F-5EF0-4C65-B044-80691655D7CE
```

### Alternative: Interactive Selection
```bash
flutter run  # Select iPhone from list
```

## Development Commands

### During Development
- `r` - Hot reload (instant UI updates)
- `R` - Hot restart (full app restart)
- `q` - Quit application
- `c` - Clear console

### Build Status
- First build: ~3 minutes (includes Xcode build)
- Hot reload: <1 second
- Success indicator: "Xcode build done"

## Common Issues

### App Not Loading / Caching Issues
**Most Common Problem**: iOS Simulator caches old app states

**Solution:**
```bash
# Kill simulator and clean cache
pkill -f "iPhone Simulator"
flutter clean
flutter pub get

# Restart and run
xcrun simctl boot 5DA4B52F-5EF0-4C65-B044-80691655D7CE
open -a Simulator
flutter run -d 5DA4B52F-5EF0-4C65-B044-80691655D7CE
```

### Build Issues
- **First build hangs**: Normal, wait 2-3 minutes
- **No devices found**: Check `flutter devices` and boot simulator first
- **Type errors**: Run `flutter clean` and rebuild

## Project Device Configuration
- **Primary Device**: iPhone 16 (`5DA4B52F-5EF0-4C65-B044-80691655D7CE`)
- **iOS Version**: 18.6
- **Alternative Devices**: iPhone 16 Pro, iPhone 16 Plus

## Quick Reference
```bash
# Complete development session
cd "/Users/leeshaun/Desktop/empty folder/first_fitness_test_app"
xcrun simctl boot 5DA4B52F-5EF0-4C65-B044-80691655D7CE
open -a Simulator
flutter run -d 5DA4B52F-5EF0-4C65-B044-80691655D7CE

# Troubleshooting commands
flutter clean && flutter pub get
flutter doctor -v
```

---
*Updated for Phase 1C - Exercise Database Complete*