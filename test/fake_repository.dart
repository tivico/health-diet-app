import 'dart:async';
import 'dart:convert';

import 'package:health/data/backup_file.dart';
import 'package:health/data/csv_export.dart';
import 'package:health/data/database.dart';
import 'package:health/data/health_repository.dart';
import 'package:health/domain/activity.dart';
import 'package:health/domain/body_composition.dart';
import 'package:health/domain/meal_type.dart';
import 'package:health/domain/nutrition.dart';

/// 記憶體假實作：讓 Widget 測試不依賴真實 SQLite，但仍能驗證讀寫流程。
/// 餐點與體重都依日期過濾，能測「切換日期看歷史」。
class FakeHealthRepository implements HealthRepository {
  UserProfile? _profile;
  final List<MealEntry> _meals = [];
  final List<WeightEntry> _weights = [];
  final List<BodyComposition> _bodies = [];
  final List<Activity> _activities = [];
  final List<Exercise> _exercises = [];
  int _nextId = 1;

  final _profileCtrl = StreamController<UserProfile?>.broadcast();
  final _mealsChanged = StreamController<void>.broadcast();
  final _weightsChanged = StreamController<void>.broadcast();
  final _bodiesChanged = StreamController<void>.broadcast();
  final _activitiesChanged = StreamController<void>.broadcast();
  final _exercisesChanged = StreamController<void>.broadcast();

  FakeHealthRepository([this._profile]);

  // --- 使用者資料 ---
  @override
  Stream<UserProfile?> watchProfile() async* {
    yield _profile;
    yield* _profileCtrl.stream;
  }

  @override
  Future<UserProfile?> getProfile() async => _profile;

  @override
  Future<void> saveProfile(UserProfile p) async {
    _profile = p;
    _profileCtrl.add(p);
  }

  // --- 餐點（依日期過濾）---
  @override
  Stream<List<MealEntry>> watchMealsOn(DateTime day) async* {
    yield _mealsOn(day);
    yield* _mealsChanged.stream.map((_) => _mealsOn(day));
  }

  @override
  Stream<List<MealEntry>> watchMealsBetween(DateTime from, DateTime to) async* {
    List<MealEntry> inRange() {
      final s = DateTime(from.year, from.month, from.day);
      final e = DateTime(to.year, to.month, to.day).add(const Duration(days: 1));
      return _meals
          .where((m) => !m.eatenAt.isBefore(s) && m.eatenAt.isBefore(e))
          .toList()
        ..sort((a, b) => a.eatenAt.compareTo(b.eatenAt));
    }

    yield inRange();
    yield* _mealsChanged.stream.map((_) => inRange());
  }

  @override
  Stream<List<MealEntry>> watchRecentMeals({int limit = 100}) async* {
    List<MealEntry> recent() =>
        (_meals.toList()..sort((a, b) => b.eatenAt.compareTo(a.eatenAt)))
            .take(limit)
            .toList();

    yield recent();
    yield* _mealsChanged.stream.map((_) => recent());
  }

