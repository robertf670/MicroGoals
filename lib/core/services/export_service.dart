import 'dart:convert';
import '../../data/models/goal.dart';
import '../../data/models/goal_progress.dart';
import '../utils/logger.dart';

class ExportService {
  static final ExportService instance = ExportService._init();
  ExportService._init();

  Future<String> exportToCsvString(
    List<Goal> goals,
    Map<int, List<GoalProgress>> progressHistory,
  ) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Date,Goal,Progress Value,Progress Percentage');
      
      for (final goal in goals) {
        final history = progressHistory[goal.id] ?? [];
        if (history.isEmpty) {
          // If no history, export current state
          final date = goal.updatedAt;
          buffer.writeln(
            '${_formatDate(date)},'
            '"${_escapeCsv(goal.title)}",'
            '${goal.currentValue},'
            '${goal.progressPercentage.toStringAsFixed(2)}',
          );
        } else {
          // Export all history entries
          for (final progress in history) {
            buffer.writeln(
              '${_formatDate(progress.recordedAt)},'
              '"${_escapeCsv(goal.title)}",'
              '${progress.progressValue},'
              '${progress.progressPercentage.toStringAsFixed(2)}',
            );
          }
        }
      }
      
      Logger.info('Generated CSV export for ${goals.length} goals');
      return buffer.toString();
    } catch (e, stackTrace) {
      Logger.error('Failed to generate CSV', e, stackTrace);
      rethrow;
    }
  }

  Future<String> exportToJsonString(
    List<Goal> goals,
    Map<int, List<GoalProgress>> progressHistory,
    Map<int, List<Map<String, dynamic>>> milestones,
  ) async {
    try {
      final jsonData = {
        'version': '1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'goals': goals.map((g) => g.toMap()).toList(),
        'progress_history': progressHistory.map((key, value) => 
          MapEntry(key.toString(), value.map((p) => p.toMap()).toList())
        ),
        'milestones': milestones.map((key, value) => 
          MapEntry(key.toString(), value)
        ),
      };
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
      Logger.info('Generated JSON export for ${goals.length} goals');
      return jsonString;
    } catch (e, stackTrace) {
      Logger.error('Failed to generate JSON', e, stackTrace);
      rethrow;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  String _escapeCsv(String text) {
    return text.replaceAll('"', '""');
  }
}

