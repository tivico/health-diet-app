/// DriftHealthRepository 的整合測試：跑**真實的 SQLite**（記憶體資料庫）。
///
/// Widget 測試用的是 `FakeHealthRepository`，驗證的是畫面流程；
/// 這裡驗證的是假 repo 永遠測不到的東西 —— 真正的 SQL：
/// 當日 SUM 加總、日期區間的邊界、intEnum 的存取、upsert 的覆蓋行為。
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/data/database.dart';
import 'package:health/data/health_repository.dart';
import 'package:health/domain/activity.dart';
import 'package:health/domain/body_composition.dart';
import 'package:health/domain/meal_type.dart';
import 'package:health/domain/nutrition.dart';

void main() {
  // 每個測試都開一個獨立的記憶體資料庫，drift 的「重複建立」警告在這裡是誤報。
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftHealthRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftHealthRepository(db);
  });

  tearDown(() => db.close());

  UserProfile profile({double weightKg = 65, double? targetWeightKg}) =>
      UserProfile(
        sex: Sex.female,
        age: 28,
        heightCm: 165,
        weightKg: weightKg,
        activity: ActivityLevel.light,
        goal: Goal.lose,
        targetWeightKg: targetWeightKg,
      );

  Future<int> addMeal(
    DateTime at,
    String name,
    double kcal, {
    MealType? mealType,
    double protein = 0,
    double fat = 0,
    double carbs = 0,
  }) =>
      repo.addMeal(
        eatenAt: at,
        name: name,
        calories: kcal,
        proteinG: protein,
        fatG: fat,
        carbsG: carbs,
        mealType: mealType,
      );

  group('個人資料', () {
    test('存檔後可讀回，enum 與選填欄位都正確', () async {
      await repo.saveProfile(UserProfile(
        sex: Sex.male,
        age: 30,
        heightCm: 175,
        weightKg: 70,
        activity: ActivityLevel.veryActive,
        goal: Goal.gain,
        bodyFatPct: 18,
        targetWeightKg: 75,
      ));

      final p = (await repo.getProfile())!;
      // enum 是以 index 存成 int，這裡驗證真的能原樣讀回
      expect(p.sex, Sex.male);
      expect(p.activity, ActivityLevel.veryActive);
      expect(p.goal, Goal.gain);
      expect(p.age, 30);
      expect(p.bodyFatPct, 18);
      expect(p.targetWeightKg, 75);
    });

    test('沒有資料時回傳 null', () async {
      expect(await repo.getProfile(), isNull);
    });

    test('重複存檔是覆蓋同一列，不會變成兩個使用者', () async {
      await repo.saveProfile(profile(weightKg: 65));
      await repo.saveProfile(profile(weightKg: 60, targetWeightKg: 58));

      final rows = await db.select(db.userProfiles).get();
      expect(rows.length, 1);
      expect(rows.single.weightKg, 60);
      expect(rows.single.targetWeightKg, 58);
    });

    test('選填欄位可以被清成 null', () async {
      await repo.saveProfile(profile(targetWeightKg: 58));
      await repo.saveProfile(profile());
      expect((await repo.getProfile())!.targetWeightKg, isNull);
    });
  });

  group('當日加總（SQL 的 SUM）', () {
    test('各營養素分別加總，且只算當天', () async {
      final day = DateTime(2026, 3, 15);
      await addMeal(DateTime(2026, 3, 15, 8), '早餐', 300,
          protein: 10, fat: 8, carbs: 40);
      await addMeal(DateTime(2026, 3, 15, 12, 30), '午餐', 800,
          protein: 35, fat: 25, carbs: 90);
      await addMeal(DateTime(2026, 3, 16, 9), '隔天的早餐', 999,
          protein: 99, fat: 99, carbs: 99);

      final t = await repo.watchDailyTotals(day).first;
      expect(t.calories, 1100);
      expect(t.proteinG, 45);
      expect(t.fatG, 33);
      expect(t.carbsG, 130);
      expect(t.mealCount, 2);
    });

    test('沒有紀錄的日子是 0 而不是 null', () async {
      // SQL 的 SUM 在沒有列時回傳 NULL，這裡確認有被轉成 0
      final t = await repo.watchDailyTotals(DateTime(2026, 3, 15)).first;
      expect(t.calories, 0);
      expect(t.proteinG, 0);
      expect(t.mealCount, 0);
    });

    test('新增餐點後，加總的 stream 會吐出新值', () async {
      final day = DateTime(2026, 3, 15);
      final seen = <double>[];
      final sub =
          repo.watchDailyTotals(day).listen((t) => seen.add(t.calories));

      await pumpEventQueue(times: 20);
      await addMeal(DateTime(2026, 3, 15, 12), '午餐', 500);
      await pumpEventQueue(times: 20);
      await sub.cancel();

      expect(seen, [0.0, 500.0]);
    });
  });

  group('日期區間', () {
    test('當日查詢的邊界：當天 00:00 含、隔天 00:00 不含', () async {
      final day = DateTime(2026, 3, 15);
      await addMeal(DateTime(2026, 3, 15, 0, 0, 0), '午夜整點', 100);
      await addMeal(DateTime(2026, 3, 15, 23, 59, 59), '睡前', 200);
      await addMeal(DateTime(2026, 3, 16, 0, 0, 0), '隔天午夜整點', 400);
      await addMeal(DateTime(2026, 3, 14, 23, 59, 59), '前一天深夜', 800);

      final meals = await repo.watchMealsOn(day).first;
      expect(meals.map((m) => m.name), ['睡前', '午夜整點']); // 由新到舊
      expect((await repo.watchDailyTotals(day).first).calories, 300);
    });

    test('區間查詢含頭尾兩天，並由舊到新排序', () async {
      await addMeal(DateTime(2026, 3, 14, 20), '區間前一天', 100);
      await addMeal(DateTime(2026, 3, 15, 8), '第一天', 200);
      await addMeal(DateTime(2026, 3, 16, 12), '中間', 300);
      await addMeal(DateTime(2026, 3, 17, 21), '最後一天', 400);
      await addMeal(DateTime(2026, 3, 18, 1), '區間後一天', 500);

      final meals = await repo
          .watchMealsBetween(DateTime(2026, 3, 15), DateTime(2026, 3, 17))
          .first;
      expect(meals.map((m) => m.name), ['第一天', '中間', '最後一天']);
    });
  });

  group('餐點的新增 / 修改 / 刪除', () {
    test('餐別以 intEnum 儲存，讀回仍是同一個值', () async {
      final day = DateTime(2026, 3, 15);
      await addMeal(DateTime(2026, 3, 15, 8), '蛋餅', 300,
          mealType: MealType.breakfast);
      await addMeal(DateTime(2026, 3, 15, 12), '便當', 800,
          mealType: MealType.lunch);
      await addMeal(DateTime(2026, 3, 15, 15), '沒標餐別', 100);

      final meals = await repo.watchMealsOn(day).first;
      final byName = {for (final m in meals) m.name: m.mealType};
      expect(byName['蛋餅'], MealType.breakfast);
      expect(byName['便當'], MealType.lunch);
      expect(byName['沒標餐別'], isNull);
    });

    test('更新是改到同一列，不會多一筆', () async {
      final day = DateTime(2026, 3, 15);
      final id = await addMeal(DateTime(2026, 3, 15, 12), '便當', 800,
          mealType: MealType.lunch);

      await repo.updateMeal(
        id: id,
        eatenAt: DateTime(2026, 3, 15, 12),
        name: '便當（少飯）',
        calories: 600,
        proteinG: 35,
        fatG: 25,
        carbsG: 50,
        mealType: MealType.dinner,
      );

      final meals = await repo.watchMealsOn(day).first;
      expect(meals.length, 1);
      expect(meals.single.id, id);
      expect(meals.single.name, '便當（少飯）');
      expect(meals.single.calories, 600);
      expect(meals.single.mealType, MealType.dinner);
    });

    test('刪除後查不到，加總也跟著變', () async {
      final day = DateTime(2026, 3, 15);
      final id = await addMeal(DateTime(2026, 3, 15, 12), '便當', 800);
      await addMeal(DateTime(2026, 3, 15, 19), '晚餐', 500);

      await repo.deleteMeal(id);

      final meals = await repo.watchMealsOn(day).first;
      expect(meals.map((m) => m.name), ['晚餐']);
      expect((await repo.watchDailyTotals(day).first).calories, 500);
    });
  });

  group('體重（一天一筆）', () {
    test('同一天重複記錄是覆蓋，而且時間正規化到當天午夜', () async {
      await repo.upsertWeight(
          day: DateTime(2026, 3, 15, 7, 30), weightKg: 65, bodyFatPct: 28);
      await repo.upsertWeight(day: DateTime(2026, 3, 15, 22, 10), weightKg: 64.5);

      final rows = await db.select(db.weightEntries).get();
      expect(rows.length, 1);
      expect(rows.single.day, DateTime(2026, 3, 15));
      expect(rows.single.weightKg, 64.5);
      expect(rows.single.bodyFatPct, isNull); // 第二次沒填 → 覆蓋成 null
    });

    test('區間查詢含頭尾兩天，並由舊到新排序', () async {
      for (final d in [13, 14, 15, 16, 17]) {
        await repo.upsertWeight(
            day: DateTime(2026, 3, d), weightKg: 60 + d.toDouble());
      }

      final rows = await repo
          .watchWeightsBetween(DateTime(2026, 3, 14), DateTime(2026, 3, 16))
          .first;
      expect(rows.map((e) => e.day.day), [14, 15, 16]);
    });

    test('刪除指定日期（傳入含時分秒也找得到）', () async {
      await repo.upsertWeight(day: DateTime(2026, 3, 15), weightKg: 65);
      await repo.deleteWeight(DateTime(2026, 3, 15, 18, 45));
      expect(await db.select(db.weightEntries).get(), isEmpty);
    });
  });

  group('最近吃過', () {
    test('由新到舊，且受 limit 限制', () async {
      await addMeal(DateTime(2026, 3, 14, 12), '前天的便當', 700);
      await addMeal(DateTime(2026, 3, 16, 12), '今天的便當', 800);
      await addMeal(DateTime(2026, 3, 15, 12), '昨天的便當', 750);

      final recent = await repo.watchRecentMeals().first;
      expect(recent.map((m) => m.name),
          ['今天的便當', '昨天的便當', '前天的便當']);

      final limited = await repo.watchRecentMeals(limit: 2).first;
      expect(limited.map((m) => m.name), ['今天的便當', '昨天的便當']);
    });

    test('新增餐點後 stream 會更新', () async {
      final seen = <int>[];
      final sub = repo.watchRecentMeals().listen((m) => seen.add(m.length));
      await pumpEventQueue(times: 20);
      await addMeal(DateTime(2026, 3, 15, 12), '便當', 800);
      await pumpEventQueue(times: 20);
      await sub.cancel();

      expect(seen, [0, 1]);
    });
  });

  group('CSV 匯出', () {
    test('餐點依時間由舊到新，且包含所有紀錄（不限單日）', () async {
      await addMeal(DateTime(2026, 3, 16, 8), '隔天早餐', 300,
          mealType: MealType.breakfast);
      await addMeal(DateTime(2026, 3, 15, 12), '便當', 800,
          mealType: MealType.lunch);

      final rows = (await repo.exportMealsCsv()).trim().split('\r\n');
      expect(rows.length, 3); // 標題 + 2 筆
      expect(rows[1], startsWith('2026-03-15,12:00,午餐,便當,800'));
      expect(rows[2], startsWith('2026-03-16,08:00,早餐,隔天早餐,300'));
    });

    test('體重依日期由舊到新', () async {
      await repo.upsertWeight(day: DateTime(2026, 3, 16), weightKg: 64.5);
      await repo.upsertWeight(
          day: DateTime(2026, 3, 15), weightKg: 65, bodyFatPct: 28);

      final rows = (await repo.exportWeightsCsv()).trim().split('\r\n');
      expect(rows[1], '2026-03-15,65,28');
      expect(rows[2], '2026-03-16,64.5,');
    });

    test('沒有資料時仍有標題列', () async {
      expect((await repo.exportMealsCsv()).trim().split('\r\n').length, 1);
      expect((await repo.exportWeightsCsv()).trim().split('\r\n').length, 1);
    });
  });

  group('體組成', () {
    BodyComposition body(DateTime day, double weight,
            {double? fat, String? note}) =>
        BodyComposition(
          day: day,
          values: {
            BodyMetric.weight: weight,
            BodyMetric.fatMass: ?fat,
          },
          note: note,
        );

    test('依日期由舊到新列出', () async {
      await repo.upsertBodyComposition(body(DateTime(2026, 3, 30), 71.6));
      await repo.upsertBodyComposition(body(DateTime(2026, 2, 2), 72.9));
      await repo.upsertBodyComposition(body(DateTime(2026, 3, 2), 72.4));

      final list = await repo.watchBodyCompositions().first;
      expect([for (final b in list) b.weightKg], [72.9, 72.4, 71.6]);
    });

    test('同一天再記會覆寫，這次沒填的項目會清掉', () async {
      await repo.upsertBodyComposition(
          body(DateTime(2026, 3, 30, 8), 71.6, fat: 17.9, note: '空腹'));
      await repo.upsertBodyComposition(body(DateTime(2026, 3, 30, 21), 72.1));

      final b = (await repo.watchBodyCompositions().first).single;
      expect(b.weightKg, 72.1);
      expect(b.valueOf(BodyMetric.fatMass), isNull);
      expect(b.note, isNull);
    });

    test('刪除', () async {
      await repo.upsertBodyComposition(body(DateTime(2026, 3, 30), 71.6));
      await repo.deleteBodyComposition(DateTime(2026, 3, 30, 15));
      expect(await repo.watchBodyCompositions().first, isEmpty);
    });
  });

  group('運動', () {
    Future<int> rower() => repo
        .saveExercise(const Exercise(name: '划船機 A', unit: WeightUnit.kg));

    test('新增與列出：新到舊，動作依記錄順序，心率區間保留空位', () async {
      final a = await rower();
      final b = await repo
          .saveExercise(const Exercise(name: '胸推機', unit: WeightUnit.lb));
      await repo.saveActivity(Activity(
        startedAt: DateTime(2026, 3, 2, 18),
        kind: ActivityKind.strength,
        duration: const Duration(minutes: 30),
        sets: [
          ExerciseSet(exerciseId: b, weight: 25, reps: 10, sets: 3),
          ExerciseSet(exerciseId: a, weight: 20, reps: 10, sets: 3),
        ],
      ));
      await repo.saveActivity(Activity(
        startedAt: DateTime(2026, 3, 4, 7),
        kind: ActivityKind.cardio,
        title: '慢跑',
        duration: const Duration(minutes: 31, seconds: 49),
        calories: 214,
        avgHr: 142,
        maxHr: 171,
        zones: const [
          null,
          Duration(minutes: 6),
          Duration(minutes: 17, seconds: 2),
          Duration(minutes: 5),
          null,
        ],
      ));

      final list = await repo.watchActivities().first;
      expect([for (final x in list) x.kind],
          [ActivityKind.cardio, ActivityKind.strength]);
      final run = list.first;
      expect(run.title, '慢跑');
      expect(run.duration, const Duration(minutes: 31, seconds: 49));
      expect(run.zones[2], const Duration(minutes: 17, seconds: 2));
      expect(run.zones[0], isNull);
      final gym = list.last;
      expect([for (final s in gym.sets) s.exerciseId], [b, a]);
      expect(gym.sets.first.weight, 25);
    });

    test('修改時動作整份取代；刪除時動作一起刪', () async {
      final a = await rower();
      final id = await repo.saveActivity(Activity(
        startedAt: DateTime(2026, 3, 2),
        kind: ActivityKind.strength,
        duration: const Duration(minutes: 30),
        sets: [
          ExerciseSet(exerciseId: a, weight: 20, reps: 10, sets: 3),
          ExerciseSet(exerciseId: a, weight: 22.5, reps: 8, sets: 1),
        ],
      ));
      await repo.saveActivity(Activity(
        id: id,
        startedAt: DateTime(2026, 3, 2),
        kind: ActivityKind.strength,
        duration: const Duration(minutes: 35),
        sets: [ExerciseSet(exerciseId: a, weight: 25, reps: 10, sets: 3)],
      ));
      final saved = (await repo.watchActivities().first).single;
      expect(saved.duration, const Duration(minutes: 35));
      expect([for (final s in saved.sets) s.weight], [25]);

      await repo.deleteActivity(id);
      expect(await repo.watchActivities().first, isEmpty);
      expect(await db.select(db.exerciseSets).get(), isEmpty);
    });

    test('器材名稱不能重複；有紀錄的器材不能改單位、也不能刪', () async {
      final a = await rower();
      await expectLater(
        repo.saveExercise(const Exercise(name: ' 划船機 A ', unit: WeightUnit.lb)),
        throwsA(isA<DuplicateExerciseNameException>()),
      );
      // 還沒有紀錄：單位可以改
      await repo.saveExercise(Exercise(id: a, name: '划船機 A', unit: WeightUnit.lb));
      await repo.saveActivity(Activity(
        startedAt: DateTime(2026, 3, 2),
        kind: ActivityKind.strength,
        duration: const Duration(minutes: 30),
        sets: [ExerciseSet(exerciseId: a, weight: 40)],
      ));
      await expectLater(
        repo.saveExercise(Exercise(id: a, name: '划船機 A', unit: WeightUnit.kg)),
        throwsStateError,
      );
      // 改名沒關係
      await repo.saveExercise(
          Exercise(id: a, name: '划船機（第一台）', unit: WeightUnit.lb));
      expect((await repo.watchExercises().first).single.name, '划船機（第一台）');

      expect(await repo.deleteExercise(a), isFalse);
      final unused = await repo
          .saveExercise(const Exercise(name: '腿推機', unit: WeightUnit.kg));
      expect(await repo.deleteExercise(unused), isTrue);
    });
  });

  group('備份', () {
    test('運動與器材會一起備份；還原後器材重新編號，動作照樣接得上', () async {
      final a = await repo
          .saveExercise(const Exercise(name: '划船機 A', unit: WeightUnit.kg));
      final b = await repo
          .saveExercise(const Exercise(name: '胸推機', unit: WeightUnit.lb));
      await repo.saveActivity(Activity(
        startedAt: DateTime(2026, 3, 2, 18),
        kind: ActivityKind.strength,
        title: '健身房',
        duration: const Duration(minutes: 36, seconds: 30),
        calories: 131,
        sets: [
          ExerciseSet(exerciseId: a, weight: 20, reps: 10, sets: 3),
          ExerciseSet(exerciseId: b, weight: 25, reps: 10, sets: 3),
        ],
      ));
      final backup = await repo.exportJson();

      final other = AppDatabase(NativeDatabase.memory());
      final otherRepo = DriftHealthRepository(other);
      // 先放一台器材，讓還原後的編號跟原本不一樣
      await otherRepo
          .saveExercise(const Exercise(name: '會被覆蓋掉', unit: WeightUnit.kg));
      await otherRepo.importJson(backup);

      final exercises = await otherRepo.watchExercises().first;
      expect([for (final e in exercises) e.name], ['划船機 A', '胸推機']);
      expect(exercises.last.unit, WeightUnit.lb);
      final names = {for (final e in exercises) e.id: e.name};
      final gym = (await otherRepo.watchActivities().first).single;
      expect(gym.title, '健身房');
      expect([for (final s in gym.sets) names[s.exerciseId]], ['划船機 A', '胸推機']);
      expect(gym.sets.last.weight, 25);
      await other.close();
    });

    test('匯出再匯入可完整還原，並覆蓋既有資料', () async {
      await repo.saveProfile(profile(weightKg: 65, targetWeightKg: 58));
      await addMeal(DateTime(2026, 3, 15, 12), '便當', 800,
          mealType: MealType.lunch, protein: 35, fat: 25, carbs: 90);
      await repo.upsertWeight(
          day: DateTime(2026, 3, 15), weightKg: 65, bodyFatPct: 28);
      final backup = await repo.exportJson();

      // 匯入到另一個資料庫
      final other = AppDatabase(NativeDatabase.memory());
      final otherRepo = DriftHealthRepository(other);
      // 先塞一筆會被蓋掉的資料，驗證匯入是「取代」而非「合併」
      await otherRepo.addMeal(
        eatenAt: DateTime(2026, 1, 1, 9),
        name: '應該要被覆蓋掉',
        calories: 111,
        proteinG: 0,
        fatG: 0,
        carbsG: 0,
      );
      await otherRepo.importJson(backup);

      final p = (await otherRepo.getProfile())!;
      expect(p.weightKg, 65);
      expect(p.targetWeightKg, 58);

      final meals = await otherRepo.watchMealsOn(DateTime(2026, 3, 15)).first;
      expect(meals.single.name, '便當');
      expect(meals.single.mealType, MealType.lunch);
      expect(meals.single.proteinG, 35);

      final old = await otherRepo.watchMealsOn(DateTime(2026, 1, 1)).first;
      expect(old, isEmpty);

      final weights = await otherRepo
          .watchWeightsBetween(DateTime(2026, 3, 1), DateTime(2026, 3, 31))
          .first;
      expect(weights.single.weightKg, 65);
      expect(weights.single.bodyFatPct, 28);

      await other.close();
    });

    test('體組成會一起備份與還原', () async {
      await repo.upsertBodyComposition(BodyComposition(
        day: DateTime(2026, 3, 30),
        values: {
          BodyMetric.weight: 71.6,
          BodyMetric.skeletalMuscle: 30.7,
          BodyMetric.waist: 82.8,
        },
        source: 'InBody',
        note: '早上空腹',
      ));
      final backup = await repo.exportJson();

      final other = AppDatabase(NativeDatabase.memory());
      final otherRepo = DriftHealthRepository(other);
      await otherRepo.importJson(backup);

      final b = (await otherRepo.watchBodyCompositions().first).single;
      expect(b.day, DateTime(2026, 3, 30));
      expect(b.valueOf(BodyMetric.skeletalMuscle), 30.7);
      expect(b.valueOf(BodyMetric.waist), 82.8);
      expect(b.valueOf(BodyMetric.bodyFat), isNull);
      expect(b.source, 'InBody');
      expect(b.note, '早上空腹');
      await other.close();
    });

    test('還原沒有體組成的舊備份（v3）：體組成也一起被覆蓋', () async {
      await repo.upsertBodyComposition(BodyComposition(
          day: DateTime(2026, 3, 30), values: {BodyMetric.weight: 71.6}));
      const v3 = '{"version": 3, "profile": null, "meals": [], "weights": []}';

      await repo.importJson(v3);

      expect(await repo.watchBodyCompositions().first, isEmpty);
    });

    test('還原到一半出錯會整筆退回，原本的資料都還在', () async {
      await repo.saveProfile(profile());
      await addMeal(DateTime(2026, 3, 15, 12), '原本的便當', 800);
      // 結構像備份（備份頁的檢查會放行），但餐點缺了時間，寫到一半會出錯
      const broken = '{"version": 3, "profile": null, '
          '"meals": [{"name": "壞掉的一筆"}], "weights": []}';

      await expectLater(repo.importJson(broken), throwsA(anything));

      expect(await repo.getProfile(), isNotNull);
      final meals = await repo.watchMealsOn(DateTime(2026, 3, 15)).first;
      expect(meals.single.name, '原本的便當');
    });
  });
}
