# Weight Lifting Fitness Tracker - Development Plan

## Project Overview
A Flutter mobile app for weight lifters to track workouts, visualize muscle group progress, and gamify the lifting experience. Features dark mode UI, Firebase backend, and radar chart visualizations.

**Target:** iOS MVP first, then Android in Phase 2

## Current Status
- ✅ Requirements analyzed
- ✅ Documentation phase completed
- ✅ Phase order optimized (Auth/Firebase moved after core features)
- ✅ **Phase 1A completed:** Foundation & Theme Setup
- ✅ **UI Enhancement completed:** Modern professional styling applied
- ✅ **ExerciseDB Integration completed:** API integration with 1,500+ exercises
- ✅ **Exercise Database Enhancement completed:** 483 premium exercises with equipment-focused popular badges
- ✅ **Phase 1C completed:** Professional Exercise Database with Visual Body Part Selection
- ✅ **Popular Badge System completed:** Equipment-prioritized Tier 1 exercise highlighting
- ⏳ **Currently on:** Ready for Phase 1D
- 🔄 **Next:** Phase 1D - Basic Workout Logging

---

## ✅ Recent Achievements

### Phase 1C: Professional Exercise Database with Visual Body Part Selection
**Status:** ✅ **COMPLETED**

#### ExerciseDB Integration & Premium Exercise Database
- **API Integration**: Successfully connected to free ExerciseDB API with 1,500+ exercises
- **Data Extraction**: Created `common_exercises_database.json` with **483 premium exercises** (upgraded from 180)
- **Body Part Coverage**: 9 body parts with optimized distribution (80 upper legs, 70 chest, 70 back, 60 shoulders, 50+ others)
- **Exercise Details**: Complete data including GIF animations, instructions, muscle targeting, equipment requirements
- **Selection Criteria**: **Enhanced gym popularity filter** with tier-based scoring system prioritizing mainstream exercises
- **File Size**: Enhanced JSON database with comprehensive exercise library
- **Success Rate**: 100% (483/500 target exercises extracted)
- **Popular Badge System**: Equipment-focused Tier 1 exercise identification with visual badges

#### Interactive Body Silhouettes & Visual Selection
- **Custom-Painted Body Diagrams**: Front and back view silhouettes with precise muscle region mapping
- **Clickable Muscle Groups**: Interactive regions for chest, back, shoulders, arms, legs, waist, and cardio
- **Visual Highlighting**: Real-time feedback with muscle group highlighting on selection
- **Intuitive Navigation**: Toggle between traditional list view and visual body selection
- **Exercise Filtering**: Seamless integration with exercise database for body part-specific filtering
- **Professional UI**: Consistent dark theme with smooth animations and visual feedback

#### Complete Exercise Experience
- **Exercise Detail Screens**: Full-screen GIF animations with comprehensive exercise information
- **Rich Content**: Step-by-step instructions, muscle targeting, equipment requirements, tips, and variations
- **Smart Data Strategy**: Hybrid approach using common database → API → cache → mock fallbacks
- **Performance Optimized**: Instant loading with 180 curated exercises, API expansion available

**Deliverable Achieved:** ✅ Professional exercise browsing experience with 1,500+ exercises, intuitive visual body part selection, equipment-focused popular badges, and rich media content

### Popular Badge System Implementation ✅
**Status:** ✅ **COMPLETED**  
**Goal:** Intelligent exercise popularity identification with equipment prioritization

#### Technical Implementation
- **Equipment-Focused Logic**: Prioritizes barbell, dumbbell, machine, and cable exercises over bodyweight alternatives
- **Tier-Based Pattern Matching**: Multi-level filtering system identifying core movement patterns
- **Advanced Exclusions**: Comprehensive filtering of niche, advanced, and specialized exercise variations
- **Consistent Application**: Same logic implemented across main.dart, CommonExerciseService, and ExerciseService
- **Popularity-Based Sorting**: Popular exercises automatically appear at top of all exercise lists

