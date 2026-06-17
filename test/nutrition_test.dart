import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/nutrition.dart';

UserProfile make({
  Sex sex = Sex.male,
  int age = 30,
  double heightCm = 180,
  double weightKg = 80,
  ActivityLevel activity = ActivityLevel.moderate,
  Goal goal = Goal.maintain,
  double? bodyFatPct,
}) {
  return UserProfile(
    sex: sex,
    age: age,
    heightCm: heightCm,
    weightKg: weightKg,
    activity: activity,
    goal: goal,
    bodyFatPct: bodyFatPct,
  );
}

void main() {
  group('BMR', () {
    test('Mifflin-St Jeor 男性', () {
      // 10*80 + 6.25*180 - 5*30 + 5 = 1780
      expect(bmrMifflinStJeor(make()), closeTo(1780.0, 0.01));
    });

    test('Mifflin-St Jeor 女性', () {
      final p = make(sex: Sex.female, heightCm: 165, weightKg: 60);
      // 10*60 + 6.25*165 - 5*30 - 161 = 1320.25
      expect(bmrMifflinStJeor(p), closeTo(1320.25, 0.01));
    });

    test('有體脂時改用 Katch-McArdle', () {
      final p = make(weightKg: 80, bodyFatPct: 20);
      // 除脂體重 64kg -> 370 + 21.6*64 = 1752.4
      expect(bmr(p), closeTo(1752.4, 0.01));
    });

    test('Katch-McArdle 缺體脂應丟例外', () {
      expect(() => bmrKatchMcArdle(make()), throwsArgumentError);
    });
  });

  group('TDEE 與熱量目標', () {
    test('套用活動係數', () {
      expect(tdee(make()), closeTo(1780.0 * 1.55, 0.01));
    });

    test('減脂扣 15%', () {
      final p = make(goal: Goal.lose);
      expect(dailyCalorieTarget(p), closeTo(1780.0 * 1.55 * 0.85, 0.01));
    });

    test('低於安全下限時改用下限，並附安全提醒', () {
      final p = make(
        sex: Sex.female,
        age: 25,
        heightCm: 150,
        weightKg: 45,
        activity: ActivityLevel.sedentary,
        goal: Goal.lose,
      );
      expect(dailyCalorieTarget(p), kAbsoluteMinCalories[Sex.female]);
      expect(nutritionPlan(p).safetyNote, isNotNull);
    });
  });

  group('三大營養素', () {
    test('熱量加總吻合目標', () {
      final m = macroTargets(make(), 2400);
      expect(m.calories, closeTo(2400, 1.0));
    });

    test('減脂時蛋白質較高', () {
      final cut = macroTargets(make(goal: Goal.lose), 2000).proteinG;
      final maintain = macroTargets(make(goal: Goal.maintain), 2000).proteinG;
      expect(cut, greaterThan(maintain));
    });
  });

  group('BMI 與健康體重', () {
    test('BMI 數值與台灣分級', () {
      final p = make(sex: Sex.female, heightCm: 165, weightKg: 60);
      expect(bmi(p), closeTo(22.04, 0.01));
      expect(bmiCategoryTaiwan(18.4), '過輕');
      expect(bmiCategoryTaiwan(22), '健康體位');
      expect(bmiCategoryTaiwan(25), '過重');
      expect(bmiCategoryTaiwan(28), '肥胖');
    });

    test('健康體重區間', () {
      final (low, high) = healthyWeightRangeKg(165);
      expect(low, closeTo(50.4, 0.1));
      expect(high, closeTo(65.3, 0.1));
    });
  });

  group('資料驗證', () {
    test('拒絕不合理輸入', () {
      expect(() => make(age: 0), throwsArgumentError);
      expect(() => make(bodyFatPct: 90), throwsArgumentError);
    });
  });

  test('完整計畫欄位齊全', () {
    final plan = nutritionPlan(make(goal: Goal.lose, bodyFatPct: 18));
    expect(plan.bmr, greaterThan(0));
    expect(plan.tdee, greaterThan(plan.bmr));
    expect(plan.calorieTarget, greaterThan(0));
    expect(plan.macros.proteinG, greaterThan(0));
    expect(['過輕', '健康體位', '過重', '肥胖'], contains(plan.bmiCategory));
  });
}
