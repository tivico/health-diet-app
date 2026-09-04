/// 期間統計：把餐點與體重紀錄整理成「這週 / 這個月過得如何」的摘要。
///
/// 純函式、不依賴 UI 或資料庫（輸入是已整理好的 Map），方便單元測試。
/// 呼應衛教內容的核心觀念：看「週趨勢」，而不是被單日數字綁架。
library;

/// 某一天的攝取熱量（該日沒有紀錄時為 0）。
class DailyIntake {
  final DateTime day;
  final double calories;

  const DailyIntake({required this.day, required this.calories});

  bool get hasRecord => calories > 0;
}

/// 一段期間的統計摘要。
class PeriodSummary {
  /// 期間內每一天（由舊到新），沒紀錄的日子熱量為 0 —— 圖表才不會斷掉。
  final List<DailyIntake> days;

  /// 「有紀錄」日子的平均攝取熱量；完全沒紀錄時為 0。
  final double averageCalories;

  /// 有記錄餐點的天數。
  final int daysWithRecords;

  /// 落在每日目標 ±容許範圍內的天數。
  final int daysOnTarget;

  /// 期間體重變化（最後一筆 − 第一筆）；不足兩筆紀錄時為 null。
  final double? weightChangeKg;
  final double? weightStartKg;
  final double? weightEndKg;

  const PeriodSummary({
    required this.days,
    required this.averageCalories,
    required this.daysWithRecords,
    required this.daysOnTarget,
    this.weightChangeKg,
    this.weightStartKg,
    this.weightEndKg,
  });

  /// 期間內單日最高攝取（給圖表決定 Y 軸上限用）。
  double get maxCalories =>
      days.isEmpty ? 0 : days.map((d) => d.calories).reduce((a, b) => a > b ? a : b);
}

/// 建立期間摘要。
///
/// [caloriesByDay] / [weightByDay] 的 key 必須是「只有年月日」的 DateTime。
/// [toleranceRatio] 預設 0.1，即落在目標 ±10% 內算達標。
PeriodSummary buildPeriodSummary({
  required DateTime from,
  required DateTime to,
  required Map<DateTime, double> caloriesByDay,
  required Map<DateTime, double> weightByDay,
  required double calorieTarget,
  double toleranceRatio = 0.1,
}) {
  final start = dateOnly(from);
  final end = dateOnly(to);

  // 補齊期間內每一天（沒紀錄的補 0）
  final days = <DailyIntake>[];
  var cursor = start;
  while (!cursor.isAfter(end)) {
    days.add(DailyIntake(day: cursor, calories: caloriesByDay[cursor] ?? 0));
    cursor = cursor.add(const Duration(days: 1));
  }

  final recorded = days.where((d) => d.hasRecord).toList();
  final average = recorded.isEmpty
      ? 0.0
      : recorded.map((d) => d.calories).reduce((a, b) => a + b) /
          recorded.length;

  final tolerance = calorieTarget * toleranceRatio;
  final onTarget = recorded
      .where((d) => (d.calories - calorieTarget).abs() <= tolerance)
      .length;

  // 體重：取期間內有紀錄的第一筆與最後一筆
  final weightDays = weightByDay.keys
      .where((d) => !d.isBefore(start) && !d.isAfter(end))
      .toList()
    ..sort();

  double? startKg, endKg, change;
  if (weightDays.isNotEmpty) {
    startKg = weightByDay[weightDays.first];
    endKg = weightByDay[weightDays.last];
    if (weightDays.length >= 2 && startKg != null && endKg != null) {
      change = endKg - startKg;
    }
  }

  return PeriodSummary(
    days: days,
    averageCalories: average,
    daysWithRecords: recorded.length,
    daysOnTarget: onTarget,
    weightChangeKg: change,
    weightStartKg: startKg,
    weightEndKg: endKg,
  );
}

/// 去掉時分秒，只留年月日（Map 的 key 需要一致的比較基準）。
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
