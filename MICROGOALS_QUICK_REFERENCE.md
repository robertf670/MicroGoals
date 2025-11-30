# MicroGoals Quick Reference Guide

Quick reference for creating MicroGoals with the same patterns as MicroHabits, MicroJournal, and MicroNotes.

## Essential Code Patterns to Replicate

### 1. AppConstants Pattern (lib/core/constants/app_constants.dart)

```dart
class AppConstants {
  AppConstants._(); // Private constructor

  // Goal limits
  static const int freeGoalLimit = 3;  // 3 active goals for free
  static const int premiumGoalLimit = 5;  // 5 active goals for premium

  // Product IDs
  static const String premiumAnnualProductId = 'premium_annual';
  static const String premiumLifetimeProductId = 'premium_lifetime';

  // Database
  static const String databaseName = 'microgoals.db';
  static const int databaseVersion = 1;

  // SharedPreferences keys
  static const String premiumStatusKey = 'is_premium';
  static const String purchaseTokenKey = 'purchase_token';

  // Default values
  static const String defaultIcon = 'flag';
  static const String defaultColor = '#9C27B0';  // Purple
  static const String defaultUnit = '';  // No unit by default

  // Milestone percentages (premium)
  static const List<double> milestonePercentages = [25.0, 50.0, 75.0];

  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 10);
  static const Duration purchaseProcessingDelay = Duration(seconds: 1);
}
```

---

### 2. Goal Model Pattern (lib/data/models/goal.dart)

```dart
class Goal {
  final int? id;
  final String title;
  final String? description;
  final double targetValue;  // Numeric target (e.g., 300 pages)
  final double currentValue;  // Current progress
  final String? unit;  // Optional unit (e.g., "pages", "km", "%")
  final String? iconName;  // Custom icon (premium)
  final String? colorHex;  // Custom color (premium)
  final DateTime? dueDate;  // Optional due date
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Goal({
    this.id,
    required this.title,
    this.description,
    required this.targetValue,
    this.currentValue = 0.0,
    this.unit,
    this.iconName,
    this.colorHex,
    this.dueDate,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate progress percentage
  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    final percentage = (currentValue / targetValue) * 100;
    return percentage.clamp(0.0, 100.0);
  }

  // Check if goal is completed
  bool get isGoalCompleted => currentValue >= targetValue;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'target_value': targetValue,
      'current_value': currentValue,
      'unit': unit,
      'icon_name': iconName,
      'color_hex': colorHex,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      targetValue: map['target_value']?.toDouble() ?? 0.0,
      currentValue: map['current_value']?.toDouble() ?? 0.0,
      unit: map['unit'],
      iconName: map['icon_name'],
      colorHex: map['color_hex'],
      dueDate: map['due_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['due_date'])
          : null,
      isCompleted: map['is_completed'] == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  Goal copyWith({
    int? id,
    String? title,
    String? description,
    double? targetValue,
    double? currentValue,
    String? unit,
    String? iconName,
    String? colorHex,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

---

### 3. Goal Progress History Model (lib/data/models/goal_progress.dart)

```dart
class GoalProgress {
  final int? id;
  final int goalId;
  final double progressValue;
  final double progressPercentage;
  final DateTime recordedAt;

  GoalProgress({
    this.id,
    required this.goalId,
    required this.progressValue,
    required this.progressPercentage,
    required this.recordedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'progress_value': progressValue,
      'progress_percentage': progressPercentage,
      'recorded_at': recordedAt.millisecondsSinceEpoch,
    };
  }

  factory GoalProgress.fromMap(Map<String, dynamic> map) {
    return GoalProgress(
      id: map['id'],
      goalId: map['goal_id'],
      progressValue: map['progress_value']?.toDouble() ?? 0.0,
      progressPercentage: map['progress_percentage']?.toDouble() ?? 0.0,
      recordedAt: DateTime.fromMillisecondsSinceEpoch(map['recorded_at']),
    );
  }
}
```

---

### 4. Database Schema Pattern

```dart
Future<void> _createDB(Database db, int version) async {
  try {
    // Goals table
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        target_value REAL NOT NULL,
        current_value REAL NOT NULL DEFAULT 0,
        unit TEXT,
        icon_name TEXT,
        color_hex TEXT,
        due_date INTEGER,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Goal progress history table (premium)
    await db.execute('''
      CREATE TABLE goal_progress_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL,
        progress_value REAL NOT NULL,
        progress_percentage REAL NOT NULL,
        recorded_at INTEGER NOT NULL,
        FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE
      )
    ''');

    // Milestones table (premium)
    await db.execute('''
      CREATE TABLE milestones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        target_percentage REAL NOT NULL,
        achieved_at INTEGER,
        FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE
      )
    ''');

    // Indexes
    await db.execute('CREATE INDEX idx_goals_is_completed ON goals(is_completed)');
    await db.execute('CREATE INDEX idx_goals_due_date ON goals(due_date)');
    await db.execute('CREATE INDEX idx_goal_progress_goal_id ON goal_progress_history(goal_id)');
    await db.execute('CREATE INDEX idx_milestones_goal_id ON milestones(goal_id)');
  } catch (e, stackTrace) {
    Logger.error('Failed to create database schema', e, stackTrace);
    throw AppDatabaseException('Failed to create database: ${e.toString()}', e);
  }
}
```

---

### 5. Repository Pattern (lib/data/repositories/goal_repository.dart)

```dart
class GoalRepository {
  final AppDatabase _database;

