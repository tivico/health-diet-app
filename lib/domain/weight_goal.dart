/// 目標體重：還差多少、照目前的每日熱量目標大概要多久。
///
/// 純 Dart、不依賴 UI 或資料庫，方便單元測試。
///
/// 公式：
/// - 每日熱量差 = 每日熱量目標 − TDEE（負值為赤字）
/// - 每週體重變化 ≒ 每日熱量差 × 7 ÷ 7700
/// - 預估週數 = 還差的公斤數 ÷ 每週體重變化（無條件進位）
///
/// ⚠️ 這是**線性估算**。實際減重會隨體重下降而變慢（代謝適應、
///    活動消耗變少），所以真實時間通常比推估的久。呈現時要講清楚。
library;

import 'nutrition.dart';

/// 體重每變化 1 公斤所對應的熱量差（大卡）——常見的 7700 經驗值。
const double kKcalPerKgBodyWeight = 7700;

/// 差距在這個範圍內就視為已達成，避免小數點跳動造成「差 0.1 公斤」的焦慮。
const double kGoalReachedToleranceKg = 0.5;

/// 目標體重的推估結果。
class WeightGoalProjection {
  final double currentWeightKg;
  final double targetWeightKg;

  /// 還差幾公斤（正 = 還要增加，負 = 還要減少）。
  final double remainingKg;

  /// 依每日熱量目標推估的每週體重變化（正 = 增，負 = 減）。
  final double weeklyChangeKg;

  /// 預估還需要幾週；已達成或方向不符時為 null。
  final int? weeksToTarget;

  /// 預估達成日期；已達成或方向不符時為 null。
  final DateTime? estimatedDate;

  /// 已在目標範圍內（差距 ≤ [kGoalReachedToleranceKg]）。
  final bool reached;

  /// 目前的每日熱量目標不會朝目標體重前進
  /// （例如想減重卻設定成增肌，或設定為維持）。
  final bool directionMismatch;

  /// 目標體重落在健康體重區間外時的提醒；否則為 null。
  final String? warning;

  const WeightGoalProjection({
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.remainingKg,
    required this.weeklyChangeKg,
    required this.reached,
    required this.directionMismatch,
    this.weeksToTarget,
    this.estimatedDate,
    this.warning,
  });

  /// 還差多少公斤（不分方向），給顯示用。
  double get remainingAbsKg => remainingKg.abs();
}

/// 推估達成目標體重所需的時間。
///
/// [currentWeightKg] 省略時用 [UserProfile.weightKg]；體重分頁會傳入
/// 最新一筆體重紀錄，比個人資料裡的數字更貼近現況。
/// 沒有設定目標體重時回傳 null。
WeightGoalProjection? projectWeightGoal({
  required UserProfile profile,
  required NutritionPlan plan,
  double? currentWeightKg,
  DateTime? now,
}) {
  final target = profile.targetWeightKg;
  if (target == null) return null;

  final current = currentWeightKg ?? profile.weightKg;
  final remaining = target - current;
  final dailyDeltaKcal = plan.calorieTarget - plan.tdee;
  final weeklyChange = dailyDeltaKcal * 7 / kKcalPerKgBodyWeight;

  final reached = remaining.abs() <= kGoalReachedToleranceKg;

  var mismatch = false;
  int? weeks;
  DateTime? date;
  if (!reached) {
    // 方向要一致：還要減重就得是赤字，還要增重就得是盈餘。
    if (weeklyChange == 0 || (remaining > 0) != (weeklyChange > 0)) {
      mismatch = true;
    } else {
      weeks = (remaining / weeklyChange).ceil();
      date = (now ?? DateTime.now()).add(Duration(days: weeks * 7));
    }
  }

  return WeightGoalProjection(
    currentWeightKg: current,
    targetWeightKg: target,
    remainingKg: remaining,
    weeklyChangeKg: weeklyChange,
    reached: reached,
    directionMismatch: mismatch,
    weeksToTarget: weeks,
    estimatedDate: date,
    warning: _healthyRangeWarning(target, profile.heightCm),
  );
}

/// 目標體重落在健康體重區間外時的提醒。
///
/// 低於區間講重話（這是本 App 的安全底線）；高於區間則是中性提醒 ——
/// 體重不分辨肌肉與脂肪，增肌的人本來就可能超過。
String? _healthyRangeWarning(double targetKg, double heightCm) {
  final (lo, hi) = healthyWeightRangeKg(heightCm);
  final range = '${_fmt1(lo)}–${_fmt1(hi)} 公斤';
  if (targetKg < lo) {
    return '這個目標體重低於你身高的健康體重區間（$range）。'
        '過低的體重會影響荷爾蒙、骨質密度與免疫力，'
        '建議把目標調整回區間內，或先與醫師 / 營養師討論。';
  }
  if (targetKg > hi) {
    return '這個目標體重高於你身高的健康體重區間（$range）。'
        '如果你正在增肌，這未必是問題 —— 體重不分辨肌肉與脂肪，'
        '可以搭配體脂率一起看。';
  }
  return null;
}

/// 從起始體重到目標體重的完成比例（0–1）。
///
/// 起點與目標幾乎相同（無從計算比例）時回傳 null；
/// 往反方向走時會被夾成 0，而不是負數。
double? weightGoalProgress({
  required double startKg,
  required double currentKg,
  required double targetKg,
}) {
  final total = targetKg - startKg;
  if (total.abs() < 0.05) return null;
  return ((currentKg - startKg) / total).clamp(0.0, 1.0);
}

String _fmt1(double v) => v.toStringAsFixed(1);
