# MicroGoals AI Prompt Template

Use this comprehensive prompt template to create MicroGoals following the exact same architecture, design system, and code patterns as MicroHabits, MicroJournal, and MicroNotes.

---

## Project Overview

Create a Flutter app called **MicroGoals** - a focused goal-tracking app that helps users stay focused on meaningful objectives rather than endless to-do lists. This app should follow the exact same architecture, design patterns, and code style as the other Micro ecosystem apps.

### App Concept

MicroGoals helps users stay focused on meaningful objectives rather than endless to-do lists. Where MicroHabits focuses on daily repetition, MicroGoals tracks progress toward specific outcomes — goals with measurable endpoints and visible progress.

### Core Features

- Limit of **3 active goals** (to maintain focus)
- Each goal includes:
  - Title and short description
  - Numeric target (e.g., "Read 300 pages")
  - Progress input (manual increment or percentage)
  - Optional due date
- Progress visualization (ring or bar)
- Completion celebration (animation + badge)
- Basic history view

### Premium Features (€2.99/year or €4.99 lifetime)

- Up to **5 active goals**
- Custom icons and colors
- Progress history chart
- Export to CSV/JSON
- "Milestone" achievements
- Optional backup/restore
- Ad-free experience
- Priority support

---

## Technical Requirements

### Tech Stack (MUST MATCH Other Micro Apps)

- **Framework**: Flutter (Dart) with SDK ^3.8.1
- **Package Name**: `ie.qqrxi.microgoals` (Android namespace and applicationId)
- **State Management**: Riverpod (`flutter_riverpod: ^2.4.9`)
- **Database**: sqflite (`sqflite: ^2.3.0`) with local-only storage
- **Architecture**: Clean Architecture (domain/data/presentation layers)
- **Navigation**: go_router (`go_router: ^12.1.3`)
- **Fonts**: Google Fonts Inter (`google_fonts: ^6.1.0`)
- **Charts**: fl_chart (`fl_chart: ^0.66.0`) for progress history
- **Animations**: Lottie (`lottie: ^3.1.0`) or Flutter built-in transitions
- **Local Storage**: shared_preferences (`shared_preferences: ^2.2.2`)
- **In-App Purchases**: in_app_purchase (`in_app_purchase: ^3.1.11`)
- **Utilities**: intl (`intl: ^0.19.0`), path_provider (`path_provider: ^2.1.1`)

### Project Structure (EXACT MATCH)

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart          # All magic numbers/strings
│   ├── errors/
│   │   └── exceptions.dart             # Custom exceptions
│   ├── routes/
│   │   └── app_router.dart             # GoRouter configuration
│   └── utils/
│       ├── logger.dart                  # Logger utility (NO print())
│       └── date_utils.dart              # Date helper functions
├── data/
│   ├── local/
│   │   └── database/
│   │       └── app_database.dart       # sqflite database setup
│   ├── models/
│   │   ├── goal.dart                   # Goal model
│   │   └── goal_progress.dart          # Progress history model
│   └── repositories/
│       └── goal_repository.dart         # Repository pattern
├── domain/
│   ├── entities/                       # Domain entities (if needed)
│   └── usecases/
│       ├── create_goal_usecase.dart
│       ├── get_goals_usecase.dart
│       ├── update_progress_usecase.dart
│       ├── complete_goal_usecase.dart
│       └── get_progress_history_usecase.dart
├── presentation/
│   ├── providers/
│   │   ├── goal_provider.dart          # Riverpod providers
│   │   ├── premium_provider.dart        # Premium status provider
│   │   └── theme_provider.dart         # Theme mode provider
│   ├── screens/
│   │   ├── home/
│   │   │   └── home_screen.dart        # Goals list screen
│   │   ├── goal/
│   │   │   ├── add_goal/
│   │   │   │   └── add_goal_screen.dart
│   │   │   ├── edit_goal/
│   │   │   │   └── edit_goal_screen.dart
│   │   │   └── detail/
│   │   │       └── goal_detail_screen.dart
│   │   ├── history/
│   │   │   └── history_screen.dart     # Progress history (premium)
│   │   ├── settings/
│   │   │   └── settings_screen.dart
│   │   └── premium/
│   │       └── premium_screen.dart
│   └── widgets/
│       ├── main_scaffold.dart           # Bottom navigation scaffold
│       ├── goal_card.dart               # Goal list card with progress
│       ├── progress_ring.dart           # Circular progress indicator
│       ├── progress_bar.dart            # Linear progress bar
│       ├── completion_celebration.dart   # Completion animation
│       └── (other reusable widgets)
└── services/
    ├── purchase_service.dart             # In-app purchase handling
    └── export_service.dart              # CSV/JSON export (premium)
