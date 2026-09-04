import 'package:flutter/material.dart';

import '../domain/nutrition.dart';
import '../domain/recommendations.dart';
import '../domain/weight_goal.dart';

/// 計算方式說明：把每個數字的公式帶入使用者的實際資料，透明呈現。
class CalculationScreen extends StatelessWidget {
  final UserProfile profile;
  const CalculationScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final plan = nutritionPlan(profile);
    final theme = Theme.of(context);
    final w = profile.weightKg;
    final h = profile.heightCm;
    final age = profile.age;
    final factor = kActivityFactors[profile.activity]!;
    final proteinPerKg = kProteinGPerKg[profile.goal]!;
    final water = waterMlForWeight(w);

    // --- BMR ---
    final String bmr;
    final bf = profile.bodyFatPct;
    if (bf != null) {
      final lean = w * (1 - bf / 100);
      bmr = '公式：Katch-McArdle（因為你有填體脂，較準）\n'
          '除脂體重 = ${_n(w)} × (1 − ${_n(bf)}%) = ${lean.toStringAsFixed(1)} 公斤\n'
          'BMR = 370 + 21.6 × ${lean.toStringAsFixed(1)} ≈ ${plan.bmr.round()} 大卡';
    } else {
      final tail = profile.sex == Sex.male ? '+ 5' : '− 161';
      bmr = '公式：Mifflin-St Jeor\n'
          'BMR = 10×${_n(w)} + 6.25×${_n(h)} − 5×$age $tail ≈ ${plan.bmr.round()} 大卡';
    }

    // --- TDEE ---
    final tdee = 'TDEE = BMR × 活動係數\n'
        '= ${plan.bmr.round()} × $factor ≈ ${plan.tdee.round()} 大卡';

    // --- 每日熱量目標 ---
    final String target;
    switch (profile.goal) {
      case Goal.lose:
        final raw = plan.tdee * (1 - kDefaultDeficitPct);
        final floored = plan.safetyNote != null
            ? '\n（低於安全下限，已改用 ${plan.calorieTarget.round()} 大卡）'
            : '';
        target = '減脂：TDEE −${(kDefaultDeficitPct * 100).round()}%\n'
            '= ${plan.tdee.round()} × ${1 - kDefaultDeficitPct} ≈ ${raw.round()} 大卡$floored';
      case Goal.gain:
        target = '增肌：TDEE +${(kDefaultSurplusPct * 100).round()}%\n'
            '= ${plan.tdee.round()} × ${1 + kDefaultSurplusPct} ≈ ${plan.calorieTarget.round()} 大卡';
      case Goal.maintain:
        target = '維持：= TDEE ≈ ${plan.calorieTarget.round()} 大卡';
    }

    // --- 目標體重達成時間（有設定目標才顯示）---
    final projection = projectWeightGoal(profile: profile, plan: plan);
    String? goalText;
    if (projection != null) {
      final dailyDelta = plan.calorieTarget - plan.tdee;
      final weekly = projection.weeklyChangeKg;
      final buf = StringBuffer()
        ..writeln('每日熱量差 = 每日目標 − TDEE')
        ..writeln('= ${plan.calorieTarget.round()} − ${plan.tdee.round()} '
            '= ${dailyDelta.round()} 大卡')
        ..writeln('每週體重變化 ≒ 每日熱量差 × 7 ÷ ${kKcalPerKgBodyWeight.round()}')
        ..writeln('= ${dailyDelta.round()} × 7 ÷ ${kKcalPerKgBodyWeight.round()} '
            '≈ ${weekly.toStringAsFixed(2)} 公斤');
      if (projection.reached) {
        buf.write('目前體重已在目標 ±$kGoalReachedToleranceKg 公斤內 → 已達成');
      } else if (projection.directionMismatch) {
        buf.write('目前的每日熱量目標不會朝目標體重前進，因此無法推估時間');
      } else {
        buf.write('預估週數 = 還差 ${projection.remainingAbsKg.toStringAsFixed(1)} '
            '÷ ${weekly.abs().toStringAsFixed(2)} ≈ ${projection.weeksToTarget} 週');
      }
      goalText = buf.toString();
    }

    // --- 三大營養素 ---
    final macros = '蛋白質 = $proteinPerKg 克/公斤 × ${_n(w)} = ${plan.macros.proteinG.round()} 克\n'
        '脂肪 = 熱量 × ${(kFatCalorieRatio * 100).round()}% ÷ 9 = ${plan.macros.fatG.round()} 克\n'
        '碳水 = 剩下的熱量 ÷ 4 = ${plan.macros.carbsG.round()} 克';

    // --- 飲水量 ---
    final waterText = '= 體重 × $kWaterMlPerKg c.c.\n'
        '= ${_n(w)} × $kWaterMlPerKg ≈ $water c.c.（約 ${(water / 1000).toStringAsFixed(1)} 公升）';

    // --- BMI ---
    final m = h / 100;
    final bmi = '= 體重 ÷ 身高(公尺)²\n'
        '= ${_n(w)} ÷ ${m.toStringAsFixed(2)}² ≈ ${plan.bmi}\n'
        '台灣分級：過輕 <18.5、健康 18.5–24、過重 24–27、肥胖 ≥27\n'
        '→ 你是「${plan.bmiCategory}」';

    return Scaffold(
      appBar: AppBar(title: const Text('計算方式')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('這些數字是怎麼算出來的（帶入你的資料）：',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          _card(theme, 'BMR（基礎代謝率）', bmr, '一天什麼都不做也會消耗的熱量'),
          _card(theme, 'TDEE（每日總消耗）', tdee, 'BMR 再乘上你的活動量'),
          _card(theme, '每日熱量目標', target, '依你的目標調整，並設有安全下限'),
          if (goalText != null)
            _card(theme, '目標體重達成時間', goalText,
                '線性估算；體重下降後代謝也會下降，實際通常更久'),
          _card(theme, '三大營養素', macros, null),
          _card(theme, '每日飲水量', waterText, '粗略參考值，運動或天熱可再增加'),
          _card(theme, 'BMI（身體質量指數）', bmi, null),
          const SizedBox(height: 8),
          Text(
            '＊以上為常見的估算公式，個體差異大，數字僅供參考。',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _n(double v) => v.toStringAsFixed(0);

  Widget _card(ThemeData theme, String title, String formula, String? note) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              if (note != null) ...[
                const SizedBox(height: 2),
                Text(note,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor)),
              ],
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(formula,
                    style: const TextStyle(height: 1.5)),
              ),
            ],
          ),
        ),
      );
}
