/// 把餐點與體重輸出成 CSV，方便丟進 Excel / Google 試算表看。
///
/// ⚠️ 這是**單向的檢視格式，不是備份**。要還原資料請用 JSON 備份
/// （CSV 沒有個人資料，也沒有還原用的結構）。
///
/// 依 RFC 4180 處理跳脫：欄位含逗號、雙引號或換行時用雙引號包起來，
/// 欄位內的雙引號重複一次；行尾用 CRLF（試算表軟體最通用）。
library;

import '../labels.dart';
import 'database.dart';

const String _crlf = '\r\n';

/// UTF-8 的 BOM。Excel（Windows）開沒有 BOM 的 UTF-8 CSV 會把中文顯示成亂碼，
/// 存成檔案時放在開頭就正常了。
///
/// 目前 App 是用「複製到剪貼簿」的方式匯出，貼上時多一個看不見的字元反而礙事，
/// 所以匯出的字串**不含** BOM；未來若加上檔案下載，要記得補上。
const String kUtf8Bom = '﻿';

/// 單一欄位的跳脫。null 視為空欄位。
String csvField(String? value) {
  final v = value ?? '';
  if (v.contains(',') ||
      v.contains('"') ||
      v.contains('\n') ||
      v.contains('\r')) {
    return '"${v.replaceAll('"', '""')}"';
  }
  return v;
}

/// 一列（不含換行）。
String csvRow(List<String?> fields) => fields.map(csvField).join(',');

/// 整份文件，每列以 CRLF 結尾（含最後一列）。
String csvDocument(List<List<String?>> rows) =>
    rows.map(csvRow).map((r) => '$r$_crlf').join();

/// 餐點：一筆一列，時間拆成日期與時間兩欄，方便在試算表裡篩選與樞紐分析。
String mealsToCsv(Iterable<MealEntry> meals) => csvDocument([
      const ['日期', '時間', '餐別', '品項', '熱量(大卡)', '蛋白質(g)', '脂肪(g)', '碳水(g)'],
      for (final m in meals)
        [
          csvDate(m.eatenAt),
          csvTime(m.eatenAt),
          mealTypeLabel(m.mealType),
          m.name,
          csvNumber(m.calories),
          csvNumber(m.proteinG),
          csvNumber(m.fatG),
          csvNumber(m.carbsG),
        ],
    ]);

/// 體重：一天一列。沒量體脂的日子留空欄，而不是填 0。
String weightsToCsv(Iterable<WeightEntry> weights) => csvDocument([
      const ['日期', '體重(kg)', '體脂率(%)'],
      for (final w in weights)
        [
          csvDate(w.day),
          csvNumber(w.weightKg),
          w.bodyFatPct == null ? null : csvNumber(w.bodyFatPct!),
        ],
    ]);

/// 試算表看得懂的日期（yyyy-MM-dd）。
String csvDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String csvTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// 整數就不要拖著沒意義的小數點（800.0 → 800），其餘留一位小數。
String csvNumber(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
