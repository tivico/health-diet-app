import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database.dart';
import 'data/health_repository.dart';
import 'domain/nutrition.dart';

/// 全 App 單一資料庫實例。
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// 資料存取層（正式用 drift 實作；測試可覆寫此 provider 注入假實作）。
final repositoryProvider = Provider<HealthRepository>(
  (ref) => DriftHealthRepository(ref.watch(databaseProvider)),
);

/// 目前使用者資料（reactive）：onboarding 存檔後，所有讀此 provider 的畫面自動更新。
/// 值為 null 代表尚未建立資料（要顯示引導設定）。
final profileProvider = StreamProvider<UserProfile?>(
  (ref) => ref.watch(repositoryProvider).watchProfile(),
);

/// 目前檢視的日期（目前固定今天）。之後要支援切換日期時，改成 NotifierProvider。
final selectedDateProvider = Provider<DateTime>((ref) => DateTime.now());

/// 當日餐點清單（reactive）。
final todayMealsProvider = StreamProvider<List<MealEntry>>(
  (ref) => ref
      .watch(repositoryProvider)
      .watchMealsOn(ref.watch(selectedDateProvider)),
);

/// 當日營養加總（reactive）。
final todayTotalsProvider = StreamProvider<DailyTotals>(
  (ref) => ref
      .watch(repositoryProvider)
      .watchDailyTotals(ref.watch(selectedDateProvider)),
);

/// 近 90 天的體重紀錄（reactive），給趨勢圖與清單用。
final weightHistoryProvider = StreamProvider<List<WeightEntry>>((ref) {
  final now = DateTime.now();
  final to = DateTime(now.year, now.month, now.day);
  final from = to.subtract(const Duration(days: 90));
  return ref.watch(repositoryProvider).watchWeightsBetween(from, to);
});
