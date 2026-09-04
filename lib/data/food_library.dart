/// 台灣常見食物庫（靜態資料），讓記錄餐點時可以搜尋帶入，不必每次手打。
///
/// ⚠️ 所有數值皆為「常見份量的估算值」，實際會因店家、烹調方式與份量差異很大。
/// 使用者選取後仍可自行修改——這是刻意的設計（估算 ≠ 精確）。
library;

enum FoodCategory { rice, noodle, snack, breakfast, drink, dessert, store }

String foodCategoryLabel(FoodCategory c) => switch (c) {
      FoodCategory.rice => '飯 / 便當',
      FoodCategory.noodle => '麵食',
      FoodCategory.snack => '小吃',
      FoodCategory.breakfast => '早餐',
      FoodCategory.drink => '飲料',
      FoodCategory.dessert => '水果 / 點心',
      FoodCategory.store => '超商',
    };

class FoodItem {
  final String name;

  /// 份量描述，例如「1 個」「700ml」。
  final String serving;
  final FoodCategory category;
  final double calories;
  final double proteinG;
  final double fatG;
  final double carbsG;

  const FoodItem({
    required this.name,
    required this.serving,
    required this.category,
    required this.calories,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
  });
}

/// 依關鍵字與分類過濾食物庫。
List<FoodItem> searchFoods(String query, {FoodCategory? category}) {
  final q = query.trim();
  return foodLibrary.where((f) {
    if (category != null && f.category != category) return false;
    if (q.isEmpty) return true;
    return f.name.contains(q);
  }).toList();
}

