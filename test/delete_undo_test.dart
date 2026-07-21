import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/main.dart';
import 'package:health/providers.dart';

import 'fake_repository.dart';

void main() {
  testWidgets('刪除餐點後可用「復原」還原', (tester) async {
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

    expect(find.text('午餐'), findsOneWidget);
    expect(find.text('餐點（1）'), findsOneWidget);

    // 刪除
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('餐點（0）'), findsOneWidget);
    expect(find.text('復原'), findsOneWidget);

    // 復原
    await tester.tap(find.text('復原'));
    await tester.pumpAndSettle();
    expect(find.text('午餐'), findsOneWidget);
    expect(find.text('餐點（1）'), findsOneWidget);
  });
}
