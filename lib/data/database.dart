import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../domain/activity.dart';
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
// 4) 體組成（v4 加入）：體脂計 / InBody 的量測報告，一天一筆（以 day 為主鍵）。
//    除了體重都可以留空——不同機器量得到的項目不一樣。
//    資料類別改名為 BodyCompositionRow，避免和 domain 層的 BodyComposition 撞名。
// ---------------------------------------------------------------------------
@DataClassName('BodyCompositionRow')
class BodyCompositions extends Table {
  DateTimeColumn get day => dateTime()();
  RealColumn get weightKg => real()();
  RealColumn get bodyFatPct => real().nullable()();
  RealColumn get fatMassKg => real().nullable()();
  RealColumn get skeletalMuscleKg => real().nullable()();
  RealColumn get muscleMassKg => real().nullable()();
  RealColumn get waterKg => real().nullable()();
  RealColumn get fatFreeMassKg => real().nullable()();
  RealColumn get subcutaneousFatPct => real().nullable()();
  RealColumn get visceralFatLevel => real().nullable()();
  RealColumn get bmrKcal => real().nullable()();
  RealColumn get asmi => real().nullable()();
  RealColumn get bodyAge => real().nullable()();
  RealColumn get waistCm => real().nullable()();
  RealColumn get hipCm => real().nullable()();
  RealColumn get armCm => real().nullable()();
  RealColumn get thighCm => real().nullable()();
  RealColumn get neckCm => real().nullable()();
  RealColumn get chestCm => real().nullable()();

  /// 量測工具，例如「InBody」或體脂計的 App 名稱。
  TextColumn get source => text().withLength(max: 40).nullable()();

  /// 量測條件備註，例如「早上空腹」「生理期第 2 天」。
  TextColumn get note => text().withLength(max: 200).nullable()();

  @override
  Set<Column> get primaryKey => {day};
}

// ---------------------------------------------------------------------------
// 5) 運動（v5 加入）：一次運動一筆；肌力訓練的每個動作記在 ExerciseSets。
//    欄位對齊 Garmin 個人 API 的活動摘要，之後匯入時可以直接對應。
//    三張表的資料類別都加 Row 結尾，避免和 domain 層的同名類別撞名。
// ---------------------------------------------------------------------------
@DataClassName('ActivityRow')
class Activities extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  IntColumn get kind => intEnum<ActivityKind>()();
  TextColumn get title => text().withLength(max: 60).nullable()();
  IntColumn get durationSec => integer()();
  RealColumn get distanceKm => real().nullable()();
  RealColumn get calories => real().nullable()();
  RealColumn get activeCalories => real().nullable()();
  IntColumn get avgHr => integer().nullable()();
  IntColumn get maxHr => integer().nullable()();
  IntColumn get zone1Sec => integer().nullable()();
  IntColumn get zone2Sec => integer().nullable()();
  IntColumn get zone3Sec => integer().nullable()();
  IntColumn get zone4Sec => integer().nullable()();
  IntColumn get zone5Sec => integer().nullable()();
  TextColumn get feeling => text().withLength(max: 500).nullable()();

  /// Garmin 的活動編號，匯入時用來合併；手動記的是 null（可以很多筆）。
  IntColumn get garminActivityId => integer().nullable().unique()();
}

/// 器材 / 動作清單。名稱不重複；單位在有紀錄之後就不能改（否則舊重量會被誤讀）。
@DataClassName('ExerciseRow')
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60).unique()();
  IntColumn get unit => intEnum<WeightUnit>()();
}

/// 肌力訓練裡的每個動作：重量（單位跟著器材）× 每組次數 × 組數。
/// 刪掉一次運動時，它的動作跟著刪（外鍵 cascade）。
@DataClassName('ExerciseSetRow')
class ExerciseSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get activityId => integer()
      .references(Activities, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();

  /// 在這次訓練裡的順序。
  IntColumn get position => integer()();
  RealColumn get weight => real().nullable()();
  IntColumn get reps => integer().nullable()();
  IntColumn get sets => integer().nullable()();
}

// ---------------------------------------------------------------------------
// 資料庫本體。driftDatabase()（來自 drift_flutter）會自動處理跨平台連線：
// 行動平台走原生 SQLite、Web 走 sqlite3 WASM + OPFS。
// ---------------------------------------------------------------------------
@DriftDatabase(tables: [
  UserProfiles,
  MealEntries,
  WeightEntries,
  BodyCompositions,
  Activities,
  Exercises,
  ExerciseSets,
])
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
  int get schemaVersion => 5;

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
          // v4：新增「體組成」資料表。既有資料不受影響。
          if (from < 4) {
            await m.createTable(bodyCompositions);
          }
          // v5：新增「運動」三張表。動作表參照另外兩張，所以最後建。
          if (from < 5) {
            await m.createTable(activities);
            await m.createTable(exercises);
            await m.createTable(exerciseSets);
          }
        },
        beforeOpen: (details) async {
          // 未來若加入資料表關聯，需要開啟外鍵約束才會生效
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
