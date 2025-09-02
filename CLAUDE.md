# Weight Lifting Fitness Tracker - Development Plan

## Project Overview
A Flutter mobile app designed for weight lifters of all experience levels to track workouts, visualize muscle group progress, and gamify the lifting experience. The app eliminates the need to memorize workout routines during gym sessions by offering fast logging tools, visual feedback, and motivational progress tracking.

**Target:** iOS MVP first, then Android in Phase 2

### App Objectives
- **Primary**: Track workouts with fast, intuitive logging for gym environments
- **Secondary**: Visualize muscle group progress through gamification and radar charts
- **Motivational**: Gamify the weight lifting process to encourage progress and fun
- **Visual**: Provide immediate progress feedback to address fitness app abandonment (73% users quit within 30 days due to lack of visual progress)

### Target Audience
- Weight lifters (beginners to advanced)
- Users seeking structured progress tracking
- Fitness enthusiasts interested in gamified motivation
- Gym-goers who want data-driven workout insights

## Current Status & Major Accomplishments

### ✅ Core MVP Features Complete (Phases 1A-1G + Database Stability)
- ✅ **Phase 1A:** Foundation & Theme Setup with professional UI styling
- ✅ **Phase 1C:** Exercise Database with 1,500+ exercises, visual body part selection, and equipment-focused popular badges
- ✅ **Phase 1D:** Complete Workout Logging with SQLite, statistics, history, and real-time tracking
- ✅ **Phase 1E:** Rest Timer with audio notifications and workout integration
- ✅ **Phase 1F:** Workout Plans & Templates System with 7 default templates and CRUD management
- ✅ **Phase 1G:** Template Discovery & Navigation Flow with dynamic recommendations and layout polish
- ✅ **Database Stability:** Fixed connection lifecycle issues with retry logic and proper resource management
- 🎯 **Next:** Phase 2 - Navigation Polish and Template Category Enhancement

### 🚀 Technical Architecture Highlights  
- **Database**: Comprehensive SQLite schema with 8+ tables, proper indexing, and CRUD operations with connection pooling
- **Stability**: Robust error handling with database retry logic and shared connection lifecycle management
- **UI/UX**: Flutter best practices applied with Row overflow solutions, proper text handling, and responsive design
- **Templates**: Professional seeding service with 7 equipment-focused workout templates
- **Navigation**: Seamless flow between workout creation, logging, templates, and history
- **Performance**: Local-first approach with optimized loading and error recovery
- **Layout Compliance**: Official Flutter documentation patterns for preventing layout overflow errors

### 🎪 Ready for Enhancement (Phase 2+)
The app now has a **complete MVP foundation** ready for:
- Navigation polish and enhanced template discovery  
- Progress tracking with body part visualization
- Gamification system with XP and achievements
- Firebase authentication and cloud sync

---

## Phase Implementation Details

### Phase 1C: Professional Exercise Database ✅
**Goal:** Professional exercise database with ExerciseDB API integration and visual body part filtering

#### Key Achievements
- **API Integration**: 1,500+ exercises with GIF animations from ExerciseDB API
- **Premium Database**: 483 curated exercises with equipment-focused popular badge system
- **Interactive Body Silhouettes**: Front/back view with clickable muscle regions and real-time highlighting
- **Visual Selection**: Toggle between list view and body part selection with seamless exercise filtering
- **Popular Badge System**: Equipment-prioritized Tier 1 exercise highlighting (barbell, dumbbell, machine, cable over bodyweight)

#### Technical Implementation
- `lib/services/common_exercise_service.dart`: Local database with popular detection and sorting
- `lib/services/exercise_service.dart`: API integration with popularity-based filtering
- `lib/widgets/body_silhouette.dart`: Interactive body diagrams with muscle group mapping

### Phase 1D: Complete Workout Logging System ✅
**Goal:** Core workout tracking with customizable workout creation

