import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/main.dart';
import 'package:health/providers.dart';

import 'fake_repository.dart';

void main() {
  testWidgets('切換日期：今天有餐點、前一天沒有、切回來又有', (tester) async {
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
    // 預先在「今天」記一筆餐點
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

    // 今天：看得到餐點
    expect(find.text('餐點（1）'), findsOneWidget);
    expect(find.text('午餐'), findsOneWidget);

    // 切到前一天：沒有餐點
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(find.text('餐點（0）'), findsOneWidget);
    expect(find.text('午餐'), findsNothing);

    // 切回今天：餐點又出現
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.text('餐點（1）'), findsOneWidget);
    expect(find.text('午餐'), findsOneWidget);
  });
}
