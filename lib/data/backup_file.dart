/// 備份檔的命名、內容檢查與體組成的 JSON 格式（純函式，方便測試）。
library;

import 'dart:convert';

import '../domain/body_composition.dart';
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
    this.bodyCompositionCount,
  });

  final int version;
  final bool hasProfile;
  final int mealCount;
  final int weightCount;

  /// v4 才有體組成；更舊的備份是 null（摘要裡就不提）。
  final int? bodyCompositionCount;

  /// 例如「個人資料、餐點 12 筆、體重 5 筆、體組成 3 筆」。
  String describe() => [
        if (hasProfile) '個人資料',
        '餐點 $mealCount 筆',
        '體重 $weightCount 筆',
        if (bodyCompositionCount != null) '體組成 $bodyCompositionCount 筆',
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
  final bodies = decoded['bodyCompositions'];
  if (version is! int || meals is! List || weights is! List) return null;
  if (bodies != null && bodies is! List) return null;
  return BackupSummary(
    version: version,
    hasProfile: decoded['profile'] is Map,
    mealCount: meals.length,
    weightCount: weights.length,
    bodyCompositionCount: bodies is List ? bodies.length : null,
  );
}

/// 體組成在備份 JSON 裡的欄位名稱。
///
/// ⚠️ 這就是備份格式：已經發布的名稱不能改（舊備份會讀不回來），只能新增。
const bodyCompositionJsonKeys = <BodyMetric, String>{
  BodyMetric.weight: 'weightKg',
  BodyMetric.bodyFat: 'bodyFatPct',
  BodyMetric.fatMass: 'fatMassKg',
  BodyMetric.skeletalMuscle: 'skeletalMuscleKg',
  BodyMetric.muscleMass: 'muscleMassKg',
  BodyMetric.water: 'waterKg',
  BodyMetric.fatFreeMass: 'fatFreeMassKg',
  BodyMetric.subcutaneousFat: 'subcutaneousFatPct',
  BodyMetric.visceralFat: 'visceralFatLevel',
  BodyMetric.bmr: 'bmrKcal',
  BodyMetric.asmi: 'asmi',
  BodyMetric.bodyAge: 'bodyAge',
  BodyMetric.waist: 'waistCm',
  BodyMetric.hip: 'hipCm',
  BodyMetric.arm: 'armCm',
  BodyMetric.thigh: 'thighCm',
  BodyMetric.neck: 'neckCm',
  BodyMetric.chest: 'chestCm',
};

Map<String, dynamic> bodyCompositionToJson(BodyComposition b) => {
      'day': b.day.toIso8601String(),
      for (final MapEntry(key: metric, value: key)
          in bodyCompositionJsonKeys.entries)
        key: b.valueOf(metric),
      'source': b.source,
      'note': b.note,
    };

/// 讀回一筆體組成。沒有體重的不算數，直接報錯（還原會整筆退回）。
BodyComposition bodyCompositionFromJson(Map<String, dynamic> json) {
  final values = <BodyMetric, double>{
    for (final MapEntry(key: metric, value: key)
        in bodyCompositionJsonKeys.entries)
      if (json[key] case final num n) metric: n.toDouble(),
  };
  if (!values.containsKey(BodyMetric.weight)) {
    throw const FormatException('體組成紀錄缺少體重');
  }
  return BodyComposition(
    day: DateTime.parse(json['day'] as String),
    values: values,
    source: json['source'] as String?,
    note: json['note'] as String?,
  );
}
