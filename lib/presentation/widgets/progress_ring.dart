import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  final double progress;  // 0.0 to 1.0
  final Color color;
  final double size;
  final double strokeWidth;
  final String? centerText;

  const ProgressRing({
    super.key,
    required this.progress,
    required this.color,
    this.size = 100.0,
    this.strokeWidth = 8.0,
    this.centerText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(color.withValues(alpha: 0.2)),
            ),
          ),
          // Progress circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          // Center text
          if (centerText != null)
            Padding(
              padding: EdgeInsets.all(strokeWidth + 4),
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(
                  centerText!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