#### Key Achievements
- **WorkoutSetupScreen**: Visual body part selection with time customization
- **WorkoutLoggingScreen**: Real-time exercise tracking with set-by-set logging (915 lines)
- **WorkoutHistoryScreen**: Comprehensive statistics and filtering (913 lines)
- **SQLite Integration**: Full CRUD operations with proper repository pattern
- **Statistics Engine**: Volume calculations, completion rates, and progress metrics

#### Technical Implementation
- Complete workout flow: Setup → Logging → Completion → History
- Professional UI with Material Design 3 compliance
- Advanced filtering, pagination, and status-based navigation
- 25+ integration tests covering complete workout flow

### Phase 1E: Rest Timer Implementation ✅
**Goal:** Professional countdown timer with audio/vibration notifications

#### Key Achievements
- **RestTimer Widget**: Circular progress animation with preset durations (60s-300s)
- **Timer Controls**: Start, pause, reset, skip with haptic feedback
- **Audio System**: TimerSoundService with configurable alerts
- **Workout Integration**: Auto-triggered modal after set completion
- **Visual Feedback**: Color-coded display (green→orange→red) with pulse animations

#### Technical Implementation
- `lib/widgets/rest_timer.dart`: Complete timer widget (415 lines)
- `lib/services/timer_sound_service.dart`: Audio notification service
- 9 widget tests + 5 integration tests with 100% pass rate

### Phase 1F: Workout Plans & Templates System ✅
**Goal:** Complete template management with CRUD operations and intelligent recommendations

#### Key Achievements
- **Template Management**: WorkoutPlansScreen with tabs (All, Favorites, Recent) and advanced filtering
- **Template Creation**: CreateWorkoutPlanScreen with exercise selection and body part targeting
- **Repository Pattern**: WorkoutTemplateRepository with full CRUD, statistics, and analytics
- **Template Categories**: Push, Pull, Legs, Full Body, Upper Body, Cardio, Strength, Custom

#### Technical Implementation
- Advanced querying with search, category filtering, and popularity scoring
- Template-to-workout conversion with seamless WorkoutSetupScreen integration
- Usage tracking, favoriting, and recommendation algorithms

### Phase 1G: Template Discovery & Navigation Flow ✅
**Goal:** Fix template discovery UX issues and implement dynamic workout recommendations

#### Key Achievements
- **7 Default Templates**: Professional equipment-focused templates (Chest Focus, Upper Legs Power, Back Builder, Shoulder Sculptor, Arm Destroyer, Push Day, Pull Day)
- **Dynamic Homepage**: "Today's Workout" shows real template data with day-of-week rotation
- **Database Fixes**: Resolved connection lifecycle issues preventing template loading
- **Layout Polish**: Applied Flutter-verified Row overflow solutions with SingleChildScrollView horizontal scrolling
- **Visual Distinction**: "Default Workouts (7)" and "My Custom Plans" section headers

#### Technical Implementation
- `lib/services/default_template_seeder_service.dart`: Automatic template creation on app launch
- `lib/services/workout_recommendation_service.dart`: Intelligent daily suggestions
- Flutter compliance with official documentation patterns for layout overflow prevention
- Error recovery and retry logic for database connection issues

### Body Silhouette Size Enhancement ✅
**Status:** ✅ **COMPLETED**  
**Goal:** Increase body silhouette display size for better user interaction and visual clarity

#### Final Solution: Asymmetric Transform Scaling ✅
**Root Cause Discovered:** The issue was not Flutter layout constraints, but the PNG files themselves containing thin silhouette artwork (1080×1350 aspect ratio = 0.8, making them naturally tall and narrow).

**Successful Solution:** `Transform` with `Matrix4.diagonal3Values()` for asymmetric scaling
```dart
Transform(
  transform: Matrix4.diagonal3Values(1.8, 1.3, 1.0), // X=1.8x, Y=1.3x, Z=1.0x
  alignment: Alignment.center,
  child: Image.asset(
    'assets/images/body_silhouette_front.png',
    width: 149,
    height: 285,
    fit: BoxFit.fill,
  ),
)
```