#### Selection Criteria Hierarchy
1. **Equipment-Based Patterns** (Highest Priority):
   - Barbell exercises: squat, deadlift, bench press, row
   - Dumbbell exercises: press, row, fly, curl
   - Machine exercises: leg press, lat pulldown, machine press
   - Cable exercises: cable row, cable fly, tricep extension

2. **Core Movement Patterns** (Equipment Required):
   - Only applies to exercises using actual equipment (not bodyweight)
   - Pattern matching: squat, deadlift, bench press, row, press, curl, extension, fly, raise, pulldown

3. **Essential Bodyweight** (Selective):
   - Limited to fundamental movements: basic push-ups, pull-ups, chin-ups, dips
   - Excludes variations: no wide, diamond, incline, decline, pike, archer variations

#### Visual Implementation
- **Orange POPULAR Badge**: Distinctive badge overlay on exercise cards
- **Positioned Top-Right**: Clear visibility without obscuring exercise imagery
- **Consistent Styling**: Matches app's orange accent color (#FFB74D) with black text

#### Results Achieved
- **Balanced Distribution**: 105/483 exercises marked popular (21.7%)
- **Equipment Focus**: Significantly reduced bodyweight popular badges (especially in back exercises)
- **Body Part Coverage**: Each body part maintains adequate popular exercise representation
- **User Experience**: Popular exercises appear first in all browsing scenarios (body part filtering, search, general browsing)

**Technical Files Updated:**
- `lib/main.dart`: Popular badge UI component and detection logic
- `lib/services/common_exercise_service.dart`: Local database popular detection and sorting
- `lib/services/exercise_service.dart`: API integration popular detection and sorting

---

## Incremental Development Plan

### Phase 1A: Foundation & Theme Setup ✅
**Goal:** Transform basic counter app into dark-themed fitness foundation
- [x] Replace counter UI with dark theme
- [x] Create basic app structure and navigation
- [x] Set up color scheme and typography for gym readability
- [x] Create placeholder home screen
- [x] **Enhanced:** Applied modern professional UI styling
**Deliverable:** Dark-themed app shell with basic navigation + Professional modern styling

### Phase 1C: Exercise Database ✅
**Goal:** Professional exercise database with ExerciseDB API integration and visual body part filtering
- [x] **COMPLETED:** Integrate ExerciseDB API (1,500+ exercises with GIF animations)
- [x] **COMPLETED:** Implement API client with caching strategy (HTTP + local SQLite)
- [x] **COMPLETED:** Build exercise selection screen with API-powered search/filter
- [x] **COMPLETED:** Extract premium exercise database (**483 exercises** with enhanced selection criteria)
- [x] **COMPLETED:** Implement **gym popularity filter** with tier-based scoring system
- [x] **COMPLETED:** Create **equipment-focused popular badge system** prioritizing weighted exercises
- [x] **COMPLETED:** Add **popularity-based sorting** ensuring popular exercises appear first
- [x] **COMPLETED:** Implement interactive body silhouettes for muscle group selection
- [x] **COMPLETED:** Add visual body part filtering with custom-painted highlighting
- [x] **COMPLETED:** Create body part mapping from ExerciseDB to visualization regions
- [x] **COMPLETED:** Create exercise detail view with GIF animations and instructions
- [x] **COMPLETED:** Integrate enhanced exercise database with app (JSON → local storage)
**Deliverable:** ✅ Professional exercise browsing with 1,500+ exercises, visual body part selection, equipment-focused popular badges, and rich media content

### Phase 1D: Basic Workout Logging
**Goal:** Core workout tracking with customizable workout creation
- [ ] **NEW:** Build workout customization interface with time selection
- [ ] **NEW:** Integrate body part targeting with visual selection
- [ ] Build workout logging form (exercise, weight, sets, reps)
- [ ] Implement local data storage (SQLite/Hive)
- [ ] Create workout history view with targeted muscle visualization
- [ ] Add basic validation and error handling
- [ ] Create mock user system for single-user experience
**Deliverable:** Functional workout logging with visual customization and local persistence

