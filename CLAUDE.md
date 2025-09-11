# Weight Lifting Fitness Tracker - Development Plan

## Project Overview
Flutter mobile app for weight lifters to track workouts, visualize muscle group progress, and gamify the lifting experience with fast logging tools and visual feedback.

**Target:** iOS MVP first, then Android in Phase 2

### App Objectives
- **Primary**: Fast, intuitive workout logging for gym environments
- **Secondary**: Gamified muscle group progress visualization with radar charts
- **Visual**: Immediate progress feedback (address 73% user abandonment due to lack of visual progress)

### Target Audience
Weight lifters (beginners to advanced), fitness enthusiasts seeking structured progress tracking and gamification

## Current Status & Major Accomplishments

### ✅ Core MVP Complete (Phases 1A-1G + Phase 2 + Progress Enhancement)
- ✅ **Phase 1A-1C:** Foundation, UI styling, Exercise Database (1,500+ exercises), visual body part selection
- ✅ **Phase 1D:** Complete Workout Logging with SQLite, statistics, history, real-time tracking
- ✅ **Phase 1E:** Rest Timer with audio notifications and workout integration
- ✅ **Phase 1F-1G:** Workout Templates System (7 default templates), navigation flow, layout polish
- ✅ **Phase 2:** Navigation Polish with advanced filtering, search, action buttons
- ✅ **Progress Screen:** Custom chart implementation, overflow fixes, layout optimization
- ✅ **Database Stability:** Connection lifecycle fixes with retry logic
- ✅ **Chart System:** Replaced fl_chart with custom CustomPainter for better control
- 🎯 **Next:** Workout History Management & Phase 1H

### 🚀 Technical Architecture
- **Database**: SQLite schema (8+ tables), proper indexing, CRUD operations, connection pooling
- **UI/UX**: Material Design 3, advanced search/filtering, polished navigation
- **Templates**: 7 default templates, CRUD operations, intelligent recommendations
- **Performance**: Local-first approach, optimized loading, error recovery, real-time search

### 🎪 Ready for Enhancement (Phase 1H+)
Complete MVP ready for: Progress tracking with body part visualization, gamification (XP/achievements), radar charts, Firebase authentication

---

## Phase Implementation Summary

### Phase 1C-1D: Exercise Database & Workout Logging ✅
- **Exercise Database**: 1,500+ exercises, interactive body silhouettes, equipment-focused badges
- **Workout System**: Complete flow (Setup → Logging → History), SQLite integration, statistics engine
- **Key Files**: `exercise_service.dart`, `body_silhouette.dart`, workout screens

### Phase 1E: Rest Timer ✅
- **Timer Widget**: Circular progress, preset durations (60s-300s), haptic feedback
- **Integration**: Auto-triggered after sets, audio/vibration alerts
- **Testing**: 14 tests with 100% pass rate

### Phase 1F-1G: Templates & Navigation ✅
- **Template System**: 7 default templates, CRUD operations, categories (Push/Pull/Legs/etc)
- **Navigation Flow**: Home → Plans → Template Selection → Workout Setup
- **Features**: Search, filtering, favorites, intelligent recommendations

### Key Bug Fixes & Enhancements ✅

#### Body Silhouette Enhancement ✅
**Solution**: `Transform` with `Matrix4.diagonal3Values(1.8, 1.3, 1.0)` for asymmetric scaling
- **Files**: `lib/widgets/body_silhouette.dart` (lines 129-137, 167-175)
- **Result**: Optimal visual prominence and full interactive functionality

#### Database Connection Fixes ✅
**Problem**: "DatabaseException(error database_closed)" errors on startup
**Solution**: Removed improper `.close()` calls in screen dispose methods, added retry logic
- **Files**: `workout_history_screen.dart`, `workout_logging_screen.dart`, `workout_setup_screen.dart`
- **Result**: Stable database operations across all screens

#### Progress Screen Layout Fixes ✅
**Problem**: Layout overflow errors ("BOTTOM OVERFLOWED BY 4.7 PIXELS")
**Solution**: GridView childAspectRatio optimization (2.2 → 1.4), Flexible text wrappers
- **Files**: `main.dart`, `progress_overview_widget.dart`
- **Result**: Professional layout with no overflow errors

