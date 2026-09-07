import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/meal_type.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/main.dart';
import 'package:health/providers.dart';

import 'fake_repository.dart';

/// 小螢幕版面測試：其他 widget 測試都把視窗開得很大（1080×3200）才好找元件，
/// 但那樣永遠測不到「在真實手機上會不會擠爆」。
///
/// 這裡用 iPhone SE 等級的 375×667 跑一遍主要分頁；只要有 RenderFlex overflow
/// 之類的版面錯誤，Flutter 就會丟例外讓測試失敗。
void main() {
  const smallPhone = Size(375, 667);

  Future<void> pumpApp(WidgetTester tester, FakeHealthRepository fake) async {
    tester.view.physicalSize = smallPhone;
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
  }

  /// 資料齊全的使用者：有目標體重、有各餐別的餐點、有體重紀錄。
  Future<FakeHealthRepository> seeded() async {
    final fake = FakeHealthRepository(
      UserProfile(
        sex: Sex.female,
        age: 28,
        heightCm: 165,
        weightKg: 63,
        activity: ActivityLevel.light,
        goal: Goal.lose,
        targetWeightKg: 58,
      ),
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await fake.addMeal(
      eatenAt: today.add(const Duration(hours: 8)),
      name: '蛋餅加蛋、豆漿',
      calories: 420,
      proteinG: 18,
      fatG: 14,
      carbsG: 52,
      mealType: MealType.breakfast,
    );
    await fake.addMeal(
      eatenAt: today.add(const Duration(hours: 12)),
      name: '雞腿便當',
      calories: 850,
      proteinG: 38,
      fatG: 30,
      carbsG: 95,
      mealType: MealType.lunch,
    );
    await fake.addMeal(
      eatenAt: today.add(const Duration(hours: 15)),
      name: '珍珠奶茶（大）',
      calories: 560,
      proteinG: 6,
      fatG: 14,
      carbsG: 100,
      mealType: MealType.snack,
    );
    await fake.upsertWeight(
        day: today.subtract(const Duration(days: 30)), weightKg: 65);
    await fake.upsertWeight(
        day: today.subtract(const Duration(days: 14)), weightKg: 64.2);
    await fake.upsertWeight(day: today, weightKg: 63, bodyFatPct: 27.5);
    return fake;
  }

  testWidgets('375×667 手機：今日分頁不會版面溢出', (tester) async {
    await pumpApp(tester, await seeded());

    // 整頁捲到底，確保下半部（BMI 卡等）也真的排過版
    await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
    await tester.pumpAndSettle();
  });

  testWidgets('375×667 手機：體重 / 統計 / 衛教分頁不會版面溢出', (tester) async {
    await pumpApp(tester, await seeded());

    for (final tab in ['體重', '統計', '衛教']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -800));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('375×667 手機：熱量超標時的今日分頁不會版面溢出', (tester) async {
    final fake = await seeded();
    // 再加一筆把熱量推爆，讓主卡切換成「超標」樣式
    await fake.addMeal(
      eatenAt: DateTime.now(),
      name: '宵夜鹹酥雞',
      calories: 900,
      proteinG: 30,
      fatG: 55,
      carbsG: 70,
      mealType: MealType.snack,
    );
    await pumpApp(tester, fake);
  });

  testWidgets('375×667 手機：新增餐點與挑選食物頁不會版面溢出', (tester) async {
    await pumpApp(tester, await seeded());

    await tester.tap(find.widgetWithText(FloatingActionButton, '新增餐點'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '最近吃過 / 食物庫'));
    await tester.pumpAndSettle();
    // 「最近吃過」與食物庫兩區都排到版
    expect(find.text('最近吃過'), findsOneWidget);
  });

  testWidgets('375×667 手機：記錄體重表單不會版面溢出', (tester) async {
    await pumpApp(tester, await seeded());

    await tester.tap(find.text('體重'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, '記錄體重'));
    await tester.pumpAndSettle();
  });

  testWidgets('375×667 手機：健康建議與計算方式頁不會版面溢出', (tester) async {
    await pumpApp(tester, await seeded());

    await tester.tap(find.byTooltip('健康建議'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('查看背後的計算公式'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await tester.pumpAndSettle();
  });

  testWidgets('375×667 手機：備份與還原頁不會版面溢出', (tester) async {
    await pumpApp(tester, await seeded());

    await tester.tap(find.byTooltip('備份與還原'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '產生備份'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
  });
}
