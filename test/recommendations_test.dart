import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/domain/recommendations.dart';

UserProfile make({
  double weightKg = 60,
  Goal goal = Goal.lose,
  ActivityLevel activity = ActivityLevel.light,
  Sex sex = Sex.female,
}) =>
    UserProfile(
      sex: sex,
      age: 28,
      heightCm: 165,
      weightKg: weightKg,
      activity: activity,
      goal: goal,
    );

void main() {
  test('產生五個建議區塊、每塊都有內容', () {
    final p = make();
    final sections = buildAdvice(p, nutritionPlan(p));
    expect(
      sections.map((s) => s.title).toList(),
      ['你的重點', '怎麼吃', '怎麼動', '喝水', '睡覺'],
    );
    for (final s in sections) {
      expect(s.headline, isNotEmpty);
      expect(s.points, isNotEmpty);
    }
  });

  test('喝水建議隨體重不同', () {
    String water(double kg) =>
        buildAdvice(make(weightKg: kg), nutritionPlan(make(weightKg: kg)))
            .firstWhere((s) => s.title == '喝水')
            .headline;
    expect(water(50) == water(90), isFalse);
  });

  test('不同目標給不同運動建議', () {
    List<String> exercise(Goal g) =>
        buildAdvice(make(goal: g), nutritionPlan(make(goal: g)))
            .firstWhere((s) => s.title == '怎麼動')
            .points;
    expect(exercise(Goal.lose).join() == exercise(Goal.gain).join(), isFalse);
  });
}
