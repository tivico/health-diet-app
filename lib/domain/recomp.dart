/// 增肌減脂分析：把體組成、訓練、飲食放在同一段期間裡看，
/// 避免「體重沒降就以為沒進步」。
///
/// 原則和衛教內容一致：看多次趨勢、量測條件相近才比；家用體脂計有誤差，
/// 前後差距在 [kBodyNoiseKg] 以內的就當作「看不出變化」，不硬判好壞。
library;

import 'dart:math' as math;

import 'activity.dart';
import 'body_composition.dart';
import 'meal_type.dart';

/// 分析的期間。
enum RecompPeriod {
  weeks4('4 週', 28),
  weeks12('12 週', 84),
  all('全部', null);

  const RecompPeriod(this.label, this.days);
  final String label;

  /// 往回看幾天（含今天）；null 代表從最早的紀錄開始。
  final int? days;
}

/// 前後兩次量測，脂肪量或肌肉量要差超過這個值，才當作「看得出變化」。
///
/// 保守估計：家用體脂計即使在相近條件下量，前後也可能差到半公斤上下。
const double kBodyNoiseKg = 0.5;

/// 搭配阻力訓練時，蛋白質每公斤體重每天建議約 1.6 克以上
/// （Morton 等人 2018 年統合分析，見衛教〈蛋白質為什麼重要〉）。
const double kRecompProteinGPerKg = 1.6;

/// WHO 身體活動指引：成人每週至少 2 天做肌力訓練。
const int kStrengthDaysPerWeek = 2;

// ---------------------------------------------------------------------------
// 體組成變化
// ---------------------------------------------------------------------------

/// 脂肪量：有量就用；沒量但有體脂率，就用「體重 × 體脂率」推算。
double? fatMassOf(BodyComposition b) {
  final direct = b.valueOf(BodyMetric.fatMass);
  if (direct != null) return direct;
  final pct = b.valueOf(BodyMetric.bodyFat);
  return pct == null ? null : b.weightKg * pct / 100;
}

/// 兩次都有量到的肌肉指標：優先骨骼肌，其次肌肉量（要同一種才比得起來）。
BodyMetric? muscleMetricOf(BodyComposition a, BodyComposition b) {
  for (final m in const [BodyMetric.skeletalMuscle, BodyMetric.muscleMass]) {
    if (a.valueOf(m) != null && b.valueOf(m) != null) return m;
  }
  return null;
}

enum Tone { good, caution, neutral }

/// 判讀結果：一句標題、一段說明，和顯示用的語氣（好 / 留意 / 中性）。
class Verdict {
  const Verdict(this.title, this.detail, this.tone);
  final String title;
  final String detail;
  final Tone tone;
}

