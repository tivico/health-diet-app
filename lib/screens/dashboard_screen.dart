import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/health_repository.dart';
import '../domain/meal_type.dart';
import '../domain/nutrition.dart';
import '../labels.dart';
import '../providers.dart';
import 'advice_screen.dart';
import 'add_meal_screen.dart';
import 'backup_screen.dart';
import 'onboarding_screen.dart';

/// 每日追蹤：可前後切換日期，顯示該日「目標 vs 已吃 vs 剩餘」（圓環）、
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('你的每日目標'),
        actions: [
          IconButton(
            tooltip: '健康建議',
            icon: const Icon(Icons.tips_and_updates_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AdviceScreen(profile: profile)),
            ),
          ),
          IconButton(
            tooltip: '備份與還原',
            icon: const Icon(Icons.backup_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BackupScreen()),
            ),
          ),
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

          // === 熱量總覽（圓環）===
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('熱量（${goalLabel(profile.goal)}）',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _CalorieRing(consumed: consumed, target: target),
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
            ..._mealSections(context, ref, theme, meals),
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

  /// 餐點清單依餐別分組：每組一列標題（含筆數與小計）＋ 一張卡片。
  /// 分組順序固定（早 → 午 → 晚 → 點心 → 未分類），空的組別不顯示。
  List<Widget> _mealSections(BuildContext context, WidgetRef ref,
      ThemeData theme, List<MealEntry> meals) {
    final groups = groupByMealType(meals, (MealEntry m) => m.mealType);
    return [
      for (final g in groups) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${mealTypeLabel(g.type)}（${g.items.length}）',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
              Text(
                '小計 ${g.items.fold<double>(0, (s, m) => s + m.calories).round()} 大卡',
                style:
                    theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [for (final m in g.items) _mealTile(context, ref, m)],
          ),
        ),
      ],
    ];
  }

  Widget _mealTile(BuildContext context, WidgetRef ref, MealEntry m) {
    return ListTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AddMealScreen(initial: m)),
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
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              final repo = ref.read(repositoryProvider);
              repo.deleteMeal(m.id);
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(SnackBar(
                content: Text('已刪除「${m.name}」'),
                action: SnackBarAction(
                  label: '復原',
                  onPressed: () => repo.addMeal(
                    eatenAt: m.eatenAt,
                    name: m.name,
                    calories: m.calories,
                    proteinG: m.proteinG,
                    fatG: m.fatG,
                    carbsG: m.carbsG,
                    mealType: m.mealType, // 復原要連餐別一起還原
                  ),
                ),
              ));
            },
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

/// 熱量圓環：已吃比例填滿，中間顯示數字。超標時轉為紅色。
class _CalorieRing extends StatelessWidget {
  final double consumed;
  final double target;
  const _CalorieRing({required this.consumed, required this.target});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final over = target > 0 && consumed > target;
    final filled = target <= 0 ? 0.0 : consumed.clamp(0, target).toDouble();
    final rest = target <= 0 ? 0.0 : (target - consumed).clamp(0, target).toDouble();
    final remaining = target - consumed;

    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 0,
              centerSpaceRadius: 64,
              sections: [
                PieChartSectionData(
                  value: filled <= 0 ? 0 : filled,
                  color: over
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  radius: 16,
                  showTitle: false,
                ),
                if (rest > 0)
                  PieChartSectionData(
                    value: rest,
                    color: theme.colorScheme.onPrimaryContainer
                        .withValues(alpha: 0.12),
                    radius: 16,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${consumed.round()}',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text('/ ${target.round()} 大卡', style: theme.textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                over ? '超出 ${(-remaining).round()}' : '剩 ${remaining.round()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: over ? theme.colorScheme.error : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