#### Custom Chart Implementation ✅
**Problem**: fl_chart library causing layout cramping and overflow issues in progress dashboard
**Solution**: Built custom SimpleLineChart using CustomPainter for precise layout control
- **Files**: `lib/widgets/simple_line_chart.dart` (new), `progress_overview_widget.dart`, `pubspec.yaml`
- **Result**: Perfect chart fit within containers, maintained visual design

---

## Development Roadmap

### 🚨 Priority: Workout History Management
- [ ] Default 30-day time filtering for performance
- [ ] Enhanced search functionality (workout names, exercises)
- [ ] Lazy loading optimization for large datasets
- [ ] User-controlled archive feature
**Issue:** Current infinite scroll may cause performance issues with large datasets

### Phase 1H: Progress Tracking & Visualization
- [ ] Volume calculation (weight × reps × sets) from completed workouts
- [ ] Body part volume aggregation from local logs
- [ ] Progress visualization on body silhouettes with heat mapping
- [ ] Comprehensive progress dashboard with statistics
**Deliverable:** Progress tracking with visual body part representation

### Phase 1I: Gamification System
- [ ] XP calculation from volume
- [ ] Body part leveling system
- [ ] Level-up notifications
- [ ] XP/level display components
**Deliverable:** Gamification mechanics with local persistence

### Phase 1J: Radar Chart Visualization
- [ ] Integrate flutter_radar_chart package
- [ ] Create radar chart for body part progress
- [ ] Style chart to match dark theme
**Deliverable:** Visual progress charts from local data

### Phase 1K: Authentication System
- [ ] Firebase project integration
- [ ] Email/password + Google OAuth authentication
- [ ] Login, register, welcome screens
**Deliverable:** Authentication flow ready for cloud sync

### Phase 1L: Firebase Data Sync
- [ ] Firestore database structure
- [ ] Workout log cloud sync with offline capability
- [ ] Local data migration to Firebase
**Deliverable:** Cloud-synced workout data

---

## Core Data Models

```dart
// Users
class User {
  String userId, email, name;
  AuthProvider provider; // email, google
  DateTime createdAt;
  Map<String, int> bodyPartLevels; // XP per body part
}

// Exercises  
class Exercise {
  String exerciseId, name, equipment, instructions, gifUrl;
  List<String> bodyParts; // Target muscle groups
  bool isPopular; // Equipment-focused badge
}

// Workout Log
class WorkoutLog {
  String logId, userId, exerciseId;
  double weight, volume; // volume = weight × reps × sets
  int sets, reps;
  DateTime timestamp;
}

// Body Part Progress
class BodyPartProgress {
  String userId, bodyPart;
  double totalVolume; // Lifetime volume
  int xpLevel;
  DateTime lastWorked;
  List<Achievement> achievements;
}
```

---

## Firebase Setup & Testing

### Firebase Checklist
- [ ] Create Firebase project, enable Authentication (Email/Google)
- [ ] Set up Firestore database, configure iOS app
- [ ] Download GoogleService-Info.plist, set security rules

### Testing Strategy  
- [ ] Unit tests (XP calculations, volume tracking)
- [ ] Widget tests (key UI components)
- [ ] Integration tests (workout flow)
- [ ] Manual gym environment testing

---

## MCP Documentation Protocol

### Session Startup Checklist
Before starting any new coding session or implementing a new feature:

1. **Check Flutter Documentation:**
   ```
   mcp__Context7__resolve-library-id flutter
   mcp__Context7__get-library-docs [flutter-library-id] topic:"latest updates"
   ```

2. **Check Firebase Documentation:**
   ```
   mcp__Context7__resolve-library-id firebase
   mcp__Context7__get-library-docs [firebase-library-id] topic:"flutter integration"
   ```

3. **Check Google Cloud/Firebase Services:**
   ```
   mcp__generative-ai_Docs__search_generative_ai_docs "firebase flutter"
   ```

### Phase-Specific Documentation Lookups

**Phase 1A (Foundation & Theme):**
- Flutter Material Design 3 dark themes
- Flutter navigation patterns

**Phase 1B (Authentication):**
- Firebase Auth Flutter integration
- Google Sign-In Flutter package

**Phase 1C-1D (Exercise Database & Logging):**
- Firestore Flutter patterns
- Local storage options (SQLite, Hive)

**Phase 1E (Rest Timer):**
- Flutter timer implementations
- Audio/vibration packages

**Phase 1F (Firebase Sync):**
- Firestore offline capabilities
- Real-time listeners in Flutter

