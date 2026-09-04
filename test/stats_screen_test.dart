import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/main.dart';
import 'package:health/providers.dart';

import 'fake_repository.dart';

void main() {
  testWidgets('切到統計分頁：顯示摘要數字與每日熱量圖表', (tester) async {
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
    // 今天記一筆，讓統計有資料（否則會顯示空狀態）
    await fake.addMeal(
      eatenAt: DateTime.now(),
      name: '午餐',
      calories: 800,
      proteinG: 30,
      fatG: 20,
      carbsG: 90,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(fake)],
        child: const HealthApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 切到統計分頁
    await tester.tap(find.text('統計'));
    await tester.pumpAndSettle();

    // 摘要卡片
    expect(find.text('平均每日攝取'), findsOneWidget);
    expect(find.text('有記錄天數'), findsOneWidget);
    expect(find.text('達標天數'), findsOneWidget);
    expect(find.text('體重變化'), findsOneWidget);

    // 有資料 → 顯示長條圖（而非空狀態）
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.textContaining('還沒有餐點紀錄'), findsNothing);

    // 可切換 7 / 30 天
    expect(find.text('近 7 天'), findsOneWidget);
    await tester.tap(find.text('近 30 天'));
    await tester.pumpAndSettle();
    expect(find.byType(BarChart), findsOneWidget);
  });
}
