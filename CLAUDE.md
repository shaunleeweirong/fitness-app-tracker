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

### ✅ Core MVP Complete (Phases 1A-1H + Phase 2 + Progress Enhancement)
- ✅ **Phase 1A-1C:** Foundation, UI styling, Exercise Database (1,500+ exercises), visual body part selection
- ✅ **Phase 1D:** Complete Workout Logging with SQLite, statistics, history, real-time tracking
- ✅ **Phase 1E:** Rest Timer with audio notifications and workout integration
- ✅ **Phase 1F-1G:** Workout Templates System (7 default templates), navigation flow, layout polish
- ✅ **Phase 1G-1H:** Exercise Preview & Customization System with template preservation (Option 1)
- ✅ **Phase 2:** Navigation Polish with advanced filtering, search, action buttons
- ✅ **Progress Screen:** Custom chart implementation, overflow fixes, layout optimization
- ✅ **Database Stability:** Connection lifecycle fixes with retry logic
- ✅ **Chart System:** Replaced fl_chart with custom CustomPainter for better control
- 🎯 **Next:** Workout History Management & Phase 1I

### 🚀 Technical Architecture
- **Database**: SQLite schema v4 (11+ tables), proper indexing, CRUD operations, connection pooling
- **UI/UX**: Material Design 3, advanced search/filtering, polished navigation
- **Templates**: 7 default templates, CRUD operations, intelligent recommendations
- **Exercise Customization**: UserWorkout system with template preservation (Option 1 approach)
- **User Interface**: Professional modal dialogs, debounced interactions, comprehensive validation
- **Performance**: Local-first approach, optimized loading, error recovery, real-time search

### 🎪 Ready for Enhancement (Phase 1I+)
Complete MVP with exercise customization ready for: Progress tracking with body part visualization, gamification (XP/achievements), radar charts, Firebase authentication

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

### Phase 1G-1H: Exercise Preview & Customization ✅
- **Template Preservation**: Option 1 approach - system templates remain unchanged
- **UserWorkout System**: Personal copies with comprehensive exercise customization
- **Exercise Management**: Remove, edit, reorder exercises with professional modals
- **Database Schema v4**: 3 new tables for user workout storage and modification tracking
- **Key Files**: `user_workout_repository.dart`, updated `workout_setup_screen.dart`, `models/workout.dart`

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

#### Exercise Preview & Customization System ✅
**Problem**: Template selection showed customize screen instead of proceeding to workout logging
**Solution**: Comprehensive exercise preview system with template preservation (Option 1 approach)
- **Files**: `lib/models/workout.dart`, `lib/services/user_workout_repository.dart`, `lib/screens/workout_setup_screen.dart`, `lib/services/database_helper.dart`
- **Features**: Professional exercise editing modal, debounced interactions, comprehensive logging
- **Database**: Schema v4 with 3 new tables (user_workouts, user_workout_exercises, user_workout_modifications)
- **Result**: Users see exactly what exercises they'll do and can customize before starting workouts

---

## Development Roadmap

### 🚨 Next Priority: Workout History Management
- [ ] 30-day time filtering for performance
- [ ] Enhanced search functionality  
- [ ] Lazy loading for large datasets
- [ ] User-controlled archive feature

### Upcoming Phases
- **Phase 1I:** Progress tracking with body part visualization
- **Phase 1J:** Gamification system (XP, levels, achievements)
- **Phase 1K:** Radar chart visualization
- **Phase 1L:** Firebase authentication
- **Phase 1M:** Cloud sync with offline capability

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

// User Workout System (Phase 1G-1H Implementation)
class UserWorkout {
  String userWorkoutId, userId, name;
  String? baseTemplateId; // Links to original template
  List<String> targetBodyParts;
  int plannedDurationMinutes;
  DateTime createdAt;
  WorkoutSource source; // template, custom, imported
  List<UserExercise> exercises;
  WorkoutCustomizations? modifications;
}

class UserExercise {
  String userExerciseId, exerciseId, exerciseName;
  List<String> bodyParts;
  int orderIndex, suggestedSets, suggestedRepsMin, suggestedRepsMax;
  double? suggestedWeight;
  int restTimeSeconds;
  bool isFromTemplate;
  String? sourceTemplateExerciseId;
}

