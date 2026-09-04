import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/stats.dart';

void main() {
  final from = DateTime(2026, 9, 1);
  final to = DateTime(2026, 9, 7);

  test('補齊期間內每一天（沒紀錄的補 0）', () {
    final s = buildPeriodSummary(
      from: from,
      to: to,
      caloriesByDay: {DateTime(2026, 9, 3): 1800},
      weightByDay: const {},
      calorieTarget: 1800,
    );
    expect(s.days.length, 7);
    expect(s.days.first.day, DateTime(2026, 9, 1));
    expect(s.days.last.day, DateTime(2026, 9, 7));
    expect(s.days[2].calories, 1800);
    expect(s.days[0].calories, 0);
    expect(s.daysWithRecords, 1);
  });

  test('平均只計算「有記錄」的日子', () {
    final s = buildPeriodSummary(
      from: from,
      to: to,
      caloriesByDay: {
        DateTime(2026, 9, 1): 1000,
        DateTime(2026, 9, 2): 2000,
      },
      weightByDay: const {},
      calorieTarget: 1800,
    );
    expect(s.daysWithRecords, 2);
    // 是 (1000+2000)/2 = 1500，不是除以 7 天
    expect(s.averageCalories, 1500);
  });

  test('達標天數以目標 ±10% 判定', () {
    final s = buildPeriodSummary(
      from: from,
      to: to,
      caloriesByDay: {
        DateTime(2026, 9, 1): 1800, // 剛好 → 達標
        DateTime(2026, 9, 2): 1900, // +5.6% → 達標
        DateTime(2026, 9, 3): 2100, // +16.7% → 未達標
        DateTime(2026, 9, 4): 1500, // −16.7% → 未達標
      },
      weightByDay: const {},
      calorieTarget: 1800,
    );
    expect(s.daysOnTarget, 2);
  });

  test('體重變化取期間內第一筆與最後一筆', () {
    final s = buildPeriodSummary(
      from: from,
      to: to,
      caloriesByDay: const {},
      weightByDay: {
        DateTime(2026, 9, 2): 60.0,
        DateTime(2026, 9, 6): 59.2,
      },
      calorieTarget: 1800,
    );
    expect(s.weightStartKg, 60.0);
    expect(s.weightEndKg, 59.2);
    expect(s.weightChangeKg, closeTo(-0.8, 0.001));
  });

  test('只有一筆體重時不計算變化', () {
    final s = buildPeriodSummary(
      from: from,
      to: to,
      caloriesByDay: const {},
      weightByDay: {DateTime(2026, 9, 2): 60.0},
      calorieTarget: 1800,
    );
    expect(s.weightChangeKg, isNull);
    expect(s.weightStartKg, 60.0);
  });

  test('期間外的體重不列入計算', () {
    final s = buildPeriodSummary(
      from: from,
      to: to,
      caloriesByDay: const {},
      weightByDay: {
        DateTime(2026, 8, 20): 65.0, // 期間之前
        DateTime(2026, 9, 3): 60.0,
      },
      calorieTarget: 1800,
    );
    expect(s.weightStartKg, 60.0);
    expect(s.weightChangeKg, isNull); // 期間內只有一筆
  });
}
