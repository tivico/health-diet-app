import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/main.dart';
import 'package:health/providers.dart';

import 'fake_repository.dart';

void main() {
  testWidgets('點餐點 → 編輯熱量 → 清單更新', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
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
    await fake.addMeal(
      eatenAt: DateTime.now(),
      name: '午餐',
      calories: 600,
      proteinG: 30,
      fatG: 20,
      carbsG: 70,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(fake)],
        child: const HealthApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('600 大卡'), findsOneWidget);

    // 點餐點進入編輯模式
    await tester.tap(find.text('午餐'));
    await tester.pumpAndSettle();
    expect(find.text('編輯餐點'), findsOneWidget);

    // 改熱量為 750 後儲存
    await tester.enterText(find.widgetWithText(TextFormField, '熱量'), '750');
    await tester.tap(find.widgetWithText(FilledButton, '儲存'));
    await tester.pumpAndSettle();

    // 清單更新
    expect(find.text('750 大卡'), findsOneWidget);
    expect(find.text('600 大卡'), findsNothing);
  });
}
