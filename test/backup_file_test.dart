import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:health/data/backup_file.dart';
import 'package:health/data/csv_export.dart';

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
  });
}
