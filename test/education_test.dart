import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/main.dart';
import 'package:health/providers.dart';

import 'fake_repository.dart';

void main() {
  testWidgets('切到衛教分頁 → 開啟文章 → 顯示內文', (tester) async {
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

    // 切到衛教分頁
    await tester.tap(find.text('衛教'));
    await tester.pumpAndSettle();
    expect(find.text('衛教知識'), findsOneWidget);

    // 點一篇文章
    await tester.tap(find.text('BMI 是參考，不是全部'));
    await tester.pumpAndSettle();

    // 進入詳細頁：離開列表頁、標題出現在詳細頁
    expect(find.text('衛教知識'), findsNothing);
    expect(find.text('BMI 是參考，不是全部'), findsWidgets);
  });
}
