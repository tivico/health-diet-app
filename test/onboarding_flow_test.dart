import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/main.dart';
import 'package:health/providers.dart';

import 'fake_repository.dart';

void main() {
  testWidgets('沒有資料 → 存檔 → 顯示健康建議 → 開始使用進入儀表板', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = FakeHealthRepository(); // 初始無資料

    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(fake)],
        child: const HealthApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 一開始沒有資料 → 顯示引導設定（欄位留白，靠提示文字引導）
    expect(find.text('建立你的個人資料'), findsOneWidget);

    // 填入基本資料後存檔
    await tester.enterText(find.widgetWithText(TextFormField, '年齡'), '28');
    await tester.enterText(find.widgetWithText(TextFormField, '身高'), '165');
    await tester.enterText(find.widgetWithText(TextFormField, '體重'), '65');
    await tester.tap(find.text('計算我的每日目標'));
    await tester.pumpAndSettle();

    // 首次 → 先出現客製化健康建議
    expect(find.text('你的健康建議'), findsOneWidget);
    expect(find.text('怎麼吃'), findsOneWidget);

    // 按「開始使用」→ 進入儀表板
    await tester.tap(find.widgetWithText(FilledButton, '開始使用'));
    await tester.pumpAndSettle();
    expect(find.text('你的每日目標'), findsOneWidget);
    expect(find.text('三大營養素（已吃 / 目標）'), findsOneWidget);
  });

  testWidgets('已有資料時直接顯示儀表板', (tester) async {
    final fake = FakeHealthRepository(
      UserProfile(
        sex: Sex.male,
        age: 30,
        heightCm: 175,
        weightKg: 70,
        activity: ActivityLevel.moderate,
        goal: Goal.maintain,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(fake)],
        child: const HealthApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('你的每日目標'), findsOneWidget);
    expect(find.text('建立你的個人資料'), findsNothing);
  });
}
