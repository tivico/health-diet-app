/// 營養計算核心邏輯（從原 Python 參考實作移植而來）。
///
/// 純 Dart、不依賴 Flutter 或任何外部套件，方便單元測試，
/// 也讓 UI 層與未來的本地資料庫共用同一套規則。
///
/// 公式：
/// - BMR：Mifflin-St Jeor（一般）／ Katch-McArdle（有體脂時較準）
/// - TDEE：BMR × 活動係數
/// - BMI 分級：採台灣衛福部國民健康署標準
library;

enum Sex { male, female }

enum ActivityLevel { sedentary, light, moderate, active, veryActive }

enum Goal { lose, maintain, gain }

/// TDEE = BMR × 活動係數
const Map<ActivityLevel, double> kActivityFactors = {
  ActivityLevel.sedentary: 1.2,
  ActivityLevel.light: 1.375,
  ActivityLevel.moderate: 1.55,
  ActivityLevel.active: 1.725,
  ActivityLevel.veryActive: 1.9,
};

/// 每日熱量安全下限（飲食障礙友善設計：不鼓勵極端節食）
const Map<Sex, double> kAbsoluteMinCalories = {
  Sex.female: 1200.0,
  Sex.male: 1500.0,
};

/// 蛋白質公克 / 每公斤體重（減脂時較高，以保留肌肉）
const Map<Goal, double> kProteinGPerKg = {
  Goal.lose: 1.8,
  Goal.maintain: 1.4,
  Goal.gain: 1.6,
};

/// 脂肪佔每日總熱量的比例
const double kFatCalorieRatio = 0.25;

/// 每公克營養素的熱量（大卡）
const int kKcalPerGProtein = 4;
const int kKcalPerGFat = 9;
const int kKcalPerGCarb = 4;

/// 每日熱量目標的預設調整幅度：減脂扣 15%、增肌加 10%。
/// （與 nutritionPlan / dailyCalorieTarget 的預設參數一致，供畫面顯示公式用。）
const double kDefaultDeficitPct = 0.15;
const double kDefaultSurplusPct = 0.10;

/// 使用者基本資料。
class UserProfile {
  final Sex sex;
  final int age;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activity;
  final Goal goal;

  /// 體脂率（%），可選；有提供時會用較準的 Katch-McArdle 公式。
  final double? bodyFatPct;

  /// 目標體重（公斤），可選。只影響「還差多少 / 預估多久」的呈現，
  /// 不參與 BMR / TDEE / 每日熱量目標的計算。
  final double? targetWeightKg;

  UserProfile({
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    this.activity = ActivityLevel.sedentary,
    this.goal = Goal.maintain,
    this.bodyFatPct,
    this.targetWeightKg,
  }) {
    // 基本驗證：壞資料在入口就擋掉，而不是算出荒謬的結果。
    if (age <= 0 || age > 120) {
      throw ArgumentError('年齡需介於 1–120');
    }
    if (heightCm <= 0) throw ArgumentError('身高需為正數');
    if (weightKg <= 0) throw ArgumentError('體重需為正數');
    final bf = bodyFatPct;
    if (bf != null && (bf <= 0 || bf >= 75)) {
      throw ArgumentError('體脂率需介於 0–75%');
    }
    final tw = targetWeightKg;
    if (tw != null && (tw <= 0 || tw > 400)) {
      throw ArgumentError('目標體重需介於 1–400 公斤');
    }
  }
}

/// 三大營養素（公克）。
class Macros {
  final double proteinG;
  final double fatG;
  final double carbsG;

  const Macros({
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
  });

  /// 由三大營養素反推總熱量（大卡）。
  double get calories =>
      proteinG * kKcalPerGProtein +
      fatG * kKcalPerGFat +
      carbsG * kKcalPerGCarb;
}

/// 一份完整的每日營養計畫（之後 UI / 資料庫直接使用）。
class NutritionPlan {
  final double bmr;
  final double tdee;
  final double calorieTarget;
  final Macros macros;
  final double bmi;
  final String bmiCategory;
  final (double, double) healthyWeightKg;
  final String? safetyNote;

  const NutritionPlan({
    required this.bmr,
    required this.tdee,
    required this.calorieTarget,
    required this.macros,
    required this.bmi,
    required this.bmiCategory,
    required this.healthyWeightKg,
    this.safetyNote,
  });
}

