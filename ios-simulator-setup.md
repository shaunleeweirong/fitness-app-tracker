# iOS Simulator Setup & Testing Guide

## Overview
This guide provides step-by-step instructions for running the Flutter fitness tracker app on iOS simulator, including troubleshooting for common issues encountered during development.

## Prerequisites

### 1. Verify Flutter & Xcode Installation
```bash
flutter doctor
```

**Expected output should show:**
- ✓ Flutter (Channel stable, 3.35.1+)
- ✓ Xcode - develop for iOS and macOS (Xcode 16.4+)

### 2. Check Available Devices
```bash
flutter devices
```

If no iOS simulators appear, proceed to simulator setup below.

## iOS Simulator Setup

### 1. List Available Simulators
```bash
xcrun simctl list devices available | grep iPhone
```

**Example output:**
```
iPhone 16 Pro (76392867-DBE7-4E61-AC47-8F73ACF6EA19) (Shutdown)
iPhone 16 (5DA4B52F-5EF0-4C65-B044-80691655D7CE) (Shutdown)
iPhone 16 Plus (1D061561-B649-409A-919E-2008FA57F6BE) (Shutdown)
```

### 2. Boot iPhone Simulator
```bash
# Using iPhone 16 as example (replace with your device ID)
xcrun simctl boot 5DA4B52F-5EF0-4C65-B044-80691655D7CE
```

### 3. Open Simulator App
```bash
open -a Simulator
```

The iOS Simulator should now open showing the iPhone home screen.

## Running the Flutter App

### Method 1: Direct Device ID (Recommended)
```bash
cd "/Users/leeshaun/Desktop/empty folder/first_fitness_test_app"
flutter run -d 5DA4B52F-5EF0-4C65-B044-80691655D7CE
```

### Method 2: Interactive Selection
```bash
flutter run
```
Then select the iPhone option when prompted (usually option 2).

## Build Process

### Initial Build (First Time)
- **Duration**: 2-3 minutes
- **Process**: Xcode build, dependency resolution, app compilation
- **Status**: Watch for "Xcode build done" message

### Successful Launch Indicators
```
Launching lib/main.dart on iPhone 16 in debug mode...
Running Xcode build...
Xcode build done.                                           17.9s
Syncing files to device iPhone 16...                       470ms

Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
```

## Development Workflow

### Hot Reload Commands
- **`r`** - Hot reload (instant updates for UI changes)
- **`R`** - Hot restart (full app restart)
- **`h`** - List all available commands
- **`d`** - Detach (keep app running, stop flutter run)
- **`c`** - Clear console screen
- **`q`** - Quit application and return to simulator home

### Debug Tools
- **Dart VM Service**: Available at displayed URL (e.g., http://127.0.0.1:60506/ayNIBdCa1es=/)
- **Flutter DevTools**: Available at displayed URL for debugging and profiling

## Troubleshooting

### Error 1: CardTheme Type Mismatch
**Symptom:**
```
Error: The argument type 'CardTheme' can't be assigned to the parameter type 'CardThemeData?'
```

**Solution:**
Replace `CardTheme(...)` with `CardThemeData(...)` in theme configuration:
```dart
// ❌ Wrong
cardTheme: CardTheme(
  elevation: 2,
  // ...
)

// ✅ Correct  
cardTheme: const CardThemeData(
  elevation: 2,
  // ...
)
```

### Error 2: No iOS Devices Found
**Symptom:**
```
No supported devices found with name or id matching 'ios'
```

**Solution:**
1. Ensure simulator is booted: `xcrun simctl boot [DEVICE_ID]`
2. Wait 30 seconds for simulator to fully start
3. Verify with: `flutter devices`
4. Use specific device ID instead of generic 'ios'

### Error 3: Build Timeout
**Symptom:**
Command appears to hang during "Running Xcode build..."

**Causes & Solutions:**
- **First build**: Normal, takes 2-3 minutes
- **Subsequent builds**: Usually indicates dependency issues
- **Solution**: Wait for first build, use `flutter clean` if persistent issues

### Error 4: Simulator Not Responding
**Symptoms:**
- Simulator shows home screen but app doesn't launch
- Build completes but no app visible

**Solutions:**
1. Check if app installed: Look for "first_fitness_test_app" icon on simulator home screen
2. Force restart simulator: `xcrun simctl shutdown [DEVICE_ID]` then boot again
3. Clean build: `flutter clean && flutter pub get && flutter run -d [DEVICE_ID]`

## Device Reference

### Current Project Configuration
- **Primary Device**: iPhone 16
- **Device ID**: `5DA4B52F-5EF0-4C65-B044-80691655D7CE`
- **iOS Version**: 18.6
- **Screen Size**: 6.1" (suitable for testing mobile layouts)

### Alternative Devices Available
- iPhone 16 Pro: `76392867-DBE7-4E61-AC47-8F73ACF6EA19`
- iPhone 16 Plus: `1D061561-B649-409A-919E-2008FA57F6BE`

## Testing Checklist

### Visual Verification
- [ ] App launches and shows fitness tracker interface
- [ ] Dark theme applied throughout the app
- [ ] Bottom navigation bar with 5 tabs visible
- [ ] Orange accent colors visible (buttons, icons)
- [ ] Text is readable and properly sized

### Navigation Testing
- [ ] Dashboard tab shows welcome card and stats
- [ ] Workout tab shows "Coming in Phase 1D" placeholder
- [ ] Exercise Library tab shows "Coming in Phase 1C" placeholder  
- [ ] Progress tab shows "Coming in Phase 1G" placeholder
- [ ] Profile tab shows "Coming in Phase 1B" placeholder
- [ ] Bottom navigation switches between screens correctly

### Interaction Testing
- [ ] Tap targets are large and responsive
- [ ] Floating Action Button works (Start Workout button)
- [ ] Scrolling works on Dashboard screen
- [ ] App orientation handles portrait mode correctly

## Performance Notes

### Build Times
- **Clean build**: ~3 minutes (includes dependency resolution)
- **Hot reload**: <1 second (for UI changes)
- **Hot restart**: ~5 seconds (full app restart)

### Memory Usage
- **Simulator RAM**: Monitor if simulator becomes slow
- **App size**: Development builds are larger than production
- **Debug tools**: DevTools connection may impact performance

## Quick Commands Reference

```bash
# Project navigation
cd "/Users/leeshaun/Desktop/empty folder/first_fitness_test_app"

# Start development session
xcrun simctl boot 5DA4B52F-5EF0-4C65-B044-80691655D7CE
open -a Simulator
flutter run -d 5DA4B52F-5EF0-4C65-B044-80691655D7CE

# During development
# Press 'r' for hot reload
# Press 'R' for hot restart  
# Press 'q' to quit

# Troubleshooting
flutter clean
flutter pub get
flutter doctor -v
```

## Next Steps

After successful iOS setup:
1. **Phase 1C**: Implement Exercise Database
2. **Phase 1D**: Add Workout Logging functionality
3. **Phase 1E**: Integrate Rest Timer
4. **Cross-platform testing**: Test on physical iOS device
5. **Performance optimization**: Profile app performance

---

*Last updated: Phase 1A completion - Foundation & Theme Setup*
*Tested on: iPhone 16 Simulator (iOS 18.6)*