  GoalRepository(this._database);

  Future<List<Goal>> getGoals({bool? activeOnly}) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps;

      if (activeOnly == true) {
        maps = await db.query(
          'goals',
          where: 'is_completed = ?',
          whereArgs: [0],
          orderBy: 'created_at DESC',
        );
      } else {
        maps = await db.query(
          'goals',
          orderBy: 'is_completed ASC, created_at DESC',
        );
      }

      return maps.map((map) => Goal.fromMap(map)).toList();
    } catch (e, stackTrace) {
      Logger.error('Failed to get goals', e, stackTrace);
      throw RepositoryException('Failed to load goals: ${e.toString()}', e);
    }
  }

  Future<int> createGoal(Goal goal) async {
    try {
      final db = await _database.database;
      return await db.insert('goals', goal.toMap());
    } catch (e, stackTrace) {
      Logger.error('Failed to create goal', e, stackTrace);
      throw RepositoryException('Failed to save goal: ${e.toString()}', e);
    }
  }

  Future<int> updateProgress(int goalId, double newValue, bool isPremium) async {
    try {
      final db = await _database.database;
      
      // Get current goal
      final goalMaps = await db.query(
        'goals',
        where: 'id = ?',
        whereArgs: [goalId],
      );
      
      if (goalMaps.isEmpty) {
        throw RepositoryException('Goal not found');
      }
      
      final goal = Goal.fromMap(goalMaps.first);
      final newGoal = goal.copyWith(
        currentValue: newValue,
        updatedAt: DateTime.now(),
        isCompleted: newValue >= goal.targetValue,
        completedAt: newValue >= goal.targetValue ? DateTime.now() : goal.completedAt,
      );
      
      // Update goal
      await db.update(
        'goals',
        newGoal.toMap(),
        where: 'id = ?',
        whereArgs: [goalId],
      );
      
      // Store progress history (premium only)
      if (isPremium) {
        await db.insert('goal_progress_history', {
          'goal_id': goalId,
          'progress_value': newValue,
          'progress_percentage': newGoal.progressPercentage,
          'recorded_at': DateTime.now().millisecondsSinceEpoch,
        });
        
        // Check milestones
        await _checkMilestones(db, goalId, newGoal.progressPercentage);
      }
      
      return goalId;
    } catch (e, stackTrace) {
      Logger.error('Failed to update progress', e, stackTrace);
      throw RepositoryException('Failed to update progress: ${e.toString()}', e);
    }
  }

  Future<void> _checkMilestones(Database db, int goalId, double percentage) async {
    final milestones = await db.query(
      'milestones',
      where: 'goal_id = ? AND achieved_at IS NULL',
      whereArgs: [goalId],
    );
    
    for (final milestone in milestones) {
      final targetPercentage = milestone['target_percentage'] as double;
      if (percentage >= targetPercentage) {
        await db.update(
          'milestones',
          {'achieved_at': DateTime.now().millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [milestone['id']],
        );
      }
    }
  }

  Future<List<GoalProgress>> getProgressHistory(int goalId) async {
    try {
      final db = await _database.database;
      final maps = await db.query(
        'goal_progress_history',
        where: 'goal_id = ?',
        whereArgs: [goalId],
        orderBy: 'recorded_at ASC',
      );
      return maps.map((map) => GoalProgress.fromMap(map)).toList();
    } catch (e, stackTrace) {
      Logger.error('Failed to get progress history', e, stackTrace);
      throw RepositoryException('Failed to load progress history: ${e.toString()}', e);
    }
  }

  // All methods wrapped in try-catch with Logger.error()
}
```

---

### 6. Provider Pattern (lib/presentation/providers/goal_provider.dart)

```dart
// Repository provider
final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(AppDatabase.instance);
});

// Goals provider (async)
final goalsProvider = FutureProvider<List<Goal>>((ref) async {
  final repository = ref.watch(goalRepositoryProvider);
  return await repository.getGoals(activeOnly: true);
});

