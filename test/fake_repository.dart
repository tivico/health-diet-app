import 'dart:async';

import 'package:health/data/database.dart';
import 'package:health/data/health_repository.dart';
import 'package:health/domain/nutrition.dart';

/// 記憶體假實作：讓 Widget 測試不依賴真實 SQLite，但仍能驗證讀寫流程。
class FakeHealthRepository implements HealthRepository {
  UserProfile? _profile;
  final List<MealEntry> _meals = [];
  int _nextId = 1;

  final _profileCtrl = StreamController<UserProfile?>.broadcast();
  final _mealsCtrl = StreamController<List<MealEntry>>.broadcast();
  final _totalsCtrl = StreamController<DailyTotals>.broadcast();

  FakeHealthRepository([this._profile]);

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
    _emit();
    return id;
  }

  @override
  Future<void> deleteMeal(int id) async {
    _meals.removeWhere((m) => m.id == id);
    _emit();
  }

  @override
  Stream<List<WeightEntry>> watchWeightsBetween(DateTime from, DateTime to) =>
      Stream.value(const <WeightEntry>[]);

  @override
  Future<void> upsertWeight({
    required DateTime day,
    required double weightKg,
    double? bodyFatPct,
  }) async {}

  @override
  Future<void> deleteWeight(DateTime day) async {}

  void _emit() {
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
}