**Phase 1G-1H (Progress & Gamification):**
- State management patterns (Provider, Riverpod, Bloc)
- Data visualization packages

**Phase 1I (Radar Charts):**
- flutter_radar_chart package updates
- Chart customization options

### Key MCP Commands Reference

**Search for specific packages:**
```
mcp__Context7__resolve-library-id [package-name]
mcp__Context7__get-library-docs [library-id] topic:"[specific-topic]"
```

**Search for Flutter patterns:**
```
mcp__Context7__get-library-docs /flutter/flutter topic:"[feature-name]"
```

**Check Google services:**
```
mcp__generative-ai_Docs__search_generative_ai_docs "[search-query]"
```

### Documentation Update Reminders
- Check MCP docs before implementing each new phase
- Verify package versions and breaking changes
- Look up best practices for each major feature
- Review security considerations for Firebase integration

### shadcn/ui Component Usage Rules

**Usage Rule:**
When asked to use shadcn components, use the MCP server.

**Planning Rule:**
When asked to plan using anything related to shadcn:
- Use the MCP server during planning
- Apply components wherever components are applicable
- Use whole blocks where possible (e.g., login page, calendar)

**Implementation Rule:**
When implementing:
- First call the demo tool to see how it is used
- Then implement it so that it is implemented correctly

**Key shadcn/ui MCP Commands:**
```
mcp__shadcn-ui__list_components
mcp__shadcn-ui__get_component [component-name]
mcp__shadcn-ui__get_component_demo [component-name]
mcp__shadcn-ui__list_blocks
mcp__shadcn-ui__get_block [block-name]
```

---

## Flutter UI Component Implementation Plan

### Core Layout (✅ Implemented)
- **MaterialApp** - Root app with enhanced dark theme configuration
- **Scaffold** - Page structure with gradient backgrounds
- **BottomNavigationBar** - 5-tab navigation with gradient container
- **SafeArea** - Handle device notches and status bars
- **SingleChildScrollView** - Scrollable content areas
- **Container** - Custom styling with gradients and shadows

### Content & Data Components
**Cards & Display (✅ Enhanced)**
- **Card** - Hero workout cards, stats cards with gradients & shadows
- **Container** - Custom styling with borders, gradients, rounded corners
- **Text** - Enhanced typography hierarchy (headlineMedium, titleLarge, etc.)
- **Icon** - Fitness icons with custom colors and sizes
- **Wrap** - Metadata chips layout

**Forms & Input (Phase 1C-1D)**
- **TextField/TextFormField** - Search, workout inputs with validation
- **DropdownButtonFormField** - Exercise selection
- **Form** + **GlobalKey** - Validation management
- **ElevatedButton/IconButton** - Actions with custom styling

**Lists & Navigation (Phase 1C-1D)**
- **ListView.builder** - Exercise lists, workout history
- **ListTile** - Exercise items, menu options
- **ExpansionTile** - Expandable workout details
- **SearchDelegate** - Exercise search interface

**Progress & Charts (✅ Custom Implementation)**
- **LinearProgressIndicator** - XP progress bars
- **CircularProgressIndicator** - Loading states, timer countdown
- **SimpleLineChart** - Custom volume tracking charts ✅
- **flutter_radar_chart** - Body part progress visualization
- **TabBar/TabBarView** - Progress time periods

**Interactive & Feedback (Phase 1E)**
- **GestureDetector** - Custom touch interactions
- **showModalBottomSheet** - Exercise selection modal
- **SnackBar/AlertDialog** - Feedback and confirmations
- **AnimatedContainer** - Smooth transitions
- **RefreshIndicator** - Pull-to-refresh functionality

### Body Visualization Components (NEW - Phase 1C-1G)
- **BodySilhouetteWidget** - Interactive SVG body silhouettes for muscle selection
- **MuscleGroupHighlight** - Tap-to-select muscle group highlighting
- **BodyPartSelector** - Front/back body views with clickable regions
- **WorkoutCustomizer** - Time selection with body part targeting interface
- **ProgressHeatMap** - Workout history visualization on body silhouettes
- **MuscleGroupFilter** - Exercise filtering by selected body parts