```

---

## Design System (EXACT MATCH)

### Theme Configuration

**Material Design 3** with the following exact settings:

```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,  // SAME as other Micro apps
    brightness: Brightness.light,  // or Brightness.dark
  ),
  textTheme: GoogleFonts.interTextTheme(),  // Google Fonts Inter
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,  // Flat design
  ),
)
```

### Color Palette (SAME as Other Micro Apps)

Use the exact same color options:
- Purple: `#9C27B0` (default)
- Blue: `#2196F3`
- Green: `#4CAF50`
- Orange: `#FF9800`
- Red: `#F44336`
- Pink: `#E91E63`
- Teal: `#009688`
- Indigo: `#3F51B5`

**Premium**: Custom icons and colors per goal

### UI Style Guidelines

- **Minimalist**: Clean, uncluttered interface
- **Card-based**: Use Material Cards with rounded corners (12px radius)
- **Progress-focused**: Visual progress indicators (rings/bars) prominent
- **Spacing**: Consistent padding (16px standard, 8px/12px/24px/32px variants)
- **Icons**: Material Icons, 24px standard size (custom icons premium)
- **Elevation**: Flat design (elevation: 0) with subtle shadows where needed
- **Animations**: Smooth transitions, celebration animations on completion

---

## Architecture Patterns (MUST FOLLOW)

### Clean Architecture Layers

1. **Domain Layer** (`lib/domain/`)
   - Entities: Pure Dart classes representing business objects
   - Use Cases: Business logic operations
   - NO dependencies on Flutter or data layer

2. **Data Layer** (`lib/data/`)
   - Models: Data transfer objects with `toMap()` and `fromMap()` methods
   - Repositories: Implement repository pattern, handle data sources
   - Local Database: sqflite with proper error handling
   - All database operations MUST have try-catch with Logger.error()

3. **Presentation Layer** (`lib/presentation/`)
   - Screens: Full-page widgets
   - Widgets: Reusable UI components
   - Providers: Riverpod providers for state management
   - NO business logic in UI layer

### Code Patterns

1. **Error Handling**
   - Use custom exceptions: `AppException`, `AppDatabaseException`
   - All database operations wrapped in try-catch
   - Log errors with `Logger.error(message, error, stackTrace)`
   - NEVER use `print()` - use `Logger.info()`, `Logger.error()`, etc.

2. **Constants**
   - ALL magic numbers/strings in `AppConstants` class
   - Example: `AppConstants.freeGoalLimit = 3`, `AppConstants.premiumProductId = 'premium_lifetime'`

3. **State Management**
   - Use Riverpod `AsyncValue` for async data
   - Use `Provider` for simple state
   - Use `StateNotifierProvider` for complex state
   - Handle loading/error states in UI with `.when()` method

4. **Database**
   - Singleton pattern: `AppDatabase.instance`
   - Version management: `AppConstants.databaseVersion`
   - Proper indexes for performance
   - Migration support in `_onUpgrade()` method

5. **Models**
   - Include `toMap()`, `fromMap()`, and `copyWith()` methods
   - Use nullable types appropriately
   - Store dates as milliseconds since epoch for database

---

## Database Schema

### Goals Table

```sql
CREATE TABLE goals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT,
  target_value REAL NOT NULL,  -- Numeric target (e.g., 300 pages)
  current_value REAL NOT NULL DEFAULT 0,  -- Current progress
  unit TEXT,  -- Optional unit (e.g., "pages", "km", "%")
  icon_name TEXT,  -- Custom icon (premium)
  color_hex TEXT,  -- Custom color (premium)
  due_date INTEGER,  -- Optional due date (milliseconds since epoch)
  is_completed INTEGER NOT NULL DEFAULT 0,  -- 0 or 1
  completed_at INTEGER,  -- When completed (milliseconds since epoch)
  created_at INTEGER NOT NULL,  -- milliseconds since epoch
  updated_at INTEGER NOT NULL
)

CREATE INDEX idx_goals_is_completed ON goals(is_completed)
CREATE INDEX idx_goals_due_date ON goals(due_date)
CREATE INDEX idx_goals_created_at ON goals(created_at)
```

