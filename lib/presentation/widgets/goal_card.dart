import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/goal.dart';
import '../../core/utils/date_utils.dart';
import 'progress_ring.dart';

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
    final fullProgressText = goal.unit != null && goal.unit!.isNotEmpty
        ? '$progressText ${goal.unit}'
        : progressText;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (goal.isCompleted)
                    const Icon(Icons.check_circle, color: Colors.green, size: 24),
                ],
              ),
              if (goal.description != null && goal.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  goal.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
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
                    size: 60,
                    strokeWidth: 6,
                    centerText: '${goal.progressPercentage.toStringAsFixed(0)}%',
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            fullProgressText,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                          ),
                        ),
                        if (goal.dueDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Due: ${AppDateUtils.formatDate(goal.dueDate!)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
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

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  IconData _getIconFromName(String iconName) {
    // Basic mapping, extend as needed
    switch (iconName) {
      case 'flag': return Icons.flag;
      case 'star': return Icons.star;
      case 'fitness': return Icons.fitness_center;
      case 'book': return Icons.book;
      case 'money': return Icons.attach_money;
      case 'work': return Icons.work;
      case 'school': return Icons.school;
      default: return Icons.flag;
    }
  }
}

