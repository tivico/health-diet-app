import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/health_repository.dart';
import '../domain/nutrition.dart';
import '../labels.dart';
import '../providers.dart';
import 'add_meal_screen.dart';
import 'onboarding_screen.dart';

/// 每日追蹤：可前後切換日期，顯示該日「目標 vs 已吃 vs 剩餘」、
/// 三大營養素進度與餐點清單。資料皆 reactive。
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final plan = nutritionPlan(profile);
    final totals = ref.watch(dayTotalsProvider).value ?? const DailyTotals();
    final meals = ref.watch(dayMealsProvider).value ?? const <MealEntry>[];
    final selectedDate = ref.watch(selectedDateProvider);
    final theme = Theme.of(context);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = selectedDate == today;

    final target = plan.calorieTarget;
    final consumed = totals.calories;
    final remaining = target - consumed;
    final calPct = target <= 0 ? 0.0 : (consumed / target).clamp(0.0, 1.0);

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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-meal', // 與體重分頁的 FAB 區分，避免 Hero tag 衝突
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddMealScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('新增餐點'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: [
          // === 日期切換 ===
          Row(
            children: [
              IconButton(
                tooltip: '前一天',
                icon: const Icon(Icons.chevron_left),
                onPressed: () =>
                    ref.read(selectedDateProvider.notifier).previousDay(),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('${selectedDate.month} 月 ${selectedDate.day} 日',
                        style: theme.textTheme.titleMedium),
                    Text(
                      isToday ? '今天' : '過去紀錄',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '後一天',
                icon: const Icon(Icons.chevron_right),
                onPressed: isToday
                    ? null
                    : () => ref.read(selectedDateProvider.notifier).nextDay(),
              ),
            ],
          ),
          if (!isToday)
            Center(
              child: TextButton(
                onPressed: () =>
                    ref.read(selectedDateProvider.notifier).goToToday(),
                child: const Text('回到今天'),
              ),
            ),
          const SizedBox(height: 8),

          // === 熱量總覽 ===
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('熱量（${goalLabel(profile.goal)}）',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _calStat('目標', target),
                      _calStat('已吃', consumed),
                      _calStat('剩餘', remaining,
                          highlight: true, over: remaining < 0),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: calPct, minHeight: 10),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // === 三大營養素（已吃 / 目標）===
          Text('三大營養素（已吃 / 目標）', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _macroProgress(
              '蛋白質', totals.proteinG, plan.macros.proteinG, Colors.redAccent),
          _macroProgress('脂肪', totals.fatG, plan.macros.fatG, Colors.amber),
          _macroProgress('碳水化合物', totals.carbsG, plan.macros.carbsG,
              Colors.lightBlue),
          const SizedBox(height: 16),

          // === 餐點 ===
          Text('餐點（${meals.length}）', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (meals.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    '這天還沒有餐點紀錄。\n切到「今天」並按右下角「新增餐點」開始記錄。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.hintColor),
                  ),
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final m in meals)
                    ListTile(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => AddMealScreen(initial: m)),
                      ),
                      title: Text(m.name),
                      subtitle: Text(
                        '${_hhmm(m.eatenAt)} ・ 蛋白 ${m.proteinG.toInt()} / 脂 ${m.fatG.toInt()} / 碳 ${m.carbsG.toInt()} g',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${m.calories.toInt()} 大卡'),
                          IconButton(
                            tooltip: '刪除',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                ref.read(repositoryProvider).deleteMeal(m.id),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // === BMI ===
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
                      '健康體重區間：${plan.healthyWeightKg.$1}–${plan.healthyWeightKg.$2} 公斤'),
                ],
              ),
            ),
          ),

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

          const SizedBox(height: 16),
          Text(
            '＊本資訊為估算，僅供參考，不取代專業醫療或營養師建議。',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _calStat(String label, double kcal,
      {bool highlight = false, bool over = false}) {
    return Column(
      children: [
        Text(
          '${kcal.round()}',
          style: TextStyle(
            fontSize: highlight ? 22 : 18,
            fontWeight: FontWeight.bold,
            color: over ? Colors.red : null,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _macroProgress(
      String name, double consumedG, double targetG, Color color) {
    final pct = targetG <= 0 ? 0.0 : (consumedG / targetG).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name),
              Text('${consumedG.toInt()} / ${targetG.toInt()} g'),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: color.withValues(alpha: 0.15),
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