### Goal Progress History Table (Premium)

```sql
CREATE TABLE goal_progress_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  goal_id INTEGER NOT NULL,
  progress_value REAL NOT NULL,  -- Progress at this point
  progress_percentage REAL NOT NULL,  -- Percentage (0-100)
  recorded_at INTEGER NOT NULL,  -- milliseconds since epoch
  FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE
)

CREATE INDEX idx_goal_progress_goal_id ON goal_progress_history(goal_id)
CREATE INDEX idx_goal_progress_recorded_at ON goal_progress_history(recorded_at)
```

### Milestones Table (Premium)

```sql
CREATE TABLE milestones (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  goal_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  target_percentage REAL NOT NULL,  -- Milestone at X% (e.g., 25%, 50%, 75%)
  achieved_at INTEGER,  -- When achieved (milliseconds since epoch)
  FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE
)

CREATE INDEX idx_milestones_goal_id ON milestones(goal_id)
```

### Premium Status (SharedPreferences)
- Key: `is_premium` (boolean)
- Key: `purchase_token` (string)

---

## Feature Implementation Details

### Goal Limits

- **Free**: 3 active goals maximum (enforced in `AddGoalScreen`)
- **Premium**: 5 active goals maximum
- Check limit in UI before allowing goal creation
- Show upgrade prompt when limit reached
- Display goal count badge (e.g., "2/3 goals")
- Completed goals don't count toward limit

### Progress Input

- **Manual Increment**: Button to add/subtract progress (e.g., +10, -5)
- **Percentage Input**: Direct percentage entry (0-100%)
- **Value Input**: Direct numeric value entry
- Update `current_value` and calculate percentage automatically
- Store progress history on each update (premium)

### Progress Visualization

- **Circular Ring**: Show percentage completion in circular progress ring
- **Linear Bar**: Show percentage completion in horizontal progress bar
- Use goal's custom color (or default purple)
- Animate progress updates smoothly
- Show current/target values (e.g., "150/300 pages")

### Completion Celebration

- **Animation**: Use Lottie animation or Flutter animations
- **Badge**: Show completion badge/icon
- **Confetti**: Optional confetti effect
- Trigger when `current_value >= target_value`
- Mark goal as completed, store `completed_at` timestamp
- Move to completed goals section

### Progress History Chart (Premium)

- Use `fl_chart` package (same as MicroHabits stats)
- Line chart showing progress over time
- X-axis: Date, Y-axis: Progress percentage
- Show milestones on chart
- Display in history screen (premium only)

### Milestone Achievements (Premium)

- Define milestones at 25%, 50%, 75% of goal
- Check milestones when progress updates
- Store achieved milestones in database
- Show milestone badges/notifications
- Display in goal detail screen

### Export Feature (Premium)

- **CSV Export**: Goal data with progress history
  - Columns: Date, Goal, Progress, Percentage
- **JSON Export**: Full goal data as JSON array
  - Include goals, progress history, milestones
- Use `path_provider` to get documents directory
- Show share dialog after export

### Backup/Restore (Premium)

- Export all data to JSON file
- Import JSON file to restore data
- Validate data before import
- Show confirmation dialog before restore (warns about overwriting)

### Custom Icons and Colors (Premium)

- Allow user to set custom icon per goal
- Allow user to set custom color per goal
- Store `icon_name` and `color_hex` in goals table
- Show icon picker in goal edit screen (premium only)
- Apply color to progress indicators

---

## Premium Features Implementation

### In-App Purchase

- Product IDs:
  - Annual: `premium_annual` (€2.99)
  - Lifetime: `premium_lifetime` (€4.99)
- Use same `PurchaseService` pattern as other Micro apps
- Store premium status in SharedPreferences
- Restore purchases on app start
- Show premium screen with upgrade options

### Premium UI Indicators

- Show premium badge/icon where premium features are locked
- Use same premium screen design as other Micro apps
- Show upgrade prompts when free users hit limits
- Disable premium-only features for free users

---

## Navigation Structure

### Routes (GoRouter)

```
/ (home) - Goals list screen
/add-goal - Create new goal
/edit-goal/:id - Edit existing goal
/goal/:id - View goal detail
/history - Progress history chart (premium)
/settings - Settings screen
/premium - Premium upgrade screen
```

### Bottom Navigation (MainScaffold)

