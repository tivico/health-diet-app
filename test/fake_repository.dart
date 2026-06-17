import 'dart:async';

import 'package:health/data/database.dart';
import 'package:health/data/health_repository.dart';
import 'package:health/domain/nutrition.dart';

/// 記憶體假實作：讓 Widget 測試不依賴真實 SQLite，但仍能驗證讀寫流程。
/// 餐點與體重都依日期過濾，能測「切換日期看歷史」。
class FakeHealthRepository implements HealthRepository {
  UserProfile? _profile;
  final List<MealEntry> _meals = [];
  final List<WeightEntry> _weights = [];
  int _nextId = 1;

  final _profileCtrl = StreamController<UserProfile?>.broadcast();
  final _mealsChanged = StreamController<void>.broadcast();
  final _weightsChanged = StreamController<void>.broadcast();

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
    ));
    _mealsChanged.add(null);
    return id;
  }

  @override
  Future<void> deleteMeal(int id) async {
    _meals.removeWhere((m) => m.id == id);
    _mealsChanged.add(null);
  }

  // --- 體重（依日期過濾）---
  @override
  Stream<List<WeightEntry>> watchWeightsBetween(DateTime from, DateTime to) async* {
    yield _weightsInRange(from, to);
    yield* _weightsChanged.stream.map((_) => _weightsInRange(from, to));
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

  List<WeightEntry> _weightsInRange(DateTime from, DateTime to) {
    return _weights
        .where((w) => !w.day.isBefore(from) && !w.day.isAfter(to))
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));
  }
}
