import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/meal_type.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/domain/recent_foods.dart';
import 'package:health/main.dart';
import 'package:health/providers.dart';

import 'fake_repository.dart';

void main() {
  group('distinctByName', () {
    List<String> namesOf(List<String> input, {int? limit}) =>
        distinctByName(input, (s) => s, limit: limit);

    test('同名只留先出現的那一筆（傳入為由新到舊 → 留最近的）', () {
      expect(namesOf(['便當', '珍奶', '便當', '滷肉飯']), ['便當', '珍奶', '滷肉飯']);
    });

    test('保留的是最近那一次的內容，不是最舊的', () {
      // 同一樣食物熱量後來被改過：要帶出最新的數值
      final entries = [
        ('便當', 700), // 最近一次
        ('便當', 850), // 比較早的一次
      ];
      final result = distinctByName(entries, (e) => e.$1);
      expect(result.single.$2, 700);
    });

    test('limit 生效', () {
      expect(namesOf(['a', 'b', 'c', 'd'], limit: 2), ['a', 'b']);
    });

    test('limit 為 null 時不限制', () {
      expect(namesOf(['a', 'b', 'c']).length, 3);
    });

    test('前後空白與英文大小寫視為同一樣', () {
      expect(namesOf(['Latte', ' latte ', 'LATTE']), ['Latte']);
    });

    test('名稱空白的紀錄直接略過', () {
      expect(namesOf(['', '   ', '便當']), ['便當']);
    });

    test('沒有資料時回傳空清單', () {
      expect(namesOf([]), isEmpty);
    });
  });

  group('挑選食物頁的「最近吃過」', () {
    FakeHealthRepository fakeWithProfile() => FakeHealthRepository(
          UserProfile(
            sex: Sex.female,
            age: 28,
            heightCm: 165,
            weightKg: 60,
            activity: ActivityLevel.light,
            goal: Goal.lose,
          ),
        );

    Future<void> openPicker(WidgetTester tester, FakeHealthRepository fake) async {
      tester.view.physicalSize = const Size(1080, 3200);
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
      await tester.tap(find.widgetWithText(FloatingActionButton, '新增餐點'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, '最近吃過 / 食物庫'));
      await tester.pumpAndSettle();
    }

    testWidgets('吃過的東西會出現在最上面，選了就帶入欄位', (tester) async {
      final fake = fakeWithProfile();
      // 食物庫裡沒有這樣東西 —— 只有從自己的紀錄才找得到
      await fake.addMeal(
        eatenAt: DateTime.now().subtract(const Duration(days: 2)),
        name: '阿姨的便當',
        calories: 720,
        proteinG: 32,
        fatG: 24,
        carbsG: 85,
        mealType: MealType.lunch,
      );

      await openPicker(tester, fake);

      expect(find.text('最近吃過'), findsOneWidget);
      expect(find.text('阿姨的便當'), findsOneWidget);

      await tester.tap(find.text('阿姨的便當'));
      await tester.pumpAndSettle();

      // 回到新增餐點頁，欄位已帶入自己那次的數值
      expect(find.widgetWithText(TextFormField, '阿姨的便當'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '720'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '32'), findsOneWidget);
    });

    testWidgets('同一樣吃很多次只會出現一列', (tester) async {
      final fake = fakeWithProfile();
      for (var i = 0; i < 3; i++) {
        await fake.addMeal(
          eatenAt: DateTime.now().subtract(Duration(days: i)),
          name: '阿姨的便當',
          calories: 720,
          proteinG: 32,
          fatG: 24,
          carbsG: 85,
        );
      }

      await openPicker(tester, fake);

      expect(find.text('阿姨的便當'), findsOneWidget);
    });

    testWidgets('搜尋會同時篩選最近吃過與食物庫', (tester) async {
      final fake = fakeWithProfile();
      await fake.addMeal(
        eatenAt: DateTime.now(),
        name: '阿姨的便當',
        calories: 720,
        proteinG: 32,
        fatG: 24,
        carbsG: 85,
      );

      await openPicker(tester, fake);

      await tester.enterText(find.byType(TextField).first, '珍珠');
      await tester.pumpAndSettle();

      // 搜尋「珍珠」→ 自己的便當不該再出現，但食物庫的珍奶要出現
      expect(find.text('阿姨的便當'), findsNothing);
      expect(find.text('最近吃過'), findsNothing);
      expect(find.textContaining('珍珠'), findsWidgets);
    });
  });
}
