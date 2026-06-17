import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/data/database.dart';
import 'package:health/data/health_repository.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/main.dart';
import 'package:health/providers.dart';

/// 記憶體假實作：避免測試依賴真實的 SQLite。
/// 只需支援 profile 的讀寫，其餘回傳空值即可。
class FakeHealthRepository implements HealthRepository {
  UserProfile? _profile;
  final _ctrl = StreamController<UserProfile?>.broadcast();

  FakeHealthRepository([this._profile]);

  @override
  Stream<UserProfile?> watchProfile() async* {
    yield _profile; // 先送出目前值
    yield* _ctrl.stream; // 之後送出更新
  }

  @override
  Future<UserProfile?> getProfile() async => _profile;

  @override
  Future<void> saveProfile(UserProfile p) async {
    _profile = p;
    _ctrl.add(p);
  }

  @override
  Stream<List<MealEntry>> watchMealsOn(DateTime day) =>
      Stream.value(const <MealEntry>[]);

  @override
  Stream<DailyTotals> watchDailyTotals(DateTime day) =>
      Stream.value(const DailyTotals());

  @override
  Future<int> addMeal({
    required DateTime eatenAt,
    required String name,
    required double calories,
    required double proteinG,
    required double fatG,
    required double carbsG,
  }) async =>
      0;

  @override
  Future<void> deleteMeal(int id) async {}

  @override
  Stream<List<WeightEntry>> watchWeightsBetween(DateTime from, DateTime to) =>
      Stream.value(const <WeightEntry>[]);

  @override
  Future<void> upsertWeight({
    required DateTime day,
    required double weightKg,
    double? bodyFatPct,
  }) async {}

  @override
  Future<void> deleteWeight(DateTime day) async {}
}

void main() {
  testWidgets('沒有資料時顯示引導設定 → 存檔 → 自動進入每日目標儀表板', (tester) async {
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
    final calcButton = find.text('計算我的每日目標');
    expect(calcButton, findsOneWidget);

    // 用預設值（女 / 28 / 165 / 65 / 輕度 / 減脂）存檔
    await tester.tap(calcButton);
    await tester.pumpAndSettle();

    // 存檔後 profileProvider 推出新值 → HomeGate 切換到儀表板
    expect(find.text('你的每日目標'), findsOneWidget);
    expect(find.text('三大營養素'), findsOneWidget);
    expect(find.text('大卡 / 天'), findsOneWidget);
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
