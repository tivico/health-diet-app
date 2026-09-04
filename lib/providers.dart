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

/// 目前使用者資料（reactive）；null 代表尚未建立（要顯示引導設定）。
final profileProvider = StreamProvider<UserProfile?>(
  (ref) => ref.watch(repositoryProvider).watchProfile(),
);

/// 目前檢視的日期：預設今天，可前後切換但不超過今天。
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => _dateOnly(DateTime.now());

  void previousDay() => state = state.subtract(const Duration(days: 1));

  void nextDay() {
    final next = state.add(const Duration(days: 1));
    final today = _dateOnly(DateTime.now());
    state = next.isAfter(today) ? today : next; // 不能看未來
  }

  void goToToday() => state = _dateOnly(DateTime.now());

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

final selectedDateProvider =
    NotifierProvider<SelectedDateNotifier, DateTime>(SelectedDateNotifier.new);

/// 所選日期的餐點清單（reactive）。
final dayMealsProvider = StreamProvider<List<MealEntry>>(
  (ref) => ref
      .watch(repositoryProvider)
      .watchMealsOn(ref.watch(selectedDateProvider)),
);

/// 所選日期的營養加總（reactive）。
final dayTotalsProvider = StreamProvider<DailyTotals>(
  (ref) => ref
      .watch(repositoryProvider)
      .watchDailyTotals(ref.watch(selectedDateProvider)),
);

/// 統計期間內的所有餐點（reactive）。參數為天數（例如 7 或 30，含今天）。
final statsMealsProvider =
    StreamProvider.family<List<MealEntry>, int>((ref, days) {
  final now = DateTime.now();
  final to = DateTime(now.year, now.month, now.day);
  final from = to.subtract(Duration(days: days - 1));
  return ref.watch(repositoryProvider).watchMealsBetween(from, to);
});

/// 近 90 天的體重紀錄（reactive），給趨勢圖與清單用。
final weightHistoryProvider = StreamProvider<List<WeightEntry>>((ref) {
  final now = DateTime.now();
  final to = DateTime(now.year, now.month, now.day);
  final from = to.subtract(const Duration(days: 90));
  return ref.watch(repositoryProvider).watchWeightsBetween(from, to);
});
