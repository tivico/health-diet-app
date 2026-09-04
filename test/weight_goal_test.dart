import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/domain/weight_goal.dart';

/// 固定一份 plan，讓推估的算術可以手算驗證：
/// 每日目標 1700 − TDEE 2000 = −300 大卡/天
/// → 每週 −300 × 7 ÷ 7700 ≈ −0.2727 公斤
NutritionPlan planOf({double calorieTarget = 1700, double tdee = 2000}) =>
    NutritionPlan(
      bmr: 1400,
      tdee: tdee,
      calorieTarget: calorieTarget,
      macros: const Macros(proteinG: 100, fatG: 50, carbsG: 200),
      bmi: 22,
      bmiCategory: '健康體位',
      healthyWeightKg: (50.4, 65.3),
    );

UserProfile profileOf({double weightKg = 65, double? targetWeightKg}) =>
    UserProfile(
      sex: Sex.female,
      age: 28,
      heightCm: 165,
      weightKg: weightKg,
      activity: ActivityLevel.light,
      goal: Goal.lose,
      targetWeightKg: targetWeightKg,
    );

void main() {
  test('沒設定目標體重時不推估', () {
    expect(projectWeightGoal(profile: profileOf(), plan: planOf()), isNull);
  });

  test('赤字下推估週數與達成日期', () {
    final p = projectWeightGoal(
      profile: profileOf(weightKg: 65, targetWeightKg: 60),
      plan: planOf(),
      now: DateTime(2026, 9, 4),
    )!;

    expect(p.remainingKg, closeTo(-5, 0.001));
    expect(p.remainingAbsKg, closeTo(5, 0.001));
    expect(p.weeklyChangeKg, closeTo(-0.2727, 0.001));
    // 5 ÷ 0.2727 ≈ 18.3 → 進位成 19 週
    expect(p.weeksToTarget, 19);
    expect(p.estimatedDate, DateTime(2026, 9, 4).add(const Duration(days: 133)));
    expect(p.reached, isFalse);
    expect(p.directionMismatch, isFalse);
  });

  test('用最新體重紀錄覆蓋個人資料裡的體重', () {
    final p = projectWeightGoal(
      profile: profileOf(weightKg: 65, targetWeightKg: 60),
      plan: planOf(),
      currentWeightKg: 62, // 個人資料寫 65，但已經瘦到 62
    )!;
    expect(p.currentWeightKg, 62);
    // 還差的是「到目標」的 2 公斤，不是個人資料上的 5 公斤
    expect(p.remainingAbsKg, closeTo(2, 0.001));
  });

  test('差距在 0.5 公斤內視為已達成，不再推估時間', () {
    final p = projectWeightGoal(
      profile: profileOf(targetWeightKg: 60),
      plan: planOf(),
      currentWeightKg: 60.4,
    )!;
    expect(p.reached, isTrue);
    expect(p.weeksToTarget, isNull);
    expect(p.estimatedDate, isNull);
  });

  test('方向不符：想減重卻是熱量盈餘', () {
    final p = projectWeightGoal(
      profile: profileOf(weightKg: 65, targetWeightKg: 60),
      plan: planOf(calorieTarget: 2200), // 盈餘 +200
      currentWeightKg: 65,
    )!;
    expect(p.directionMismatch, isTrue);
    expect(p.weeksToTarget, isNull);
  });

  test('方向不符：維持熱量（沒有赤字也沒有盈餘）', () {
    final p = projectWeightGoal(
      profile: profileOf(weightKg: 65, targetWeightKg: 60),
      plan: planOf(calorieTarget: 2000), // 等於 TDEE
    )!;
    expect(p.weeklyChangeKg, 0);
    expect(p.directionMismatch, isTrue);
  });

  test('增重方向也能推估', () {
    final p = projectWeightGoal(
      profile: profileOf(weightKg: 50, targetWeightKg: 55),
      plan: planOf(calorieTarget: 2300), // 盈餘 +300 → 每週 +0.2727
      now: DateTime(2026, 9, 4),
    )!;
    expect(p.remainingKg, closeTo(5, 0.001));
    expect(p.weeklyChangeKg, closeTo(0.2727, 0.001));
    expect(p.weeksToTarget, 19);
  });

  group('健康體重區間提醒', () {
    // 165 cm 的健康體重區間為 50.4–65.3 公斤
    test('目標低於區間 → 明確勸阻', () {
      final p = projectWeightGoal(
        profile: profileOf(targetWeightKg: 45),
        plan: planOf(),
      )!;
      expect(p.warning, isNotNull);
      expect(p.warning, contains('低於'));
      expect(p.warning, contains('50.4–65.3'));
    });

    test('目標高於區間 → 中性提醒（增肌未必是問題）', () {
      final p = projectWeightGoal(
        profile: profileOf(targetWeightKg: 70),
        plan: planOf(),
      )!;
      expect(p.warning, contains('高於'));
      expect(p.warning, contains('肌肉'));
    });

    test('目標在區間內 → 沒有提醒', () {
      final p = projectWeightGoal(
        profile: profileOf(targetWeightKg: 58),
        plan: planOf(),
      )!;
      expect(p.warning, isNull);
    });
  });

  group('weightGoalProgress', () {
    test('走完一半就是 50%', () {
      expect(weightGoalProgress(startKg: 70, currentKg: 65, targetKg: 60),
          closeTo(0.5, 0.001));
    });

    test('達標或超過都是 100%', () {
      expect(weightGoalProgress(startKg: 70, currentKg: 60, targetKg: 60), 1.0);
      expect(weightGoalProgress(startKg: 70, currentKg: 58, targetKg: 60), 1.0);
    });

    test('往反方向走夾成 0，不會出現負進度', () {
      expect(weightGoalProgress(startKg: 70, currentKg: 72, targetKg: 60), 0.0);
    });

    test('起點等於目標時無從計算', () {
      expect(weightGoalProgress(startKg: 60, currentKg: 60, targetKg: 60),
          isNull);
    });
  });

  test('目標體重超出合理範圍會被擋下', () {
    expect(() => profileOf(targetWeightKg: 0), throwsArgumentError);
    expect(() => profileOf(targetWeightKg: 500), throwsArgumentError);
  });
}