class WorkoutCustomizations {
  List<String> removedExerciseIds;
  List<UserExercise> addedExercises;
  Map<String, ExerciseModification> modifiedExercises;
  DateTime modifiedAt;
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

**Phase 1G-1H (Exercise Customization):** ✅
- Template preservation patterns
- User workout data models
- Professional modal dialogs

**Phase 1I-1J (Progress & Gamification):**
- State management patterns (Provider, Riverpod, Bloc)
- Data visualization packages

**Phase 1K (Radar Charts):**
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
- **ExerciseEditDialog** - Professional exercise editing modal with validation ✅
- **XPProgressBar** - Gamification progress (Phase 1I)

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

### Critical Test Cases
1. **Home Tab Recommendation:** Verify correct exercise count displays (not "0 exercises")
2. **Tab Navigation:** Ensure recommendations persist when switching tabs
3. **Pull-to-Refresh:** Test manual cache refresh functionality
4. **Plans Tab Comparison:** Verify Home and Plans show same exercise count

### Testing Checklist
**Before Changes:**
- [ ] Home tab shows workout recommendations with correct exercise count
- [ ] No console errors during recommendation loading
- [ ] All 5 tabs load properly without layout issues

**After Changes:**
- [ ] New features work as expected
- [ ] No new console errors introduced
- [ ] Performance remains smooth

---

## Recent Bug Fixes

### ✅ Fixed: RenderFlex Overflow (Body Silhouettes)
**Fix:** Reduced width from 149px to 130px
**Test:** Navigate to Progress tab → Verify no overflow warnings

### ✅ Fixed: Recommendation System Persistence 
**Fix:** SharedPreferences-based caching with automatic cleanup
**Test:** App restart should show cached recommendations instantly

### ✅ Fixed: Exercise Preview & Customization System (Phase 1G-1H)
**Implementation:** Complete exercise preview system with template preservation
- UserWorkout model system with Option 1 approach (system templates preserved)
- Database schema v4 with 3 new tables for user workout customization
- Professional exercise editing modal with validation and debouncing
- Template modification tracking with audit trail
- 1,889 lines of code across 6 files

### ✅ Fixed: Home Screen Exercise Count Display Issue
**Problem:** Home screen showed "0 exercises" while Plans tab correctly showed actual count
**Root Cause:** Template caching excluded exercise data during serialization
**Solution:** 
- Added `WorkoutTemplate.toCompleteMap()` method that includes exercises
- Updated `WorkoutTemplate.fromMap()` to deserialize cached exercise data
- Modified recommendation service to use complete serialization for caching
- Added comprehensive logging to track exercise data throughout system

**Files:** `lib/models/workout.dart`, `lib/services/workout_recommendation_service.dart`, `lib/main.dart`
**Result:** Home screen now displays correct exercise count matching Plans tab

---

## Recommendation Algorithm Documentation

### How "Today's Recommendation" Is Determined

The workout recommendation system uses a **day-of-week rotation strategy** with usage-based selection for variety.

#### **Day-Based Workout Categories**
```dart
Monday:    Push/Upper Body     // Start week strong
Tuesday:   Legs/Lower Body     // Foundation building  
Wednesday: Pull/Upper Body     // Mid-week back focus
Thursday:  Full Body/Strength  // Balanced training
Friday:    Push/Upper Body     // End week strong
Saturday:  Full Body/Cardio    // Weekend warrior
Sunday:    Pull/Full Body      // Active recovery
```

#### **Selection Process**
1. **Get today's day of week** (1=Monday, 7=Sunday)
2. **Lookup preferred categories** for that day
3. **Find templates matching those categories** from available system/user templates
4. **Sort by usage count** (ascending - least used first)
5. **Return the least-used template** in preferred category for variety

#### **Fallback Logic**
- If no templates match today's preferred categories → try any available template
- If no templates exist at all → return `null` → shows "Create Your Workout" fallback
- Fallback recommendation method tries `fullBody` or `push` categories as safe defaults

#### **Why "Create Your Workout" Appears**
The fallback content appears when:
1. **No system templates seeded** - Template seeding failed during user creation
2. **Category mismatch** - Templates exist but don't match any expected categories
3. **Database connection issues** - Template loading fails completely
4. **Cache deserialization failure** - SharedPreferences data corruption

#### **System Template Categories Expected**
The default templates should include:
- `TemplateCategory.push` (Chest, Shoulders, Triceps)
- `TemplateCategory.pull` (Back, Biceps) 
- `TemplateCategory.legs` (Quads, Glutes, Hamstrings)
- `TemplateCategory.fullBody` (Compound movements)
- `TemplateCategory.upperBody` (Arms, chest, back)
- `TemplateCategory.lowerBody` (Legs, glutes)

#### **Debug Console Verification**
To verify the algorithm is working:
```
📋 Found X system templates           // Should be > 0
📝 System template: [Name] (push)     // Should show various categories
🎯 Selected recommendation: [Name]    // Should match today's preferred category
```

If you see `📋 Found 0 system templates`, the issue is template seeding, not the recommendation algorithm.

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
- **Exercise Browser**: Add/search functionality not yet implemented in customization
- **Exercise Reordering**: Drag-and-drop reordering not yet implemented

### 📋 Guidelines
- Each phase fully functional before proceeding
- Test incrementally, prioritize core functionality before gamification
- Check MCP documentation before new features
- Maintain database connection lifecycle with retry logic