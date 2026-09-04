import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/main.dart';
import 'package:health/providers.dart';

import 'fake_repository.dart';

FakeHealthRepository _fakeWith({double? targetWeightKg}) =>
    FakeHealthRepository(
      UserProfile(
        sex: Sex.female,
        age: 28,
        heightCm: 165, // 健康體重區間 50.4–65.3 公斤
        weightKg: 65,
        activity: ActivityLevel.light,
        goal: Goal.lose,
        targetWeightKg: targetWeightKg,
      ),
    );

Future<void> _openWeightTab(WidgetTester tester, FakeHealthRepository fake,
    {Size size = const Size(1080, 3600)}) async {
  tester.view.physicalSize = size;
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
  await tester.tap(find.text('體重'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('設定目標體重後：顯示還差多少、進度與預估達成時間', (tester) async {
    final fake = _fakeWith(targetWeightKg: 60);
    final now = DateTime.now();
    await fake.upsertWeight(
        day: now.subtract(const Duration(days: 30)), weightKg: 65);
    await fake.upsertWeight(day: now, weightKg: 63);

    await _openWeightTab(tester, fake);

    expect(find.text('目標體重'), findsOneWidget);
    expect(find.text('目前 63.0 → 目標 60.0 kg'), findsOneWidget);
    expect(find.text('還差 3.0 公斤'), findsOneWidget);
    // 65 → 63，目標 60：走完 5 公斤中的 2 公斤
    expect(find.textContaining('已完成 40%'), findsOneWidget);
    expect(find.textContaining('照目前的每日熱量目標'), findsOneWidget);
    // 目標在健康區間內 → 不該出現提醒
    expect(find.textContaining('健康體重區間'), findsNothing);
  });

  testWidgets('沒設定目標時顯示引導，不會硬塞一個目標', (tester) async {
    final fake = _fakeWith();
    await fake.upsertWeight(day: DateTime.now(), weightKg: 63);

    await _openWeightTab(tester, fake);

    expect(find.textContaining('設定目標體重'), findsOneWidget);
    expect(find.text('去設定'), findsOneWidget);
    expect(find.text('目標體重'), findsNothing);
  });

  testWidgets('目標低於健康體重區間時出現勸阻提醒', (tester) async {
    final fake = _fakeWith(targetWeightKg: 45);
    await fake.upsertWeight(day: DateTime.now(), weightKg: 63);

    await _openWeightTab(tester, fake);

    expect(find.textContaining('低於你身高的健康體重區間'), findsOneWidget);
  });

  testWidgets('目標體重會跟著備份匯出與還原', (tester) async {
    final fake = _fakeWith(targetWeightKg: 58);
    final json = await fake.exportJson();

    final restored = FakeHealthRepository();
    await restored.importJson(json);

    final profile = await restored.getProfile();
    expect(profile!.targetWeightKg, 58);
  });
}