const List<FoodItem> foodLibrary = [
  // ===== 飯 / 便當 =====
  FoodItem(
      name: '雞腿便當',
      serving: '1 個',
      category: FoodCategory.rice,
      calories: 850,
      proteinG: 35,
      fatG: 35,
      carbsG: 95),
  FoodItem(
      name: '排骨便當',
      serving: '1 個',
      category: FoodCategory.rice,
      calories: 800,
      proteinG: 30,
      fatG: 33,
      carbsG: 92),
  FoodItem(
      name: '燒臘三寶飯',
      serving: '1 份',
      category: FoodCategory.rice,
      calories: 840,
      proteinG: 35,
      fatG: 38,
      carbsG: 90),
  FoodItem(
      name: '滷肉飯（小）',
      serving: '1 碗',
      category: FoodCategory.rice,
      calories: 400,
      proteinG: 12,
      fatG: 15,
      carbsG: 55),
  FoodItem(
      name: '雞肉飯',
      serving: '1 碗',
      category: FoodCategory.rice,
      calories: 450,
      proteinG: 20,
      fatG: 14,
      carbsG: 60),
  FoodItem(
      name: '白飯',
      serving: '1 碗（約 200g）',
      category: FoodCategory.rice,
      calories: 280,
      proteinG: 5,
      fatG: 1,
      carbsG: 62),
  FoodItem(
      name: '糙米飯',
      serving: '1 碗',
      category: FoodCategory.rice,
      calories: 270,
      proteinG: 6,
      fatG: 2,
      carbsG: 57),
  FoodItem(
      name: '炒飯',
      serving: '1 盤',
      category: FoodCategory.rice,
      calories: 600,
      proteinG: 15,
      fatG: 20,
      carbsG: 85),

  // ===== 麵食 =====
  FoodItem(
      name: '牛肉麵',
      serving: '1 碗',
      category: FoodCategory.noodle,
      calories: 550,
      proteinG: 30,
      fatG: 18,
      carbsG: 65),
  FoodItem(
      name: '陽春麵',
      serving: '1 碗',
      category: FoodCategory.noodle,
      calories: 350,
      proteinG: 10,
      fatG: 8,
      carbsG: 58),
  FoodItem(
      name: '乾麵',
      serving: '1 碗',
      category: FoodCategory.noodle,
      calories: 390,
      proteinG: 11,
      fatG: 12,
      carbsG: 60),
  FoodItem(
      name: '炒麵',
      serving: '1 盤',
      category: FoodCategory.noodle,
      calories: 520,
      proteinG: 14,
      fatG: 18,
      carbsG: 75),
  FoodItem(
      name: '泡麵',
      serving: '1 包',
      category: FoodCategory.noodle,
      calories: 450,
      proteinG: 10,
      fatG: 18,
      carbsG: 60),
  FoodItem(
      name: '義大利麵（奶油）',
      serving: '1 份',
      category: FoodCategory.noodle,
      calories: 650,
      proteinG: 18,
      fatG: 28,
      carbsG: 80),
  FoodItem(
      name: '大腸麵線',
      serving: '1 碗',
      category: FoodCategory.noodle,
      calories: 350,
      proteinG: 10,
      fatG: 10,
      carbsG: 55),

  // ===== 小吃 =====
  FoodItem(
      name: '鹹酥雞',
      serving: '小份（約 150g）',
      category: FoodCategory.snack,
      calories: 500,
      proteinG: 25,
      fatG: 32,
      carbsG: 28),
  FoodItem(
      name: '雞排',
      serving: '1 片',
      category: FoodCategory.snack,
      calories: 500,
      proteinG: 30,
      fatG: 30,
      carbsG: 28),
  FoodItem(
      name: '蚵仔煎',
      serving: '1 份',
      category: FoodCategory.snack,
      calories: 450,
      proteinG: 15,
      fatG: 22,
      carbsG: 48),
  FoodItem(
      name: '臭豆腐',
      serving: '1 份',
      category: FoodCategory.snack,
      calories: 380,
      proteinG: 15,
      fatG: 22,
      carbsG: 30),
  FoodItem(
      name: '小籠包',
      serving: '5 個',
      category: FoodCategory.snack,
      calories: 310,
      proteinG: 12,
      fatG: 14,
      carbsG: 33),
  FoodItem(
      name: '水餃',
      serving: '10 顆',
      category: FoodCategory.snack,
      calories: 490,
      proteinG: 20,
      fatG: 19,
      carbsG: 60),
  FoodItem(
      name: '鍋貼',
      serving: '10 個',
      category: FoodCategory.snack,
      calories: 530,
      proteinG: 18,
      fatG: 26,
      carbsG: 55),
  FoodItem(
      name: '肉圓',
      serving: '1 個',
      category: FoodCategory.snack,
      calories: 320,
      proteinG: 8,
      fatG: 12,
      carbsG: 45),
  FoodItem(
      name: '胡椒餅',
      serving: '1 個',
      category: FoodCategory.snack,
      calories: 330,
      proteinG: 12,
      fatG: 14,
      carbsG: 38),
  FoodItem(
      name: '割包',
      serving: '1 個',
      category: FoodCategory.snack,
      calories: 330,
      proteinG: 12,
      fatG: 14,
      carbsG: 38),
  FoodItem(
      name: '滷味',
      serving: '小份',
      category: FoodCategory.snack,
      calories: 270,
      proteinG: 15,
      fatG: 12,
      carbsG: 25),

  // ===== 早餐 =====
  FoodItem(
      name: '蛋餅',
      serving: '1 份',
      category: FoodCategory.breakfast,
      calories: 300,
      proteinG: 10,
      fatG: 14,
      carbsG: 33),
  FoodItem(
      name: '火腿蛋三明治',
      serving: '1 份',
      category: FoodCategory.breakfast,
      calories: 315,
      proteinG: 14,
      fatG: 14,
      carbsG: 33),
  FoodItem(
      name: '豬肉漢堡',
      serving: '1 個',
      category: FoodCategory.breakfast,
      calories: 340,
      proteinG: 15,
      fatG: 16,
      carbsG: 33),
  FoodItem(
      name: '蘿蔔糕',
      serving: '2 塊',
      category: FoodCategory.breakfast,
      calories: 220,
      proteinG: 4,
      fatG: 8,
      carbsG: 33),
  FoodItem(
      name: '饅頭',
      serving: '1 個',
      category: FoodCategory.breakfast,
      calories: 275,
      proteinG: 8,
      fatG: 1,
      carbsG: 58),
  FoodItem(
      name: '無糖豆漿',
      serving: '350ml',
      category: FoodCategory.breakfast,
      calories: 110,
      proteinG: 10,
      fatG: 5,
      carbsG: 6),
  FoodItem(
      name: '米漿',
      serving: '350ml',
      category: FoodCategory.breakfast,
      calories: 195,
      proteinG: 4,
      fatG: 5,
      carbsG: 33),

  // ===== 飲料 =====
  FoodItem(
      name: '珍珠奶茶（全糖）',
      serving: '700ml',
      category: FoodCategory.drink,
      calories: 550,
      proteinG: 5,
      fatG: 15,
      carbsG: 95),
  FoodItem(
      name: '珍珠奶茶（半糖）',
      serving: '700ml',
      category: FoodCategory.drink,
      calories: 435,
      proteinG: 5,
      fatG: 15,
      carbsG: 70),
  FoodItem(
      name: '紅茶拿鐵',
      serving: '700ml',
      category: FoodCategory.drink,
      calories: 305,
      proteinG: 6,
      fatG: 9,
      carbsG: 50),
  FoodItem(
      name: '無糖綠茶',
      serving: '700ml',
      category: FoodCategory.drink,
      calories: 0,
      proteinG: 0,
      fatG: 0,
      carbsG: 0),
  FoodItem(
      name: '可樂',
      serving: '330ml',
      category: FoodCategory.drink,
      calories: 140,
      proteinG: 0,
      fatG: 0,
      carbsG: 35),
  FoodItem(
      name: '拿鐵咖啡',
      serving: '中杯',
      category: FoodCategory.drink,
      calories: 150,
      proteinG: 8,
      fatG: 8,
      carbsG: 12),

  // ===== 水果 / 點心 =====
  FoodItem(
      name: '香蕉',
      serving: '1 根',
      category: FoodCategory.dessert,
      calories: 105,
      proteinG: 1,
      fatG: 0,
      carbsG: 26),
  FoodItem(
      name: '蘋果',
      serving: '1 顆',
      category: FoodCategory.dessert,
      calories: 100,
      proteinG: 1,
      fatG: 0,
      carbsG: 25),
  FoodItem(
      name: '芭樂',
      serving: '1 顆',
      category: FoodCategory.dessert,
      calories: 80,
      proteinG: 2,
      fatG: 1,
      carbsG: 17),
  FoodItem(
      name: '菠蘿麵包',
      serving: '1 個',
      category: FoodCategory.dessert,
      calories: 340,
      proteinG: 7,
      fatG: 12,
      carbsG: 50),
  FoodItem(
      name: '蛋塔',
      serving: '1 個',
      category: FoodCategory.dessert,
      calories: 235,
      proteinG: 4,
      fatG: 13,
      carbsG: 25),

  // ===== 超商 =====
  FoodItem(
      name: '御飯糰',
      serving: '1 個',
      category: FoodCategory.store,
      calories: 180,
      proteinG: 5,
      fatG: 3,
      carbsG: 33),
  FoodItem(
      name: '茶葉蛋',
      serving: '1 顆',
      category: FoodCategory.store,
      calories: 75,
      proteinG: 7,
      fatG: 5,
      carbsG: 1),
  FoodItem(
      name: '雞肉沙拉',
      serving: '1 盒',
      category: FoodCategory.store,
      calories: 230,
      proteinG: 20,
      fatG: 10,
      carbsG: 15),
  FoodItem(
      name: '關東煮',
      serving: '3 串',
      category: FoodCategory.store,
      calories: 140,
      proteinG: 8,
      fatG: 5,
      carbsG: 15),
  FoodItem(
      name: '無糖優格',
      serving: '1 杯',
      category: FoodCategory.store,
      calories: 105,
      proteinG: 9,
      fatG: 4,
      carbsG: 8),
];
