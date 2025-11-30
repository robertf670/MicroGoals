import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/goal.dart';
import '../../data/models/goal_progress.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/local/database/app_database.dart';
import '../../core/constants/app_constants.dart';
import 'premium_provider.dart';

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
  final isPremium = ref.watch(premiumStatusProvider);
  return isPremium ? AppConstants.premiumGoalLimit : AppConstants.freeGoalLimit;
});

// Progress history provider (premium)
final progressHistoryProvider = FutureProvider.family<List<GoalProgress>, int>((ref, goalId) async {
  final repository = ref.watch(goalRepositoryProvider);
  final isPremium = ref.watch(premiumStatusProvider);
  if (!isPremium) return [];
  return await repository.getProgressHistory(goalId);
});

// Milestones provider (premium)
final milestonesProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, goalId) async {
  final repository = ref.watch(goalRepositoryProvider);
  final isPremium = ref.watch(premiumStatusProvider);
  if (!isPremium) return [];
  return await repository.getMilestones(goalId);
});
