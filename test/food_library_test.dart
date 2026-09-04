import 'package:flutter_test/flutter_test.dart';
import 'package:health/data/food_library.dart';

void main() {
  test('食物庫有資料且欄位合理', () {
    expect(foodLibrary.length, greaterThan(30));
    for (final f in foodLibrary) {
      expect(f.name.isNotEmpty, isTrue);
      expect(f.serving.isNotEmpty, isTrue);
      expect(f.calories, greaterThanOrEqualTo(0));
      expect(f.proteinG, greaterThanOrEqualTo(0));
      expect(f.fatG, greaterThanOrEqualTo(0));
      expect(f.carbsG, greaterThanOrEqualTo(0));
    }
  });

  test('三大營養素換算的熱量與標示熱量大致相符（估算容許 15% 誤差）', () {
    for (final f in foodLibrary) {
      if (f.calories == 0) continue; // 無糖飲料等
      final fromMacros = f.proteinG * 4 + f.fatG * 9 + f.carbsG * 4;
      final diff = (fromMacros - f.calories).abs() / f.calories;
      expect(diff, lessThan(0.15), reason: '${f.name} 的營養素與熱量落差過大');
    }
  });

  test('搜尋與分類過濾', () {
    final bento = searchFoods('便當');
    expect(bento, isNotEmpty);
    expect(bento.every((f) => f.name.contains('便當')), isTrue);

    final drinks = searchFoods('', category: FoodCategory.drink);
    expect(drinks, isNotEmpty);
    expect(drinks.every((f) => f.category == FoodCategory.drink), isTrue);

    expect(searchFoods('不存在的食物ＸＹＺ'), isEmpty);
  });
}
