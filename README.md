# MicroGoals

A focused goal-tracking Flutter app that helps users stay focused on meaningful objectives rather than endless to-do lists. Track progress toward specific outcomes with measurable endpoints and visible progress visualization.

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-02569B?logo=flutter)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## 🎯 Features

### Free Version
- **3 Active Goals** - Stay focused on what matters most
- **Progress Tracking** - Visualize your progress with circular progress rings
- **Manual Progress Updates** - Increment/decrement or set specific values
- **Due Dates** - Set optional deadlines for your goals
- **Completion Celebrations** - Animated celebrations when you achieve your goals
- **History View** - See all your completed goals
- **Dark Mode** - Light and dark theme support

### Premium Features (€2.99/year or €4.99 lifetime)
- **30 Active Goals** - Track up to 30 goals simultaneously
- **Progress History Charts** - Visualize your progress over time with interactive charts
- **Milestone Tracking** - Automatic achievements at 25%, 50%, and 75% completion
- **Custom Colors** - Choose from 12 colors to personalize your goals
- **Custom Icons** - Select from 16 icons to represent your goals
- **Export to CSV** - Export your goals and progress history for analysis
- **Export to JSON** - Create full backups of all your data
- **Restore from Backup** - Import your data from JSON backups

## 📱 Screenshots

Screenshots available in `assets/screenshots/` directory.

## 🛠️ Tech Stack

- **Framework**: Flutter (Dart SDK ^3.8.1)
- **State Management**: Riverpod (`flutter_riverpod: ^2.4.9`)
- **Database**: SQLite (`sqflite: ^2.3.0`) - Local-only storage
- **Navigation**: go_router (`go_router: ^12.1.3`)
- **Charts**: fl_chart (`fl_chart: ^0.66.0`) for progress history
- **Fonts**: Google Fonts Inter (`google_fonts: ^6.1.0`)
- **In-App Purchases**: `in_app_purchase: ^3.1.11`
- **File Operations**: `file_picker: ^8.1.4`, `share_plus: ^10.1.2`

## 🏗️ Architecture

The app follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── core/              # Core utilities and constants
│   ├── constants/    # App constants (limits, product IDs, etc.)
│   ├── errors/       # Custom exception classes
│   ├── routes/       # Navigation configuration
│   ├── services/     # Export/backup services
│   └── utils/        # Logger, date utilities
├── data/             # Data layer
│   ├── local/        # Database implementation
│   ├── models/       # Data models (Goal, GoalProgress)
│   └── repositories/ # Data access layer
└── presentation/     # UI layer
    ├── providers/    # Riverpod providers
    ├── screens/      # App screens
    └── widgets/      # Reusable widgets
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK ^3.8.1
- Dart SDK ^3.8.1
- Android Studio / Xcode (for mobile development)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/robertf670/MicroGoals.git
   cd MicroGoals
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Building for Release

**Android:**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## 📦 Package Information

- **Package Name**: `ie.qqrxi.microgoals`
- **Version**: 1.0.0+1
- **Minimum SDK**: Android 21, iOS 12.0

## 🎨 Design System

- **Theme**: Material Design 3
- **Color Seed**: Deep Purple (`Colors.deepPurple`)
- **Typography**: Google Fonts Inter
- **Icons**: Material Icons

## 🔒 Privacy

MicroGoals respects your privacy. All data is stored locally on your device - we don't collect, store, or transmit any personal information.

- **Privacy Policy**: [View Privacy Policy](PRIVACY_POLICY.md)
- **Online Version**: https://www.ixrqq.pro/microgoals/privacy-policy

## 📝 License

This project is licensed under the MIT License.

## 👤 Author

**Rob**

- Email: rob@ixrqq.pro
- Website: https://www.ixrqq.pro

## 🙏 Acknowledgments

- Built following the same architecture patterns as MicroHabits, MicroJournal, and MicroNotes
- Uses Clean Architecture principles for maintainability
- Material Design 3 for modern UI/UX

## 📄 Additional Documentation

- [Privacy Policy](PRIVACY_POLICY.md)
- [Prompt Template](MICROGOALS_PROMPT_TEMPLATE.md) - Comprehensive development guide
- [Quick Reference](MICROGOALS_QUICK_REFERENCE.md) - Code patterns and checklist

---

**Note**: This app is part of the Micro ecosystem of focused productivity apps. Each app follows the same architecture, design system, and code patterns for consistency and maintainability.
