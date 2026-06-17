import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/main.dart';
import 'package:health/providers.dart';

import 'fake_repository.dart';

void main() {
  testWidgets('新增餐點 → 出現在今日清單，計數更新', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
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
        child: const HealthApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 在儀表板，今日餐點為空
    expect(find.text('今日餐點（0）'), findsOneWidget);

    // 點 FAB 進入新增餐點頁
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // 填寫名稱與熱量後儲存
    await tester.enterText(
        find.widgetWithText(TextFormField, '餐點名稱'), '雞腿便當');
    await tester.enterText(find.widgetWithText(TextFormField, '熱量'), '800');
    await tester.tap(find.widgetWithText(FilledButton, '儲存'));
    await tester.pumpAndSettle();

    // 回到儀表板：餐點出現、計數變成 1
    expect(find.text('雞腿便當'), findsOneWidget);
    expect(find.text('今日餐點（1）'), findsOneWidget);
  });
}
