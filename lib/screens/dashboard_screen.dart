import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/health_repository.dart';
import '../domain/meal_type.dart';
import '../domain/nutrition.dart';
import '../labels.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets/bmi_scale.dart';
import '../widgets/calorie_ring.dart';
import '../widgets/common.dart';
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
    final palette = theme.palette;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = selectedDate == today;

    final target = plan.calorieTarget;
    final consumed = totals.calories;

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
          const SizedBox(width: 4),
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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          _DateSwitcher(selectedDate: selectedDate, isToday: isToday),
          if (!isToday)
            Center(
              child: TextButton.icon(
                onPressed: () =>
                    ref.read(selectedDateProvider.notifier).goToToday(),
                icon: const Icon(Icons.today_outlined, size: 18),
                label: const Text('回到今天'),
              ),
            ),
          const SizedBox(height: 14),

          // === 熱量總覽（漸層主卡 + 圓環）===
          _CalorieHero(
            consumed: consumed,
            target: target,
            goalLabel: goalLabel(profile.goal),
            isToday: isToday,
          ),
          const SizedBox(height: 22),

          // === 三大營養素（已吃 / 目標）===
          const SectionHeader(
            icon: Icons.donut_small,
            title: '三大營養素（已吃 / 目標）',
          ),
          SoftCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                _MacroRow(
                  name: '蛋白質',
                  consumedG: totals.proteinG,
                  targetG: plan.macros.proteinG,
                  color: palette.protein,
                  icon: Icons.egg_alt_outlined,
                ),
                _MacroRow(
                  name: '脂肪',
                  consumedG: totals.fatG,
                  targetG: plan.macros.fatG,
                  color: palette.fat,
                  icon: Icons.water_drop_outlined,
                ),
                _MacroRow(
                  name: '碳水化合物',
                  consumedG: totals.carbsG,
                  targetG: plan.macros.carbsG,
                  color: palette.carbs,
                  icon: Icons.rice_bowl_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // === 餐點 ===
          SectionHeader(
            icon: Icons.restaurant_menu,
            title: '餐點（${meals.length}）',
            color: palette.breakfast,
            trailing: meals.isEmpty
                ? null
                : PillLabel(
                    text: '共 ${consumed.round()} 大卡',
                    color: theme.colorScheme.primary,
                    icon: Icons.local_fire_department_outlined,
                  ),
          ),
          if (meals.isEmpty)
            EmptyState(
              icon: Icons.ramen_dining_outlined,
              message: isToday
                  ? '今天還沒有餐點紀錄。\n按右下角「新增餐點」開始記錄。'
                  : '這天還沒有餐點紀錄。\n切到「今天」並按右下角「新增餐點」開始記錄。',
            )
          else
            ..._mealSections(context, ref, theme, meals),
          const SizedBox(height: 22),

          // === BMI ===
          _BmiCard(plan: plan),

          if (plan.safetyNote != null) ...[
            const SizedBox(height: 16),
            InfoNote(text: plan.safetyNote!, color: palette.warning),
          ],

          const SizedBox(height: 20),
          const FootNote('＊本資訊為估算，僅供參考，不取代專業醫療或營養師建議。'),
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
          padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
          child: Row(
            children: [
              Icon(
                mealTypeIcon(g.type),
                size: 18,
                color: theme.palette.mealColor(g.type),
              ),
              const SizedBox(width: 6),
              Text(
                '${mealTypeLabel(g.type)}（${g.items.length}）',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: theme.palette.mealColor(g.type)),
              ),
              const Spacer(),
              PillLabel(
                text:
                    '小計 ${g.items.fold<double>(0, (s, m) => s + m.calories).round()} 大卡',
                color: theme.palette.mealColor(g.type),
              ),
            ],
          ),
        ),
        SoftCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < g.items.length; i++) ...[
                if (i > 0)
                  const Divider(indent: 62, endIndent: 16, height: 1),
                _mealTile(context, ref, theme, g.items[i]),
              ],
            ],
          ),
        ),
      ],
    ];
  }

  Widget _mealTile(
      BuildContext context, WidgetRef ref, ThemeData theme, MealEntry m) {
    final color = theme.palette.mealColor(m.mealType);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AddMealScreen(initial: m)),
      ),
      leading: IconBadge(icon: mealTypeIcon(m.mealType), color: color),
      title: Text(m.name),
      subtitle: Text(
        '${_hhmm(m.eatenAt)} ・ 蛋白 ${m.proteinG.toInt()} / 脂 ${m.fatG.toInt()} / 碳 ${m.carbsG.toInt()} g',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${m.calories.toInt()} 大卡',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          IconButton(
            tooltip: '刪除',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.delete_outline,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
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

  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

/// 日期切換列：左右各一個箭頭，中間顯示日期與「今天 / 過去紀錄」。
class _DateSwitcher extends ConsumerWidget {
  final DateTime selectedDate;
  final bool isToday;

  const _DateSwitcher({required this.selectedDate, required this.isToday});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SoftCard(
      radius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          IconButton(
            tooltip: '前一天',
            icon: const Icon(Icons.chevron_left),
            onPressed: () =>
                ref.read(selectedDateProvider.notifier).previousDay(),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${selectedDate.month} 月 ${selectedDate.day} 日',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  isToday ? '今天' : '過去紀錄',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isToday
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
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
    );
  }
}

/// 熱量主卡：漸層底 + 圓環 + 三個關鍵數字。超標時整張卡轉為暖色。
class _CalorieHero extends StatelessWidget {
  final double consumed;
  final double target;
  final String goalLabel;
  final bool isToday;

  const _CalorieHero({
    required this.consumed,
    required this.target,
    required this.goalLabel,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.palette;
    final over = target > 0 && consumed > target;
    final remaining = target - consumed;
    final colors = over ? palette.heroOverGradient : palette.heroGradient;

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      shadow: false,
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      // 漸層上的文字一律白色，層次靠透明度區分
      child: Column(
        children: [
          Row(
            children: [
              _HeroChip(icon: Icons.flag_outlined, text: goalLabel),
              const Spacer(),
              Text(
                isToday ? _greeting() : '這天的紀錄',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          CalorieRing(
            consumed: consumed,
            target: target,
            trackColor: Colors.white.withValues(alpha: 0.22),
            progressColor: Colors.white,
            overColor: const Color(0xFF43201F),
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${consumed.round()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                Text(
                  '/ ${target.round()} 大卡',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                _HeroChip(
                  icon: over
                      ? Icons.warning_amber_rounded
                      : Icons.local_fire_department_outlined,
                  text: over
                      ? '超出 ${(-remaining).round()}'
                      : '剩 ${remaining.round()}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _heroStat('目標', target),
              _heroDivider(),
              _heroStat('已吃', consumed),
              _heroDivider(),
              _heroStat('剩餘', remaining),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, double kcal) => Expanded(
        child: Column(
          children: [
            Text(
              '${kcal.round()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );

  Widget _heroDivider() => Container(
        width: 1,
        height: 28,
        color: Colors.white.withValues(alpha: 0.22),
      );

  /// 依時間打招呼，讓每天打開 App 有一點溫度。
  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return '早安 ☀️';
    if (h < 17) return '午安 🌤';
    return '晚安 🌙';
  }
}

/// 漸層卡片上的小標籤（半透明白底）。
class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 單一營養素：圖示 + 名稱 + 已吃/目標 + 進度條。
class _MacroRow extends StatelessWidget {
  final String name;
  final double consumedG;
  final double targetG;
  final Color color;
  final IconData icon;

  const _MacroRow({
    required this.name,
    required this.consumedG,
    required this.targetG,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = targetG <= 0 ? 0.0 : consumedG / targetG;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(name, style: theme.textTheme.bodyMedium),
              const Spacer(),
              Text(
                '${consumedG.toInt()} / ${targetG.toInt()} g',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ratio > 1
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GradientBar(value: ratio, color: color),
        ],
      ),
    );
  }
}

/// BMI 卡：數字 + 分級標籤 + 刻度尺 + 健康體重區間。
class _BmiCard extends StatelessWidget {
  final NutritionPlan plan;
  const _BmiCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.palette;
    final color = switch (plan.bmiCategory) {
      '過輕' => palette.carbs,
      '健康體位' => palette.success,
      '過重' => palette.warning,
      _ => theme.colorScheme.error,
    };

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: Icons.accessibility_new, color: color),
              const SizedBox(width: 10),
              Text('BMI ${plan.bmi}', style: theme.textTheme.titleLarge),
              const SizedBox(width: 8),
              PillLabel(text: plan.bmiCategory, color: color),
            ],
          ),
          const SizedBox(height: 16),
          BmiScale(bmi: plan.bmi),
          const SizedBox(height: 12),
          Text(
            '健康體重區間：${plan.healthyWeightKg.$1}–${plan.healthyWeightKg.$2} 公斤',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
