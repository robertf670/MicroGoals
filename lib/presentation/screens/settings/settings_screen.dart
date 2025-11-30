import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/theme_provider.dart';
import '../../providers/premium_provider.dart';
import '../../providers/goal_provider.dart';
import '../../../core/services/export_service.dart';
import '../../../core/utils/logger.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isPremium = ref.watch(premiumStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
            ),
          ),
          const Divider(),
          if (!isPremium)
            ListTile(
              leading: const Icon(Icons.workspace_premium, color: Colors.amber),
              title: const Text('Upgrade to Premium'),
              subtitle: const Text('Unlock unlimited goals, history charts, and more'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/premium'),
            )
          else
            ListTile(
              leading: const Icon(Icons.verified, color: Colors.green),
              title: const Text('Premium Active'),
              subtitle: const Text('Thank you for your support!'),
              onTap: () => context.push('/premium'), 
            ),
          const Divider(),
          // Premium features: Export & Backup
          if (isPremium) ...[
            ExpansionTile(
              leading: const Icon(Icons.file_download, color: Colors.amber),
              title: const Text('Export & Backup'),
              children: [
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Export to CSV'),
                  subtitle: const Text('Export goals and progress history'),
                  onTap: () => _exportToCsv(context, ref),
                ),
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Export to JSON'),
                  subtitle: const Text('Export full backup (can be restored)'),
                  onTap: () => _backupToJson(context, ref),
                ),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Restore from Backup'),
                  subtitle: const Text('Import data from JSON file'),
                  onTap: () => _restoreFromJson(context, ref),
                ),
              ],
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('MicroGoals v1.0.0'),
          ),
          const Divider(),
          // Debug Section (only in debug mode)
          if (kDebugMode)
            ExpansionTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Debug Mode'),
              children: [
                ListTile(
                  title: const Text('Premium Status'),
                  subtitle: Text(isPremium ? 'Active' : 'Inactive'),
                  trailing: Switch(
                    value: isPremium,
                    onChanged: (value) {
                      ref.read(premiumStatusProvider.notifier).setPremium(value);
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Add Dummy Goals'),
                  subtitle: const Text('Generates sample data'),
                  onTap: () async {
                    await ref.read(goalRepositoryProvider).addDummyData();
                    // Invalidate providers
                    ref.invalidate(goalsProvider);
                    ref.invalidate(allGoalsProvider);
                    ref.invalidate(activeGoalCountProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dummy goals added')),
                      );
                    }
                  },
                ),
                ListTile(
                  title: const Text('Clear All Data'),
                  subtitle: const Text('Deletes all goals and history'),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear Data?'),
                        content: const Text('This will delete EVERYTHING.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirmed == true) {
                      await ref.read(goalRepositoryProvider).clearAllData();
                      ref.invalidate(goalsProvider);
                      ref.invalidate(allGoalsProvider);
                      ref.invalidate(activeGoalCountProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All data cleared')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _exportToCsv(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(goalRepositoryProvider);
      final goals = await repository.getGoals();
      final progressHistory = await repository.getAllProgressHistory();
      
      // Generate CSV content
      final csvContent = await ExportService.instance.exportToCsvString(goals, progressHistory);
      
      if (!context.mounted) return;
      
      // Let user choose where to save
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final bytes = utf8.encode(csvContent);
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV Export',
        fileName: 'microgoals_export_$timestamp.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );
      
      if (result != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV exported successfully')),
        );
      }
    } catch (e, stack) {
      Logger.error('Failed to export CSV', e, stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _backupToJson(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(goalRepositoryProvider);
      final goals = await repository.getGoals();
      final progressHistory = await repository.getAllProgressHistory();
      final milestones = await repository.getAllMilestones();
      
      // Generate JSON content
      final jsonContent = await ExportService.instance.exportToJsonString(
        goals,
        progressHistory,
        milestones,
      );
      
      if (!context.mounted) return;
      
      // Let user choose where to save
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final bytes = utf8.encode(jsonContent);
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save JSON Backup',
        fileName: 'microgoals_backup_$timestamp.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );
      
      if (result != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully')),
        );
      }
    } catch (e, stack) {
      Logger.error('Failed to create backup', e, stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }

  Future<void> _restoreFromJson(BuildContext context, WidgetRef ref) async {
    try {
      // Confirm restore
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore Backup?'),
          content: const Text(
            'This will replace ALL your current data. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Restore'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
      
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result == null || result.files.single.path == null) {
        return;
      }
      
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      
      // Restore data
      final repository = ref.read(goalRepositoryProvider);
      await repository.restoreFromJson(jsonString);
      
      // Invalidate providers
      ref.invalidate(goalsProvider);
      ref.invalidate(allGoalsProvider);
      ref.invalidate(activeGoalCountProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restored successfully')),
        );
      }
    } catch (e, stack) {
      Logger.error('Failed to restore backup', e, stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }
}
