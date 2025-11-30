import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/premium_provider.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _isPurchasing = false;
  StreamSubscription<bool>? _premiumStatusSubscription;

  @override
  void initState() {
    super.initState();
    // Listen to premium status changes from purchases
    _premiumStatusSubscription = PurchaseService.instance.premiumStatusStream.listen(
      (isPremium) {
        if (isPremium && mounted) {
          // Refresh premium status provider
          ref.invalidate(premiumStatusProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Premium activated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Close screen after successful purchase
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) context.pop();
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _premiumStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _purchaseProduct(String productId) async {
    setState(() {
      _isPurchasing = true;
    });

    try {
      // Check if products are loaded
      final products = PurchaseService.instance.products;
      if (products.isEmpty) {
        // Try to load products first
        await PurchaseService.instance.loadProducts();
        
        // Check again
        final productsAfterLoad = PurchaseService.instance.products;
        if (productsAfterLoad.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Products not available. Make sure:\n'
                '1. App is published to Internal Testing\n'
                '2. Products are Active in Play Console\n'
                '3. App is installed from Play Store',
              ),
              duration: Duration(seconds: 5),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      final success = await PurchaseService.instance.purchaseProduct(productId);
      
      if (!mounted) return;
      
      if (success) {
        // Purchase initiated - PurchaseService will handle the result
        // and update premium status via SharedPreferences
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Processing purchase...'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to initiate purchase.\n'
              'Make sure the app is installed from Play Store and products are active.',
            ),
            duration: Duration(seconds: 4),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isPurchasing = true;
    });

    try {
      await PurchaseService.instance.restorePurchases();
      
      if (!mounted) return;
      
      // Wait a moment for restore to process
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      
      // Refresh premium status
      ref.invalidate(premiumStatusProvider);
      
      final isPremium = ref.read(premiumStatusProvider);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPremium 
              ? 'Purchases restored successfully!' 
              : 'No previous purchases found.'),
          backgroundColor: isPremium ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error restoring purchases: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: _isPurchasing
                    ? null
                    : () => _purchaseProduct(AppConstants.premiumLifetimeProductId),
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
                onPressed: _isPurchasing
                    ? null
                    : () => _purchaseProduct(AppConstants.premiumAnnualProductId),
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
                onPressed: _isPurchasing ? null : _restorePurchases,
                child: _isPurchasing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Restore Purchases'),
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
