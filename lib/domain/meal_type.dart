/// 餐別：把一天的攝取拆成早 / 午 / 晚 / 點心，才看得出「哪一餐吃最多」。
///
/// ⚠️ 這個 enum 以 drift 的 `intEnum` 儲存（存的是 **index**），
///    所以只能往**最後面**加新值，不可插入中間或重新排序，
///    否則既有使用者的資料會被解讀成別的餐別。詳見 docs/DATABASE.md。
library;

enum MealType { breakfast, lunch, dinner, snack }

/// 顯示用的固定順序：早 → 午 → 晚 → 點心 → 未分類（`null` 排最後）。
const List<MealType?> kMealTypeOrder = [...MealType.values, null];

/// 依用餐時間推測餐別，作為記錄時的**預設值**（使用者仍可自行更改）。
///
/// 落在正餐時段以外的（下午茶、宵夜、清晨）一律算點心。
MealType guessMealType(DateTime at) {
  final h = at.hour;
  if (h >= 5 && h < 11) return MealType.breakfast;
  if (h >= 11 && h < 15) return MealType.lunch;
  if (h >= 17 && h < 22) return MealType.dinner;
  return MealType.snack;
}

/// 從備份 JSON 還原餐別。
///
/// 認不得的名稱（例如用舊版 App 匯入新版備份）一律視為未分類，
/// 而不是整份備份匯入失敗 —— 少一個標籤，總比資料進不來好。
MealType? mealTypeFromName(String? name) {
  if (name == null) return null;
  for (final t in MealType.values) {
    if (t.name == name) return t;
  }
  return null;
}

/// 一個餐別分組的結果。
class MealGroup<T> {
  final MealType? type;
  final List<T> items;

  const MealGroup(this.type, this.items);
}

/// 依餐別把項目分組，並依 [kMealTypeOrder] 排序、略過空的組別。
///
/// 用泛型是為了讓 domain 層不必認識資料庫的 `MealEntry` 型別。
List<MealGroup<T>> groupByMealType<T>(
  Iterable<T> items,
  MealType? Function(T item) typeOf,
) {
  final buckets = <MealType?, List<T>>{};
  for (final item in items) {
    (buckets[typeOf(item)] ??= <T>[]).add(item);
  }
  return [
    for (final t in kMealTypeOrder)
      if (buckets[t] case final list?) MealGroup(t, list),
  ];
}
