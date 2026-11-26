import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/activity.dart';

// 以下都是虛構的測試資料。
Activity _a(
  DateTime at,
  ActivityKind kind, {
  int minutes = 30,
  String? title,
  List<ExerciseSet> sets = const [],
  int? id,
}) =>
    Activity(
      id: id,
      startedAt: at,
      kind: kind,
      title: title,
      duration: Duration(minutes: minutes),
      sets: sets,
    );

void main() {
  group('時間的輸入與顯示', () {
    test('照手錶的寫法解析', () {
      expect(parseClock('31:49'), const Duration(minutes: 31, seconds: 49));
      expect(parseClock('1:00:53'), const Duration(hours: 1, seconds: 53));
      expect(parseClock('45'), const Duration(minutes: 45));
      expect(parseClock(' 21:06 '), const Duration(minutes: 21, seconds: 6));
    });

    test('格式不對回傳 null', () {
      for (final bad in ['', '31:60', '1:60:00', 'abc', '-5', '1:2:3:4', '31:']) {
        expect(parseClock(bad), isNull, reason: '「$bad」');
      }
    });

    test('顯示成手錶的樣子', () {
      expect(formatClock(const Duration(minutes: 31, seconds: 49)), '31:49');
      expect(formatClock(const Duration(hours: 1, seconds: 53)), '1:00:53');
      expect(formatClock(const Duration(minutes: 5, seconds: 3)), '5:03');
      expect(formatMinutes(const Duration(minutes: 45)), '45 分');
      expect(formatMinutes(const Duration(hours: 2, minutes: 5)), '2 小時 5 分');
    });
  });

  group('每週摘要', () {
    test('一週從週一開始；只算這一週的', () {
      // 2026-03-04 是週三 → 那週是 3/2（一）到 3/8（日）
      expect(weekStartOf(DateTime(2026, 3, 4, 20)), DateTime(2026, 3, 2));
      expect(weekStartOf(DateTime(2026, 3, 8, 23)), DateTime(2026, 3, 2));

      final list = [
        _a(DateTime(2026, 3, 1, 23), ActivityKind.cardio), // 上週日
        _a(DateTime(2026, 3, 2, 7), ActivityKind.cardio, minutes: 40),
        _a(DateTime(2026, 3, 5, 18), ActivityKind.strength, minutes: 35),
        _a(DateTime(2026, 3, 8, 21), ActivityKind.cardio),
        _a(DateTime(2026, 3, 9, 6), ActivityKind.other), // 下週一
      ];
      final s = summarizeWeek(list, DateTime(2026, 3, 4));
      expect(s.sessions, 3);
      expect(s.describeCounts(), '有氧 2 次、肌力 1 次');
      expect(s.total, const Duration(minutes: 105));
    });

    test('沒運動的週', () {
      final s = summarizeWeek(const [], DateTime(2026, 3, 4));
      expect(s.sessions, 0);
      expect(s.describeCounts(), '');
    });
  });

  group('器材的進步紀錄', () {
    test('同一台器材的歷次紀錄，由舊到新', () {
      final list = [
        _a(DateTime(2026, 3, 16), ActivityKind.strength, sets: const [
          ExerciseSet(exerciseId: 1, weight: 25, reps: 10, sets: 3),
          ExerciseSet(exerciseId: 2, weight: 10),
        ]),
        _a(DateTime(2026, 3, 2), ActivityKind.strength, sets: const [
          ExerciseSet(exerciseId: 1, weight: 20, reps: 10, sets: 3),
        ]),
        _a(DateTime(2026, 3, 9), ActivityKind.cardio),
      ];
      expect([for (final r in historyOf(1, list)) r.set.weight], [20, 25]);
      expect(historyOf(3, list), isEmpty);
    });

    test('動作的文字說明：沒填的部分略過', () {
      expect(
        describeExerciseSet(
            const ExerciseSet(exerciseId: 1, weight: 18, reps: 10, sets: 3),
            WeightUnit.kg),
        '18 kg × 10 下 × 3 組',
      );
      expect(
        describeExerciseSet(
            const ExerciseSet(exerciseId: 1, weight: 22.5, reps: 8),
            WeightUnit.lb),
        '22.5 lb × 8 下',
      );
      expect(
        describeExerciseSet(
            const ExerciseSet(exerciseId: 1, reps: 15, sets: 2), WeightUnit.kg),
        '15 下 × 2 組',
      );
    });

    test('磅換公斤', () {
      expect(WeightUnit.lb.toKg(10), closeTo(4.536, 0.001));
      expect(WeightUnit.kg.toKg(10), 10);
    });
  });

  group('快速填寫', () {
    test('複製上次：最近一次有記動作的肌力訓練，排除正在修改的那筆', () {
      final older = _a(DateTime(2026, 3, 2), ActivityKind.strength,
          id: 1, sets: const [ExerciseSet(exerciseId: 1)]);
      final newer = _a(DateTime(2026, 3, 9), ActivityKind.strength,
          id: 2, sets: const [ExerciseSet(exerciseId: 1)]);
      final noSets = _a(DateTime(2026, 3, 12), ActivityKind.strength, id: 3);
      final cardio = _a(DateTime(2026, 3, 13), ActivityKind.cardio, id: 4);
      final list = [older, newer, noSets, cardio];

      expect(lastStrengthSession(list)!.id, 2);
      expect(lastStrengthSession(list, excludeId: 2)!.id, 1);
      expect(lastStrengthSession([cardio]), isNull);
    });

    test('最近用過的名稱：新到舊、不重複', () {
      final list = [
        _a(DateTime(2026, 3, 2), ActivityKind.cardio, title: '慢跑'),
        _a(DateTime(2026, 3, 5), ActivityKind.strength, title: '健身房'),
        _a(DateTime(2026, 3, 9), ActivityKind.cardio, title: '慢跑'),
        _a(DateTime(2026, 3, 10), ActivityKind.other),
      ];
      expect([for (final a in recentTitled(list)) a.title], ['慢跑', '健身房']);
    });
  });
}
