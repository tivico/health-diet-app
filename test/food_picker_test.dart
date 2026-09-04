import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/main.dart';
import 'package:health/providers.dart';

import 'fake_repository.dart';

void main() {
  testWidgets('從食物庫挑選 → 自動帶入欄位 → 儲存後出現在清單', (tester) async {
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(fake)],
        child: const HealthApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 進入新增餐點頁
    await tester.tap(find.widgetWithText(FloatingActionButton, '新增餐點'));
    await tester.pumpAndSettle();

    // 開啟食物庫
    await tester.tap(find.widgetWithText(OutlinedButton, '從食物庫挑選'));
    await tester.pumpAndSettle();
    expect(find.text('食物庫'), findsOneWidget);

    // 搜尋並選取
    await tester.enterText(find.byType(TextField).first, '雞腿');
    await tester.pumpAndSettle();
    expect(find.text('雞腿便當'), findsOneWidget);
    await tester.tap(find.text('雞腿便當'));
    await tester.pumpAndSettle();

    // 回到新增餐點頁，欄位已自動帶入
    expect(find.widgetWithText(TextFormField, '雞腿便當'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '850'), findsOneWidget);

    // 儲存後出現在今日清單
    await tester.tap(find.widgetWithText(FilledButton, '儲存'));
    await tester.pumpAndSettle();
    expect(find.text('雞腿便當'), findsOneWidget);
    expect(find.text('850 大卡'), findsOneWidget);
  });
}