  @override
  Stream<DailyTotals> watchDailyTotals(DateTime day) async* {
    yield _totalsOn(day);
    yield* _mealsChanged.stream.map((_) => _totalsOn(day));
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
  }) async {
    final id = _nextId++;
    _meals.add(MealEntry(
      id: id,
      eatenAt: eatenAt,
      name: name,
      calories: calories,
      proteinG: proteinG,
      fatG: fatG,
      carbsG: carbsG,
      mealType: mealType,
    ));
    _mealsChanged.add(null);
    return id;
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
  }) async {
    final i = _meals.indexWhere((m) => m.id == id);
    if (i != -1) {
      _meals[i] = MealEntry(
        id: id,
        eatenAt: eatenAt,
        name: name,
        calories: calories,
        proteinG: proteinG,
        fatG: fatG,
        carbsG: carbsG,
        mealType: mealType,
      );
      _mealsChanged.add(null);
    }
  }

  @override
  Future<void> deleteMeal(int id) async {
    _meals.removeWhere((m) => m.id == id);
    _mealsChanged.add(null);
  }

  // --- 體重（依日期過濾）---
  @override
  Stream<List<WeightEntry>> watchWeightsBetween(DateTime from, DateTime to) async* {
    yield _inRange(from, to);
    yield* _weightsChanged.stream.map((_) => _inRange(from, to));
  }

  @override
  Future<void> upsertWeight({
    required DateTime day,
    required double weightKg,
    double? bodyFatPct,
  }) async {
    final d = DateTime(day.year, day.month, day.day);
    _weights.removeWhere((w) => w.day == d);
    _weights.add(WeightEntry(day: d, weightKg: weightKg, bodyFatPct: bodyFatPct));
    _weightsChanged.add(null);
  }

  @override
  Future<void> deleteWeight(DateTime day) async {
    final d = DateTime(day.year, day.month, day.day);
    _weights.removeWhere((w) => w.day == d);
    _weightsChanged.add(null);
  }

  // --- 體組成（一天一筆，由舊到新）---
  @override
  Stream<List<BodyComposition>> watchBodyCompositions() async* {
    List<BodyComposition> sorted() =>
        _bodies.toList()..sort((a, b) => a.day.compareTo(b.day));
    yield sorted();
    yield* _bodiesChanged.stream.map((_) => sorted());
  }

  @override
  Future<void> upsertBodyComposition(BodyComposition entry) async {
    _bodies
      ..removeWhere((b) => b.day == entry.day)
      ..add(entry);
    _bodiesChanged.add(null);
  }

  @override
  Future<void> deleteBodyComposition(DateTime day) async {
    final d = DateTime(day.year, day.month, day.day);
    _bodies.removeWhere((b) => b.day == d);
    _bodiesChanged.add(null);
  }

  // --- 運動（新到舊）---
  @override
  Stream<List<Activity>> watchActivities() async* {
    List<Activity> sorted() =>
        _activities.toList()..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    yield sorted();
    yield* _activitiesChanged.stream.map((_) => sorted());
  }

  @override
  Future<int> saveActivity(Activity a) async {
    final id = a.id ?? _nextId++;
    _activities
      ..removeWhere((x) => x.id == id)
      ..add(Activity(
        id: id,
        startedAt: a.startedAt,
        kind: a.kind,
        title: a.title,
        duration: a.duration,
        distanceKm: a.distanceKm,
        calories: a.calories,
        activeCalories: a.activeCalories,
        avgHr: a.avgHr,
        maxHr: a.maxHr,
        zones: a.zones,
        feeling: a.feeling,
        garminActivityId: a.garminActivityId,
        sets: a.sets,
      ));
    _activitiesChanged.add(null);
    return id;
  }

  @override
  Future<void> deleteActivity(int id) async {
    _activities.removeWhere((a) => a.id == id);
    _activitiesChanged.add(null);
  }

  // --- 器材（依名稱排序）---
  @override
  Stream<List<Exercise>> watchExercises() async* {
    List<Exercise> sorted() =>
        _exercises.toList()..sort((a, b) => a.name.compareTo(b.name));
    yield sorted();
    yield* _exercisesChanged.stream.map((_) => sorted());
  }

  bool _exerciseInUse(int id) =>
      _activities.any((a) => a.sets.any((s) => s.exerciseId == id));

  @override
  Future<int> saveExercise(Exercise e) async {
    final name = e.name.trim();
    if (_exercises.any((x) => x.name == name && x.id != e.id)) {
      throw DuplicateExerciseNameException(name);
    }
    if (e.id != null) {
      final current = _exercises.firstWhere((x) => x.id == e.id);
      if (current.unit != e.unit && _exerciseInUse(e.id!)) {
        throw StateError('已經有紀錄的器材不能改單位');
      }
    }
    final id = e.id ?? _nextId++;
    _exercises
      ..removeWhere((x) => x.id == id)
      ..add(Exercise(id: id, name: name, unit: e.unit));
    _exercisesChanged.add(null);
    return id;
  }

  @override
  Future<bool> deleteExercise(int id) async {
    if (_exerciseInUse(id)) return false;
    _exercises.removeWhere((x) => x.id == id);
    _exercisesChanged.add(null);
    return true;
  }

  // --- 備份 ---
  @override
  Future<String> exportMealsCsv() async => mealsToCsv(
      _meals.toList()..sort((a, b) => a.eatenAt.compareTo(b.eatenAt)));

  @override
  Future<String> exportWeightsCsv() async =>
      weightsToCsv(_weights.toList()..sort((a, b) => a.day.compareTo(b.day)));

  @override
  Future<String> exportJson() async {
    final p = _profile;
    final map = <String, dynamic>{
      'version': 5,
      'profile': p == null
          ? null
          : {
              'sex': p.sex.name,
              'age': p.age,
              'heightCm': p.heightCm,
              'weightKg': p.weightKg,
              'activity': p.activity.name,
              'goal': p.goal.name,
              'bodyFatPct': p.bodyFatPct,
              'targetWeightKg': p.targetWeightKg,
            },
      'meals': [
        for (final m in _meals)
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
        for (final w in _weights)
          {
            'day': w.day.toIso8601String(),
            'weightKg': w.weightKg,
            'bodyFatPct': w.bodyFatPct,
          }
      ],
      'bodyCompositions': [for (final b in _bodies) bodyCompositionToJson(b)],
      'exercises': [for (final e in _exercises) exerciseToJson(e)],
      'activities': [for (final a in _activities) activityToJson(a)],
    };
    return jsonEncode(map);
  }

  @override
  Future<void> importJson(String json) async {
    final map = jsonDecode(json) as Map<String, dynamic>;
    _meals.clear();
    _weights.clear();
    _bodies.clear();
    _activities.clear();
    _exercises.clear();
    final p = map['profile'];
    if (p is Map<String, dynamic>) {
      _profile = UserProfile(
        sex: Sex.values.byName(p['sex'] as String),
        age: p['age'] as int,
        heightCm: (p['heightCm'] as num).toDouble(),
        weightKg: (p['weightKg'] as num).toDouble(),
        activity: ActivityLevel.values.byName(p['activity'] as String),
        goal: Goal.values.byName(p['goal'] as String),
        bodyFatPct:
            p['bodyFatPct'] == null ? null : (p['bodyFatPct'] as num).toDouble(),
        targetWeightKg: p['targetWeightKg'] == null
            ? null
            : (p['targetWeightKg'] as num).toDouble(),
      );
      _profileCtrl.add(_profile);
    }
    for (final m in (map['meals'] as List? ?? const [])) {
      final mm = m as Map<String, dynamic>;
      _meals.add(MealEntry(
        id: _nextId++,
        eatenAt: DateTime.parse(mm['eatenAt'] as String),
        name: mm['name'] as String,
        calories: (mm['calories'] as num).toDouble(),
        proteinG: (mm['proteinG'] as num).toDouble(),
        fatG: (mm['fatG'] as num).toDouble(),
        carbsG: (mm['carbsG'] as num).toDouble(),
        mealType: mealTypeFromName(mm['mealType'] as String?),
      ));
    }
    for (final w in (map['weights'] as List? ?? const [])) {
      final ww = w as Map<String, dynamic>;
      final day = DateTime.parse(ww['day'] as String);
      _weights.add(WeightEntry(
        day: DateTime(day.year, day.month, day.day),
        weightKg: (ww['weightKg'] as num).toDouble(),
        bodyFatPct:
            ww['bodyFatPct'] == null ? null : (ww['bodyFatPct'] as num).toDouble(),
      ));
    }
    for (final b in (map['bodyCompositions'] as List? ?? const [])) {
      _bodies.add(bodyCompositionFromJson(b as Map<String, dynamic>));
    }
    final exerciseIds = <int, int>{};
    for (final e in (map['exercises'] as List? ?? const [])) {
      final ex = exerciseFromJson(e as Map<String, dynamic>);
      final id = _nextId++;
      exerciseIds[ex.id!] = id;
      _exercises.add(Exercise(id: id, name: ex.name, unit: ex.unit));
    }
    for (final a in (map['activities'] as List? ?? const [])) {
      await saveActivity(activityFromJson(a as Map<String, dynamic>,
          exerciseIds: exerciseIds));
    }
    _mealsChanged.add(null);
    _weightsChanged.add(null);
    _bodiesChanged.add(null);
    _exercisesChanged.add(null);
  }

  // --- helpers ---
  List<MealEntry> _mealsOn(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final next = d.add(const Duration(days: 1));
    return _meals
        .where((m) => !m.eatenAt.isBefore(d) && m.eatenAt.isBefore(next))
        .toList()
      ..sort((a, b) => b.eatenAt.compareTo(a.eatenAt));
  }

  DailyTotals _totalsOn(DateTime day) {
    var c = 0.0, p = 0.0, f = 0.0, cb = 0.0;
    var n = 0;
    for (final m in _mealsOn(day)) {
      c += m.calories;
      p += m.proteinG;
      f += m.fatG;
      cb += m.carbsG;
      n++;
    }
    return DailyTotals(
        calories: c, proteinG: p, fatG: f, carbsG: cb, mealCount: n);
  }

  List<WeightEntry> _inRange(DateTime from, DateTime to) {
    return _weights
        .where((w) => !w.day.isBefore(from) && !w.day.isAfter(to))
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));
  }
}
