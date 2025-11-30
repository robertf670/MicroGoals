class GoalProgress {
  final int? id;
  final int goalId;
  final double progressValue;
  final double progressPercentage;
  final DateTime recordedAt;

  GoalProgress({
    this.id,
    required this.goalId,
    required this.progressValue,
    required this.progressPercentage,
    required this.recordedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'progress_value': progressValue,
      'progress_percentage': progressPercentage,
      'recorded_at': recordedAt.millisecondsSinceEpoch,
    };
  }

  factory GoalProgress.fromMap(Map<String, dynamic> map) {
    return GoalProgress(
      id: map['id'],
      goalId: map['goal_id'],
      progressValue: map['progress_value']?.toDouble() ?? 0.0,
      progressPercentage: map['progress_percentage']?.toDouble() ?? 0.0,
      recordedAt: DateTime.fromMillisecondsSinceEpoch(map['recorded_at']),
    );
  }
}

