import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../domain/nutrition.dart';

// build_runner 會產生這個檔（型別安全的 row class、companion、查詢 API）。
// 執行：dart run build_runner build --delete-conflicting-outputs
part 'database.g.dart';

// ---------------------------------------------------------------------------
// 1) 使用者資料：目前只有單一使用者，用固定 id = 1 的單列表。
//    用 @DataClassName 把產生的資料類別改名為 UserProfileRow，
//    避免和 domain 層的 UserProfile 撞名。
//    sex / activity / goal 直接用 intEnum 重用既有 enum（以 index 存成 int）。
// ---------------------------------------------------------------------------
@DataClassName('UserProfileRow')
class UserProfiles extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get sex => intEnum<Sex>()();
  IntColumn get age => integer()();
  RealColumn get heightCm => real()();
  RealColumn get weightKg => real()();
  IntColumn get activity => intEnum<ActivityLevel>()();
  IntColumn get goal => intEnum<Goal>()();
  RealColumn get bodyFatPct => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// 2) 餐點紀錄。之後拍照辨識的結果也會寫進這張表。
// ---------------------------------------------------------------------------
class MealEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get eatenAt => dateTime()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get calories => real()();
  RealColumn get proteinG => real()();
  RealColumn get fatG => real()();
  RealColumn get carbsG => real()();
}

// ---------------------------------------------------------------------------
// 3) 體重紀錄。一天一筆：以 day（當天午夜）為主鍵，方便畫趨勢圖與覆寫。
// ---------------------------------------------------------------------------
class WeightEntries extends Table {
  DateTimeColumn get day => dateTime()();
  RealColumn get weightKg => real()();
  RealColumn get bodyFatPct => real().nullable()();

  @override
  Set<Column> get primaryKey => {day};
}

// ---------------------------------------------------------------------------
// 資料庫本體。driftDatabase()（來自 drift_flutter）會自動處理跨平台連線：
// 行動平台走原生 SQLite、Web 走 sqlite3 WASM + OPFS。
// ---------------------------------------------------------------------------
@DriftDatabase(tables: [UserProfiles, MealEntries, WeightEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ??
            driftDatabase(
              name: 'health_db',
              // Web 需要這兩個放在 web/ 的靜態資源（行動平台會忽略此設定）。
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
              ),
            ));

  @override
  int get schemaVersion => 1;
}