/// 依脂肪與肌肉的變化方向判讀；在量測誤差內的變化算「持平」。
Verdict judgeRecomp({required double? fatDelta, required double? muscleDelta}) {
  int dir(double d) => d > kBodyNoiseKg ? 1 : (d < -kBodyNoiseKg ? -1 : 0);

  if (fatDelta == null) {
    return const Verdict(
      '還分不出來',
      '需要脂肪量或體脂率，才看得出體重變化來自脂肪還是其他部分。',
      Tone.neutral,
    );
  }
  final f = dir(fatDelta);
  if (muscleDelta == null) {
    return switch (f) {
      -1 => const Verdict('脂肪減少',
          '脂肪量明顯下降。量測時也記下骨骼肌或肌肉量，就能看出肌肉有沒有保住。', Tone.good),
      1 => const Verdict('脂肪增加', '脂肪量明顯增加，可以回頭看看這段期間的飲食紀錄。', Tone.caution),
      _ => const Verdict('脂肪大致持平', '脂肪量的變化在量測誤差內。', Tone.neutral),
    };
  }
  return switch ((f, dir(muscleDelta))) {
    (-1, 1) => const Verdict('增肌減脂',
        '脂肪減少、肌肉增加——這就是體態重組。體重不一定會降，但身體組成正在變好。', Tone.good),
    (-1, 0) => const Verdict(
        '減脂，肌肉保住了', '脂肪明顯下降，肌肉沒有明顯流失。繼續維持蛋白質和肌力訓練。', Tone.good),
    (-1, -1) => const Verdict('減脂中，但肌肉也在減少',
        '脂肪下降的同時肌肉也少了。可以檢查蛋白質吃得夠不夠、肌力訓練有沒有持續，減重速度也可以放慢一點。',
        Tone.caution),
    (0, 1) => const Verdict('肌肉增加', '肌肉明顯增加，脂肪大致持平。', Tone.good),
    (0, -1) => const Verdict('肌肉減少',
        '肌肉明顯減少、脂肪大致持平。留意蛋白質與肌力訓練；水分、生理期也會影響量出來的數字。',
        Tone.caution),
    (1, 1) => const Verdict('肌肉和脂肪都增加',
        '增肌期常見的情況；如果目標是減脂，可以檢查熱量是不是偏高。', Tone.neutral),
    (1, 0) => const Verdict(
        '脂肪增加', '脂肪明顯增加，肌肉沒有跟著增加。可以回頭看看這段期間的飲食紀錄。', Tone.caution),
    (1, -1) => const Verdict('脂肪增加、肌肉減少',
        '最需要調整的組合：檢查熱量、蛋白質與活動量，也確認兩次的量測條件是否相近。', Tone.caution),
    _ => const Verdict('大致維持',
        '脂肪和肌肉的變化都在量測誤差內，身體組成大致維持。要看出變化，通常需要更長的時間。',
        Tone.neutral),
  };
}

/// 期間內第一次與最後一次體組成量測的比較。
class BodyChange {
  const BodyChange({required this.first, required this.last, required this.count});

  final BodyComposition first;
  final BodyComposition last;

  /// 期間內一共量了幾次。
  final int count;

  int get days => last.day.difference(first.day).inDays;
  double get weightDelta => last.weightKg - first.weightKg;

  double? get fatDelta {
    final a = fatMassOf(first);
    final b = fatMassOf(last);
    return a == null || b == null ? null : b - a;
  }

  /// 脂肪量是不是用體脂率推算的（兩次都直接量到才算「實測」）。
  bool get fatEstimated =>
      first.valueOf(BodyMetric.fatMass) == null ||
      last.valueOf(BodyMetric.fatMass) == null;

  /// 體重變化裡「不是脂肪」的部分：肌肉、水分、肝醣、骨骼等。
  double? get nonFatDelta {
    final f = fatDelta;
    return f == null ? null : weightDelta - f;
  }

  BodyMetric? get muscleMetric => muscleMetricOf(first, last);

  double? get muscleDelta {
    final m = muscleMetric;
    return m == null ? null : deltaOf(m, first, last);
  }

  Verdict get verdict =>
      judgeRecomp(fatDelta: fatDelta, muscleDelta: muscleDelta);
}

/// [entries]（由舊到新）中 [from] 之後的量測；不到兩次就沒得比，回傳 null。
BodyChange? bodyChangeSince(List<BodyComposition> entries, DateTime from) {
  final inRange = [
    for (final b in entries)
      if (!b.day.isBefore(from)) b,
  ];
  if (inRange.length < 2) return null;
  return BodyChange(
      first: inRange.first, last: inRange.last, count: inRange.length);
}

// ---------------------------------------------------------------------------
// 訓練
// ---------------------------------------------------------------------------

/// 某台器材在期間內第一次與最後一次的紀錄。
class ExerciseProgress {
  const ExerciseProgress({
    required this.exerciseId,
    required this.first,
    required this.last,
    required this.records,
  });

  final int exerciseId;
  final ExerciseRecord first;
  final ExerciseRecord last;
  final int records;

  double? get weightDelta {
    final a = first.set.weight;
    final b = last.set.weight;
    return a == null || b == null ? null : b - a;
  }
}

