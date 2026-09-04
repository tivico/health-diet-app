/// 「最近吃過」快選：從自己的紀錄整理出常用食物，比每次搜尋食物庫快。
///
/// 純函式、不依賴 UI 或資料庫（用泛型避開資料庫型別），方便單元測試。
library;

/// 快選最多顯示幾樣。太多就失去「快」的意義了。
const int kRecentFoodLimit = 10;

/// 依名稱去重，保留**先出現**的那一筆。
///
/// 呼叫端傳入的是「由新到舊」的紀錄，所以留下來的就是最近一次吃的版本 ——
/// 份量或熱量後來有調整過的話，帶出來的會是最新的數值。
///
/// 比對時會去掉前後空白並忽略英文大小寫（`Latte` 與 `latte` 視為同一樣）；
/// 名稱空白的紀錄直接略過。[limit] 為 null 表示不限制數量。
List<T> distinctByName<T>(
  Iterable<T> items,
  String Function(T item) nameOf, {
  int? limit,
}) {
  final seen = <String>{};
  final result = <T>[];
  for (final item in items) {
    final key = nameOf(item).trim().toLowerCase();
    if (key.isEmpty || !seen.add(key)) continue;
    result.add(item);
    if (limit != null && result.length >= limit) break;
  }
  return result;
}
