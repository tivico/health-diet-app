import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/activity.dart';
import 'package:health/domain/body_composition.dart';
import 'package:health/domain/meal_type.dart';
import 'package:health/domain/recomp.dart';

// 以下都是虛構的測試資料。
BodyComposition _b(DateTime day, double weight,
        {double? fat, double? bodyFat, double? skeletal, double? muscle}) =>
    BodyComposition(day: day, values: {
      BodyMetric.weight: weight,
      BodyMetric.fatMass: ?fat,
      BodyMetric.bodyFat: ?bodyFat,
      BodyMetric.skeletalMuscle: ?skeletal,
      BodyMetric.muscleMass: ?muscle,
    });

void main() {
  group('脂肪量與肌肉指標', () {
    test('脂肪量：有量用量的，沒量就用體重 × 體脂率推算', () {
      expect(fatMassOf(_b(DateTime(2026, 3, 2), 70, fat: 17.5)), 17.5);
      expect(fatMassOf(_b(DateTime(2026, 3, 2), 70, bodyFat: 25)), 17.5);
      expect(fatMassOf(_b(DateTime(2026, 3, 2), 70)), isNull);
    });

    test('肌肉：兩次都有骨骼肌就用骨骼肌，否則用肌肉量', () {
      final a = _b(DateTime(2026, 3, 2), 70, skeletal: 30, muscle: 50);
      final b = _b(DateTime(2026, 3, 30), 70, skeletal: 31, muscle: 51);
      final c = _b(DateTime(2026, 4, 6), 70, muscle: 52);
      expect(muscleMetricOf(a, b), BodyMetric.skeletalMuscle);
      expect(muscleMetricOf(b, c), BodyMetric.muscleMass);
      expect(muscleMetricOf(c, _b(DateTime(2026, 4, 9), 70)), isNull);
    });
  });

  group('判讀：0.5 公斤以內算看不出變化', () {
    String title(double? fat, double? muscle) =>
        judgeRecomp(fatDelta: fat, muscleDelta: muscle).title;

    test('脂肪 × 肌肉的九種組合', () {
      expect(title(-1.0, 0.8), '增肌減脂');
      expect(title(-1.0, 0.2), '減脂，肌肉保住了');
      expect(title(-1.0, -0.8), '減脂中，但肌肉也在減少');
      expect(title(0.3, 0.8), '肌肉增加');
      expect(title(0.3, -0.2), '大致維持');
      expect(title(0.1, -0.8), '肌肉減少');
      expect(title(1.0, 0.8), '肌肉和脂肪都增加');
      expect(title(1.0, 0.0), '脂肪增加');
      expect(title(1.0, -0.8), '脂肪增加、肌肉減少');
    });

    test('剛好 0.5 公斤還算在誤差內', () {
      expect(title(-0.5, 0.5), '大致維持');
    });

    test('沒有肌肉資料：只看脂肪；連脂肪都沒有就說分不出來', () {
      expect(title(-1.0, null), '脂肪減少');
      expect(title(1.0, null), '脂肪增加');
      expect(title(0.2, null), '脂肪大致持平');
      expect(title(null, 0.8), '還分不出來');
    });

    test('語氣：好的方向、需要留意、中性', () {
      expect(judgeRecomp(fatDelta: -1, muscleDelta: 1).tone, Tone.good);
      expect(judgeRecomp(fatDelta: -1, muscleDelta: -1).tone, Tone.caution);
      expect(judgeRecomp(fatDelta: 0, muscleDelta: 0).tone, Tone.neutral);
    });
  });

  group('期間內的體組成變化', () {
    final list = [
      _b(DateTime(2026, 1, 5), 73.0, fat: 19.0, skeletal: 30.0),
      _b(DateTime(2026, 3, 2), 72.4, fat: 18.5, skeletal: 30.2),
      _b(DateTime(2026, 3, 16), 72.1, bodyFat: 25, skeletal: 30.5),
      _b(DateTime(2026, 3, 30), 72.0, fat: 17.4, skeletal: 30.9),
    ];

    test('只比期間內第一次和最後一次', () {
      final c = bodyChangeSince(list, DateTime(2026, 3, 1))!;
      expect(c.first.day, DateTime(2026, 3, 2));
      expect(c.last.day, DateTime(2026, 3, 30));
      expect(c.count, 3);
      expect(c.days, 28);
      expect(c.weightDelta, closeTo(-0.4, 1e-9));
      expect(c.fatDelta, closeTo(-1.1, 1e-9));
      expect(c.nonFatDelta, closeTo(0.7, 1e-9));
      expect(c.muscleMetric, BodyMetric.skeletalMuscle);
      expect(c.muscleDelta, closeTo(0.7, 1e-9));
      expect(c.fatEstimated, isFalse);
      expect(c.verdict.title, '增肌減脂');
    });

    test('有一端的脂肪量是推算的，會標出來', () {
      final c = bodyChangeSince(list.sublist(0, 3), DateTime(2026, 3, 1))!;
      expect(c.fatEstimated, isTrue);
      expect(c.fatDelta, closeTo(72.1 * 0.25 - 18.5, 1e-9));
    });

    test('期間內不到兩次就沒得比', () {
      expect(bodyChangeSince(list, DateTime(2026, 3, 20)), isNull);
      expect(bodyChangeSince(const [], DateTime(2026, 1, 1)), isNull);
    });
  });

  group('訓練摘要', () {
    Activity a(DateTime at, ActivityKind kind, [List<ExerciseSet> sets = const []]) =>
        Activity(
            startedAt: at,
            kind: kind,
            duration: const Duration(minutes: 30),
            sets: sets);

    final list = [
      a(DateTime(2026, 2, 20), ActivityKind.strength,
          const [ExerciseSet(exerciseId: 1, weight: 18)]), // 期間外
      a(DateTime(2026, 3, 3), ActivityKind.strength,
          const [ExerciseSet(exerciseId: 1, weight: 20, reps: 10, sets: 3)]),
      a(DateTime(2026, 3, 5), ActivityKind.cardio),
      a(DateTime(2026, 3, 12), ActivityKind.cardio),
      a(DateTime(2026, 3, 24), ActivityKind.strength, const [
        ExerciseSet(exerciseId: 1, weight: 22.5, reps: 10, sets: 3),
        ExerciseSet(exerciseId: 2, weight: 25),
      ]),
    ];

    test('只算期間內的；週數不足一週算一週', () {
      final t = summarizeTraining(list,
          from: DateTime(2026, 3, 2), to: DateTime(2026, 3, 29));
      expect(t.weeks, 4);
      expect(t.sessions, 4);
      expect(t.counts[ActivityKind.strength], 2);
      expect(t.perWeek(ActivityKind.cardio), 0.5);
      expect(t.sessionsPerWeek, 1.0);
      expect(t.total, const Duration(minutes: 120));

      final shortPeriod = summarizeTraining(list,
          from: DateTime(2026, 3, 2), to: DateTime(2026, 3, 11));
      expect(shortPeriod.weeks, 2, reason: '10 天算 2 週');
    });

    test('器材：期間內第一次 → 最近一次（期間外的不算）', () {
      final t = summarizeTraining(list,
          from: DateTime(2026, 3, 2), to: DateTime(2026, 3, 29));
      final rower = t.progress.firstWhere((p) => p.exerciseId == 1);
      expect(rower.first.set.weight, 20);
      expect(rower.last.set.weight, 22.5);
      expect(rower.records, 2);
      expect(rower.weightDelta, 2.5);
      final press = t.progress.firstWhere((p) => p.exerciseId == 2);
      expect(press.records, 1);
    });
  });

  group('飲食摘要', () {
    MealFact m(DateTime at, double kcal, double protein, MealType? type) =>
        (eatenAt: at, calories: kcal, proteinG: protein, type: type);

    final meals = [
      m(DateTime(2026, 3, 1, 12), 900, 50, MealType.lunch), // 期間外
      m(DateTime(2026, 3, 2, 8), 400, 20, MealType.breakfast),
      m(DateTime(2026, 3, 2, 12), 700, 35, MealType.lunch),
      m(DateTime(2026, 3, 3, 19), 600, 30, MealType.dinner),
      m(DateTime(2026, 3, 3, 15), 300, 5, MealType.snack),
    ];

    test('平均只算有記錄的日子；各餐蛋白質是平均每天', () {
      final d = summarizeDiet(meals,
          from: DateTime(2026, 3, 2), to: DateTime(2026, 3, 8));
      expect(d.loggedDays, 2);
      expect(d.totalDays, 7);
      expect(d.avgCalories, 1000);
      expect(d.avgProtein, 45);
      expect(d.proteinByMeal[MealType.breakfast], 10);
      expect(d.proteinByMeal[MealType.lunch], 17.5);
      expect(d.coverage, closeTo(2 / 7, 1e-9));
    });

    test('沒有紀錄', () {
      final d = summarizeDiet(const [],
          from: DateTime(2026, 3, 2), to: DateTime(2026, 3, 8));
      expect(d.hasData, isFalse);
      expect(d.avgProtein, 0);
    });
  });
}
