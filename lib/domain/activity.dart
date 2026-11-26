/// 運動紀錄：一次運動（有氧、肌力或其他）；肌力訓練另外記每個動作的
/// 「重量 × 次數 × 組數」。
///
/// 欄位對齊 Garmin 個人 API 的活動摘要（時長、熱量、平均 / 最高心率、心率區間、
/// 重訓動作），之後從 Garmin 匯入時可以直接對應。
library;

/// 運動種類。⚠️ 資料庫存的是 index：只能往最後面加，不能插隊或重排（見 docs/DATABASE.md）。
enum ActivityKind {
  cardio('有氧'),
  strength('肌力'),
  other('其他');

  const ActivityKind(this.label);
  final String label;
}

/// 器材的重量單位。⚠️ 同上，存的是 index。
enum WeightUnit {
  kg('kg'),
  lb('lb');

  const WeightUnit(this.label);
  final String label;

  /// 換算成公斤（加總訓練量、跨單位比較時用）。
  double toKg(double value) =>
      this == WeightUnit.lb ? value * 0.45359237 : value;
}

/// 器材 / 動作：每台器材一個名字、固定一種單位。
///
/// 不同器材的重量不能互比（滑輪比例、力臂、阻力曲線都不同），進步只跟同一台比。
class Exercise {
  const Exercise({this.id, required this.name, required this.unit});

  /// 新增時是 null，存進資料庫後才有。
  final int? id;
  final String name;
  final WeightUnit unit;
}

/// 器材名稱重複（清單裡已經有同名的器材）。
class DuplicateExerciseNameException implements Exception {
  const DuplicateExerciseNameException(this.name);
  final String name;

  @override
  String toString() => '已經有叫「$name」的器材了';
}

/// 一個動作在一次訓練裡的紀錄，例如「18 kg × 10 下 × 3 組」。重量的單位跟著器材。
class ExerciseSet {
  const ExerciseSet({
    required this.exerciseId,
    this.weight,
    this.reps,
    this.sets,
  });

  final int exerciseId;

  /// 自身體重的動作（例如棒式）可以不填。
  final double? weight;

  /// 每組次數。
  final int? reps;

  /// 組數。
  final int? sets;
}

/// 一次運動。
class Activity {
  Activity({
    this.id,
    required this.startedAt,
    required this.kind,
    this.title,
    required this.duration,
    this.distanceKm,
    this.calories,
    this.activeCalories,
    this.avgHr,
    this.maxHr,
    List<Duration?> zones = noZones,
    this.feeling,
    this.garminActivityId,
    List<ExerciseSet> sets = const [],
  })  : assert(zones.length == 5, '心率區間固定 5 個（沒記的放 null）'),
        zones = List.unmodifiable(zones),
        sets = List.unmodifiable(sets);

  static const noZones = <Duration?>[null, null, null, null, null];

  /// 新增時是 null，存進資料庫後才有。
  final int? id;
  final DateTime startedAt;
  final ActivityKind kind;

  /// 例如「慢跑」「重訓」；沒填就用種類名稱顯示。
  final String? title;
  final Duration duration;
  final double? distanceKm;

  /// 總熱量（大卡）。
  final double? calories;

  /// 動態熱量：總熱量扣掉這段時間本來就會消耗的基礎代謝。
  final double? activeCalories;
  final int? avgHr;
  final int? maxHr;

  /// 心率區間 Zone 1～5 待了多久；沒記的是 null。
  final List<Duration?> zones;

  /// 主觀感受與備註，例如「後段沒力」。
  final String? feeling;

  /// Garmin 的活動編號：之後從 Garmin 匯入時用來合併，避免同一次運動記兩筆。
  final int? garminActivityId;

  /// 肌力訓練的各個動作（依記錄順序）。
  final List<ExerciseSet> sets;

  String get displayTitle => title ?? kind.label;
  bool get hasZones => zones.any((z) => z != null);

  /// 總組數（肌力訓練）。
  int get totalSets => sets.fold(0, (sum, s) => sum + (s.sets ?? 0));

  /// 同樣內容、但還沒存進資料庫的一筆（刪除後「復原」用）。
  Activity asNew() => Activity(
        startedAt: startedAt,
        kind: kind,
        title: title,
        duration: duration,
        distanceKm: distanceKm,
        calories: calories,
        activeCalories: activeCalories,
        avgHr: avgHr,
        maxHr: maxHr,
        zones: zones,
        feeling: feeling,
        garminActivityId: garminActivityId,
        sets: sets,
      );
}

