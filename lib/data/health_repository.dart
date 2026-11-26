import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/activity.dart';
import '../domain/body_composition.dart';
import '../domain/meal_type.dart';
import '../domain/nutrition.dart';
import 'backup_file.dart';
import 'csv_export.dart';
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

  /// 最近的餐點紀錄（由新到舊），給「最近吃過」快選用。
  /// 取回來的是原始紀錄（同一樣食物可能出現多次），去重交給呼叫端。
  Stream<List<MealEntry>> watchRecentMeals({int limit = 100});
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

  // 體組成（一天一筆）
  /// 所有體組成紀錄，由舊到新。量測頻率低（幾週一次），不必分區間查。
  Stream<List<BodyComposition>> watchBodyCompositions();

  /// 新增或覆寫當天那筆。
  Future<void> upsertBodyComposition(BodyComposition entry);
  Future<void> deleteBodyComposition(DateTime day);

  // 運動
  /// 所有運動紀錄，新到舊；肌力訓練含各個動作（依記錄順序）。
  Stream<List<Activity>> watchActivities();

  /// [Activity.id] 是 null 就新增，否則修改（動作整份取代）。回傳 id。
  Future<int> saveActivity(Activity activity);
  Future<void> deleteActivity(int id);

  // 器材 / 動作清單
  /// 依名稱排序。
  Stream<List<Exercise>> watchExercises();

  /// 新增或修改。名稱重複丟 [DuplicateExerciseNameException]；
  /// 已經有紀錄的器材改單位丟 [StateError]（舊重量會被誤讀）。回傳 id。
  Future<int> saveExercise(Exercise exercise);

  /// 只刪得掉沒被任何紀錄用到的器材；用過的回傳 false、不會刪。
  Future<bool> deleteExercise(int id);

  // 備份
  /// 匯出所有資料成 JSON 字串。
  Future<String> exportJson();

  /// 從 JSON 字串還原（會覆蓋現有資料）。
  Future<void> importJson(String json);

  /// 匯出餐點成 CSV（試算表檢視用，**不能**用來還原）。
  Future<String> exportMealsCsv();

  /// 匯出體重紀錄成 CSV。
  Future<String> exportWeightsCsv();
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
        targetWeightKg: r.targetWeightKg,
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
            targetWeightKg: Value(p.targetWeightKg),
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
  Stream<List<MealEntry>> watchRecentMeals({int limit = 100}) {
    final q = _db.select(_db.mealEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.eatenAt)])
      ..limit(limit);
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

  // ===== 體組成 =====

  @override
  Stream<List<BodyComposition>> watchBodyCompositions() =>
      (_db.select(_db.bodyCompositions)
            ..orderBy([(t) => OrderingTerm.asc(t.day)]))
          .watch()
          .map((rows) => [for (final r in rows) _bodyFromRow(r)]);

  @override
  Future<void> upsertBodyComposition(BodyComposition entry) => _db
      .into(_db.bodyCompositions)
      .insertOnConflictUpdate(_bodyToCompanion(entry));

  @override
  Future<void> deleteBodyComposition(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return (_db.delete(_db.bodyCompositions)..where((t) => t.day.equals(d)))
        .go();
  }

  // ===== 運動 =====

  @override
  Stream<List<Activity>> watchActivities() {
    // 用 join 一起查：運動或動作任一張表有變動，畫面都會更新
    final query = _db.select(_db.activities).join([
      leftOuterJoin(_db.exerciseSets,
          _db.exerciseSets.activityId.equalsExp(_db.activities.id)),
    ])
      ..orderBy([
        OrderingTerm.desc(_db.activities.startedAt),
        OrderingTerm.asc(_db.exerciseSets.position),
      ]);
    return query.watch().map((rows) {
      // Map 會保留放進去的順序，也就是上面排好的「新到舊」
      final byId = <int, (ActivityRow, List<ExerciseSetRow>)>{};
      for (final row in rows) {
        final a = row.readTable(_db.activities);
        final entry = byId.putIfAbsent(a.id, () => (a, <ExerciseSetRow>[]));
        final s = row.readTableOrNull(_db.exerciseSets);
        if (s != null) entry.$2.add(s);
      }
      return [for (final (a, sets) in byId.values) _activityFromRow(a, sets)];
    });
  }

  @override
  Future<int> saveActivity(Activity activity) =>
      _db.transaction(() => _writeActivity(activity));

  /// 寫入一次運動與它的動作（呼叫端負責包在交易裡）。
  Future<int> _writeActivity(Activity a) async {
    final int id;
    if (a.id == null) {
      id = await _db.into(_db.activities).insert(_activityToCompanion(a));
    } else {
      id = a.id!;
      await (_db.update(_db.activities)..where((t) => t.id.equals(id)))
          .write(_activityToCompanion(a));
      await (_db.delete(_db.exerciseSets)..where((t) => t.activityId.equals(id)))
          .go();
    }
    for (final (i, s) in a.sets.indexed) {
      await _db.into(_db.exerciseSets).insert(ExerciseSetsCompanion.insert(
            activityId: id,
            exerciseId: s.exerciseId,
            position: i,
            weight: Value(s.weight),
            reps: Value(s.reps),
            sets: Value(s.sets),
          ));
    }
    return id;
  }

  @override
  Future<void> deleteActivity(int id) => _db.transaction(() async {
        await (_db.delete(_db.exerciseSets)
              ..where((t) => t.activityId.equals(id)))
            .go();
        await (_db.delete(_db.activities)..where((t) => t.id.equals(id))).go();
      });

  // ===== 器材 / 動作清單 =====

  @override
  Stream<List<Exercise>> watchExercises() =>
      (_db.select(_db.exercises)..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch()
          .map((rows) => [
                for (final r in rows)
                  Exercise(id: r.id, name: r.name, unit: r.unit),
              ]);

  Future<bool> _exerciseInUse(int id) async =>
      await (_db.select(_db.exerciseSets)
            ..where((t) => t.exerciseId.equals(id))
            ..limit(1))
          .getSingleOrNull() !=
      null;

  @override
  Future<int> saveExercise(Exercise exercise) => _db.transaction(() async {
        final name = exercise.name.trim();
        final id = exercise.id;
        final clash = await (_db.select(_db.exercises)
              ..where((t) => t.name.equals(name))
              ..limit(1))
            .getSingleOrNull();
        if (clash != null && clash.id != id) {
          throw DuplicateExerciseNameException(name);
        }
        if (id == null) {
          return _db
              .into(_db.exercises)
              .insert(ExercisesCompanion.insert(name: name, unit: exercise.unit));
        }
        final current = await (_db.select(_db.exercises)
              ..where((t) => t.id.equals(id)))
            .getSingle();
        if (current.unit != exercise.unit && await _exerciseInUse(id)) {
          throw StateError('已經有紀錄的器材不能改單位');
        }
        await (_db.update(_db.exercises)..where((t) => t.id.equals(id))).write(
            ExercisesCompanion(name: Value(name), unit: Value(exercise.unit)));
        return id;
      });

  @override
  Future<bool> deleteExercise(int id) => _db.transaction(() async {
        if (await _exerciseInUse(id)) return false;
        await (_db.delete(_db.exercises)..where((t) => t.id.equals(id))).go();
        return true;
      });

  // ===== 備份 =====

  @override
  Future<String> exportMealsCsv() async {
    final meals = await (_db.select(_db.mealEntries)
          ..orderBy([(t) => OrderingTerm.asc(t.eatenAt)]))
        .get();
    return mealsToCsv(meals);
  }

  @override
  Future<String> exportWeightsCsv() async {
    final weights = await (_db.select(_db.weightEntries)
          ..orderBy([(t) => OrderingTerm.asc(t.day)]))
        .get();
    return weightsToCsv(weights);
  }

  @override
  Future<String> exportJson() async {
    final profileRow =
        await (_db.select(_db.userProfiles)..where((t) => t.id.equals(1)))
            .getSingleOrNull();
    final meals = await _db.select(_db.mealEntries).get();
    final weights = await _db.select(_db.weightEntries).get();
    final bodies = await _db.select(_db.bodyCompositions).get();
    final exercises = await watchExercises().first;
    final activities = await watchActivities().first;

    final map = <String, dynamic>{
      // 舊備份缺少後來才加的資料（v2 的 mealType、v3 的 targetWeightKg、
      // v4 的 bodyCompositions、v5 的 exercises / activities），匯入時一律當作沒有。
      'version': 5,
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
      'bodyCompositions': [
        for (final b in bodies) bodyCompositionToJson(_bodyFromRow(b)),
      ],
      'exercises': [for (final e in exercises) exerciseToJson(e)],
      'activities': [for (final a in activities) activityToJson(a)],
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  @override
  Future<void> importJson(String json) async {
    final map = jsonDecode(json) as Map<String, dynamic>;
    await _db.transaction(() async {
      await _db.delete(_db.mealEntries).go();
      await _db.delete(_db.weightEntries).go();
      await _db.delete(_db.bodyCompositions).go();
      // 動作參照運動與器材，要最先刪
      await _db.delete(_db.exerciseSets).go();
      await _db.delete(_db.activities).go();
      await _db.delete(_db.exercises).go();
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
      for (final b in (map['bodyCompositions'] as List? ?? const [])) {
        await upsertBodyComposition(
            bodyCompositionFromJson(b as Map<String, dynamic>));
      }
      // 器材重新編號，動作再照「舊編號 → 新編號」接回去
      final exerciseIds = <int, int>{};
      for (final e in (map['exercises'] as List? ?? const [])) {
        final ex = exerciseFromJson(e as Map<String, dynamic>);
        exerciseIds[ex.id!] = await _db
            .into(_db.exercises)
            .insert(ExercisesCompanion.insert(name: ex.name, unit: ex.unit));
      }
      for (final a in (map['activities'] as List? ?? const [])) {
        await _writeActivity(activityFromJson(a as Map<String, dynamic>,
            exerciseIds: exerciseIds));
      }
    });
  }
}

/// 資料列 → domain 的運動。
Activity _activityFromRow(ActivityRow r, List<ExerciseSetRow> sets) {
  Duration? sec(int? s) => s == null ? null : Duration(seconds: s);
  return Activity(
    id: r.id,
    startedAt: r.startedAt,
    kind: r.kind,
    title: r.title,
    duration: Duration(seconds: r.durationSec),
    distanceKm: r.distanceKm,
    calories: r.calories,
    activeCalories: r.activeCalories,
    avgHr: r.avgHr,
    maxHr: r.maxHr,
    zones: [
      sec(r.zone1Sec),
      sec(r.zone2Sec),
      sec(r.zone3Sec),
      sec(r.zone4Sec),
      sec(r.zone5Sec),
    ],
    feeling: r.feeling,
    garminActivityId: r.garminActivityId,
    sets: [
      for (final s in sets)
        ExerciseSet(
          exerciseId: s.exerciseId,
          weight: s.weight,
          reps: s.reps,
          sets: s.sets,
        ),
    ],
  );
}

/// domain → 寫入用的 companion（不含 id；沒填的寫 null，修改時才會清掉舊值）。
ActivitiesCompanion _activityToCompanion(Activity a) {
  Value<int?> zone(int i) => Value(a.zones[i]?.inSeconds);
  return ActivitiesCompanion.insert(
    startedAt: a.startedAt,
    kind: a.kind,
    title: Value(a.title),
    durationSec: a.duration.inSeconds,
    distanceKm: Value(a.distanceKm),
    calories: Value(a.calories),
    activeCalories: Value(a.activeCalories),
    avgHr: Value(a.avgHr),
    maxHr: Value(a.maxHr),
    zone1Sec: zone(0),
    zone2Sec: zone(1),
    zone3Sec: zone(2),
    zone4Sec: zone(3),
    zone5Sec: zone(4),
    feeling: Value(a.feeling),
    garminActivityId: Value(a.garminActivityId),
  );
}

/// 資料列 → domain 的體組成：每個欄位對應一個 [BodyMetric]，null（沒量到）就略過。
BodyComposition _bodyFromRow(BodyCompositionRow r) => BodyComposition(
      day: r.day,
      values: {
        for (final (metric, value) in [
          (BodyMetric.weight, r.weightKg),
          (BodyMetric.bodyFat, r.bodyFatPct),
          (BodyMetric.fatMass, r.fatMassKg),
          (BodyMetric.skeletalMuscle, r.skeletalMuscleKg),
          (BodyMetric.muscleMass, r.muscleMassKg),
          (BodyMetric.water, r.waterKg),
          (BodyMetric.fatFreeMass, r.fatFreeMassKg),
          (BodyMetric.subcutaneousFat, r.subcutaneousFatPct),
          (BodyMetric.visceralFat, r.visceralFatLevel),
          (BodyMetric.bmr, r.bmrKcal),
          (BodyMetric.asmi, r.asmi),
          (BodyMetric.bodyAge, r.bodyAge),
          (BodyMetric.waist, r.waistCm),
          (BodyMetric.hip, r.hipCm),
          (BodyMetric.arm, r.armCm),
          (BodyMetric.thigh, r.thighCm),
          (BodyMetric.neck, r.neckCm),
          (BodyMetric.chest, r.chestCm),
        ])
          metric: ?value,
      },
      source: r.source,
      note: r.note,
    );

/// domain → 寫入用的 companion。沒量到的項目寫 null，覆寫時才會清掉舊值。
BodyCompositionsCompanion _bodyToCompanion(BodyComposition b) {
  Value<double?> v(BodyMetric m) => Value(b.valueOf(m));
  return BodyCompositionsCompanion.insert(
    day: b.day,
    weightKg: b.weightKg,
    bodyFatPct: v(BodyMetric.bodyFat),
    fatMassKg: v(BodyMetric.fatMass),
    skeletalMuscleKg: v(BodyMetric.skeletalMuscle),
    muscleMassKg: v(BodyMetric.muscleMass),
    waterKg: v(BodyMetric.water),
    fatFreeMassKg: v(BodyMetric.fatFreeMass),
    subcutaneousFatPct: v(BodyMetric.subcutaneousFat),
    visceralFatLevel: v(BodyMetric.visceralFat),
    bmrKcal: v(BodyMetric.bmr),
    asmi: v(BodyMetric.asmi),
    bodyAge: v(BodyMetric.bodyAge),
    waistCm: v(BodyMetric.waist),
    hipCm: v(BodyMetric.hip),
    armCm: v(BodyMetric.arm),
    thighCm: v(BodyMetric.thigh),
    neckCm: v(BodyMetric.neck),
    chestCm: v(BodyMetric.chest),
    source: Value(b.source),
    note: Value(b.note),
  );
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
      'targetWeightKg': p.targetWeightKg,
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
      targetWeightKg: m['targetWeightKg'] == null
          ? null
          : (m['targetWeightKg'] as num).toDouble(),
    );
