/// 備份檔的命名、內容檢查與體組成的 JSON 格式（純函式，方便測試）。
library;

import 'dart:convert';

import '../domain/activity.dart';
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
    this.activityCount,
  });

  final int version;
  final bool hasProfile;
  final int mealCount;
  final int weightCount;

  /// v4 才有體組成、v5 才有運動；更舊的備份是 null（摘要裡就不提）。
  final int? bodyCompositionCount;
  final int? activityCount;

  /// 例如「個人資料、餐點 12 筆、體重 5 筆、體組成 3 筆、運動 8 筆」。
  String describe() => [
        if (hasProfile) '個人資料',
        '餐點 $mealCount 筆',
        '體重 $weightCount 筆',
        if (bodyCompositionCount != null) '體組成 $bodyCompositionCount 筆',
        if (activityCount != null) '運動 $activityCount 筆',
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
  final activities = decoded['activities'];
  if (version is! int || meals is! List || weights is! List) return null;
  if (bodies != null && bodies is! List) return null;
  if (activities != null && activities is! List) return null;
  return BackupSummary(
    version: version,
    hasProfile: decoded['profile'] is Map,
    mealCount: meals.length,
    weightCount: weights.length,
    bodyCompositionCount: bodies is List ? bodies.length : null,
    activityCount: activities is List ? activities.length : null,
  );
}

// ---------------------------------------------------------------------------
// 運動與器材在備份裡的格式（v5）。種類、單位存英文名稱，比存數字穩。
// ---------------------------------------------------------------------------

/// 器材。id 只用來讓備份裡的動作找到對應的器材，還原時會重新編號。
Map<String, dynamic> exerciseToJson(Exercise e) =>
    {'id': e.id, 'name': e.name, 'unit': e.unit.name};

Exercise exerciseFromJson(Map<String, dynamic> json) => Exercise(
      id: json['id'] as int,
      name: json['name'] as String,
      unit: WeightUnit.values.byName(json['unit'] as String),
    );

Map<String, dynamic> activityToJson(Activity a) => {
      'startedAt': a.startedAt.toIso8601String(),
      'kind': a.kind.name,
      'title': a.title,
      'durationSec': a.duration.inSeconds,
      'distanceKm': a.distanceKm,
      'calories': a.calories,
      'activeCalories': a.activeCalories,
      'avgHr': a.avgHr,
      'maxHr': a.maxHr,
      'zoneSec': [for (final z in a.zones) z?.inSeconds],
      'feeling': a.feeling,
      'garminActivityId': a.garminActivityId,
      'sets': [
        for (final s in a.sets)
          {
            'exerciseId': s.exerciseId,
            'weight': s.weight,
            'reps': s.reps,
            'sets': s.sets,
          },
      ],
    };

/// 讀回一次運動。[exerciseIds] 把備份裡的器材編號換成還原後的新編號；
/// 對不到器材的動作直接報錯（還原會整筆退回）。
Activity activityFromJson(
  Map<String, dynamic> json, {
  required Map<int, int> exerciseIds,
}) {
  final zones = json['zoneSec'] as List? ?? const [];
  double? real(String key) => (json[key] as num?)?.toDouble();
  int? whole(String key) => (json[key] as num?)?.toInt();
  return Activity(
    startedAt: DateTime.parse(json['startedAt'] as String),
    kind: ActivityKind.values.byName(json['kind'] as String),
    title: json['title'] as String?,
    duration: Duration(seconds: json['durationSec'] as int),
    distanceKm: real('distanceKm'),
    calories: real('calories'),
    activeCalories: real('activeCalories'),
    avgHr: whole('avgHr'),
    maxHr: whole('maxHr'),
    zones: [
      for (var i = 0; i < 5; i++)
        if (i < zones.length && zones[i] is num)
          Duration(seconds: (zones[i] as num).toInt())
        else
          null,
    ],
    feeling: json['feeling'] as String?,
    garminActivityId: whole('garminActivityId'),
    sets: [
      for (final s in json['sets'] as List? ?? const [])
        _setFromJson(s as Map<String, dynamic>, exerciseIds),
    ],
  );
}

ExerciseSet _setFromJson(Map<String, dynamic> json, Map<int, int> ids) {
  final oldId = json['exerciseId'] as int;
  final id = ids[oldId] ??
      (throw FormatException('有動作對不到器材（備份裡的編號 $oldId）'));
  return ExerciseSet(
    exerciseId: id,
    weight: (json['weight'] as num?)?.toDouble(),
    reps: (json['reps'] as num?)?.toInt(),
    sets: (json['sets'] as num?)?.toInt(),
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
