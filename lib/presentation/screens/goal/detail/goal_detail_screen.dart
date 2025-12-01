import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/goal.dart';
import '../../../providers/goal_provider.dart';
import '../../../providers/premium_provider.dart';
import '../../../widgets/progress_ring.dart';
import '../../../widgets/completion_celebration.dart';
import '../../../widgets/history_chart.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/logger.dart';

class GoalDetailScreen extends ConsumerStatefulWidget {
  final int goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  final _progressController = TextEditingController();
  bool _showCelebration = false;

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _deleteGoal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: const Text('This action cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(goalRepositoryProvider).deleteGoal(widget.goalId);
        
        ref.invalidate(goalsProvider);
        ref.invalidate(allGoalsProvider);
        ref.invalidate(activeGoalCountProvider);
        ref.invalidate(goalByIdProvider(widget.goalId));
        
        if (mounted) {
          context.pop(); // Return to previous screen
        }
      } catch (e, stack) {
        Logger.error('Failed to delete goal', e, stack);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting goal: $e')),
          );
        }
      }
    }
  }

  Future<void> _updateProgress(Goal goal, double newProgress) async {
    try {
      if (newProgress < 0) newProgress = 0;
      // Note: We allow exceeding target value for overachievement

      // Check premium status to determine if we should store history
      // Note: In real app, we might want to store history always but only show it for premium
      // For now, let's store it always if isPremium is passed as true to repository,
      // but repository logic relies on the flag.
      // Let's check premium status here.
      final isPremium = ref.read(premiumStatusProvider);

      await ref.read(goalRepositoryProvider).updateProgress(goal.id!, newProgress, isPremium); 
      
      ref.invalidate(goalsProvider);
      ref.invalidate(allGoalsProvider);
      ref.invalidate(activeGoalCountProvider);
      ref.invalidate(goalByIdProvider(goal.id!));
      if (isPremium) {
        ref.invalidate(progressHistoryProvider(goal.id!));
        ref.invalidate(milestonesProvider(goal.id!));
      }
      
      // Check for completion
      if (newProgress >= goal.targetValue && !goal.isCompleted) {
        setState(() {
          _showCelebration = true;
        });
      }
    } catch (e, stack) {
      Logger.error('Failed to update progress', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating progress: $e')),
        );
      }
    }
  }

  void _showUpdateDialog(Goal goal) {
    _progressController.text = goal.currentValue.toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Progress'),
        content: TextField(
          controller: _progressController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Current Value',
            suffixText: goal.unit,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(_progressController.text);
              if (value != null) {
                _updateProgress(goal, value);
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalAsync = ref.watch(goalByIdProvider(widget.goalId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/edit-goal/${widget.goalId}'),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteGoal,
          ),
        ],
      ),
      body: Stack(
        children: [
          goalAsync.when(
            data: (goal) {
              if (goal == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Goal not found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                );
              }
              return _buildContent(goal);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) {
              Logger.error('Failed to load goal', error, stack);
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading goal',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_showCelebration)
            CompletionCelebration(
              onAnimationComplete: () {
                setState(() {
                  _showCelebration = false;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildContent(Goal goal) {
    final color = goal.colorHex != null
        ? _getColorFromHex(goal.colorHex!)
        : Theme.of(context).colorScheme.primary;
    final isPremium = ref.watch(premiumStatusProvider);
    final historyAsync = ref.watch(progressHistoryProvider(goal.id!));
    final milestonesAsync = ref.watch(milestonesProvider(goal.id!));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Center(
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.maxWidth < 400 
                      ? constraints.maxWidth * 0.4 
                      : 150.0;
                  return ProgressRing(
                    progress: goal.progressPercentage / 100,
                    color: color,
                    size: size.clamp(100.0, 150.0),
                    strokeWidth: 12,
                    centerText: '${goal.progressPercentage.toStringAsFixed(0)}%',
                  );
                },
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    goal.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              if (goal.description != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    goal.description!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Stats Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildStatItem('Current', '${goal.currentValue.toStringAsFixed(0)} ${goal.unit ?? ""}')),
                Expanded(child: _buildStatItem('Target', '${goal.targetValue.toStringAsFixed(0)} ${goal.unit ?? ""}')),
                if (goal.dueDate != null)
                  Expanded(child: _buildStatItem('Due', AppDateUtils.formatDate(goal.dueDate!))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Quick Actions or Completion Message
        if (goal.isCompleted) ...[
          Card(
            color: Colors.green.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Goal Completed!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (goal.completedAt != null)
                    Text(
                      'Completed on ${AppDateUtils.formatDate(goal.completedAt!)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ),
        ] else ...[
          Text(
            'Update Progress',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 360;
              return isSmallScreen
                  ? Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(Icons.remove, () => _updateProgress(goal, goal.currentValue - 1), color),
                            _buildActionButton(Icons.add, () => _updateProgress(goal, goal.currentValue + 1), color),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _showUpdateDialog(goal),
                            icon: const Icon(Icons.edit),
                            label: const Text('Set Value'),
                            style: FilledButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(Icons.remove, () => _updateProgress(goal, goal.currentValue - 1), color),
                        _buildActionButton(Icons.add, () => _updateProgress(goal, goal.currentValue + 1), color),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: FilledButton.icon(
                              onPressed: () => _showUpdateDialog(goal),
                              icon: const Icon(Icons.edit),
                              label: const Text('Set Value'),
                              style: FilledButton.styleFrom(
                                backgroundColor: color,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
            },
          ),
        ],
        
        const SizedBox(height: 32),
        
        // Premium Features Section
        if (isPremium) ...[
          // History Chart
          Text(
            'History',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartHeight = constraints.maxWidth < 360 ? 200.0 : 250.0;
                return SizedBox(
                  height: chartHeight,
                  child: historyAsync.when(
                    data: (history) => HistoryChart(history: history, color: color),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(
                          'Error: $error',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Milestones
          Text(
            'Milestones',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          milestonesAsync.when(
            data: (milestones) {
              if (milestones.isEmpty) {
                return const Text('No milestones yet.');
              }
              return Column(
                children: milestones.map((m) {
                  final isAchieved = m['achieved_at'] != null;
                  return Card(
                    color: isAchieved ? color.withValues(alpha: 0.1) : null,
                    child: ListTile(
                      leading: Icon(
                        isAchieved ? Icons.emoji_events : Icons.emoji_events_outlined,
                        color: isAchieved ? Colors.amber : Colors.grey,
                      ),
                      title: Text(
                        m['title'],
                        style: TextStyle(
                          fontWeight: isAchieved ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: isAchieved
                          ? Text('Achieved on ${AppDateUtils.formatDate(DateTime.fromMillisecondsSinceEpoch(m['achieved_at']))}')
                          : const Text('Not yet achieved'),
                      trailing: isAchieved
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Error loading milestones: $error'),
          ),
        ] else ...[
          // Premium upsell
           Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock Premium Features',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text('Get detailed history charts and milestone tracking.'),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => context.push('/premium'),
                    child: const Text('Go Premium'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.grey,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: color,
        iconSize: 32,
      ),
    );
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
