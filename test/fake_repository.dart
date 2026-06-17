import 'dart:async';

import 'package:health/data/database.dart';
import 'package:health/data/health_repository.dart';
import 'package:health/domain/nutrition.dart';

/// 記憶體假實作：讓 Widget 測試不依賴真實 SQLite，但仍能驗證讀寫流程。
class FakeHealthRepository implements HealthRepository {
  UserProfile? _profile;
  final List<MealEntry> _meals = [];
  final List<WeightEntry> _weights = [];
  int _nextId = 1;

  final _profileCtrl = StreamController<UserProfile?>.broadcast();
  final _mealsCtrl = StreamController<List<MealEntry>>.broadcast();
  final _totalsCtrl = StreamController<DailyTotals>.broadcast();
  final _weightsCtrl = StreamController<void>.broadcast();

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

  // --- 餐點 ---
  @override
  Stream<List<MealEntry>> watchMealsOn(DateTime day) async* {
    yield List.unmodifiable(_meals);
    yield* _mealsCtrl.stream;
  }

  @override
  Stream<DailyTotals> watchDailyTotals(DateTime day) async* {
    yield _totals();
    yield* _totalsCtrl.stream;
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
    _emitMeals();
    return id;
  }

  @override
  Future<void> deleteMeal(int id) async {
    _meals.removeWhere((m) => m.id == id);
    _emitMeals();
  }

  // --- 體重 ---
  @override
  Stream<List<WeightEntry>> watchWeightsBetween(DateTime from, DateTime to) async* {
    yield _inRange(from, to);
    yield* _weightsCtrl.stream.map((_) => _inRange(from, to));
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
    _weightsCtrl.add(null);
  }

  @override
  Future<void> deleteWeight(DateTime day) async {
    final d = DateTime(day.year, day.month, day.day);
    _weights.removeWhere((w) => w.day == d);
    _weightsCtrl.add(null);
  }

  // --- helpers ---
  void _emitMeals() {
    _mealsCtrl.add(List.unmodifiable(_meals));
    _totalsCtrl.add(_totals());
  }

  DailyTotals _totals() {
    var c = 0.0, p = 0.0, f = 0.0, cb = 0.0;
    for (final m in _meals) {
      c += m.calories;
      p += m.proteinG;
      f += m.fatG;
      cb += m.carbsG;
    }
    return DailyTotals(
      calories: c,
      proteinG: p,
      fatG: f,
      carbsG: cb,
      mealCount: _meals.length,
    );
  }

  List<WeightEntry> _inRange(DateTime from, DateTime to) {
    final list = _weights
        .where((w) => !w.day.isBefore(from) && !w.day.isAfter(to))
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    return list;
  }
}
