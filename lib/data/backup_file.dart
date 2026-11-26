/// 備份檔的命名與內容檢查（純函式，方便測試）。
library;

import 'dart:convert';

import 'csv_export.dart';

/// 檔名帶日期，存了好幾份也分得出哪份最新，例如「健康飲控備份-2026-11-26.json」。
String backupFileName(DateTime now) => '健康飲控備份-${csvDate(now)}.json';

String mealsCsvFileName(DateTime now) => '健康飲控-餐點-${csvDate(now)}.csv';

String weightsCsvFileName(DateTime now) => '健康飲控-體重-${csvDate(now)}.csv';

/// 還原前給使用者看「這份備份裡有什麼」。
class BackupSummary {
  const BackupSummary({
    required this.version,
    required this.hasProfile,
    required this.mealCount,
    required this.weightCount,
  });

  final int version;
  final bool hasProfile;
  final int mealCount;
  final int weightCount;

  /// 例如「個人資料、餐點 12 筆、體重 5 筆」。
  String describe() => [
        if (hasProfile) '個人資料',
        '餐點 $mealCount 筆',
        '體重 $weightCount 筆',
      ].join('、');
}

/// 檢查文字是不是本 App 匯出的備份：是就回傳摘要；不是（例如選到 CSV）就回傳 null。
///
/// 只檢查整體結構。個別資料有問題時，還原會在資料庫交易裡整筆退回，不會只還原一半。
BackupSummary? summarizeBackup(String text) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;
  final version = decoded['version'];
  final meals = decoded['meals'];
  final weights = decoded['weights'];
  if (version is! int || meals is! List || weights is! List) return null;
  return BackupSummary(
    version: version,
    hasProfile: decoded['profile'] is Map,
    mealCount: meals.length,
    weightCount: weights.length,
  );
}
