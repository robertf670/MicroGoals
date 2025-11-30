import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../local/database/app_database.dart';
import '../models/goal.dart';
import '../models/goal_progress.dart';
import '../../core/utils/logger.dart';
import '../../core/errors/exceptions.dart';
import '../../core/constants/app_constants.dart';

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
      return await db.transaction((txn) async {
        final goalId = await txn.insert('goals', goal.toMap());
        
        // Create milestones for this goal
        for (final percentage in AppConstants.milestonePercentages) {
          await txn.insert('milestones', {
            'goal_id': goalId,
            'title': '${percentage.toInt()}% Complete',
            'target_percentage': percentage,
            'achieved_at': null,
          });
        }
        
        return goalId;
      });
    } catch (e, stackTrace) {
      Logger.error('Failed to create goal', e, stackTrace);
      throw RepositoryException('Failed to save goal: ${e.toString()}', e);
    }
  }

  Future<void> updateGoal(Goal goal) async {
    try {
      final db = await _database.database;
      await db.update(
        'goals',
        goal.toMap(),
        where: 'id = ?',
        whereArgs: [goal.id],
      );
    } catch (e, stackTrace) {
      Logger.error('Failed to update goal', e, stackTrace);
      throw RepositoryException('Failed to update goal: ${e.toString()}', e);
    }
  }

  Future<void> deleteGoal(int goalId) async {
    try {
      final db = await _database.database;
      await db.delete(
        'goals',
        where: 'id = ?',
        whereArgs: [goalId],
      );
    } catch (e, stackTrace) {
      Logger.error('Failed to delete goal', e, stackTrace);
      throw RepositoryException('Failed to delete goal: ${e.toString()}', e);
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

  Future<List<Map<String, dynamic>>> getMilestones(int goalId) async {
    try {
      final db = await _database.database;
      return await db.query(
        'milestones',
        where: 'goal_id = ?',
        whereArgs: [goalId],
        orderBy: 'target_percentage ASC',
      );
    } catch (e, stackTrace) {
      Logger.error('Failed to get milestones', e, stackTrace);
      throw RepositoryException('Failed to load milestones: ${e.toString()}', e);
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

  Future<Map<int, List<GoalProgress>>> getAllProgressHistory() async {
    try {
      final db = await _database.database;
      final maps = await db.query(
        'goal_progress_history',
        orderBy: 'goal_id ASC, recorded_at ASC',
      );
      
      final Map<int, List<GoalProgress>> historyMap = {};
      for (final map in maps) {
        final goalId = map['goal_id'] as int;
        final progress = GoalProgress.fromMap(map);
        historyMap.putIfAbsent(goalId, () => []).add(progress);
      }
      
      return historyMap;
    } catch (e, stackTrace) {
      Logger.error('Failed to get all progress history', e, stackTrace);
      throw RepositoryException('Failed to load progress history: ${e.toString()}', e);
    }
  }

  Future<Map<int, List<Map<String, dynamic>>>> getAllMilestones() async {
    try {
      final db = await _database.database;
      final maps = await db.query('milestones', orderBy: 'goal_id ASC');
      
      final Map<int, List<Map<String, dynamic>>> milestonesMap = {};
      for (final map in maps) {
        final goalId = map['goal_id'] as int;
        milestonesMap.putIfAbsent(goalId, () => []).add(map);
      }
      
      return milestonesMap;
    } catch (e, stackTrace) {
      Logger.error('Failed to get all milestones', e, stackTrace);
      throw RepositoryException('Failed to load milestones: ${e.toString()}', e);
    }
  }

  // Debug methods
  Future<void> addDummyData() async {
    try {
      final db = await _database.database;
      await db.transaction((txn) async {
        // Goal 1: Reading (Active, 30%)
        final g1 = Goal(
          title: 'Read 300 pages',
          description: 'Finish the book "The Seven Husbands of Evelyn Hugo"',
          targetValue: 300,
          currentValue: 90,
          unit: 'pages',
          iconName: 'book',
          colorHex: '#2196F3',
          dueDate: DateTime.now().add(const Duration(days: 7)),
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now(),
        );
        final id1 = await txn.insert('goals', g1.toMap());
        await _createMilestones(txn, id1);
        await _addDummyHistory(txn, id1, [10, 30, 60, 90], 300);
        
        // Update milestones manually for realistic dates
        // 25% (75 pages) reached when progress was 90 (1 day ago)
        await txn.update('milestones',
          {'achieved_at': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch},
          where: 'goal_id = ? AND target_percentage = 25.0',
          whereArgs: [id1]);

        // Goal 2: Running (Active, 76%)
        final g2 = Goal(
          title: 'Run 50km',
          targetValue: 50,
          currentValue: 38,
          unit: 'km',
          iconName: 'fitness',
          colorHex: '#4CAF50',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now(),
        );
        final id2 = await txn.insert('goals', g2.toMap());
        await _createMilestones(txn, id2);
        // Realistic daily running: 3, 4, 2, 5, 3, 4, 6, 2, 4, 5 km (cumulative: 3, 7, 9, 14, 17, 21, 27, 29, 33, 38)
        await _addDummyHistory(txn, id2, [3, 7, 9, 14, 17, 21, 27, 29, 33, 38], 50);
        
        // 25% (12.5km) reached at 14km (7 days ago)
        await txn.update('milestones',
          {'achieved_at': DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch},
          where: 'goal_id = ? AND target_percentage = 25.0',
          whereArgs: [id2]);
        // 50% (25km) reached at 27km (3 days ago)
        await txn.update('milestones',
          {'achieved_at': DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch},
          where: 'goal_id = ? AND target_percentage = 50.0',
          whereArgs: [id2]);
        // 75% (37.5km) reached at 38km (1 day ago)
        await txn.update('milestones',
          {'achieved_at': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch},
          where: 'goal_id = ? AND target_percentage = 75.0',
          whereArgs: [id2]);

        // Goal 3: Meditation (Completed)
        final g3 = Goal(
          title: 'Meditate 10 times',
          targetValue: 10,
          currentValue: 10,
          unit: 'sessions',
          iconName: 'star',
          colorHex: '#9C27B0',
          isCompleted: true,
          completedAt: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          updatedAt: DateTime.now(),
        );
        final id3 = await txn.insert('goals', g3.toMap());
        await _createMilestones(txn, id3);
        await _addDummyHistory(txn, id3, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 10);
        
        // 25% (2.5) reached at 3 (8 days ago)
        await txn.update('milestones', {'achieved_at': DateTime.now().subtract(const Duration(days: 8)).millisecondsSinceEpoch}, where: 'goal_id = ? AND target_percentage = 25.0', whereArgs: [id3]);
        // 50% (5) reached at 5 (6 days ago)
        await txn.update('milestones', {'achieved_at': DateTime.now().subtract(const Duration(days: 6)).millisecondsSinceEpoch}, where: 'goal_id = ? AND target_percentage = 50.0', whereArgs: [id3]);
        // 75% (7.5) reached at 8 (3 days ago)
        await txn.update('milestones', {'achieved_at': DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch}, where: 'goal_id = ? AND target_percentage = 75.0', whereArgs: [id3]);

        // Goal 4: Savings (Active, 65%)
        final g4 = Goal(
          title: 'Save €500',
          description: 'Emergency fund for unexpected expenses',
          targetValue: 500,
          currentValue: 325,
          unit: '€',
          iconName: 'money',
          colorHex: '#FF9800',
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          updatedAt: DateTime.now(),
        );
        final id4 = await txn.insert('goals', g4.toMap());
        await _createMilestones(txn, id4);
        // Realistic savings pattern: 50, 100, 150, 180, 220, 250, 280, 310, 325 (cumulative)
        await _addDummyHistory(txn, id4, [50, 100, 150, 180, 220, 250, 280, 310, 325], 500);
        
        // 25% (125€) reached at 150€ (12 days ago)
        await txn.update('milestones',
          {'achieved_at': DateTime.now().subtract(const Duration(days: 12)).millisecondsSinceEpoch},
          where: 'goal_id = ? AND target_percentage = 25.0',
          whereArgs: [id4]);
        // 50% (250€) reached at 250€ (5 days ago)
        await txn.update('milestones',
          {'achieved_at': DateTime.now().subtract(const Duration(days: 5)).millisecondsSinceEpoch},
          where: 'goal_id = ? AND target_percentage = 50.0',
          whereArgs: [id4]);
        // 75% (375€) not yet reached (currently at 65%)

        // Goal 5: Workouts (Completed)
        final g5 = Goal(
          title: 'Complete 20 workouts',
          description: 'Build a consistent exercise routine',
          targetValue: 20,
          currentValue: 20,
          unit: 'workouts',
          iconName: 'fitness',
          colorHex: '#E91E63',
          isCompleted: true,
          completedAt: DateTime.now().subtract(const Duration(days: 2)),
          createdAt: DateTime.now().subtract(const Duration(days: 25)),
          updatedAt: DateTime.now(),
        );
        final id5 = await txn.insert('goals', g5.toMap());
        await _createMilestones(txn, id5);
        // Realistic workout progression over 25 days: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
        await _addDummyHistory(txn, id5, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20], 20);
        
        // 25% (5) reached at 5 (20 days ago)
        await txn.update('milestones', {'achieved_at': DateTime.now().subtract(const Duration(days: 20)).millisecondsSinceEpoch}, where: 'goal_id = ? AND target_percentage = 25.0', whereArgs: [id5]);
        // 50% (10) reached at 10 (15 days ago)
        await txn.update('milestones', {'achieved_at': DateTime.now().subtract(const Duration(days: 15)).millisecondsSinceEpoch}, where: 'goal_id = ? AND target_percentage = 50.0', whereArgs: [id5]);
        // 75% (15) reached at 15 (10 days ago)
        await txn.update('milestones', {'achieved_at': DateTime.now().subtract(const Duration(days: 10)).millisecondsSinceEpoch}, where: 'goal_id = ? AND target_percentage = 75.0', whereArgs: [id5]);

      });
    } catch (e, stackTrace) {
      Logger.error('Failed to add dummy data', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _createMilestones(Transaction txn, int goalId) async {
    for (final percentage in AppConstants.milestonePercentages) {
      await txn.insert('milestones', {
        'goal_id': goalId,
        'title': '${percentage.toInt()}% Complete',
        'target_percentage': percentage,
        'achieved_at': null,
      });
    }
  }

  Future<void> _addDummyHistory(Transaction txn, int goalId, List<double> values, double targetValue) async {
    // Add history points over last few days
    int dayOffset = values.length;
    for (final val in values) {
      final percentage = targetValue > 0 ? (val / targetValue) * 100 : 0.0;
      await txn.insert('goal_progress_history', {
        'goal_id': goalId,
        'progress_value': val,
        'progress_percentage': percentage,
        'recorded_at': DateTime.now().subtract(Duration(days: dayOffset)).millisecondsSinceEpoch,
      });
      dayOffset--;
    }
  }

  Future<void> clearAllData() async {
    try {
      final db = await _database.database;
      await db.delete('goals');
      await db.delete('goal_progress_history');
      await db.delete('milestones');
    } catch (e, stackTrace) {
      Logger.error('Failed to clear data', e, stackTrace);
      rethrow;
    }
  }

  Future<void> restoreFromJson(String jsonString) async {
    try {
      final db = await _database.database;
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      await db.transaction((txn) async {
        // Clear existing data
        await txn.delete('goals');
        await txn.delete('goal_progress_history');
        await txn.delete('milestones');
        
        // Restore goals
        final goalsList = jsonData['goals'] as List<dynamic>;
        for (final goalMap in goalsList) {
          final goal = Goal.fromMap(goalMap as Map<String, dynamic>);
          await txn.insert('goals', goal.toMap());
        }
        
        // Restore progress history
        final progressHistoryMap = jsonData['progress_history'] as Map<String, dynamic>?;
        if (progressHistoryMap != null) {
          for (final entry in progressHistoryMap.entries) {
            final goalId = int.parse(entry.key);
            final historyList = entry.value as List<dynamic>;
            for (final progressMap in historyList) {
              final progress = GoalProgress.fromMap(progressMap as Map<String, dynamic>);
              await txn.insert('goal_progress_history', {
                'goal_id': goalId,
                'progress_value': progress.progressValue,
                'progress_percentage': progress.progressPercentage,
                'recorded_at': progress.recordedAt.millisecondsSinceEpoch,
              });
            }
          }
        }
        
        // Restore milestones
        final milestonesMap = jsonData['milestones'] as Map<String, dynamic>?;
        if (milestonesMap != null) {
          for (final entry in milestonesMap.entries) {
            final goalId = int.parse(entry.key);
            final milestonesList = entry.value as List<dynamic>;
            for (final milestoneMap in milestonesList) {
              await txn.insert('milestones', {
                'goal_id': goalId,
                'title': milestoneMap['title'],
                'target_percentage': milestoneMap['target_percentage'],
                'achieved_at': milestoneMap['achieved_at'],
              });
            }
          }
        }
      });
      
      Logger.info('Restored data from JSON backup');
    } catch (e, stackTrace) {
      Logger.error('Failed to restore from JSON', e, stackTrace);
      throw RepositoryException('Failed to restore backup: ${e.toString()}', e);
    }
  }
}
