import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/goal_provider.dart';
import '../../widgets/goal_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final activeCountAsync = ref.watch(activeGoalCountProvider);
    final maxGoalsAsync = ref.watch(maxGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MicroGoals'),
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flag_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'No active goals',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: const Text(
                      'Tap + to create your first goal',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: goals.length,
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (context, index) {
              return GoalCard(goal: goals[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Check limits
          final activeCount = activeCountAsync.value ?? 0;
          final maxGoals = maxGoalsAsync.value ?? 3;
          
          if (activeCount >= maxGoals) {
            // Show limit reached dialog or snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Goal limit reached ($activeCount/$maxGoals). Upgrade to Premium for more!'),
                action: SnackBarAction(
                  label: 'Upgrade',
                  onPressed: () => context.push('/premium'),
                ),
              ),
            );
            return;
          }
          
          context.push('/add-goal');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