#### Implementation Results ✅
- **Width Enhancement**: 1.8x scaling provides excellent visual width, making silhouettes much more interactive
- **Height Optimization**: 1.3x scaling maintains proportions without excessive height
- **Visual Balance**: Perfect balance between width prominence and appropriate height
- **No Layout Errors**: Transform scaling is purely visual, no constraint violations
- **Maintained Functionality**: All clickable regions and muscle highlighting work perfectly
- **User Experience**: Silhouettes now visually prominent and easy to interact with

#### Technical Implementation
**Files Modified:**
- `lib/widgets/body_silhouette.dart` lines 129-137 (front view)
- `lib/widgets/body_silhouette.dart` lines 167-175 (back view)

**Key Technical Details:**
- **Matrix4.diagonal3Values(1.8, 1.3, 1.0)**: Asymmetric scaling (width=1.8x, height=1.3x)
- **alignment: Alignment.center**: Ensures proper scaling from center point
- **BoxFit.fill**: Maintains exact container dimensions before scaling
- **No clickable region adjustments needed**: Transform only affects visual rendering

#### Failed Approaches & Lessons Learned ❌
1. **Container Constraint Modifications** (FAILED): OverflowBox, IntrinsicWidth, Flexible widgets
2. **Layout Restructuring** (FAILED): Row alignment changes, SizedBox modifications
3. **Uniform Transform.scale** (PARTIALLY SUCCESSFUL): scale: 1.8 provided good width but excessive height

#### Success Criteria Achieved ✅
- [x] ✅ Body silhouettes visible and functional 
- [x] ✅ Silhouettes display with excellent visual prominence and interactivity
- [x] ✅ No layout constraint errors or warnings
- [x] ✅ Interactive muscle selection working perfectly at scaled size
- [x] ✅ Responsive behavior maintained across screen interactions

**Final Result:** Body silhouettes now provide optimal user experience with perfect visual balance and full interactive functionality.

### Database Connection Lifecycle Fixes ✅
**Status:** ✅ **COMPLETED**  
**Goal:** Resolve "DatabaseException(error database_closed)" errors occurring on app startup

#### Problem Identified ✅
**Root Cause:** Multiple screens were improperly closing the shared database connection in their `dispose()` methods, causing subsequent database operations to fail with "database_closed" errors.

#### Solution Implemented ✅
**Database Connection Lifecycle Management:**
1. **Identified Problem Screens**: Found 4 screens with improper database `.close()` calls
2. **Fixed Connection Sharing**: Commented out all database close calls in screen dispose methods
3. **Added Retry Logic**: Enhanced error handling with automatic retry for connection issues
4. **Resource Management**: Proper singleton database connection shared across app lifecycle

#### Files Modified ✅
- `lib/screens/workout_history_screen.dart`: Added retry logic + commented out `.close()`
- `lib/screens/workout_logging_screen.dart`: Commented out `_workoutRepository.close()`
- `lib/screens/workout_setup_screen.dart`: Commented out `_repository.close()`
- `lib/screens/workout_plans_screen.dart`: Already properly handled ✅
- `lib/screens/create_workout_plan_screen.dart`: Already properly handled ✅

#### Technical Implementation Details ✅
**Retry Logic Pattern Added:**
```dart
} catch (e) {
  print('Error loading data: $e');
  
  // If database connection issue, try to retry once
  if (e.toString().contains('database_closed')) {
    print('Database connection closed, attempting retry...');
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadDataRetry();
      return;
    } catch (retryError) {
      print('Retry failed: $retryError');
    }
  }
  
  // Handle error normally
  _showError('Failed to load data: $e');
}
```

**Database Connection Comments:**
```dart
@override
void dispose() {
  _controllers.dispose();
  // Don't close the database connection - it's shared across the app
  // _repository.close();
  super.dispose();
}
```

#### Results Achieved ✅
- [x] ✅ Eliminated "DatabaseException(error database_closed)" errors on app startup
- [x] ✅ Workout History screen loads properly without database connection issues
- [x] ✅ All screens now share the database connection properly throughout app lifecycle
- [x] ✅ Added robust retry logic for edge cases during app initialization
- [x] ✅ Improved error handling and user feedback for database operations

