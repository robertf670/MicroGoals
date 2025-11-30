import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/theme_provider.dart';
import '../../providers/premium_provider.dart';
import '../../providers/goal_provider.dart';
import '../../../core/services/export_service.dart';
import '../../../core/utils/logger.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '1.0.1';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      Logger.warning('Failed to load package info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isPremium = ref.watch(premiumStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Appearance Section
          _buildSectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(_getThemeModeText(themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, ref),
          ),
          const Divider(),
          
          // Premium Section
          _buildSectionHeader('Premium'),
          if (!isPremium)
            ListTile(
              leading: const Icon(Icons.workspace_premium, color: Colors.amber),
              title: const Text('Upgrade to Premium'),
              subtitle: const Text('Unlock 30 active goals, history charts, and more'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/premium'),
            )
          else
            ListTile(
              leading: const Icon(Icons.verified, color: Colors.green),
              title: const Text('Premium Active'),
              subtitle: const Text('Thank you for your support!'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/premium'), 
            ),
          const Divider(),
          
          // Premium features: Export & Backup
          if (isPremium) ...[
            _buildSectionHeader('Export & Backup'),
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
          
          // About Section
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About MicroGoals'),
            subtitle: const Text('App version and info'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAboutDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            subtitle: const Text('How we handle your data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPrivacyPolicyDialog(context),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(themeModeProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setTheme(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setTheme(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System default'),
              value: ThemeMode.system,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setTheme(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.flag,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MicroGoals',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Version $_appVersion',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'A focused goal-tracking app that helps users stay focused on meaningful objectives. Built with Flutter and Material Design 3.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(
            _getPrivacyPolicyText(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getPrivacyPolicyText() {
    return '''Last Updated: January 2025

Introduction

MicroGoals ("we", "our", or "us") respects your privacy. This Privacy Policy explains how we handle information when you use our mobile application.

Data Collection

We do not collect, store, or transmit any personal data.

MicroGoals operates entirely on your device. All data including:

• Goal information
• Progress history
• Milestone achievements
• Settings and preferences

...is stored locally on your device only. We do not have access to this data.

Data Storage

All app data is stored locally on your device using:

• SQLite database (for goals, progress history, and milestones)
• SharedPreferences (for settings and premium status)

No data is transmitted to external servers or third parties.

In-App Purchases

When you make in-app purchases (Premium upgrade), payment processing is handled entirely by Google Play. We do not collect, store, or have access to:

• Payment information
• Credit card details
• Billing addresses
• Transaction details

All payment data is managed by Google Play according to their privacy policy.

Permissions

MicroGoals does not require any special permissions. The app operates entirely offline and does not access your device's contacts, location, camera, or other sensitive data.

Third-Party Services

MicroGoals does not integrate with any third-party analytics, advertising, or tracking services.

Data Deletion

Since all data is stored locally on your device:

• Uninstalling the app will delete all app data
• You can delete individual goals within the app
• You can export your data (CSV/JSON) before uninstalling if desired
• There is no account or cloud data to delete

Children's Privacy

MicroGoals is not intended for children under 13. We do not knowingly collect data from children.

Changes to This Policy

We may update this Privacy Policy from time to time. The "Last Updated" date at the top indicates when changes were made.''';
  }
}