/// 一個動作的文字說明，例如「18 kg × 10 下 × 3 組」；沒填的部分略過。
String describeExerciseSet(ExerciseSet s, WeightUnit unit) {
  String fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
  return [
    if (s.weight != null) '${fmt(s.weight!)} ${unit.label}',
    if (s.reps != null) '${s.reps} 下',
    if (s.sets != null) '${s.sets} 組',
  ].join(' × ');
}

// ---------------------------------------------------------------------------
// 時間的輸入與顯示：照手錶上的寫法（31:49、1:00:53）
// ---------------------------------------------------------------------------

final _digits = RegExp(r'^\d+$');

/// 解析「31:49」「1:00:53」或只寫分鐘的「45」；格式不對回傳 null。
Duration? parseClock(String text) {
  final parts = text.trim().split(':');
  if (parts.length > 3 || parts.any((p) => !_digits.hasMatch(p))) return null;
  final n = [for (final p in parts) int.parse(p)];
  return switch (n) {
    [final m] => Duration(minutes: m),
    [final m, final s] when s < 60 => Duration(minutes: m, seconds: s),
    [final h, final m, final s] when m < 60 && s < 60 =>
      Duration(hours: h, minutes: m, seconds: s),
    _ => null,
  };
}

/// 顯示成手錶上的樣子：「31:49」「1:00:53」。
String formatClock(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

/// 口語的總時間：「45 分」「2 小時 5 分」。
String formatMinutes(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return h > 0 ? '$h 小時 $m 分' : '$m 分';
}

// ---------------------------------------------------------------------------
// 每週摘要
// ---------------------------------------------------------------------------

/// 那一週的週一（台灣習慣一週從週一開始）。
DateTime weekStartOf(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - DateTime.monday));

class WeekSummary {
  const WeekSummary({
    required this.start,
    required this.counts,
    required this.total,
  });

  /// 這週的週一。
  final DateTime start;
  final Map<ActivityKind, int> counts;
  final Duration total;

  int get sessions => counts.values.fold(0, (a, b) => a + b);

  /// 例如「有氧 2 次、肌力 1 次」；沒運動回傳空字串。
  String describeCounts() => [
        for (final k in ActivityKind.values)
          if ((counts[k] ?? 0) > 0) '${k.label} ${counts[k]} 次',
      ].join('、');
}

/// [anyDay] 那一週（週一到週日）的次數與總時間。
WeekSummary summarizeWeek(Iterable<Activity> activities, DateTime anyDay) {
  final start = weekStartOf(anyDay);
  final end = DateTime(start.year, start.month, start.day + 7);
  final counts = <ActivityKind, int>{};
  var total = Duration.zero;
  for (final a in activities) {
    if (a.startedAt.isBefore(start) || !a.startedAt.isBefore(end)) continue;
    counts[a.kind] = (counts[a.kind] ?? 0) + 1;
    total += a.duration;
  }
  return WeekSummary(start: start, counts: counts, total: total);
}

// ---------------------------------------------------------------------------
// 器材的進步紀錄、快速填寫
// ---------------------------------------------------------------------------

/// 某台器材在某次訓練的紀錄。
class ExerciseRecord {
  const ExerciseRecord({required this.date, required this.set});
  final DateTime date;
  final ExerciseSet set;
}

/// 某台器材的歷次紀錄，由舊到新。同一次訓練做了兩輪就有兩筆。
List<ExerciseRecord> historyOf(int exerciseId, Iterable<Activity> activities) {
  final records = [
    for (final a in activities)
      for (final s in a.sets)
        if (s.exerciseId == exerciseId)
          ExerciseRecord(date: a.startedAt, set: s),
  ];
  records.sort((a, b) => a.date.compareTo(b.date));
  return records;
}

/// 最近一次有記動作的肌力訓練（「複製上次」用）；[excludeId] 是正在修改的那筆。
Activity? lastStrengthSession(Iterable<Activity> activities, {int? excludeId}) {
  Activity? latest;
  for (final a in activities) {
    if (a.kind != ActivityKind.strength || a.sets.isEmpty || a.id == excludeId) {
      continue;
    }
    if (latest == null || a.startedAt.isAfter(latest.startedAt)) latest = a;
  }
  return latest;
}

/// 最近用過的運動名稱（新到舊、不重複），記錄時可以一鍵帶入。
List<Activity> recentTitled(Iterable<Activity> activities, {int limit = 6}) {
  final sorted = activities.where((a) => a.title != null).toList()
    ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  final seen = <String>{};
  return [
    for (final a in sorted)
      if (seen.add(a.title!)) a,
  ].take(limit).toList();
}