**Final Result:** Database operations are now stable and reliable across all screens with proper connection lifecycle management and automated error recovery.

---

## Development Roadmap

### Phase 2: Navigation Polish & Template Enhancement
**Goal:** Improve navigation flow and template category functionality
- [ ] Replace "CHOOSE DIFFERENT" button with "BROWSE ALL WORKOUTS" for better UX
- [ ] Test complete navigation flow from Home → Plans → Home → Plans  
- [ ] Add enhanced category filtering in Plans screen with visual badges
- [ ] Improve search functionality to work across all templates
- [ ] Add template action buttons (Start, Edit, Favorite) with proper styling
- [ ] Standardize terminology throughout app for consistent UX
**Deliverable:** Polished navigation experience with enhanced template discovery

### Phase 1H: Progress Tracking & Visualization
**Goal:** Volume calculations and visual progress representation
- [ ] Implement volume calculation (weight × reps × sets) from completed workouts
- [ ] Create body part volume aggregation from local workout logs
- [ ] Build progress visualization on body silhouettes with heat mapping
- [ ] Add workout history visualization on muscle groups  
- [ ] Build comprehensive progress dashboard with statistics
- [ ] Add historical progress views with time-based filtering
- [ ] Calculate progress metrics and trends from local storage
**Deliverable:** Progress tracking with visual body part representation and local data calculations

### Phase 1I: Gamification System
**Goal:** XP and leveling mechanics with local storage
- [ ] Implement XP calculation from volume
- [ ] Create body part leveling system
- [ ] Add level-up notifications
- [ ] Build XP/level display components
- [ ] Store XP/level data locally
**Deliverable:** Working gamification mechanics with local persistence

### Phase 1J: Radar Chart Visualization
**Goal:** Visual progress representation from local data
- [ ] Integrate flutter_radar_chart package
- [ ] Create radar chart for body part progress
- [ ] Add interactive chart features
- [ ] Style chart to match dark theme
- [ ] Display local progress data in charts
**Deliverable:** Visual progress charts showing local workout data

### Phase 1K: Authentication System
**Goal:** User login/registration functionality (moved after core features)
- [ ] Set up Firebase project integration
- [ ] Implement email/password authentication
- [ ] Add Google OAuth login
- [ ] Create login, register, and welcome screens
- [ ] Add basic user session management
- [ ] Plan local data migration to user accounts
**Deliverable:** Working authentication flow ready for cloud sync

### Phase 1L: Firebase Data Sync
**Goal:** Cloud storage and real-time sync (moved after core features)
- [ ] Set up Firestore database structure
- [ ] Implement workout log cloud sync
- [ ] Add offline capability with sync when online
- [ ] Create user data management
- [ ] Migrate existing local data to Firebase
- [ ] Implement data sync between local and cloud storage
**Deliverable:** Cloud-synced workout data with migration from local storage

---

## Data Models

### Users
```dart
class User {
  String userId;           // Unique identifier
  String email;           // Email address (unique)
  String name;            // Display name
  AuthProvider provider;  // enum: email, google
  DateTime createdAt;     // Registration timestamp
  Map<String, int> bodyPartLevels; // XP levels per body part
}
```

### Exercises
```dart
class Exercise {
  String exerciseId;         // Unique identifier
  String name;              // Exercise name
  List<String> bodyParts;   // Target body parts
  String equipment;         // Required equipment
  String instructions;      // Step-by-step guide
  String gifUrl;           // Animation URL
  bool isPopular;          // Equipment-focused popularity badge
}
```

### Workout Log
```dart
class WorkoutLog {
  String logId;        // Unique identifier
  String userId;       // Foreign key to Users
  String exerciseId;   // Foreign key to Exercises
  double weight;       // Weight lifted (kg)
  int sets;           // Number of sets
  int reps;           // Reps per set
  DateTime timestamp; // When exercise was performed
  double volume;      // Calculated: weight × reps × sets
}
```

### Body Part Progress
```dart
class BodyPartProgress {
  String userId;          // Foreign key to Users
  String bodyPart;        // Body part name
  double totalVolume;     // Lifetime volume lifted
  int xpLevel;           // Current XP level
  DateTime lastWorked;   // Last workout date
  List<Achievement> achievements; // Unlocked achievements
}
```