- Home (goals list)
- History (premium, or show upgrade prompt)
- Settings

---

## Testing Requirements

### Test Structure

```
test/
├── helpers/
│   └── test_helpers.dart          # Database initialization helpers
├── unit/
│   ├── repositories/
│   ├── usecases/
│   └── models/
└── widget/
    └── (widget tests)
```

### Testing Patterns

- Use `sqflite_common_ffi` for database tests
- Mock repositories for use case tests
- Test all business logic in use cases
- Test error handling paths
- Test progress calculation logic
- Test milestone achievement logic
- Maintain >75% test coverage

---

## Code Quality Rules

1. **Zero Linting Warnings**: Run `flutter analyze` - must have 0 issues
2. **No print()**: Use Logger instead
3. **Error Handling**: All database operations wrapped in try-catch
4. **Constants**: No magic numbers/strings
5. **Clean Code**: Follow Clean Architecture principles
6. **Documentation**: Document complex logic with comments
7. **Naming**: Use descriptive names, follow Dart conventions

---

## Version Management

- Start with version: `1.0.0+1`
- Follow same versioning rules as other Micro apps
- Update `pubspec.yaml` version
- Create `CHANGELOG.md` with release notes
- Use git tags: `v1.0.0`

---

## Android Configuration

### build.gradle.kts

```kotlin
namespace = "ie.qqrxi.microgoals"
applicationId = "ie.qqrxi.microgoals"
minSdk = 21  // Same as other Micro apps
```

### AndroidManifest.xml

- Same permissions as other Micro apps (internet for IAP, if needed)
- No notification permissions needed (unless adding reminders later)

---

## Key Differences from Other Micro Apps

While following the same architecture, these are the domain-specific differences:

1. **Data Model**: Goals instead of habits/journal entries/notes
   - Numeric target and current progress
   - Progress percentage calculation
   - Optional due date
   - Completion status

2. **UI Focus**: Progress visualization and tracking
   - Circular/linear progress indicators
   - Progress input controls
   - Completion celebrations
   - History charts

3. **Limits**: 3 goals (free) vs 3 habits (MicroHabits) vs 1 entry/day (MicroJournal) vs 10 notes (MicroNotes)
   - Different limit checking logic
   - Completed goals don't count toward limit

4. **Progress Tracking**: Numeric progress vs completion tracking
   - Progress history storage (premium)
   - Milestone achievements (premium)
   - Progress charts (premium)

5. **Animations**: Completion celebrations
   - Lottie animations or Flutter animations
   - Smooth progress updates
   - Achievement notifications

---

## Prompt Usage Instructions

When using this template with an AI agent:

1. **Copy this entire document** as the initial prompt
2. **Add specific requirements** if needed (e.g., "Use Lottie for completion animation")
3. **Reference other Micro apps codebase** if available: "Follow the exact same patterns as MicroHabits, MicroJournal, and MicroNotes apps"
4. **Iterate**: Start with core features, then add premium features
5. **Test**: Ensure `flutter analyze` passes and tests run successfully

---

## Example Prompt Start

```
I want to create a Flutter app called MicroGoals following the exact same architecture, design system, and code patterns as MicroHabits, MicroJournal, and MicroNotes. 

[Paste the entire template above]

Please start by creating the project structure, database schema, and core models. Then implement the home screen with goals list and add goal functionality.
```

---

## Additional Notes

- **Privacy**: All data stored locally (no cloud sync)
- **Offline-first**: App works completely offline
- **Material Design 3**: Follow latest Material Design guidelines
- **Accessibility**: Ensure proper semantic labels and contrast ratios
- **Performance**: Optimize database queries with indexes
- **Error Messages**: User-friendly error messages, log technical details
- **Animations**: Use smooth, performant animations (Lottie or Flutter)
- **Progress Calculation**: Always calculate percentage: `(current_value / target_value) * 100`

---

## Dependencies to Add

```yaml
dependencies:
  fl_chart: ^0.66.0  # For progress history charts
  lottie: ^3.1.0     # For completion animations (optional, can use Flutter animations)
  # All other dependencies same as other Micro apps
```

---

This template ensures MicroGoals will have:
✅ Same architecture as other Micro apps
✅ Same design language and colors
✅ Same code quality standards
✅ Same premium feature patterns
✅ Consistent user experience across Micro ecosystem apps
✅ Unique progress tracking and visualization features

