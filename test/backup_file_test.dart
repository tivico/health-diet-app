import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:health/data/backup_file.dart';
import 'package:health/data/csv_export.dart';
import 'package:health/domain/activity.dart';
import 'package:health/domain/body_composition.dart';

void main() {
  test('檔名帶日期，月、日補零', () {
    final d = DateTime(2026, 3, 5, 23, 59);
    expect(backupFileName(d), '健康飲控備份-2026-03-05.json');
    expect(mealsCsvFileName(d), '健康飲控-餐點-2026-03-05.csv');
    expect(weightsCsvFileName(d), '健康飲控-體重-2026-03-05.csv');
  });

  group('檢查備份內容', () {
    String backup({
      Object? profile = const {'sex': 'female'},
      int meals = 2,
      int weights = 1,
      Object version = 3,
    }) =>
        jsonEncode({
          'version': version,
          'profile': profile,
          'meals': [
            for (var i = 0; i < meals; i++) {'name': '餐點$i'}
          ],
          'weights': [
            for (var i = 0; i < weights; i++) {'weightKg': 60}
          ],
        });

    test('本 App 的備份：回傳筆數摘要', () {
      final s = summarizeBackup(backup())!;
      expect(s.version, 3);
      expect(s.hasProfile, isTrue);
      expect(s.mealCount, 2);
      expect(s.weightCount, 1);
      expect(s.describe(), '個人資料、餐點 2 筆、體重 1 筆');
    });

    test('沒有個人資料時，摘要不提個人資料', () {
      expect(summarizeBackup(backup(profile: null))!.describe(),
          '餐點 2 筆、體重 1 筆');
    });

    test('舊版（v1）備份也認得', () {
      expect(summarizeBackup(backup(version: 1)), isNotNull);
    });

    test('不是備份的內容一律回傳 null', () {
      expect(
          summarizeBackup('日期,時間,餐別,品項\r\n2026-06-17,12:30,午餐,雞腿便當,800\r\n'),
          isNull,
          reason: 'CSV');
      expect(summarizeBackup(''), isNull);
      expect(summarizeBackup('[1, 2, 3]'), isNull, reason: 'JSON 但不是物件');
      expect(summarizeBackup('{"meals": [], "weights": []}'), isNull,
          reason: '缺 version');
      expect(summarizeBackup(backup(version: '3')), isNull,
          reason: 'version 不是數字');
      expect(summarizeBackup('{"version": 3, "meals": {}, "weights": []}'),
          isNull,
          reason: 'meals 不是清單');
    });

    test('還原前的 trim() 會去掉記事本存檔加上的 BOM', () {
      expect('$kUtf8Bom{}'.trim(), '{}');
      expect(summarizeBackup('$kUtf8Bom${backup()}\r\n'.trim()), isNotNull);
    });

    test('v4 備份的摘要會列出體組成筆數；舊備份不提', () {
      final v4 = jsonEncode({
        'version': 4,
        'profile': null,
        'meals': [],
        'weights': [],
        'bodyCompositions': [{}, {}, {}],
      });
      expect(summarizeBackup(v4)!.describe(), '餐點 0 筆、體重 0 筆、體組成 3 筆');
      expect(summarizeBackup(backup())!.bodyCompositionCount, isNull);
    });
  });

  group('體組成的 JSON 格式', () {
    test('每個量測項目都有自己的欄位名稱，而且不重複', () {
      expect(bodyCompositionJsonKeys.keys.toSet(), BodyMetric.values.toSet());
      expect(bodyCompositionJsonKeys.values.toSet().length,
          BodyMetric.values.length);
    });

    test('寫出再讀回，數值、來源、備註都一樣；沒量到的維持沒有', () {
      final original = BodyComposition(
        day: DateTime(2026, 3, 30),
        values: {
          BodyMetric.weight: 71.6,
          BodyMetric.bodyFat: 25.1,
          BodyMetric.visceralFat: 9,
          BodyMetric.waist: 82.8,
        },
        source: 'InBody',
        note: '早上空腹',
      );

      final back = bodyCompositionFromJson(
          jsonDecode(jsonEncode(bodyCompositionToJson(original)))
              as Map<String, dynamic>);

      expect(back.day, original.day);
      expect(back.values, original.values);
      expect(back.valueOf(BodyMetric.hip), isNull);
      expect(back.source, 'InBody');
      expect(back.note, '早上空腹');
    });

    test('v5 備份的摘要會列出運動筆數', () {
      final v5 = jsonEncode({
        'version': 5,
        'profile': null,
        'meals': [],
        'weights': [],
        'bodyCompositions': [],
        'exercises': [{}],
        'activities': [{}, {}],
      });
      expect(summarizeBackup(v5)!.describe(),
          '餐點 0 筆、體重 0 筆、體組成 0 筆、運動 2 筆');
    });

    test('缺體重的紀錄讀不進來（還原會整筆退回）', () {
      expect(
        () => bodyCompositionFromJson(
            {'day': '2026-03-30T00:00:00.000', 'bodyFatPct': 30}),
        throwsFormatException,
      );
    });
  });

  group('運動的 JSON 格式', () {
    test('寫出再讀回：數值、心率區間、動作都一樣；器材編號照對照表換', () {
      final original = Activity(
        startedAt: DateTime(2026, 3, 4, 7, 30),
        kind: ActivityKind.strength,
        title: '健身房',
        duration: const Duration(minutes: 36, seconds: 30),
        calories: 131,
        activeCalories: 90,
        avgHr: 109,
        maxHr: 143,
        zones: const [Duration(minutes: 5), null, null, null, null],
        feeling: '狀態不錯',
        garminActivityId: 123456789,
        sets: const [ExerciseSet(exerciseId: 7, weight: 20, reps: 10, sets: 3)],
      );

      final back = activityFromJson(
        jsonDecode(jsonEncode(activityToJson(original))) as Map<String, dynamic>,
        exerciseIds: {7: 1},
      );

      expect(back.startedAt, original.startedAt);
      expect(back.kind, ActivityKind.strength);
      expect(back.duration, original.duration);
      expect(back.activeCalories, 90);
      expect(back.zones, original.zones);
      expect(back.feeling, '狀態不錯');
      expect(back.garminActivityId, 123456789);
      expect(back.sets.single.exerciseId, 1);
      expect(back.sets.single.weight, 20);
    });

    test('動作對不到器材就報錯（還原會整筆退回）', () {
      final json = activityToJson(Activity(
        startedAt: DateTime(2026, 3, 4),
        kind: ActivityKind.strength,
        duration: const Duration(minutes: 30),
        sets: const [ExerciseSet(exerciseId: 7)],
      ));
      expect(() => activityFromJson(json, exerciseIds: const {}),
          throwsFormatException);
    });
  });
}