---

## Firebase Setup Checklist
- [ ] Create Firebase project
- [ ] Enable Authentication (Email/Password + Google)
- [ ] Set up Firestore database
- [ ] Configure iOS app in Firebase Console
- [ ] Download and add GoogleService-Info.plist
- [ ] Set up Firestore security rules
- [ ] Test authentication flow

---

## Testing Strategy
- [ ] Unit tests for business logic (XP calculations, volume tracking)
- [ ] Widget tests for key UI components
- [ ] Integration tests for workout flow
- [ ] Manual testing on physical device in gym environment
- [ ] Test offline capability and sync

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

**Progress & Charts (Phase 1G-1I)**
- **LinearProgressIndicator** - XP progress bars
- **CircularProgressIndicator** - Loading states, timer countdown
- **flutter_radar_chart** - Body part progress visualization
- **fl_chart** - Volume tracking charts
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
- **_buildMetadataChip()** - Workout detail badges ✅
- **_buildStatCard()** - Metric display cards ✅
- **_buildQuickActionCard()** - Dashboard shortcuts ✅
- **WorkoutCard** - Featured workout displays (Phase 1D)
- **TimerWidget** - Countdown timer with animations (Phase 1E)
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
fl_chart: ^0.68.0            # General charts

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

### iOS Simulator Testing
For detailed iOS simulator setup, troubleshooting, and testing instructions, see **[ios-simulator-setup.md](ios-simulator-setup.md)**

**Quick Start:**
```bash
# Boot iPhone 16 simulator and run app
xcrun simctl boot 5DA4B52F-5EF0-4C65-B044-80691655D7CE
open -a Simulator
flutter run -d 5DA4B52F-5EF0-4C65-B044-80691655D7CE
```

---

## Design Principles & Security

### UI/UX Guidelines
- **Dark mode by default** - Gym-friendly interface optimized for low-light environments
- **Large tap targets** - Easy interaction during workouts with gloves or sweaty hands
- **High-contrast text** - Readable in dimly lit gym environments
- **Minimalist layout** - Reduce distractions and focus on core functionality
- **Centered CTAs** - Step-by-step flows for onboarding and setup
- **Visual progress focus** - Immediate feedback on achievements to address 73% user abandonment

### Professional Styling Standards
- **Enhanced Dark Theme**: Deep backgrounds (#0A0A0A), sophisticated surfaces (#1A1A1A, #2A2A2A)
- **Orange Accent Color**: Consistent #FFB74D for improvements, achievements, and CTAs
- **Material Design 3**: Professional gradients, proper shadows, enhanced typography hierarchy
- **Equipment-Focused Design**: Prioritize barbell/dumbbell exercises over bodyweight alternatives

### Security Considerations
- **Firebase Authentication**: JWT token management handled by Firebase SDK
- **Secure Access Rules**: Firestore per-userId data isolation
- **Data Encryption**: User data encrypted in transit and at rest
- **OAuth Integration**: Email/password and Google Sign-In with secure token handling
- **Privacy by Design**: No unnecessary data collection, user-controlled data retention

---

## Development Status & Notes

### ✅ Completed Achievements
- ✅ **Core MVP Complete**: All essential features implemented with professional UX and stability
- ✅ **Flutter Best Practices**: Official documentation patterns applied throughout with proper error handling
- ✅ **Database Architecture**: Comprehensive SQLite with proper relationships, indexing, and connection management  
- ✅ **Layout Compliance**: Overflow issues resolved with Flutter-verified solutions
- ✅ **Production Ready**: Database stability fixes ensure reliable operation on app startup and navigation

### 📋 Development Guidelines
- Each phase should be fully functional before moving to next
- Test incrementally after each phase completion
- Prioritize core workout functionality before gamification features
- **Always check MCP documentation** before starting new features or phases
- Maintain proper database connection lifecycle management across all screens
- Use retry logic pattern for database operations that may fail on app startup