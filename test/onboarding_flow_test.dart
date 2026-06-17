import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/main.dart';
import 'package:health/providers.dart';

import 'fake_repository.dart';

void main() {
  testWidgets('沒有資料時顯示引導設定 → 存檔 → 自動進入儀表板', (tester) async {
    // 用較高的測試畫面，確保整張表單（含底部按鈕）都在可視範圍內。
    tester.view.physicalSize = const Size(1080, 2600);
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

    // 一開始沒有資料 → 顯示引導設定
    expect(find.text('建立你的個人資料'), findsOneWidget);

    // 用預設值存檔
    await tester.tap(find.text('計算我的每日目標'));
    await tester.pumpAndSettle();

    // 存檔後 profileProvider 推出新值 → HomeGate 切換到儀表板
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