### Phase 1E: Rest Timer
**Goal:** Timer functionality between sets
- [ ] Implement countdown timer UI
- [ ] Add timer controls (start, pause, reset)
- [ ] Include audio/vibration notifications
- [ ] Integrate timer into workout flow
**Deliverable:** Working rest timer feature

### Phase 1G: Progress Tracking
**Goal:** Volume calculations and visual progress representation
- [ ] Implement volume calculation (weight × reps × sets)
- [ ] Create body part volume aggregation from local workout logs
- [ ] **NEW:** Build progress visualization on body silhouettes
- [ ] **NEW:** Add workout history heat mapping on muscle groups
- [ ] Build basic progress dashboard
- [ ] Add historical progress views
- [ ] Calculate progress metrics from local storage
**Deliverable:** Progress tracking with visual body part representation and local data calculations

### Phase 1H: Gamification System
**Goal:** XP and leveling mechanics with local storage
- [ ] Implement XP calculation from volume
- [ ] Create body part leveling system
- [ ] Add level-up notifications
- [ ] Build XP/level display components
- [ ] Store XP/level data locally
**Deliverable:** Working gamification mechanics with local persistence

### Phase 1I: Radar Chart Visualization
**Goal:** Visual progress representation from local data
- [ ] Integrate flutter_radar_chart package
- [ ] Create radar chart for body part progress
- [ ] Add interactive chart features
- [ ] Style chart to match dark theme
- [ ] Display local progress data in charts
**Deliverable:** Visual progress charts showing local workout data

### Phase 1B: Authentication System
**Goal:** User login/registration functionality (moved after core features)
- [ ] Set up Firebase project integration
- [ ] Implement email/password authentication
- [ ] Add Google OAuth login
- [ ] Create login, register, and welcome screens
- [ ] Add basic user session management
- [ ] Plan local data migration to user accounts
**Deliverable:** Working authentication flow ready for cloud sync

### Phase 1F: Firebase Data Sync
**Goal:** Cloud storage and real-time sync (moved after core features)
- [ ] Set up Firestore database structure
- [ ] Implement workout log cloud sync
- [ ] Add offline capability with sync when online
- [ ] Create user data management
- [ ] Migrate existing local data to Firebase
- [ ] Implement data sync between local and cloud storage
**Deliverable:** Cloud-synced workout data with migration from local storage

### Phase 1J: Polish & Testing
**Goal:** MVP refinement and bug fixes
- [ ] UI/UX improvements based on testing
- [ ] Performance optimization
- [ ] Bug fixes and edge case handling
- [ ] Add loading states and error handling
- [ ] Test authentication and cloud sync integration
**Deliverable:** Polished MVP ready for testing

---

## UI Enhancement Log

### Professional Styling Implementation ✅
**Date:** Phase 1A Enhancement  
**Goal:** Transform basic app into professional, modern fitness app matching industry standards

