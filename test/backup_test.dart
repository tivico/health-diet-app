import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/providers.dart';
import 'package:health/screens/backup_screen.dart';

import 'fake_repository.dart';

void main() {
  test('匯出再匯入可還原資料', () async {
    final src = FakeHealthRepository(
      UserProfile(
        sex: Sex.female,
        age: 28,
        heightCm: 165,
        weightKg: 60,
        activity: ActivityLevel.light,
        goal: Goal.lose,
      ),
    );
    await src.addMeal(
      eatenAt: DateTime(2026, 6, 17, 12),
      name: '午餐',
      calories: 600,
      proteinG: 30,
      fatG: 20,
      carbsG: 70,
    );
    await src.upsertWeight(day: DateTime(2026, 6, 17), weightKg: 59, bodyFatPct: 25);

    final json = await src.exportJson();

    final dst = FakeHealthRepository();
    await dst.importJson(json);

    expect(await dst.getProfile(), isNotNull);
    final meals = await dst.watchMealsOn(DateTime(2026, 6, 17)).first;
    expect(meals.length, 1);
    expect(meals.first.name, '午餐');
    final weights = await dst
        .watchWeightsBetween(DateTime(2026, 6, 1), DateTime(2026, 6, 30))
        .first;
    expect(weights.length, 1);
    expect(weights.first.weightKg, 59);
  });

  testWidgets('備份頁：產生備份後出現「複製」按鈕', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = FakeHealthRepository(
      UserProfile(
        sex: Sex.female,
        age: 28,
        heightCm: 165,
        weightKg: 60,
        activity: ActivityLevel.light,
        goal: Goal.lose,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: BackupScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('備份與還原'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '產生備份'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, '複製到剪貼簿'), findsOneWidget);
  });
}
