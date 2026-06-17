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
