/// Migration 測試：真的建一個**舊版 schema 的資料庫**，用 [AppDatabase] 打開它，
/// 驗證 `onUpgrade` 有把既有資料完整帶上來。
///
/// 這是 local-first 最危險的一段 —— 升級只會發生在使用者自己的裝置上，
/// 而且只有一次機會。詳見 docs/DATABASE.md。
///
/// 舊版的 DDL 是照當時的 table 定義**手寫重現**的（v1、v2 時期還沒有保留
/// schema 快照）。為了確保重現得夠準，每個測試最後都會比對
/// 「升級後的欄位」與「全新安裝的欄位」是否一致。
library;

import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/data/database.dart';
import 'package:health/data/health_repository.dart';
import 'package:health/domain/meal_type.dart';
import 'package:health/domain/nutrition.dart';
import 'package:sqlite3/sqlite3.dart';

/// schemaVersion 1 時期的資料表。
const _v1Tables = [
  '''
CREATE TABLE user_profiles (
  id INTEGER NOT NULL DEFAULT 1,
  sex INTEGER NOT NULL,
  age INTEGER NOT NULL,
  height_cm REAL NOT NULL,
  weight_kg REAL NOT NULL,
  activity INTEGER NOT NULL,
  goal INTEGER NOT NULL,
  body_fat_pct REAL,
  PRIMARY KEY (id)
)''',
  '''
CREATE TABLE meal_entries (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  eaten_at INTEGER NOT NULL,
  name TEXT NOT NULL,
  calories REAL NOT NULL,
  protein_g REAL NOT NULL,
  fat_g REAL NOT NULL,
  carbs_g REAL NOT NULL
)''',
  '''
CREATE TABLE weight_entries (
  day INTEGER NOT NULL,
  weight_kg REAL NOT NULL,
  body_fat_pct REAL,
  PRIMARY KEY (day)
)''',
];

/// v2 相對於 v1 只多了餐別欄位。
const _v2Extra = 'ALTER TABLE meal_entries ADD COLUMN meal_type INTEGER';

/// drift 的 DateTime 預設存成 Unix 秒數。
int _toDriftDateTime(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

final _mealDay = DateTime(2026, 3, 15);
final _mealTime = DateTime(2026, 3, 15, 12, 30);

/// 建一個「使用者已經用了一陣子」的舊版資料庫。
File _createLegacyDatabase(Directory dir, int version) {
  final file = File('${dir.path}/health_v$version.db');
  final raw = sqlite3.open(file.path);

  for (final ddl in _v1Tables) {
    raw.execute(ddl);
  }
  if (version >= 2) raw.execute(_v2Extra);

  // 個人資料：女性(1) / 輕度活動(1) / 減脂(0)
  raw.execute(
    'INSERT INTO user_profiles '
    '(id, sex, age, height_cm, weight_kg, activity, goal, body_fat_pct) '
    'VALUES (1, ?, 28, 165, 65, ?, ?, 28)',
    [Sex.female.index, ActivityLevel.light.index, Goal.lose.index],
  );

  if (version >= 2) {
    raw.execute(
      'INSERT INTO meal_entries '
      '(eaten_at, name, calories, protein_g, fat_g, carbs_g, meal_type) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        _toDriftDateTime(_mealTime),
        '雞腿便當',
        800.0,
        35.0,
        25.0,
        90.0,
        MealType.lunch.index,
      ],
    );
  } else {
    raw.execute(
      'INSERT INTO meal_entries '
      '(eaten_at, name, calories, protein_g, fat_g, carbs_g) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      [_toDriftDateTime(_mealTime), '雞腿便當', 800.0, 35.0, 25.0, 90.0],
    );
  }

  raw.execute(
    'INSERT INTO weight_entries (day, weight_kg, body_fat_pct) VALUES (?, ?, ?)',
    [_toDriftDateTime(_mealDay), 65.0, 28.0],
  );

  raw.execute('PRAGMA user_version = $version');
  raw.close();
  return file;
}

Future<int> _userVersion(AppDatabase db) async {
  final row = await db.customSelect('PRAGMA user_version').getSingle();
  return row.data.values.first! as int;
}

Future<List<String>> _columnsOf(AppDatabase db, String table) async {
  final rows = await db.customSelect('PRAGMA table_info($table)').get();
  return [for (final r in rows) r.data['name']! as String]..sort();
}

Future<Map<String, List<String>>> _schemaShape(AppDatabase db) async {
  return {
    for (final t in ['user_profiles', 'meal_entries', 'weight_entries'])
      t: await _columnsOf(db, t),
  };
}

