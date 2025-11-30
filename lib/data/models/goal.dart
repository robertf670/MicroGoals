class Goal {
  final int? id;
  final String title;
  final String? description;
  final double targetValue;  // Numeric target (e.g., 300 pages)
  final double currentValue;  // Current progress
  final String? unit;  // Optional unit (e.g., "pages", "km", "%")
  final String? iconName;  // Custom icon (premium)
  final String? colorHex;  // Custom color (premium)
  final DateTime? dueDate;  // Optional due date
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Goal({
    this.id,
    required this.title,
    this.description,
    required this.targetValue,
    this.currentValue = 0.0,
    this.unit,
    this.iconName,
    this.colorHex,
    this.dueDate,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate progress percentage
  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    final percentage = (currentValue / targetValue) * 100;
    return percentage.clamp(0.0, 100.0);
  }

  // Check if goal is completed
  bool get isGoalCompleted => currentValue >= targetValue;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'target_value': targetValue,
      'current_value': currentValue,
      'unit': unit,
      'icon_name': iconName,
      'color_hex': colorHex,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      targetValue: map['target_value']?.toDouble() ?? 0.0,
      currentValue: map['current_value']?.toDouble() ?? 0.0,
      unit: map['unit'],
      iconName: map['icon_name'],
      colorHex: map['color_hex'],
      dueDate: map['due_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['due_date'])
          : null,
      isCompleted: map['is_completed'] == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  Goal copyWith({
    int? id,
    String? title,
    String? description,
    double? targetValue,
    double? currentValue,
    String? unit,
    String? iconName,
    String? colorHex,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

