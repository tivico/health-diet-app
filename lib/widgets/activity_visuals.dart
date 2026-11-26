import 'package:flutter/material.dart';

import '../domain/activity.dart';
import '../theme.dart';

/// 運動種類的圖示與顏色（清單、記錄頁共用，才不會各畫各的）。
IconData activityKindIcon(ActivityKind kind) => switch (kind) {
      ActivityKind.cardio => Icons.directions_run,
      ActivityKind.strength => Icons.fitness_center,
      ActivityKind.other => Icons.self_improvement,
    };

Color activityKindColor(BuildContext context, ActivityKind kind) {
  final palette = Theme.of(context).palette;
  return switch (kind) {
    ActivityKind.cardio => palette.breakfast,
    ActivityKind.strength => palette.dinner,
    ActivityKind.other => palette.carbs,
  };
}

/// 「11/22（六）」這種短日期。
String shortDateWithWeekday(DateTime d) {
  const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  return '${d.month}/${d.day}（${weekdays[d.weekday - 1]}）';
}
