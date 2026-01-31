# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
Lightweight is a simple, open-source iOS exercise tracking app built with SwiftUI and SwiftData. It's designed as an educational project demonstrating modern iOS development practices with no external dependencies.

## Development Commands

### Build & Run
```bash
# Open project in Xcode
open Lightweight.xcodeproj

# Build from command line
xcodebuild -project Lightweight.xcodeproj -scheme Lightweight -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests
xcodebuild test -project Lightweight.xcodeproj -scheme LightweightTests -destination 'platform=iOS Simulator,name=iPhone 15'

# Run a single test
xcodebuild test -project Lightweight.xcodeproj -scheme LightweightTests -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:LightweightTests/ExerciseTests/testExerciseCreation
```

### Code Quality
```bash
# Format Swift code (if swift-format is installed)
swift-format -i Lightweight/*.swift

# Lint with SwiftLint (if installed)
swiftlint
```

## Architecture

### Tech Stack
- **Platform**: iOS 17.0+ native app
- **UI Framework**: SwiftUI with declarative UI patterns
- **Data Persistence**: SwiftData (Apple's modern Core Data wrapper)
- **Cloud Sync**: CloudKit integration for iCloud syncing
- **Architecture Pattern**: MVVM with SwiftUI's built-in state management

### Core Components

**Data Models** (using SwiftData @Model):
- `Exercise`: Core entity representing an exercise with type, logs, and metadata
- `ExerciseLog`: Individual workout entries with flexible measurement system
- `ExerciseValue`: Polymorphic value storage supporting weight, reps, time, and custom metrics
- Relationships use cascade deletion for data integrity

**Views**:
- `ContentView`: Main navigation and exercise list with search/filter
- `ExerciseDetailView`: Exercise details and log management
- `AddEditView`: Unified form for creating/editing exercises
- `AddLogView`: Log entry with dynamic input based on exercise type

**Key Patterns**:
- Environment-based dependency injection for ModelContainer
- @Query for reactive data fetching with automatic UI updates
- First-run detection with sample data generation
- Type-safe exercise values with enum-based discrimination

### Project Structure
```
Lightweight/
├── Lightweight.swift          # App entry point with ModelContainer setup
├── ContentView.swift          # Main list view with search
├── ExerciseDetailView.swift   # Exercise details and logs
├── AddEditView.swift          # Create/edit exercise form
├── AddLogView.swift           # Add workout log form
├── Exercise.swift             # Core data models
└── Utilities.swift            # Helper extensions
```

## Important Conventions

- All data models use SwiftData's @Model macro
- CloudKit container: `iCloud.boisvert.lightweight`
- Weight units stored in UserDefaults key "weightUnit"
- Date formatting uses relative style for recent dates
- Sample data auto-generates on first launch if no exercises exist
- All CloudKit-synced properties must be optional or have default values

## Testing
The project includes comprehensive unit tests for data models in `LightweightTests/`. Tests focus on model creation, validation, relationships, and the flexible value system.