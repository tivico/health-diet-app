import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/meal_type.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/main.dart';
import 'package:health/providers.dart';

import 'fake_repository.dart';

FakeHealthRepository _fakeWithProfile() => FakeHealthRepository(
      UserProfile(
        sex: Sex.female,
        age: 28,
        heightCm: 165,
        weightKg: 60,
        activity: ActivityLevel.light,
        goal: Goal.lose,
      ),
    );

void main() {
  testWidgets('新增餐點時選餐別 → 今日清單依餐別分組顯示', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = _fakeWithProfile();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(fake)],
        child: const HealthApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FloatingActionButton, '新增餐點'));
    await tester.pumpAndSettle();

    // 明確選「早餐」，不依賴執行測試當下的時間
    // （要點文字本身；點 SegmentedButton 會落在整排的正中間，選到別的餐別）
    expect(find.byType(SegmentedButton<MealType>), findsOneWidget);
    await tester.tap(find.text('早餐'));
    await tester.enterText(
        find.widgetWithText(TextFormField, '餐點名稱'), '蛋餅加蛋');
    await tester.enterText(find.widgetWithText(TextFormField, '熱量'), '350');
    await tester.tap(find.widgetWithText(FilledButton, '儲存'));
    await tester.pumpAndSettle();

    // 回到今日：出現「早餐」分組標題與小計，餐點在其中
    expect(find.text('早餐（1）'), findsOneWidget);
    expect(find.text('小計 350 大卡'), findsOneWidget);
    expect(find.text('蛋餅加蛋'), findsOneWidget);
  });

  testWidgets('加入餐別欄位前記的舊資料顯示為「未分類」', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = _fakeWithProfile();
    // 沒有 mealType，等同 schema v1 時期留下的餐點
    await fake.addMeal(
      eatenAt: DateTime.now(),
      name: '舊資料便當',
      calories: 700,
      proteinG: 30,
      fatG: 20,
      carbsG: 80,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(fake)],
        child: const HealthApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('未分類（1）'), findsOneWidget);
    expect(find.text('舊資料便當'), findsOneWidget);
  });

  testWidgets('統計分頁顯示各餐別分佈與「吃最多的一餐」', (tester) async {
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = _fakeWithProfile();
    final now = DateTime.now();
    await fake.addMeal(
      eatenAt: now,
      name: '蛋餅',
      calories: 300,
      proteinG: 10,
      fatG: 10,
      carbsG: 40,
      mealType: MealType.breakfast,
    );
    await fake.addMeal(
      eatenAt: now,
      name: '雞腿便當',
      calories: 700,
      proteinG: 35,
      fatG: 25,
      carbsG: 80,
      mealType: MealType.dinner,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(fake)],
        child: const HealthApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('統計'));
    await tester.pumpAndSettle();

    expect(find.text('各餐別熱量分佈'), findsOneWidget);
    // 晚餐 700 / 總計 1000 = 70%
    expect(find.textContaining('吃最多的是「晚餐」'), findsOneWidget);
    expect(find.text('700 大卡 ・ 70%'), findsOneWidget);
    expect(find.text('300 大卡 ・ 30%'), findsOneWidget);
  });

  testWidgets('備份匯出 / 匯入會保留餐別', (tester) async {
    final fake = _fakeWithProfile();
    await fake.addMeal(
      eatenAt: DateTime.now(),
      name: '午餐便當',
      calories: 700,
      proteinG: 35,
      fatG: 25,
      carbsG: 80,
      mealType: MealType.lunch,
    );

    final json = await fake.exportJson();
    final restored = _fakeWithProfile();
    await restored.importJson(json);

    final meals = await restored.watchMealsOn(DateTime.now()).first;
    expect(meals.single.name, '午餐便當');
    expect(meals.single.mealType, MealType.lunch);
  });
}
