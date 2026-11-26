import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/activity.dart';
import 'package:health/domain/body_composition.dart';
import 'package:health/domain/meal_type.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/main.dart';
import 'package:health/providers.dart';

import 'fake_repository.dart';

// 以下都是虛構的測試資料。
final _now = DateTime.now();
final _today = DateTime(_now.year, _now.month, _now.day);
DateTime _daysAgo(int n, [int hour = 8]) =>
    DateTime(_today.year, _today.month, _today.day - n, hour);

FakeHealthRepository _fake() => FakeHealthRepository(
      UserProfile(
        sex: Sex.male,
        age: 35,
        heightCm: 175,
        weightKg: 72,
        activity: ActivityLevel.light,
        goal: Goal.lose,
      ),
    );

Future<void> _measure(FakeHealthRepository fake, int daysAgo, double weight,
        double fat, double skeletal) =>
    fake.upsertBodyComposition(BodyComposition(
      day: _daysAgo(daysAgo),
      values: {
        BodyMetric.weight: weight,
        BodyMetric.fatMass: fat,
        BodyMetric.skeletalMuscle: skeletal,
      },
    ));

Future<void> _openRecomp(WidgetTester tester, FakeHealthRepository fake) async {
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [repositoryProvider.overrideWithValue(fake)],
      child: const HealthApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('統計'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(Tab, '增肌減脂'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('還沒有體組成：提示要兩次量測，可以直接去記錄', (tester) async {
    await _openRecomp(tester, _fake());

    expect(find.text('這段期間還沒有體組成量測。'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '記錄體組成'), findsOneWidget);
    expect(find.textContaining('這段期間沒有運動紀錄'), findsOneWidget);
    expect(find.text('這段期間沒有餐點紀錄。'), findsOneWidget);
  });

  testWidgets('兩次量測：判讀增肌減脂，拆解體重變化，畫出趨勢', (tester) async {
    final fake = _fake();
    await _measure(fake, 20, 72.4, 18.5, 30.2);
    await _measure(fake, 2, 72.0, 17.4, 30.9);
    await _openRecomp(tester, fake);

    expect(find.textContaining('這就是體態重組'), findsOneWidget);
    expect(find.text('體重 −0.4 kg ＝ 脂肪 −1.1 ＋ 非脂肪 +0.7（肌肉、水分、肝醣等）'),
        findsOneWidget);
    expect(find.textContaining('只有兩次量測'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('訓練與飲食：每週頻率、器材重量變化、蛋白質每公斤幾克', (tester) async {
    final fake = _fake();
    final rower = await fake
        .saveExercise(const Exercise(name: '划船機 A', unit: WeightUnit.kg));
    for (final (daysAgo, weight) in [(20, 20.0), (6, 22.5)]) {
      await fake.saveActivity(Activity(
        startedAt: _daysAgo(daysAgo, 18),
        kind: ActivityKind.strength,
        duration: const Duration(minutes: 30),
        sets: [ExerciseSet(exerciseId: rower, weight: weight, reps: 10, sets: 3)],
      ));
    }
    for (final daysAgo in [15, 3]) {
      await fake.saveActivity(Activity(
        startedAt: _daysAgo(daysAgo, 7),
        kind: ActivityKind.cardio,
        duration: const Duration(minutes: 30),
      ));
    }
    // 相隔 20 天的兩天餐點：每天蛋白質 108 g → 108 / 72 kg = 1.5 g/kg
    for (final daysAgo in [20, 1]) {
      await fake.addMeal(
        eatenAt: _daysAgo(daysAgo, 8),
        name: '早餐',
        calories: 500,
        proteinG: 30,
        fatG: 15,
        carbsG: 60,
        mealType: MealType.breakfast,
      );
      await fake.addMeal(
        eatenAt: _daysAgo(daysAgo, 12),
        name: '午餐',
        calories: 900,
        proteinG: 78,
        fatG: 30,
        carbsG: 100,
        mealType: MealType.lunch,
      );
    }
    await _openRecomp(tester, fake);
    await tester.tap(find.text('4 週'));
    await tester.pumpAndSettle();

    // 訓練：從第一筆（20 天前）起算 3 週，4 次 → 每週 1.3 次；
    // 肌力每週 0.7 次 → 提醒 WHO 建議
    expect(find.textContaining('從第一筆運動紀錄'), findsOneWidget);
    expect(find.text('1.3 次'), findsOneWidget);
    expect(find.textContaining('肌力 每週 0.7 次'), findsOneWidget);
    expect(find.textContaining('WHO 建議成人每週至少 2 天'), findsOneWidget);
    expect(find.text('20 → 22.5 kg'), findsOneWidget);
    expect(find.text('+2.5'), findsOneWidget);

    // 飲食：從第一筆（20 天前）起算 21 天、記了 2 天 → 記錄天數不到一半
    expect(find.textContaining('有記錄的 2／21 天（從第一筆餐點紀錄'), findsOneWidget);
    expect(find.text('1400 大卡'), findsOneWidget);
    expect(find.text('108 g'), findsOneWidget);
    expect(find.textContaining('約每公斤體重 1.5 克'), findsOneWidget);
    expect(find.text('早餐 30 g'), findsOneWidget);
    expect(find.text('午餐 78 g'), findsOneWidget);
    expect(find.textContaining('記錄天數不到一半'), findsOneWidget);
    expect(find.text('看衛教：蛋白質為什麼重要'), findsOneWidget);
  });

  testWidgets('切換期間：4 週內只有一次量測，12 週就比得起來', (tester) async {
    final fake = _fake();
    await _measure(fake, 60, 73.0, 19.0, 30.0);
    await _measure(fake, 10, 72.0, 17.8, 30.1);
    await _openRecomp(tester, fake);

    // 預設 12 週：兩次都在範圍內 → 脂肪 −1.2、肌肉 +0.1 → 減脂，肌肉保住了
    expect(find.text('減脂，肌肉保住了'), findsOneWidget);

    await tester.tap(find.text('4 週'));
    await tester.pumpAndSettle();
    expect(find.text('這段期間只有 1 次體組成量測，至少要兩次才能比較。'), findsOneWidget);
  });
}