void main() {
  // 測試裡會同時開好幾個各自獨立的資料庫，這個警告在這裡是誤報。
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('health_migration');
  });

  tearDown(() async {
    try {
      await dir.delete(recursive: true);
    } on FileSystemException {
      // Windows 上偶爾還握著檔案 handle，清不掉就算了（是暫存目錄）
    }
  });

  /// 全新安裝（走 onCreate）長什麼樣子，作為升級結果的比對基準。
  Future<Map<String, List<String>>> freshSchemaShape() async {
    final fresh = AppDatabase(NativeDatabase.memory());
    final shape = await _schemaShape(fresh);
    await fresh.close();
    return shape;
  }

  test('全新安裝就是最新版', () async {
    final db = AppDatabase(NativeDatabase.memory());
    expect(await _userVersion(db), db.schemaVersion);
    expect(db.schemaVersion, 3);
    await db.close();
  });

  test('v1 資料庫升級到最新版：既有資料都在，新欄位為未設定', () async {
    final db = AppDatabase(NativeDatabase(_createLegacyDatabase(dir, 1)));
    final repo = DriftHealthRepository(db);

    final profile = await repo.getProfile(); // 第一次查詢會觸發升級
    expect(profile, isNotNull);
    expect(profile!.age, 28);
    expect(profile.weightKg, 65);
    expect(profile.bodyFatPct, 28);
    expect(profile.sex, Sex.female);
    expect(profile.goal, Goal.lose);
    // v3 才加的欄位 → 舊使用者維持未設定
    expect(profile.targetWeightKg, isNull);

    final meals = await repo.watchMealsOn(_mealDay).first;
    expect(meals.single.name, '雞腿便當');
    expect(meals.single.calories, 800);
    expect(meals.single.eatenAt, _mealTime);
    // v2 才加的欄位 → 舊餐點是「未分類」
    expect(meals.single.mealType, isNull);

    final weights = await repo
        .watchWeightsBetween(DateTime(2026, 3, 1), DateTime(2026, 3, 31))
        .first;
    expect(weights.single.weightKg, 65);
    expect(weights.single.bodyFatPct, 28);

    expect(await _userVersion(db), 3);
    expect(await _schemaShape(db), await freshSchemaShape());
    await db.close();
  });

  test('v2 資料庫升級到最新版：已經標好的餐別不會被弄丟', () async {
    final db = AppDatabase(NativeDatabase(_createLegacyDatabase(dir, 2)));
    final repo = DriftHealthRepository(db);

    final meals = await repo.watchMealsOn(_mealDay).first;
    expect(meals.single.name, '雞腿便當');
    expect(meals.single.mealType, MealType.lunch);
    expect((await repo.getProfile())!.targetWeightKg, isNull);

    expect(await _userVersion(db), 3);
    expect(await _schemaShape(db), await freshSchemaShape());
    await db.close();
  });

  test('升級後新欄位可以正常寫入（不是只讀得到 null）', () async {
    final db = AppDatabase(NativeDatabase(_createLegacyDatabase(dir, 1)));
    final repo = DriftHealthRepository(db);

    final before = (await repo.getProfile())!;
    await repo.saveProfile(UserProfile(
      sex: before.sex,
      age: before.age,
      heightCm: before.heightCm,
      weightKg: before.weightKg,
      activity: before.activity,
      goal: before.goal,
      bodyFatPct: before.bodyFatPct,
      targetWeightKg: 58,
    ));
    await repo.addMeal(
      eatenAt: DateTime(2026, 3, 15, 19),
      name: '晚餐',
      calories: 600,
      proteinG: 30,
      fatG: 20,
      carbsG: 70,
      mealType: MealType.dinner,
    );

    expect((await repo.getProfile())!.targetWeightKg, 58);
    final meals = await repo.watchMealsOn(_mealDay).first;
    final dinner = meals.firstWhere((m) => m.name == '晚餐');
    expect(dinner.mealType, MealType.dinner);
    // 舊資料還在
    expect(meals.any((m) => m.name == '雞腿便當'), isTrue);

    await db.close();
  });

  test('已經是最新版的資料庫不會被重跑升級', () async {
    final file = File('${dir.path}/health_current.db');

    final first = AppDatabase(NativeDatabase(file));
    final repo = DriftHealthRepository(first);
    await repo.addMeal(
      eatenAt: _mealTime,
      name: '便當',
      calories: 800,
      proteinG: 35,
      fatG: 25,
      carbsG: 90,
      mealType: MealType.lunch,
    );
    await first.close();

    // 重新開啟同一個檔案：版本相同 → 什麼都不該做
    final second = AppDatabase(NativeDatabase(file));
    final meals =
        await DriftHealthRepository(second).watchMealsOn(_mealDay).first;
    expect(meals.single.name, '便當');
    expect(meals.single.mealType, MealType.lunch);
    expect(await _userVersion(second), 3);
    await second.close();
  });
}
