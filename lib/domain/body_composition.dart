/// 體組成：體脂計 / InBody 的一次量測報告（一天一筆）。
///
/// 欄位照家用體脂計與 InBody 報告常見的項目。除了體重都是選填——
/// 不同機器量得到的項目不一樣。BMI、腰臀比這類算得出來的不存，用到時再算。
library;

/// 量測項目分組（記錄頁依此分區）。
enum MetricGroup { main, other, circumference }

/// 往哪個方向變算是好事。
///
/// 體重刻意設成 [neutral]：增肌減脂時體重不一定會降，只看體重容易誤判。
enum BetterWhen { lower, higher, neutral }

enum BodyMetric {
  weight('體重', 'kg', MetricGroup.main, BetterWhen.neutral, 20, 400),
  bodyFat('體脂率', '%', MetricGroup.main, BetterWhen.lower, 1, 75),
  fatMass('脂肪量', 'kg', MetricGroup.main, BetterWhen.lower, 0.5, 250,
      partOfWeight: true),
  skeletalMuscle('骨骼肌', 'kg', MetricGroup.main, BetterWhen.higher, 3, 150,
      partOfWeight: true),
  muscleMass('肌肉量', 'kg', MetricGroup.main, BetterWhen.higher, 5, 200,
      partOfWeight: true),
  water('含水量', 'kg', MetricGroup.other, BetterWhen.neutral, 5, 200,
      partOfWeight: true),
  fatFreeMass('去脂體重', 'kg', MetricGroup.other, BetterWhen.higher, 10, 250,
      partOfWeight: true),
  subcutaneousFat('皮下脂肪', '%', MetricGroup.other, BetterWhen.lower, 1, 70),
  visceralFat('內臟脂肪等級', '', MetricGroup.other, BetterWhen.lower, 0.5, 60),
  bmr('基礎代謝率', '大卡', MetricGroup.other, BetterWhen.neutral, 500, 5000),
  asmi('ASMI', 'kg/m²', MetricGroup.other, BetterWhen.higher, 2, 20),
  bodyAge('身體年齡', '歲', MetricGroup.other, BetterWhen.neutral, 5, 120),
  waist('腰圍', 'cm', MetricGroup.circumference, BetterWhen.lower, 30, 250),
  hip('臀圍', 'cm', MetricGroup.circumference, BetterWhen.neutral, 30, 250),
  arm('手臂圍', 'cm', MetricGroup.circumference, BetterWhen.neutral, 10, 80),
  thigh('大腿圍', 'cm', MetricGroup.circumference, BetterWhen.neutral, 20, 120),
  neck('頸圍', 'cm', MetricGroup.circumference, BetterWhen.neutral, 15, 80),
  chest('胸圍', 'cm', MetricGroup.circumference, BetterWhen.neutral, 40, 250);

  const BodyMetric(
    this.label,
    this.unit,
    this.group,
    this.betterWhen,
    this.min,
    this.max, {
    this.partOfWeight = false,
  });

  final String label;

  /// 顯示用單位；空字串代表沒有單位（例如內臟脂肪「等級」）。
  final String unit;
  final MetricGroup group;
  final BetterWhen betterWhen;

  /// 合理範圍，用來擋打錯字（例如把 30.7 打成 307）。
  final double min;
  final double max;

  /// 是體重的一部分：重量不可能超過體重。
  final bool partOfWeight;
}

/// 一次量測。只存有量到的項目；沒量到的就不在 [values] 裡。
class BodyComposition {
  BodyComposition({
    required DateTime day,
    required Map<BodyMetric, double> values,
    this.source,
    this.note,
  })  : assert(values.containsKey(BodyMetric.weight), '體組成至少要有體重'),
        day = DateTime(day.year, day.month, day.day),
        values = Map.unmodifiable(values);

  /// 量測日（當天午夜）。
  final DateTime day;
  final Map<BodyMetric, double> values;

  /// 量測工具，例如「InBody」或體脂計的 App 名稱。
  final String? source;

  /// 量測條件，例如「早上空腹」「生理期第 2 天」——之後比較時才知道條件是否相近。
  final String? note;

  double get weightKg => values[BodyMetric.weight]!;

  double? valueOf(BodyMetric m) => values[m];

  /// BMI 要用到身高（在個人資料裡）。
  double bmiWith(double heightCm) {
    final m = heightCm / 100;
    return weightKg / (m * m);
  }

  /// 腰臀比；腰圍、臀圍都有量才算得出來。
  double? get waistHipRatio {
    final waist = values[BodyMetric.waist];
    final hip = values[BodyMetric.hip];
    if (waist == null || hip == null || hip == 0) return null;
    return waist / hip;
  }
}

/// 和前一次比的變化方向。
enum Change { better, worse, neutral, flat }

/// [from] → [to] 的變化量；任一次沒量到就回傳 null。
double? deltaOf(BodyMetric m, BodyComposition from, BodyComposition to) {
  final a = from.valueOf(m);
  final b = to.valueOf(m);
  return a == null || b == null ? null : b - a;
}

/// 依「往哪個方向變算好事」判斷；小到顯示成一位小數也看不出來的算持平。
Change changeOf(BodyMetric m, double delta) {
  if (delta.abs() < 0.05) return Change.flat;
  return switch (m.betterWhen) {
    BetterWhen.neutral => Change.neutral,
    BetterWhen.lower => delta < 0 ? Change.better : Change.worse,
    BetterWhen.higher => delta > 0 ? Change.better : Change.worse,
  };
}

/// 數值顯示：整數不帶小數（1580、9），其餘留一位（71.6）。
String formatBodyValue(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

/// 變化量顯示：+0.2、−0.6；持平顯示「持平」。
String formatBodyDelta(double delta) {
  if (delta.abs() < 0.05) return '持平';
  return '${delta > 0 ? '+' : '−'}${formatBodyValue(delta.abs())}';
}