class TrainingSummary {
  const TrainingSummary({
    required this.weeks,
    required this.counts,
    required this.total,
    required this.progress,
  });

  /// 期間有幾週（不足一週算一週）。
  final int weeks;
  final Map<ActivityKind, int> counts;
  final Duration total;

  /// 期間內有紀錄的器材，依器材編號排序。
  final List<ExerciseProgress> progress;

  int get sessions => counts.values.fold(0, (a, b) => a + b);
  double perWeek(ActivityKind kind) => (counts[kind] ?? 0) / weeks;
  double get sessionsPerWeek => sessions / weeks;
}

/// [from] 到 [to]（含）這段期間的訓練。
TrainingSummary summarizeTraining(
  Iterable<Activity> activities, {
  required DateTime from,
  required DateTime to,
}) {
  final end = DateTime(to.year, to.month, to.day + 1);
  final inRange = [
    for (final a in activities)
      if (!a.startedAt.isBefore(from) && a.startedAt.isBefore(end)) a,
  ];
  final counts = <ActivityKind, int>{};
  var total = Duration.zero;
  final ids = <int>{};
  for (final a in inRange) {
    counts[a.kind] = (counts[a.kind] ?? 0) + 1;
    total += a.duration;
    for (final s in a.sets) {
      ids.add(s.exerciseId);
    }
  }
  final progress = [
    for (final id in ids.toList()..sort())
      if (historyOf(id, inRange) case final h when h.isNotEmpty)
        ExerciseProgress(
            exerciseId: id, first: h.first, last: h.last, records: h.length),
  ];
  final days = end.difference(from).inDays;
  return TrainingSummary(
    weeks: math.max(1, (days / 7).ceil()),
    counts: counts,
    total: total,
    progress: progress,
  );
}

// ---------------------------------------------------------------------------
// 飲食
// ---------------------------------------------------------------------------

/// 分析用的一筆餐點（只取需要的欄位，domain 才不必認識資料庫的類別）。
typedef MealFact = ({
  DateTime eatenAt,
  double calories,
  double proteinG,
  MealType? type,
});

class DietSummary {
  const DietSummary({
    required this.loggedDays,
    required this.totalDays,
    required this.avgCalories,
    required this.avgProtein,
    required this.proteinByMeal,
  });

  /// 有記錄餐點的天數。
  final int loggedDays;
  final int totalDays;

  /// 平均只算「有記錄」的日子，避免漏記的日子把數字拉低。
  final double avgCalories;
  final double avgProtein;

  /// 各餐別平均每天吃到的蛋白質（公克）；沒吃的餐別不在裡面。
  final Map<MealType?, double> proteinByMeal;

  bool get hasData => loggedDays > 0;

  /// 記錄的完整度（0–1）。
  double get coverage => totalDays == 0 ? 0 : loggedDays / totalDays;
}

/// [from] 到 [to]（含）這段期間的飲食。
DietSummary summarizeDiet(
  Iterable<MealFact> meals, {
  required DateTime from,
  required DateTime to,
}) {
  final end = DateTime(to.year, to.month, to.day + 1);
  final days = <DateTime>{};
  var calories = 0.0;
  var protein = 0.0;
  final byMeal = <MealType?, double>{};
  for (final m in meals) {
    if (m.eatenAt.isBefore(from) || !m.eatenAt.isBefore(end)) continue;
    days.add(DateTime(m.eatenAt.year, m.eatenAt.month, m.eatenAt.day));
    calories += m.calories;
    protein += m.proteinG;
    byMeal[m.type] = (byMeal[m.type] ?? 0) + m.proteinG;
  }
  final n = days.length;
  return DietSummary(
    loggedDays: n,
    totalDays: end.difference(from).inDays,
    avgCalories: n == 0 ? 0 : calories / n,
    avgProtein: n == 0 ? 0 : protein / n,
    proteinByMeal: {
      for (final MapEntry(:key, :value) in byMeal.entries)
        if (value > 0) key: value / n,
    },
  );
}
