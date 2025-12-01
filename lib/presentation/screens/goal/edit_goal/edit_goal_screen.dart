import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/goal_provider.dart';
import '../../../providers/premium_provider.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/constants/app_constants.dart';

class EditGoalScreen extends ConsumerStatefulWidget {
  final int goalId;

  const EditGoalScreen({super.key, required this.goalId});

  @override
  ConsumerState<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends ConsumerState<EditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _targetValueController;
  late TextEditingController _unitController;
  DateTime? _dueDate;
  bool _isSaving = false;
  bool _isLoading = true;
  String _selectedColorHex = AppConstants.defaultColor;
  String _selectedIconName = AppConstants.defaultIcon;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _targetValueController = TextEditingController();
    _unitController = TextEditingController();
    _loadGoal();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetValueController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _loadGoal() async {
    try {
      final goals = await ref.read(allGoalsProvider.future);
      final goal = goals.firstWhere((g) => g.id == widget.goalId);
      
      if (mounted) {
        setState(() {
          _titleController.text = goal.title;
          _descriptionController.text = goal.description ?? '';
          _targetValueController.text = goal.targetValue.toString();
          _unitController.text = goal.unit ?? '';
          _dueDate = goal.dueDate;
          _selectedColorHex = goal.colorHex ?? AppConstants.defaultColor;
          _selectedIconName = goal.iconName ?? AppConstants.defaultIcon;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      Logger.error('Error loading goal', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading goal: $e')),
        );
        context.pop();
      }
    }
  }

  Future<void> _updateGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final goals = await ref.read(allGoalsProvider.future);
      final originalGoal = goals.firstWhere((g) => g.id == widget.goalId);
      
      // Since repository doesn't have a generic updateGoal method yet (only updateProgress),
      // we need to add it or perform a hack. 
      // Ideally we should add updateGoal to the repository.
      // For now, I'll update the repository to include updateGoal.
      
      // Let's assume we'll update the repository next.
      final updatedGoal = originalGoal.copyWith(
        title: _titleController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        targetValue: double.parse(_targetValueController.text),
        unit: _unitController.text.isEmpty ? null : _unitController.text,
        dueDate: _dueDate,
        colorHex: _selectedColorHex,
        iconName: _selectedIconName,
        updatedAt: DateTime.now(),
      );

      // We need to implement updateGoal in repository first.
      await ref.read(goalRepositoryProvider).updateGoal(updatedGoal);
      
      // Invalidate providers
      ref.invalidate(goalsProvider);
      ref.invalidate(allGoalsProvider);
      ref.invalidate(goalByIdProvider(widget.goalId));
      
      if (mounted) {
        context.pop();
      }
    } catch (e, stack) {
      Logger.error('Error updating goal', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating goal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Goal'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Goal Title',
                hintText: 'e.g., Read 300 pages',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Why is this goal important?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _targetValueController,
                    decoration: const InputDecoration(
                      labelText: 'Target Value',
                      hintText: 'e.g., 300',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (double.tryParse(value) == null) return 'Invalid number';
                      if (double.parse(value) <= 0) return 'Must be > 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit (Optional)',
                      hintText: 'e.g., pages',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Due Date (Optional)'),
              subtitle: Text(_dueDate == null ? 'Not set' : _dueDate.toString().split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (date != null) {
                  setState(() {
                    _dueDate = date;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // Premium features: Color and Icon selection
            Consumer(
              builder: (context, ref, child) {
                final isPremium = ref.watch(premiumStatusProvider);
                if (!isPremium) {
                  return Card(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Custom Colors & Icons',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  'Upgrade to Premium',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/premium'),
                            child: const Text('Upgrade'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customize',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    // Color picker
                    Text(
                      'Color',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    _buildColorPicker(),
                    const SizedBox(height: 16),
                    // Icon picker
                    Text(
                      'Icon',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    _buildIconPicker(),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _updateGoal,
              icon: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Update Goal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    final colors = [
      {'name': 'Purple', 'hex': '#9C27B0'},
      {'name': 'Blue', 'hex': '#2196F3'},
      {'name': 'Green', 'hex': '#4CAF50'},
      {'name': 'Orange', 'hex': '#FF9800'},
      {'name': 'Red', 'hex': '#F44336'},
      {'name': 'Pink', 'hex': '#E91E63'},
      {'name': 'Teal', 'hex': '#009688'},
      {'name': 'Amber', 'hex': '#FFC107'},
      {'name': 'Indigo', 'hex': '#3F51B5'},
      {'name': 'Cyan', 'hex': '#00BCD4'},
      {'name': 'Deep Orange', 'hex': '#FF5722'},
      {'name': 'Lime', 'hex': '#CDDC39'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((colorData) {
        final hex = colorData['hex'] as String;
        final isSelected = _selectedColorHex == hex;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedColorHex = hex;
            });
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getColorFromHex(hex),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIconPicker() {
    final icons = [
      {'name': 'flag', 'icon': Icons.flag},
      {'name': 'star', 'icon': Icons.star},
      {'name': 'fitness', 'icon': Icons.fitness_center},
      {'name': 'book', 'icon': Icons.book},
      {'name': 'money', 'icon': Icons.attach_money},
      {'name': 'work', 'icon': Icons.work},
      {'name': 'school', 'icon': Icons.school},
      {'name': 'home', 'icon': Icons.home},
      {'name': 'directions_run', 'icon': Icons.directions_run},
      {'name': 'restaurant', 'icon': Icons.restaurant},
      {'name': 'music_note', 'icon': Icons.music_note},
      {'name': 'palette', 'icon': Icons.palette},
      {'name': 'code', 'icon': Icons.code},
      {'name': 'language', 'icon': Icons.language},
      {'name': 'flight', 'icon': Icons.flight},
      {'name': 'favorite', 'icon': Icons.favorite},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: icons.map((iconData) {
        final name = iconData['name'] as String;
        final icon = iconData['icon'] as IconData;
        final isSelected = _selectedIconName == name;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedIconName = name;
            });
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? _getColorFromHex(_selectedColorHex)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? _getColorFromHex(_selectedColorHex)
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        );
      }).toList(),
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
