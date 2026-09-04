import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/meal_type.dart';
import '../domain/nutrition.dart';
import 'database.dart';

/// 某一天的營養加總（純值物件，給 UI 顯示用）。
class DailyTotals {
  final double calories;
  final double proteinG;
  final double fatG;
  final double carbsG;
  final int mealCount;

  const DailyTotals({
    this.calories = 0,
    this.proteinG = 0,
    this.fatG = 0,
    this.carbsG = 0,
    this.mealCount = 0,
  });
}

/// 資料存取層介面。對外回傳 domain 型別與 Stream，UI / Riverpod 不需認識 drift。
/// 抽成介面是為了好測試：正式用 [DriftHealthRepository]，測試可注入假實作。
abstract class HealthRepository {
  // 使用者資料（單一使用者）
  Stream<UserProfile?> watchProfile();
  Future<UserProfile?> getProfile();
  Future<void> saveProfile(UserProfile p);

  // 餐點
  Stream<List<MealEntry>> watchMealsOn(DateTime day);

  /// 某段日期區間（含頭尾兩天）的所有餐點，給統計用。
  Stream<List<MealEntry>> watchMealsBetween(DateTime from, DateTime to);
  Stream<DailyTotals> watchDailyTotals(DateTime day);
  /// [mealType] 省略時存成 null（未分類）。
  Future<int> addMeal({
    required DateTime eatenAt,
    required String name,
    required double calories,
    required double proteinG,
    required double fatG,
    required double carbsG,
    MealType? mealType,
  });
  Future<void> updateMeal({
    required int id,
    required DateTime eatenAt,
    required String name,
    required double calories,
    required double proteinG,
    required double fatG,
    required double carbsG,
    MealType? mealType,
  });
  Future<void> deleteMeal(int id);

  // 體重（一天一筆）
  Stream<List<WeightEntry>> watchWeightsBetween(DateTime from, DateTime to);
  Future<void> upsertWeight({
    required DateTime day,
    required double weightKg,
    double? bodyFatPct,
  });
  Future<void> deleteWeight(DateTime day);

  // 備份
  /// 匯出所有資料成 JSON 字串。
  Future<String> exportJson();

  /// 從 JSON 字串還原（會覆蓋現有資料）。
  Future<void> importJson(String json);
}

/// 以 drift 實作的資料存取層。
class DriftHealthRepository implements HealthRepository {
  DriftHealthRepository(this._db);
  final AppDatabase _db;

  /// 某天的 [午夜, 隔天午夜) 區間，用來查「某一天」的資料。
  (DateTime, DateTime) _dayBounds(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    return (start, start.add(const Duration(days: 1)));
  }

  UserProfile _toDomain(UserProfileRow r) => UserProfile(
        sex: r.sex,
        age: r.age,
        heightCm: r.heightCm,
        weightKg: r.weightKg,
        activity: r.activity,
        goal: r.goal,
        bodyFatPct: r.bodyFatPct,
      );

  @override
  Stream<UserProfile?> watchProfile() {
    final q = _db.select(_db.userProfiles)..where((t) => t.id.equals(1));
    return q.watchSingleOrNull().map((r) => r == null ? null : _toDomain(r));
  }

  @override
  Future<UserProfile?> getProfile() async {
    final q = _db.select(_db.userProfiles)..where((t) => t.id.equals(1));
    final r = await q.getSingleOrNull();
    return r == null ? null : _toDomain(r);
  }

  @override
  Future<void> saveProfile(UserProfile p) {
    return _db.into(_db.userProfiles).insertOnConflictUpdate(
          UserProfilesCompanion(
            id: const Value(1),
            sex: Value(p.sex),
            age: Value(p.age),
            heightCm: Value(p.heightCm),
            weightKg: Value(p.weightKg),
            activity: Value(p.activity),
            goal: Value(p.goal),
            bodyFatPct: Value(p.bodyFatPct),
          ),
        );
  }

  @override
  Stream<List<MealEntry>> watchMealsOn(DateTime day) {
    final (start, end) = _dayBounds(day);
    final q = _db.select(_db.mealEntries)
      ..where((t) =>
          t.eatenAt.isBiggerOrEqualValue(start) &
          t.eatenAt.isSmallerThanValue(end))
      ..orderBy([(t) => OrderingTerm.desc(t.eatenAt)]);
    return q.watch();
  }

