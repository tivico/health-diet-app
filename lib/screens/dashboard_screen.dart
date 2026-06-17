import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/nutrition.dart';
import '../labels.dart';
import '../providers.dart';
import 'onboarding_screen.dart';

/// 每日目標儀表板：從本地資料庫讀取使用者資料（reactive），顯示計算後的目標。
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    if (profile == null) {
      // 理論上 HomeGate 已擋掉 null，這裡只是保險。
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final plan = nutritionPlan(profile);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('你的每日目標'),
        actions: [
          IconButton(
            tooltip: '編輯資料',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OnboardingScreen(initial: profile),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- 熱量目標大卡片 ---
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '每日熱量目標（${goalLabel(profile.goal)}）',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${plan.calorieTarget.toInt()}',
                    style: theme.textTheme.displayMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Text('大卡 / 天'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _miniStat('基礎代謝 BMR', '${plan.bmr.toInt()}'),
                      _miniStat('每日消耗 TDEE', '${plan.tdee.toInt()}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- 三大營養素 ---
          Text('三大營養素', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _macroBar('蛋白質', plan.macros.proteinG, kKcalPerGProtein,
              plan.calorieTarget, Colors.redAccent),
          _macroBar('脂肪', plan.macros.fatG, kKcalPerGFat, plan.calorieTarget,
              Colors.amber),
          _macroBar('碳水化合物', plan.macros.carbsG, kKcalPerGCarb,
              plan.calorieTarget, Colors.lightBlue),
          const SizedBox(height: 16),

          // --- BMI ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('BMI ${plan.bmi}',
                          style: theme.textTheme.titleLarge),
                      const SizedBox(width: 8),
                      Chip(label: Text(plan.bmiCategory)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '健康體重區間：${plan.healthyWeightKg.$1}–${plan.healthyWeightKg.$2} 公斤',
                  ),
                ],
              ),
            ),
          ),

          // --- 安全提醒（若觸發熱量下限）---
          if (plan.safetyNote != null) ...[
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 8),
                    Expanded(child: Text(plan.safetyNote!)),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          Text(
            '＊本資訊為估算，僅供參考，不取代專業醫療或營養師建議。',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) => Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );

  Widget _macroBar(
    String name,
    double grams,
    int kcalPerG,
    double target,
    Color color,
  ) {
    final pct = (grams * kcalPerG) / target;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name),
              Text('${grams.toInt()} g（${(pct * 100).round()}%）'),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: color.withValues(alpha: 0.15),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