### Custom Fitness Widgets (✅ Partially Implemented)
- **SimpleLineChart** - Custom chart implementation with CustomPainter ✅
- **_buildMetadataChip()** - Workout detail badges ✅
- **_buildStatCard()** - Metric display cards ✅
- **_buildQuickActionCard()** - Dashboard shortcuts ✅
- **RestTimer** - Circular progress timer with haptic feedback ✅
- **XPProgressBar** - Gamification progress (Phase 1H)

### State Management & Storage (Phase 1C+)
- **StatefulWidget** - Local state management
- **Provider/Riverpod** - App-wide state (planned)
- **SQLite/Hive** - Local data persistence
- **SharedPreferences** - Settings storage

### Theme & Styling (✅ Enhanced)
**Dark Theme Implementation:**
- **ColorScheme.fromSeed()** - Custom orange accent (#FFB74D)
- **ThemeData** - Material 3 with enhanced colors (#0A0A0A, #1A1A1A, #2A2A2A)
- **CardThemeData** - Consistent styling with shadows and rounded corners
- **TextTheme** - Professional typography hierarchy
- **BoxDecoration** - Gradients, shadows, borders for custom styling

### Required Packages by Phase
```yaml
# Core (Phase 1A-1C)
flutter: sdk: flutter
cupertino_icons: ^1.0.8

# Data & Storage (Phase 1C-1D)
sqflite: ^2.3.0              # Local database
path: ^1.8.3                 # File path utilities

# Body Visualization (Phase 1C-1G) - NEW
flutter_svg: ^2.0.10         # Interactive body silhouettes
path_provider: ^2.1.1        # Asset file access

# Charts & Visualization (Phase 1G-1I) 
flutter_radar_chart: ^0.2.2  # Radar charts
# Custom chart implementation replaces fl_chart

# Firebase (Phase 1B, 1F)
firebase_core: ^3.8.0        # Firebase core
firebase_auth: ^5.3.3        # Authentication
cloud_firestore: ^5.5.0      # Cloud database
google_sign_in: ^6.2.2       # Google OAuth

# Polish & Feedback (Phase 1E, 1J)
vibration: ^2.0.0            # Haptic feedback
audioplayers: ^6.1.0         # Sound notifications
shimmer: ^3.0.0              # Loading animations
```

---

## Body Part Visualization Feature

### Overview
Interactive body silhouettes for muscle group selection, workout customization, and progress tracking - inspired by professional fitness apps.

### Technical Implementation
**Approach:** SVG-based interactive body silhouettes using `flutter_svg` package
**Scope:** 8-12 major muscle groups per body view (front/back)
**Interaction:** Tap-to-select muscle groups with visual highlighting

### Feature Integration Across Phases
- **Phase 1C**: Visual muscle group filtering for exercise selection
- **Phase 1D**: Workout customization with body part targeting and time selection
- **Phase 1G**: Progress visualization with workout history heat mapping on body silhouettes
- **Phase 1H**: XP/level visualization per muscle group

### Body Part Mapping (Simplified)
**Front View:** Chest, Shoulders, Arms (biceps), Abs, Quads
**Back View:** Upper Back, Arms (triceps), Lower Back, Glutes, Hamstrings, Calves

### Implementation Benefits
- **Visual Exercise Discovery**: Users can tap body parts to find relevant exercises
- **Workout Customization**: Visual selection of target muscle groups
- **Progress Motivation**: See workout history and progress mapped to body parts
- **Professional UX**: Matches industry-standard fitness app interfaces

### Technical Limitations
- Simplified anatomical representation (major muscle groups only)
- Static SVG silhouettes (not 3D or animated body models)
- Focus on functionality over detailed anatomical accuracy

---

## Technical Stack & Development Commands

### Frontend
- **Flutter**: Cross-platform mobile framework
- **Material Design**: UI components with dark theme
- **flutter_radar_chart**: Radar chart visualization

### Backend
- **Firebase Auth**: Email/password + Google OAuth
- **Firestore**: NoSQL database for workout data
- **Cloud Functions**: XP calculations (if needed)

### Development Commands
```bash
# Run app in development
flutter run

# Run on specific device
flutter run -d chrome
flutter run -d ios

# Hot reload: Press 'r' in terminal
# Hot restart: Press 'R' in terminal

# Build for release
flutter build ios
flutter build apk

# Install dependencies
flutter pub get

# Check for issues
flutter doctor
```

### iOS Simulator Protocol ⚠️
**CRITICAL**: Always refresh simulator after code changes
1. Stop Flutter process
2. Restart: `flutter run -d 5DA4B52F-5EF0-4C65-B044-80691655D7CE`
3. Wait for complete rebuild
4. Verify changes are visible

**Why**: Hot reload may not reflect all changes, new features need full restart

### Quick Start
```bash
xcrun simctl boot 5DA4B52F-5EF0-4C65-B044-80691655D7CE
open -a Simulator
flutter run -d 5DA4B52F-5EF0-4C65-B044-80691655D7CE
```

---

## Manual Testing Protocol

### Critical Testing Areas
Before making changes or validating fixes, follow these manual testing steps to ensure app stability and user experience.

### 🧪 Recommendation System Testing (Home Tab)
**Priority: HIGH** - Addresses inconsistent "Create Your Workout" vs recommended workout display

#### Test Case 1: Fresh App Launch
1. **Kill and restart** the Flutter app completely
2. **Navigate to Home tab** (should be default)
3. **Observe initial state:**
   - ✅ **Expected:** Workout recommendation with template name, reason, and action buttons
   - ❌ **Issue:** "Create Your Workout" fallback content appears instead
   - 📝 **Log:** Check debug console for recommendation loading messages

#### Test Case 2: Tab Navigation Consistency  
1. **Start on Home tab** with successful recommendation
2. **Navigate to other tabs:** History → Plans → Exercises → Progress
3. **Return to Home tab**
4. **Verify state persistence:**
   - ✅ **Expected:** Same recommendation still displayed
   - ❌ **Issue:** Fallback content appears or recommendation changes unexpectedly

#### Test Case 3: Refresh Functionality (NEW)
1. **Navigate to Home tab**
2. **If fallback content shows:**
   - **Pull down to refresh** (swipe down gesture)
   - **Or tap small refresh icon** in fallback content
3. **Verify refresh behavior:**
   - ✅ **Expected:** Loading indicator → Recommendation appears
   - 📝 **Log:** Check console for retry attempts and success/failure messages

#### Test Case 4: Database Connection Recovery
1. **Force database issues** (if possible, by rapidly switching tabs during startup)
2. **Verify automatic retry:**
   - ✅ **Expected:** Up to 3 automatic retries with 2-second delays
   - ✅ **Expected:** Fallback recommendation attempts if main fails
   - 📝 **Log:** Watch console for retry messages and fallback attempts

### 🎯 Validation Questions for Changes
**BEFORE IMPLEMENTING NEW FEATURES - ASK USER:**

1. **"Can you test the Home tab recommendation consistency?"**
   - Navigate between tabs 5-10 times
   - Verify recommendation stays consistent
   - Report if "Create Your Workout" appears when it shouldn't

2. **"Does the pull-to-refresh work properly?"**
   - Try pull-to-refresh gesture on Home tab
   - Test manual refresh button in fallback content
   - Confirm recommendations load after refresh

3. **"Are there any console errors during recommendation loading?"**
   - Check Flutter debug console during app startup
   - Look for database connection errors or template loading failures
   - Report any red error messages related to recommendations

### 🔧 UI/UX Testing Protocol

#### Navigation Flow Testing
1. **Bottom Navigation Tabs:**
   - Test all 5 tabs: Home, History, Plans, Exercises, Progress
   - Verify smooth transitions without flickering
   - Check that each tab loads content properly

#### Layout Overflow Testing  
1. **Progress Tab Body Silhouettes:**
   - Navigate to Progress tab
   - Verify no yellow/red overflow warnings
   - Check that body silhouettes display properly without layout issues

2. **Home Tab Responsive Layout:**
   - Test on different screen orientations (if applicable)
   - Verify workout cards display properly
   - Check button layouts don't overflow

#### Error State Testing
1. **Network/Database Errors:**
   - Test app behavior with poor connectivity simulation
   - Verify graceful error handling and user feedback
   - Check retry mechanisms work as expected

### 📋 Testing Checklist Template

**Before Code Changes:**
- [ ] Home tab shows workout recommendations consistently
- [ ] Tab navigation preserves Home tab state
- [ ] No console errors during recommendation loading
- [ ] Pull-to-refresh functionality works
- [ ] No UI overflow errors in any tab

**After Code Changes:**
- [ ] Original functionality still works
- [ ] New feature works as expected
- [ ] No new console errors introduced
- [ ] Performance remains smooth
- [ ] UI layouts remain intact

**Regression Testing:**
- [ ] All 5 tabs still load properly
- [ ] Database operations still function
- [ ] App startup time acceptable
- [ ] Memory usage reasonable (check iOS simulator debugger)

### 🐛 Issue Reporting Format

When reporting issues during testing, use this format:

```markdown
## Issue: [Brief Description]

**Steps to Reproduce:**
1. Step one
2. Step two
3. Step three

**Expected Behavior:**
[What should happen]

**Actual Behavior:**  
[What actually happens]

**Console Output:**
[Any relevant debug messages]

**Device/Environment:**
- iOS Simulator: iPhone 16 (5DA4B52F-5EF0-4C65-B044-80691655D7CE)
- Flutter Version: [check with `flutter --version`]

**Screenshots:**
[If applicable]
```

### 🚀 Performance Testing

#### Memory and Performance Checks
1. **iOS Simulator Debug Menu:**
   - **Instruments → Memory Usage** (check for leaks)
   - **Debug → Slow Animations** (verify smooth transitions)
   - **Debug → Color Blended Layers** (check rendering performance)

2. **Flutter Performance:**
   - **Hot Reload Speed:** Should be < 2 seconds
   - **App Startup:** Should reach Home tab < 5 seconds
   - **Tab Switching:** Should be instant with no noticeable lag

#### Database Performance
1. **Recommendation Loading:** Should complete < 3 seconds on first load
2. **Template Loading:** Plans tab should load < 2 seconds
3. **Exercise Search:** Should be real-time with no input lag

---

## Recent Bug Fixes & Manual Validation Required

### ✅ Fixed: RenderFlex Overflow (Body Silhouettes)
**Files:** `lib/widgets/body_silhouette.dart`
**Fix:** Reduced width from 149px to 130px
**Manual Test:** Navigate to Progress tab → Verify no overflow warnings

### 🔄 NEW: Recommendation System Reliability 
**Files:** `lib/main.dart` (DashboardScreen)
**Fix:** Added retry logic, pull-to-refresh, AutomaticKeepAliveClientMixin
**Manual Test Required:** 
1. **Kill and restart app 3-5 times** → Verify recommendations load consistently
2. **Navigate between tabs 10+ times** → Verify Home tab state persists  
3. **Test pull-to-refresh** → Verify manual refresh works when fallback appears
4. **Check console logs** → Verify retry attempts and success messages appear

**USER VALIDATION NEEDED:** Please test the above scenarios and confirm:
- ✅ Recommendations appear consistently on Home tab
- ✅ Tab navigation doesn't cause fallback content to appear unexpectedly  
- ✅ Pull-to-refresh resolves stuck "Create Your Workout" states
- ✅ Console shows successful recommendation loading messages

---

## Design Principles & Security

### UI/UX Guidelines
- **Dark mode**: Gym-friendly, low-light optimized interface
- **Large tap targets**: Easy interaction with gloves/sweaty hands
- **High-contrast text**: Readable in dimly lit environments
- **Visual progress focus**: Immediate feedback (address 73% user abandonment)

### Styling Standards
- **Enhanced Dark Theme**: Deep backgrounds (#0A0A0A), surfaces (#1A1A1A, #2A2A2A)
- **Orange Accent**: Consistent #FFB74D for achievements and CTAs
- **Material Design 3**: Professional gradients, shadows, typography
- **Equipment-Focused**: Prioritize barbell/dumbbell over bodyweight

### Security
- **Firebase Auth**: JWT token management, per-userId data isolation
- **Data Encryption**: Transit and rest encryption, secure OAuth
- **Privacy**: No unnecessary data collection, user-controlled retention

---

## Development Status & Guidelines

### ✅ Completed Achievements
- **Complete MVP**: Essential features, template discovery, Progress screen
- **Professional UX**: Polished navigation, search, filtering, overflow-free layouts
- **Database Architecture**: SQLite with relationships, indexing, connection management
- **Production Ready**: Stable operations, professional experience

### 🚨 Current Issues & Gaps
- **Workout History**: Infinite scroll without limits may cause performance issues
- **Data Management**: No user-controlled data retention policies
- **Search**: Limited search functionality across workout history
- **Performance**: No lazy loading for large workout datasets

### 📋 Guidelines
- Each phase fully functional before proceeding
- Test incrementally, prioritize core functionality before gamification
- Check MCP documentation before new features
- Maintain database connection lifecycle with retry logic