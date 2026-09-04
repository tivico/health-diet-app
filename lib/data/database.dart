import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../domain/meal_type.dart';
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

  /// 目標體重（v3 加入）。nullable：沒設定目標的人不該被硬塞一個數字。
  RealColumn get targetWeightKg => real().nullable()();

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

  /// 餐別（v2 加入）。nullable：v1 時期記的餐點本來就沒有這個資訊，
  /// 硬塞預設值等於偽造資料，所以留 null 顯示為「未分類」。
  IntColumn get mealType => intEnum<MealType>().nullable()();
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
  int get schemaVersion => 3;

  /// 資料庫版本升級策略。
  ///
  /// ⚠️ **改 schema 的規則**（完整流程見 `docs/DATABASE.md`）：
  /// 1. 修改上面的 table 定義
  /// 2. `schemaVersion` +1
  /// 3. 在 [onUpgrade] 加一段 `if (from < 新版號) { ... }` 描述如何從舊版升上來
  /// 4. 跑 `dart run build_runner build`
  ///
  /// 只改 table 定義卻不寫 migration，既有使用者（手機／瀏覽器裡）的資料會壞掉。
  @override
  MigrationStrategy get migration => MigrationStrategy(
        // 全新安裝：直接依目前定義建立所有資料表
        onCreate: (m) async {
          await m.createAll();
        },
        // 既有使用者升級：從 from 版逐步升到 to 版。
        // 一律用 if 而非 else if —— 很久沒更新的人可能一次跳好幾版，要能逐步跑完。
        onUpgrade: (m, from, to) async {
          // v2：餐點加入「餐別」欄位。既有餐點維持 null（未分類）。
          if (from < 2) {
            await m.addColumn(mealEntries, mealEntries.mealType);
          }
          // v3：個人資料加入「目標體重」。既有使用者維持 null（未設定）。
          if (from < 3) {
            await m.addColumn(userProfiles, userProfiles.targetWeightKg);
          }
        },
        beforeOpen: (details) async {
          // 未來若加入資料表關聯，需要開啟外鍵約束才會生效
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