// All goals provider (including completed)
final allGoalsProvider = FutureProvider<List<Goal>>((ref) async {
  final repository = ref.watch(goalRepositoryProvider);
  return await repository.getGoals();
});

// Active goal count provider
final activeGoalCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(goalRepositoryProvider);
  final goals = await repository.getGoals(activeOnly: true);
  return goals.length;
});

// Max goals provider (3 free, 5 premium)
final maxGoalsProvider = FutureProvider<int>((ref) async {
  final isPremium = await ref.watch(premiumStatusProvider.future);
  return isPremium ? AppConstants.premiumGoalLimit : AppConstants.freeGoalLimit;
});

// Progress history provider (premium)
final progressHistoryProvider = FutureProvider.family<List<GoalProgress>, int>((ref, goalId) async {
  final repository = ref.watch(goalRepositoryProvider);
  final isPremium = await ref.watch(premiumStatusProvider.future);
  if (!isPremium) return [];
  return await repository.getProgressHistory(goalId);
});
```

---

### 7. Progress Ring Widget (lib/presentation/widgets/progress_ring.dart)

```dart
import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  final double progress;  // 0.0 to 1.0
  final Color color;
  final double size;
  final double strokeWidth;
  final String? centerText;

  const ProgressRing({
    super.key,
    required this.progress,
    required this.color,
    this.size = 100.0,
    this.strokeWidth = 8.0,
    this.centerText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(color.withValues(alpha: 0.2)),
            ),
          ),
          // Progress circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          // Center text
          if (centerText != null)
            Text(
              centerText!,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
        ],
      ),
    );
  }
}
```

---

### 8. Goal Card Widget Pattern (lib/presentation/widgets/goal_card.dart)

```dart
class GoalCard extends ConsumerWidget {
  final Goal goal;

  const GoalCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = goal.colorHex != null
        ? _getColorFromHex(goal.colorHex!)
        : Theme.of(context).colorScheme.primary;
    
