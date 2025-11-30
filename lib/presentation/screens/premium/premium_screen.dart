import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/premium_provider.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MicroGoals Premium'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.workspace_premium,
              size: 80,
              color: Colors.amber,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isPremium ? 'You are Premium!' : 'Unlock Full Potential',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Get the most out of your goal tracking with these premium features:',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 32),
            _buildFeatureItem(context, Icons.insights, 'Progress History Charts', 'Visualise your progress over time'),
            _buildFeatureItem(context, Icons.emoji_events, 'Milestone Tracking', 'Celebrate achievements at 25%, 50%, 75%'),
            _buildFeatureItem(context, Icons.add_circle_outline, '30 Active Goals', 'Track up to 30 active goals'),
            _buildFeatureItem(context, Icons.palette, 'Custom Colors & Icons', 'Personalize your goals'),
            const SizedBox(height: 48),
            
            if (!isPremium) ...[
              // Lifetime option (Best Value)
              FilledButton(
                onPressed: () {
                  // Simulate lifetime purchase
                  ref.read(premiumStatusProvider.notifier).setPremium(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Premium Lifetime Activated! (Simulated)')),
                  );
                  context.pop();
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  backgroundColor: Colors.amber[700],
                  foregroundColor: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: const Text(
                          'Lifetime - €4.99',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'BEST VALUE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Annual option
              OutlinedButton(
                onPressed: () {
                  // Simulate annual purchase
                  ref.read(premiumStatusProvider.notifier).setPremium(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Premium Annual Activated! (Simulated)')),
                  );
                  context.pop();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.amber[700]!, width: 2),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: const Text(
                    'Annual - €2.99/year',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                   // Restore logic placeholder
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Restore Purchases (Simulated)')),
                  );
                },
                child: const Text('Restore Purchases'),
              ),
            ] else ...[
              if (kDebugMode)
                FilledButton.tonal(
                  onPressed: () {
                    // Debug: remove premium
                    ref.read(premiumStatusProvider.notifier).setPremium(false);
                  },
                  child: const Text('Deactivate Premium (Debug)'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
