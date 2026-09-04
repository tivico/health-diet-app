import 'package:flutter_test/flutter_test.dart';
import 'package:health/data/csv_export.dart';
import 'package:health/data/database.dart';
import 'package:health/domain/meal_type.dart';

MealEntry meal({
  int id = 1,
  DateTime? eatenAt,
  String name = '雞腿便當',
  double calories = 800,
  double proteinG = 35,
  double fatG = 25,
  double carbsG = 90,
  MealType? mealType = MealType.lunch,
}) =>
    MealEntry(
      id: id,
      eatenAt: eatenAt ?? DateTime(2026, 3, 15, 12, 30),
      name: name,
      calories: calories,
      proteinG: proteinG,
      fatG: fatG,
      carbsG: carbsG,
      mealType: mealType,
    );

/// 取出第 [n] 列（0 為標題列），並去掉行尾的 CRLF。
String line(String csv, int n) => csv.split('\r\n')[n];

void main() {
  group('欄位跳脫（RFC 4180）', () {
    test('一般文字原樣輸出', () {
      expect(csvField('雞腿便當'), '雞腿便當');
      expect(csvField('800'), '800');
    });

    test('null 與空字串都是空欄位', () {
      expect(csvField(null), '');
      expect(csvField(''), '');
    });

    test('含逗號要加引號', () {
      expect(csvField('便當,加蛋'), '"便當,加蛋"');
    });

    test('含雙引號要加引號，且內部的引號重複一次', () {
      expect(csvField('「大」份"特餐"'), '"「大」份""特餐"""');
    });

    test('含換行要加引號（換行不會破壞欄位）', () {
      expect(csvField('第一行\n第二行'), '"第一行\n第二行"');
      expect(csvField('第一行\r\n第二行'), '"第一行\r\n第二行"');
    });

    test('整列與整份文件', () {
      expect(csvRow(['a', 'b,c', null]), 'a,"b,c",');
      // 每列（含最後一列）都以 CRLF 結尾
      expect(csvDocument([
        ['a', 'b'],
        ['c', 'd'],
      ]), 'a,b\r\nc,d\r\n');
    });
  });

  group('格式化', () {
    test('整數不留沒意義的小數點', () {
      expect(csvNumber(800), '800');
      expect(csvNumber(0), '0');
    });

    test('非整數留一位小數', () {
      expect(csvNumber(62.5), '62.5');
      expect(csvNumber(62.34), '62.3');
    });

    test('日期與時間補零', () {
      expect(csvDate(DateTime(2026, 3, 5)), '2026-03-05');
      expect(csvTime(DateTime(2026, 3, 5, 9, 5)), '09:05');
    });
  });

  group('餐點 CSV', () {
    test('標題列', () {
      expect(line(mealsToCsv([]), 0),
          '日期,時間,餐別,品項,熱量(大卡),蛋白質(g),脂肪(g),碳水(g)');
    });

    test('沒有資料時只有標題列', () {
      expect(mealsToCsv([]), '日期,時間,餐別,品項,熱量(大卡),蛋白質(g),脂肪(g),碳水(g)\r\n');
    });

    test('一筆餐點的完整內容', () {
      expect(line(mealsToCsv([meal()]), 1),
          '2026-03-15,12:30,午餐,雞腿便當,800,35,25,90');
    });

    test('沒標餐別的舊資料輸出「未分類」', () {
      expect(line(mealsToCsv([meal(mealType: null)]), 1),
          contains(',未分類,'));
    });

    test('品項含逗號時不會多出一欄', () {
      final csv = mealsToCsv([meal(name: '便當,加蛋')]);
      final row = line(csv, 1);
      expect(row, contains('"便當,加蛋"'));
      // 欄位數要和標題一致：8 欄 → 7 個「分隔用」的逗號
      expect(_topLevelCommas(row), _topLevelCommas(line(csv, 0)));
    });

    test('多筆依傳入順序輸出', () {
      final csv = mealsToCsv([
        meal(id: 1, name: '早餐', eatenAt: DateTime(2026, 3, 15, 8)),
        meal(id: 2, name: '晚餐', eatenAt: DateTime(2026, 3, 15, 19)),
      ]);
      expect(line(csv, 1), startsWith('2026-03-15,08:00'));
      expect(line(csv, 2), startsWith('2026-03-15,19:00'));
    });
  });

  group('體重 CSV', () {
    test('標題列與一般資料', () {
      final csv = weightsToCsv([
        WeightEntry(day: DateTime(2026, 3, 15), weightKg: 62.5, bodyFatPct: 28),
      ]);
      expect(line(csv, 0), '日期,體重(kg),體脂率(%)');
      expect(line(csv, 1), '2026-03-15,62.5,28');
    });

    test('沒量體脂的日子留空欄，而不是填 0', () {
      final csv = weightsToCsv([
        WeightEntry(day: DateTime(2026, 3, 15), weightKg: 62.5),
      ]);
      expect(line(csv, 1), '2026-03-15,62.5,');
    });
  });
}

/// 算「不在引號內」的逗號數量，用來驗證欄位沒有因為跳脫而錯位。
int _topLevelCommas(String row) {
  var inQuotes = false;
  var count = 0;
  for (final ch in row.split('')) {
    if (ch == '"') {
      inQuotes = !inQuotes;
    } else if (ch == ',' && !inQuotes) {
      count++;
    }
  }
  return count;
}