    final progress = goal.progressPercentage / 100.0;
    final progressText = '${goal.currentValue.toStringAsFixed(0)}/${goal.targetValue.toStringAsFixed(0)}';
    if (goal.unit != null && goal.unit!.isNotEmpty) {
      progressText += ' ${goal.unit}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => context.pushNamed('goal-detail', pathParameters: {'id': goal.id.toString()}),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (goal.iconName != null)
                    Icon(
                      _getIconFromName(goal.iconName!),
                      color: color,
                      size: 24,
                    ),
                  if (goal.iconName != null) const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      goal.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (goal.isCompleted)
                    Icon(Icons.check_circle, color: Colors.green, size: 24),
                ],
              ),
              if (goal.description != null && goal.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  goal.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              // Progress ring
              Row(
                children: [
                  ProgressRing(
                    progress: progress,
                    color: color,
                    size: 80,
                    centerText: '${goal.progressPercentage.toStringAsFixed(0)}%',
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          progressText,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (goal.dueDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Due: ${_formatDate(goal.dueDate!)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### 9. Completion Celebration Widget (lib/presentation/widgets/completion_celebration.dart)

```dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';  // Or use Flutter animations

class CompletionCelebration extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const CompletionCelebration({
    super.key,
    required this.onAnimationComplete,
  });

  @override
  State<CompletionCelebration> createState() => _CompletionCelebrationState();
}

class _CompletionCelebrationState extends State<CompletionCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onAnimationComplete();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(24),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 64,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Alternative: Use Lottie animation
class LottieCelebration extends StatelessWidget {
  final VoidCallback onAnimationComplete;

  const LottieCelebration({
    super.key,
    required this.onAnimationComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/celebration.json',  // Add Lottie animation file
      repeat: false,
      onLoaded: (composition) {
        Future.delayed(composition.duration, () {
          onAnimationComplete();
        });
      },
    );
  }
}
```

---

### 10. Export Service Pattern (lib/services/export_service.dart)

```dart
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../data/models/goal.dart';
import '../data/models/goal_progress.dart';
import '../core/utils/logger.dart';

class ExportService {
  static final ExportService instance = ExportService._init();
  ExportService._init();

  Future<File> exportToCsv(List<Goal> goals, Map<int, List<GoalProgress>> progressHistory) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/goals_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      
      final buffer = StringBuffer();
      buffer.writeln('Goal,Progress,Percentage,Date');
      
      for (final goal in goals) {
        final history = progressHistory[goal.id] ?? [];
        if (history.isEmpty) {
          buffer.writeln('${goal.title},${goal.currentValue},${goal.progressPercentage},${goal.updatedAt}');
        } else {
          for (final progress in history) {
            buffer.writeln('${goal.title},${progress.progressValue},${progress.progressPercentage},${progress.recordedAt}');
          }
        }
      }
      
      await file.writeAsString(buffer.toString());
      Logger.info('Exported ${goals.length} goals to ${file.path}');
      return file;
    } catch (e, stackTrace) {
      Logger.error('Failed to export to CSV', e, stackTrace);
      rethrow;
    }
  }

  Future<File> exportToJson(List<Goal> goals, Map<int, List<GoalProgress>> progressHistory) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/goals_export_${DateTime.now().millisecondsSinceEpoch}.json');
      
      final jsonData = {
        'goals': goals.map((g) => g.toMap()).toList(),
        'progress_history': progressHistory.map((key, value) => 
          MapEntry(key.toString(), value.map((p) => p.toMap()).toList())
        ),
        'exported_at': DateTime.now().millisecondsSinceEpoch,
      };
      
      await file.writeAsString(jsonEncode(jsonData));
      Logger.info('Exported ${goals.length} goals to ${file.path}');
      return file;
    } catch (e, stackTrace) {
      Logger.error('Failed to export to JSON', e, stackTrace);
      rethrow;
    }
  }
}
```

---

## Key Differences: MicroGoals vs Other Micro Apps

| Aspect | MicroHabits | MicroJournal | MicroNotes | MicroGoals |
|--------|-------------|--------------|------------|------------|
| **Main Entity** | Habit (name, icon, color) | Journal Entry (content, mood) | Note (title, content) | Goal (title, target, progress) |
| **Free Limit** | 3 habits | 1 entry/day | 10 notes | 3 active goals |
| **Content Type** | Checkbox completion | Text entry | Markdown text | Numeric progress |
| **Visual** | Icons + colors | Text + mood emoji | Cards + markdown | Progress rings/bars |
| **Special Feature** | Streak tracking | Mood tracking | Pin notes | Progress tracking |
| **Premium Extra** | - | Export | PIN lock | History chart, milestones |

---

## Checklist for AI Agent

When creating MicroGoals, ensure:

- [ ] Package name: `ie.qqrxi.microgoals`
- [ ] Theme: Material 3 with `Colors.deepPurple` seed
- [ ] Font: Google Fonts Inter
- [ ] Logger: No `print()` statements
- [ ] Exceptions: Custom exception classes
- [ ] Constants: All magic numbers in `AppConstants`
- [ ] Database: Proper error handling with try-catch
- [ ] Providers: Use `AsyncValue` for async data
- [ ] UI: Handle loading/error states with `.when()`
- [ ] Premium: Same purchase service pattern
- [ ] Navigation: GoRouter with MainScaffold
- [ ] Progress: Circular rings and linear bars
- [ ] Completion: Celebration animation
- [ ] History: Progress history chart (premium)
- [ ] Milestones: Achievement tracking (premium)
- [ ] Export: CSV and JSON formats (premium)
- [ ] Tests: Database helpers, unit tests, widget tests
- [ ] Linting: `flutter analyze` passes with 0 issues

---

## Quick Start Prompt

```
Create MicroGoals app following MicroHabits/MicroJournal/MicroNotes architecture:

1. Project setup: `ie.qqrxi.microgoals`, Flutter SDK ^3.8.1
2. Database: goals table (id, title, description, target_value, current_value, unit, icon_name, color_hex, due_date, is_completed, completed_at, created_at, updated_at)
3. Database: goal_progress_history table (premium) for tracking progress over time
4. Database: milestones table (premium) for achievement tracking
5. Models: Goal with toMap/fromMap/copyWith, progressPercentage getter
6. Repository: GoalRepository with CRUD, updateProgress, getProgressHistory
7. Providers: goalsProvider, activeGoalCountProvider, maxGoalsProvider, progressHistoryProvider
8. Home screen: List goals with progress rings, FAB to add (check limit), completion indicator
9. Add/edit goal screen: Title, description, target value, unit, due date, icon/color (premium)
10. Detail screen: Progress visualization, progress input controls, history chart (premium)
11. Progress input: Manual increment/decrement, percentage input, value input
12. Completion: Celebration animation when goal completed
13. Premium: 5 goals, progress history, milestones, export, custom icons/colors
14. Theme: Material 3, deepPurple seed, Google Fonts Inter
15. Use Logger, custom exceptions, AppConstants pattern

Start with core structure, database, and home screen with progress visualization.
```

---

## Additional Dependencies

```yaml
dependencies:
  fl_chart: ^0.66.0  # For progress history charts
  lottie: ^3.1.0     # For completion animations (optional, can use Flutter animations)
  # All other dependencies same as other Micro apps
```

---

This quick reference ensures consistency with MicroHabits/MicroJournal/MicroNotes patterns while adapting to goal-specific requirements with progress tracking and visualization.

