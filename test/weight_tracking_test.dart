import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

Future<void> _openWeightRecordScreen(WidgetTester tester) async {
  await tester.tap(find.text('體重'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FloatingActionButton, '記錄體重'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('切到體重分頁 → 記錄體重 → 出現在清單', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
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

    // 從今日分頁切到體重分頁
    await tester.tap(find.text('體重'));
    await tester.pumpAndSettle();
    expect(find.text('體重追蹤'), findsOneWidget);
    expect(find.textContaining('還沒有體重紀錄'), findsOneWidget);

    // 記錄一筆體重（日期預設今天）
    await tester.tap(find.widgetWithText(FloatingActionButton, '記錄體重'));
    await tester.pumpAndSettle();
    expect(find.textContaining('（今天）'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, '體重'), '58');
    await tester.tap(find.widgetWithText(FilledButton, '儲存'));
    await tester.pumpAndSettle();

    // 回到體重分頁，紀錄出現
    expect(find.text('58.0 kg'), findsOneWidget);
  });

  testWidgets('記錄體重可開啟日期選擇器（補記過去日期）', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
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

    await _openWeightRecordScreen(tester);

    // 點日期按鈕會開啟日期選擇器
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
}
