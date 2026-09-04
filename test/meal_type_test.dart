import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/meal_type.dart';

void main() {
  group('guessMealType', () {
    MealType at(int hour) => guessMealType(DateTime(2026, 9, 4, hour));

    test('正餐時段', () {
      expect(at(7), MealType.breakfast);
      expect(at(12), MealType.lunch);
      expect(at(19), MealType.dinner);
    });

    test('時段邊界', () {
      expect(at(5), MealType.breakfast); // 早餐開始
      expect(at(10), MealType.breakfast);
      expect(at(11), MealType.lunch); // 轉午餐
      expect(at(14), MealType.lunch);
      expect(at(17), MealType.dinner); // 轉晚餐
      expect(at(21), MealType.dinner);
    });

    test('正餐時段以外都算點心（下午茶 / 宵夜 / 清晨）', () {
      expect(at(15), MealType.snack);
      expect(at(16), MealType.snack);
      expect(at(22), MealType.snack);
      expect(at(2), MealType.snack);
    });
  });

  group('groupByMealType', () {
    // 用 (餐別, 名稱) 的簡單 record 當測試資料，不必牽扯資料庫型別
    List<MealGroup<(MealType?, String)>> groupOf(
            List<(MealType?, String)> items) =>
        groupByMealType(items, (e) => e.$1);

    test('依固定順序排列，未分類排最後', () {
      final groups = groupOf([
        (MealType.snack, '雞排'),
        (null, '舊資料'),
        (MealType.breakfast, '蛋餅'),
        (MealType.dinner, '便當'),
      ]);
      expect(groups.map((g) => g.type).toList(),
          [MealType.breakfast, MealType.dinner, MealType.snack, null]);
    });

    test('空的餐別不會產生分組', () {
      final groups = groupOf([(MealType.lunch, '便當')]);
      expect(groups.length, 1);
      expect(groups.single.type, MealType.lunch);
    });

    test('同餐別的項目維持原本順序', () {
      final groups = groupOf([
        (MealType.lunch, '第一筆'),
        (MealType.lunch, '第二筆'),
      ]);
      expect(groups.single.items.map((e) => e.$2).toList(), ['第一筆', '第二筆']);
    });

    test('沒有項目時回傳空清單', () {
      expect(groupOf([]), isEmpty);
    });
  });

  group('mealTypeFromName', () {
    test('名稱可還原', () {
      for (final t in MealType.values) {
        expect(mealTypeFromName(t.name), t);
      }
    });

    test('null 與認不得的名稱都視為未分類（不丟例外）', () {
      expect(mealTypeFromName(null), isNull);
      expect(mealTypeFromName('brunch'), isNull); // 假設是更新版才有的餐別
    });
  });
}
