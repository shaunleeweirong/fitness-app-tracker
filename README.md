# Weight Lifting Fitness Tracker

A Flutter mobile app designed for weight lifters to track workouts, visualize muscle group progress, and gamify the lifting experience with dark mode UI, visual progress indicators, and comprehensive exercise database.

## 🎯 App Overview

Transform your weight lifting experience with:
- **Exercise Database**: 1,500+ exercises with GIF animations and equipment-focused popular badges
- **Visual Progress Tracking**: Weekly volume charts and trend analysis
- **Interactive Body Part Selection**: Visual muscle group targeting for workout customization
- **Professional Dark UI**: Gym-optimized interface with orange accent theme
- **Progress Gamification**: XP system, streaks, and achievement badges

## 🚀 Current Status

- ✅ **Phase 1A**: Foundation & Professional Theme Setup
- ✅ **Phase 1C**: Exercise Database with ExerciseDB Integration (483 premium exercises)
- ✅ **Popular Badge System**: Equipment-focused exercise prioritization
- ✅ **Visual Body Part Selection**: Interactive muscle group filtering
- ✅ **Home Screen UX Enhancement**: Weekly progress charts and trend indicators
- 🔄 **Phase 1D**: Basic Workout Logging (Next)

## 🛠 Quick Setup

### Prerequisites
- Flutter SDK (3.35.1+)
- Xcode 16.4+ (for iOS development)
- iOS Simulator or physical device

### Installation
```bash
# Clone and navigate to project
git clone [repository-url]
cd first_fitness_test_app

# Install dependencies
flutter pub get

# Run on iOS simulator
flutter run -d ios

# Or run on specific device (iPhone 16)
flutter run -d 5DA4B52F-5EF0-4C65-B044-80691655D7CE
```

### Development Commands
```bash
# Hot reload during development
# Press 'r' in terminal for hot reload
# Press 'R' for hot restart

# Build for release
flutter build ios

# Check Flutter setup
flutter doctor
```

## 📱 Key Features

### Exercise Database
- **1,500+ Exercises**: Complete ExerciseDB integration with GIF animations
- **Popular Badge System**: Equipment-focused exercise highlighting (barbell, dumbbell, machine priority)
- **Visual Body Selection**: Interactive front/back body silhouettes for muscle targeting
- **Smart Filtering**: Body part, equipment, and popularity-based exercise discovery

### Progress Visualization
- **Weekly Volume Charts**: FL Chart integration with trend analysis
- **Stats Cards**: Workout count and total time with percentage changes
- **Achievement System**: Streaks, XP tracking, and milestone progress
- **Body Part Balance**: Radar chart visualization (planned)

### Professional UI/UX
- **Dark Theme**: Gym-optimized interface (#0A0A0A backgrounds)
- **Orange Accent**: Consistent #FFB74D color scheme for improvements
- **Material Design 3**: Professional gradients, shadows, and typography
- **Large Touch Targets**: Designed for workout environments

## 🏗 Technical Stack

- **Frontend**: Flutter with Material Design 3
- **Charts**: FL Chart for progress visualization
- **State Management**: StatefulWidget (Provider/Riverpod planned)
- **Data**: Local SQLite with ExerciseDB API integration
- **Authentication**: Firebase Auth (Phase 1B)
- **Cloud Sync**: Firestore (Phase 1F)

## 📋 Development Phases

**Phase 1 (MVP - Current Focus):**
- [x] Foundation & Theme Setup
- [x] Exercise Database Integration
- [x] Home Screen Progress Enhancement
- [ ] Basic Workout Logging
- [ ] Rest Timer
- [ ] Local Data Storage
- [ ] Progress Tracking

**Phase 2 (Future):**
- [ ] Firebase Authentication & Cloud Sync
- [ ] Advanced Gamification
- [ ] Android Release
- [ ] Social Features

## 🔧 iOS Simulator Setup

For detailed iOS simulator setup and troubleshooting, see [ios-simulator-setup.md](ios-simulator-setup.md).

**Quick start:**
```bash
# Boot iPhone 16 simulator
xcrun simctl boot 5DA4B52F-5EF0-4C65-B044-80691655D7CE
open -a Simulator
flutter run -d 5DA4B52F-5EF0-4C65-B044-80691655D7CE
```

## 📊 API Integration

The app uses a free ExerciseDB deployment for exercise data. For deployment instructions, see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md).

## 📖 Documentation

- **[CLAUDE.md](CLAUDE.md)** - Comprehensive development guide and project roadmap
- **[research.md](research.md)** - UX research findings and design recommendations
- **[ios-simulator-setup.md](ios-simulator-setup.md)** - iOS development setup and troubleshooting
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - ExerciseDB API deployment guide

## 🎨 Design Principles

- **Dark mode by default** - Gym-friendly interface
- **Large tap targets** - Easy interaction during workouts
- **High-contrast text** - Readable in dim lighting
- **Minimalist layout** - Reduced distractions
- **Visual progress focus** - Immediate feedback on achievements

## 🤝 Contributing

For development guidelines, phase planning, and implementation details, see [CLAUDE.md](CLAUDE.md).

---

**Target Platform**: iOS first (MVP), Android in Phase 2  
**Current Build**: Phase 1C Complete - Exercise Database with Visual Progress  
**Next Milestone**: Phase 1D - Basic Workout Logging