  @override
  Stream<List<MealEntry>> watchMealsBetween(DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day).add(const Duration(days: 1));
    final q = _db.select(_db.mealEntries)
      ..where((t) =>
          t.eatenAt.isBiggerOrEqualValue(start) &
          t.eatenAt.isSmallerThanValue(end))
      ..orderBy([(t) => OrderingTerm.asc(t.eatenAt)]);
    return q.watch();
  }

  @override
  Stream<DailyTotals> watchDailyTotals(DateTime day) {
    final (start, end) = _dayBounds(day);
    final cal = _db.mealEntries.calories.sum();
    final pro = _db.mealEntries.proteinG.sum();
    final fat = _db.mealEntries.fatG.sum();
    final carb = _db.mealEntries.carbsG.sum();
    final cnt = _db.mealEntries.id.count();
    final q = _db.selectOnly(_db.mealEntries)
      ..addColumns([cal, pro, fat, carb, cnt])
      ..where(_db.mealEntries.eatenAt.isBiggerOrEqualValue(start) &
          _db.mealEntries.eatenAt.isSmallerThanValue(end));
    return q.watchSingle().map((row) => DailyTotals(
          calories: row.read(cal) ?? 0.0,
          proteinG: row.read(pro) ?? 0.0,
          fatG: row.read(fat) ?? 0.0,
          carbsG: row.read(carb) ?? 0.0,
          mealCount: row.read(cnt) ?? 0,
        ));
  }

  @override
  Future<int> addMeal({
    required DateTime eatenAt,
    required String name,
    required double calories,
    required double proteinG,
    required double fatG,
    required double carbsG,
    MealType? mealType,
  }) {
    return _db.into(_db.mealEntries).insert(MealEntriesCompanion.insert(
          eatenAt: eatenAt,
          name: name,
          calories: calories,
          proteinG: proteinG,
          fatG: fatG,
          carbsG: carbsG,
          mealType: Value(mealType),
        ));
  }

  @override
  Future<void> updateMeal({
    required int id,
    required DateTime eatenAt,
    required String name,
    required double calories,
    required double proteinG,
    required double fatG,
    required double carbsG,
    MealType? mealType,
  }) {
    return (_db.update(_db.mealEntries)..where((t) => t.id.equals(id))).write(
      MealEntriesCompanion(
        eatenAt: Value(eatenAt),
        name: Value(name),
        calories: Value(calories),
        proteinG: Value(proteinG),
        fatG: Value(fatG),
        carbsG: Value(carbsG),
        mealType: Value(mealType),
      ),
    );
  }

  @override
  Future<void> deleteMeal(int id) {
    return (_db.delete(_db.mealEntries)..where((t) => t.id.equals(id))).go();
  }

  @override
  Stream<List<WeightEntry>> watchWeightsBetween(DateTime from, DateTime to) {
    final q = _db.select(_db.weightEntries)
      ..where((t) =>
          t.day.isBiggerOrEqualValue(from) & t.day.isSmallerOrEqualValue(to))
      ..orderBy([(t) => OrderingTerm.asc(t.day)]);
    return q.watch();
  }

  @override
  Future<void> upsertWeight({
    required DateTime day,
    required double weightKg,
    double? bodyFatPct,
  }) {
    final d = DateTime(day.year, day.month, day.day);
    return _db.into(_db.weightEntries).insertOnConflictUpdate(
          WeightEntriesCompanion(
            day: Value(d),
            weightKg: Value(weightKg),
            bodyFatPct: Value(bodyFatPct),
          ),
        );
  }

  @override
  Future<void> deleteWeight(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return (_db.delete(_db.weightEntries)..where((t) => t.day.equals(d))).go();
  }

  // ===== 備份 =====

  @override
  Future<String> exportJson() async {
    final profileRow =
        await (_db.select(_db.userProfiles)..where((t) => t.id.equals(1)))
            .getSingleOrNull();
    final meals = await _db.select(_db.mealEntries).get();
    final weights = await _db.select(_db.weightEntries).get();

    final map = <String, dynamic>{
      // v2 起多了餐點的 mealType；舊備份沒有這個 key，匯入時視為未分類。
      'version': 2,
      'profile': profileRow == null ? null : _profileToMap(_toDomain(profileRow)),
      'meals': [
        for (final m in meals)
          {
            'eatenAt': m.eatenAt.toIso8601String(),
            'name': m.name,
            'calories': m.calories,
            'proteinG': m.proteinG,
            'fatG': m.fatG,
            'carbsG': m.carbsG,
            'mealType': m.mealType?.name,
          }
      ],
      'weights': [
        for (final w in weights)
          {
            'day': w.day.toIso8601String(),
            'weightKg': w.weightKg,
            'bodyFatPct': w.bodyFatPct,
          }
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  @override
  Future<void> importJson(String json) async {
    final map = jsonDecode(json) as Map<String, dynamic>;
    await _db.transaction(() async {
      await _db.delete(_db.mealEntries).go();
      await _db.delete(_db.weightEntries).go();
      await _db.delete(_db.userProfiles).go();

      final p = map['profile'];
      if (p is Map<String, dynamic>) {
        await saveProfile(_profileFromMap(p));
      }
      for (final m in (map['meals'] as List? ?? const [])) {
        final mm = m as Map<String, dynamic>;
        await addMeal(
          eatenAt: DateTime.parse(mm['eatenAt'] as String),
          name: mm['name'] as String,
          calories: (mm['calories'] as num).toDouble(),
          proteinG: (mm['proteinG'] as num).toDouble(),
          fatG: (mm['fatG'] as num).toDouble(),
          carbsG: (mm['carbsG'] as num).toDouble(),
          mealType: mealTypeFromName(mm['mealType'] as String?),
        );
      }
      for (final w in (map['weights'] as List? ?? const [])) {
        final ww = w as Map<String, dynamic>;
        final day = DateTime.parse(ww['day'] as String);
        await upsertWeight(
          day: day,
          weightKg: (ww['weightKg'] as num).toDouble(),
          bodyFatPct: ww['bodyFatPct'] == null
              ? null
              : (ww['bodyFatPct'] as num).toDouble(),
        );
      }
    });
  }
}

/// 個人資料的 JSON 對應（enum 存名稱，跨版本較穩），備份共用。
Map<String, dynamic> _profileToMap(UserProfile p) => {
      'sex': p.sex.name,
      'age': p.age,
      'heightCm': p.heightCm,
      'weightKg': p.weightKg,
      'activity': p.activity.name,
      'goal': p.goal.name,
      'bodyFatPct': p.bodyFatPct,
    };

UserProfile _profileFromMap(Map<String, dynamic> m) => UserProfile(
      sex: Sex.values.byName(m['sex'] as String),
      age: m['age'] as int,
      heightCm: (m['heightCm'] as num).toDouble(),
      weightKg: (m['weightKg'] as num).toDouble(),
      activity: ActivityLevel.values.byName(m['activity'] as String),
      goal: Goal.values.byName(m['goal'] as String),
      bodyFatPct:
          m['bodyFatPct'] == null ? null : (m['bodyFatPct'] as num).toDouble(),
    );
