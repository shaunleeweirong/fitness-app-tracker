PRD: Weight Lifting Fitness Tracker App
App Overview and Objectives

This mobile app is designed for weight lifters of all experience levels to track their workouts and visualize muscle group progress through gamification. It eliminates the need to memorize workout routines during gym sessions by offering fast logging tools and visual feedback.

The objective is also to gamify the weight lifting process and to encourage progress and fun.

Target Audience

Weight lifters (beginners to advanced)

Users who want structured progress tracking

Fitness enthusiasts interested in gamified motivation

Core Features and Functionality

Phase 1 (MVP):

User Registration/Login: Email/password and Google OAuth

Workout Logging:

Exercise name

Sets, reps, and weight

Rest countdown timer between sets

Progress Tracking:

Volume = weight x reps x sets

Volume per body part

Radar chart visualization of body part progress

Gamification System:

Each exercise maps to a body part

Volume lifted accumulates XP

Body part levels increase with volume

Phase 2:

Leaderboards (e.g., most volume lifted)

Streaks (daily/weekly consistency)

Challenges (e.g., "Lift 5,000 lbs for back this week")

Android version release

Technical Stack Recommendations

Frontend: Flutter (dark mode UI, radar charts, cross-platform setup)

Backend: Firebase

Authentication (Firebase Auth)

Firestore (NoSQL data storage)

Cloud Functions (for XP calculation, if needed)

Conceptual Data Model
Users

userId (string, unique)

email (string, unique)

name (string)

authProvider (enum: email, google)

Exercises

exerciseId (string, unique)

name (string)

targetBodyPart (string)

Workout Log

logId (string, unique)

userId (string, FK)

exerciseId (string, FK)

weight (number)

sets (number)

reps (number)

timestamp (datetime)

Body Part Progress

userId (string, FK)

bodyPart (string)

volume (number)

xpLevel (number)

UI Design Principles

Dark mode by default (as shown in provided mockup)

Minimalist and distraction-free layout

Large tap targets for logging during workouts

Centered CTAs with step-by-step flows (onboarding, setup)

High-contrast text for readability in dimly lit gyms

Security Considerations

Firebase Authentication with OAuth and email/password

Secure access rules in Firestore per userId

JWT token management (handled by Firebase SDK)

User data encrypted in transit and at rest

Development Phases and Milestones
Phase 1 (MVP)

Design & Planning (2 weeks)

Finalize wireframes and UI theme

Define exercise list and body part mappings

Authentication Setup (1 week)

Implement Firebase Auth with email/password and Google login

Core Workout Logging (2 weeks)

Build exercise log entry (exercise name, sets, reps, weight)

Implement rest countdown timer

Progress Tracking & Radar Chart (2 weeks)

Volume calculation per body part

Radar chart visualization

Gamification Basics (1 week)

XP and level-up system per body part

Cloud Sync (1 week)

Firestore integration for workout logs and progress

Testing & QA (2 weeks)

Internal testing, bug fixes, usability improvements

Launch on iOS App Store

Estimated Timeline: ~11 weeks

Phase 2

Android Release (2 weeks)

Adapt app for Android using Flutter’s cross-platform support

Google Play Store launch

Leaderboards (2 weeks)

Rank users by total volume, body part XP, or streaks

Streak Tracking (1 week)

Daily/weekly consistency badges

Challenges & Rewards (2 weeks)

Weekly/monthly goals (e.g., lift X lbs in Y days)

Badge and reward system

Advanced Testing & Scaling (2 weeks)

Ensure backend can scale to larger user base

Estimated Timeline: ~9 weeks

Potential Challenges and Solutions

Radar chart rendering: Use Flutter packages like flutter_radar_chart

Accurate body part mapping: Require exercise selection from a controlled list

Real-time sync bugs: Use Firestore’s offline capabilities and conflict resolution

Future Expansion Possibilities

Apple Health / Google Fit integration

Workout plan generator

AI-based coaching recommendations

Wearable device support (e.g., Apple Watch, Fitbit)