**Visual Improvements:**
- **Enhanced Dark Theme**: Deeper backgrounds (#0A0A0A), sophisticated surface colors (#1A1A1A, #2A2A2A)
- **Professional Gradients**: Subtle gradients throughout app for depth and visual interest
- **Improved Color Scheme**: Warmer orange/yellow accent (#FFB74D) for better visibility
- **Typography Hierarchy**: Proper font weights, improved spacing, better readability

**Dashboard Redesign:**
- **Hero Workout Card**: Featured "25 min Upper Body" workout with gradient background
- **Workout Metadata**: Professional chips showing duration, body part, difficulty, equipment
- **Badge System**: "TODAY'S WORKOUT" badge with proper styling
- **Enhanced Stats**: Color-coded metric cards with proper visual hierarchy
- **Quick Actions**: Dedicated section for common user tasks
- **Professional Spacing**: Improved margins, padding, and visual balance

**Navigation Enhancement:**
- **Gradient Bottom Bar**: Professional gradient with subtle shadow
- **Icon States**: Outlined/filled icons for better visual feedback
- **Enhanced Typography**: Proper font weights and sizing
- **Visual Polish**: Transparent background with proper elevation

**Technical Implementation:**
- Custom color constants for consistent theming
- Enhanced MaterialApp theme configuration
- Professional card styling with shadows and borders
- Improved button and chip theming
- Better visual hierarchy with proper color coding

**Result:** App now matches professional fitness app standards with modern, polished UI while maintaining our unique fitness tracking functionality.

---

## Technical Stack

### Frontend
- **Flutter**: Cross-platform mobile framework
- **Material Design**: UI components with dark theme
- **flutter_radar_chart**: Radar chart visualization

### Backend
- **Firebase Auth**: Email/password + Google OAuth
- **Firestore**: NoSQL database for workout data
- **Cloud Functions**: XP calculations (if needed)

### Key Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  firebase_core: ^3.8.0
  firebase_auth: ^5.3.3
  cloud_firestore: ^5.5.0
  google_sign_in: ^6.2.2
  flutter_radar_chart: ^0.2.2
```

---

## Data Models

### Users
- userId (string, unique)
- email (string, unique)
- name (string)
- authProvider (enum: email, google)

### Exercises
- exerciseId (string, unique)
- name (string)
- targetBodyPart (string)

### Workout Log
- logId (string, unique)
- userId (string, FK)
- exerciseId (string, FK)
- weight (number)
- sets (number)
- reps (number)
- timestamp (datetime)

### Body Part Progress
- userId (string, FK)
- bodyPart (string)
- volume (number)
- xpLevel (number)

---

## Development Commands

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

## iOS Simulator Testing
For detailed iOS simulator setup, troubleshooting, and testing instructions, see **[ios-simulator-setup.md](ios-simulator-setup.md)**

**Quick Start:**
```bash
# Boot iPhone 16 simulator and run app
xcrun simctl boot 5DA4B52F-5EF0-4C65-B044-80691655D7CE
open -a Simulator
flutter run -d 5DA4B52F-5EF0-4C65-B044-80691655D7CE
```

---

## Design Principles
- **Dark mode by default** (gym-friendly)
- **Large tap targets** for easy interaction during workouts
- **High-contrast text** for readability in dim lighting
- **Minimalist layout** to reduce distractions
- **Centered CTAs** with step-by-step flows

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

## Phase 2 Features (Future)
- Android release
- Leaderboards
- Streak tracking
- Weekly challenges
- Social features

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

### Implementation Status Summary
- ✅ **Phase 1A Complete**: Enhanced UI foundation with professional styling
- ✅ **Phase 1C Complete**: Exercise Database with visual body part selection & popular badge system
- ✅ **Popular Badge System**: Equipment-focused exercise highlighting with intelligent filtering
- 🆕 **Exercise Database**: 483 premium exercises with tier-based popularity scoring
- 🔄 **Components**: 45+ Flutter widgets including body visualization and popular badge components
- 📦 **Packages**: 14 external dependencies including SVG support for body models
- ⏳ **Next**: Phase 1D - Basic Workout Logging

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

## Notes
- ✅ Phase 1A (Foundation & Theme Setup) - **COMPLETED with modern UI enhancement**
- ✅ Phase 1C (Exercise Database & Visual Body Selection) - **COMPLETED with popular badge system**
- ✅ Popular Badge System - **COMPLETED with equipment-focused prioritization**
- ✅ Exercise Database - **COMPLETED with 483 premium exercises and intelligent filtering**
- Each phase should be fully functional before moving to next
- Test incrementally after each phase
- Prioritize core workout functionality before gamification features
- **Always check MCP documentation** before starting new features or phases
- **UI Standards**: App now follows modern fitness app design patterns with professional styling
- **Popular Badges**: Equipment-based exercises prioritized over bodyweight alternatives for better gym experience