/// Mifflin-St Jeor 公式——最常用、不需體脂的 BMR 估算。
double bmrMifflinStJeor(UserProfile p) {
  final base = 10 * p.weightKg + 6.25 * p.heightCm - 5 * p.age;
  return p.sex == Sex.male ? base + 5 : base - 161;
}

/// Katch-McArdle 公式——以除脂體重計算，有體脂資料時較準。
double bmrKatchMcArdle(UserProfile p) {
  final bf = p.bodyFatPct;
  if (bf == null) {
    throw ArgumentError('Katch-McArdle 需要體脂率 (bodyFatPct)');
  }
  final leanMassKg = p.weightKg * (1 - bf / 100);
  return 370 + 21.6 * leanMassKg;
}

/// 有體脂用較準的 Katch-McArdle，否則退回通用的 Mifflin-St Jeor。
double bmr(UserProfile p) =>
    p.bodyFatPct != null ? bmrKatchMcArdle(p) : bmrMifflinStJeor(p);

double tdee(UserProfile p) => bmr(p) * kActivityFactors[p.activity]!;

double _applyGoal(double base, Goal goal, double deficitPct, double surplusPct) {
  switch (goal) {
    case Goal.lose:
      return base * (1 - deficitPct);
    case Goal.gain:
      return base * (1 + surplusPct);
    case Goal.maintain:
      return base;
  }
}

/// 每日建議熱量（已套用安全下限）。
double dailyCalorieTarget(
  UserProfile p, {
  double deficitPct = 0.15,
  double surplusPct = 0.10,
}) {
  final raw = _applyGoal(tdee(p), p.goal, deficitPct, surplusPct);
  final floor = kAbsoluteMinCalories[p.sex]!;
  return raw < floor ? floor : raw;
}

/// 依每日熱量目標換算三大營養素：先決定蛋白質與脂肪，剩下的熱量給碳水。
Macros macroTargets(UserProfile p, double calorieTarget) {
  final proteinG = kProteinGPerKg[p.goal]! * p.weightKg;
  final fatG = (calorieTarget * kFatCalorieRatio) / kKcalPerGFat;
  final used = proteinG * kKcalPerGProtein + fatG * kKcalPerGFat;
  final remaining = calorieTarget - used;
  final carbsG = (remaining < 0 ? 0.0 : remaining) / kKcalPerGCarb;
  return Macros(proteinG: proteinG, fatG: fatG, carbsG: carbsG);
}

double bmi(UserProfile p) {
  final m = p.heightCm / 100;
  return p.weightKg / (m * m);
}

/// 台灣衛福部國民健康署的 BMI 分級。
String bmiCategoryTaiwan(double value) {
  if (value < 18.5) return '過輕';
  if (value < 24) return '健康體位';
  if (value < 27) return '過重';
  return '肥胖';
}

/// 以 BMI 18.5–24 反推某身高的健康體重區間（公斤）。
(double, double) healthyWeightRangeKg(double heightCm) {
  final m = heightCm / 100;
  return (_round1(18.5 * m * m), _round1(24 * m * m));
}

/// 把上面所有計算組成一份完整、可直接給 UI 的營養計畫。
NutritionPlan nutritionPlan(
  UserProfile p, {
  double deficitPct = 0.15,
  double surplusPct = 0.10,
}) {
  final t = tdee(p);
  final rawTarget = _applyGoal(t, p.goal, deficitPct, surplusPct);
  final floor = kAbsoluteMinCalories[p.sex]!;
  final target = rawTarget < floor ? floor : rawTarget;

  String? note;
  if (target > rawTarget) {
    note = '為了健康，每日熱量目標已設下限 ${floor.toInt()} 大卡。'
        '（依你的目標原本計算約 ${rawTarget.round()} 大卡，過低的熱量攝取'
        '可能有害，建議搭配運動而非極端節食。）';
  }

  final m = macroTargets(p, target);
  final b = bmi(p);

  return NutritionPlan(
    bmr: bmr(p).roundToDouble(),
    tdee: t.roundToDouble(),
    calorieTarget: target.roundToDouble(),
    macros: Macros(
      proteinG: m.proteinG.roundToDouble(),
      fatG: m.fatG.roundToDouble(),
      carbsG: m.carbsG.roundToDouble(),
    ),
    bmi: _round1(b),
    bmiCategory: bmiCategoryTaiwan(b),
    healthyWeightKg: healthyWeightRangeKg(p.heightCm),
    safetyNote: note,
  );
}

double _round1(double v) => (v * 10).round() / 10;
