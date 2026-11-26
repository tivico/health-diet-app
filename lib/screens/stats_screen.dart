import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../domain/meal_type.dart';
import '../domain/nutrition.dart';
import '../domain/stats.dart';
import '../labels.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'recomp_view.dart';

/// 統計：「飲食」看近 7 / 30 天的每日熱量長條圖與摘要；
/// 「增肌減脂」把體組成、訓練、飲食放在同一段期間裡看（見 recomp_view.dart）。
/// 呼應衛教觀念——看「週趨勢」，而不是被單日數字綁架。
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.palette;
    final profile = ref.watch(profileProvider).value;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final plan = nutritionPlan(profile);
    final meals =
        ref.watch(statsMealsProvider(_days)).value ?? const <MealEntry>[];
    final weights =
        ref.watch(weightHistoryProvider).value ?? const <WeightEntry>[];

    final to = dateOnly(DateTime.now());
    final from = to.subtract(Duration(days: _days - 1));

    // 把餐點依日期加總、體重依日期整理，再交給純函式算摘要。
    final caloriesByDay = <DateTime, double>{};
    for (final m in meals) {
      final d = dateOnly(m.eatenAt);
      caloriesByDay[d] = (caloriesByDay[d] ?? 0) + m.calories;
    }
    final weightByDay = {
      for (final w in weights) dateOnly(w.day): w.weightKg,
    };

    final summary = buildPeriodSummary(
      from: from,
      to: to,
      caloriesByDay: caloriesByDay,
      weightByDay: weightByDay,
      calorieTarget: plan.calorieTarget,
    );

    // 各餐別的熱量小計（固定順序，空的餐別不會出現）
    final byType = [
      for (final g in groupByMealType(meals, (MealEntry m) => m.mealType))
        (g.type, g.items.fold<double>(0, (s, m) => s + m.calories)),
    ];
    final totalCalories = byType.fold<double>(0, (s, e) => s + e.$2);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('統計'),
          bottom: const TabBar(tabs: [Tab(text: '飲食'), Tab(text: '增肌減脂')]),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Center(
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 7, label: Text('近 7 天')),
                      ButtonSegment(value: 30, label: Text('近 30 天')),
                    ],
                    selected: {_days},
                    onSelectionChanged: (s) => setState(() => _days = s.first),
                  ),
                ),
                const SizedBox(height: 18),

                // === 摘要數字 ===
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        icon: Icons.local_fire_department_outlined,
                        color: theme.colorScheme.primary,
                        label: '平均每日攝取',
                        value: summary.daysWithRecords == 0
                            ? '—'
                            : '${summary.averageCalories.round()}',
                        unit: '大卡（目標 ${plan.calorieTarget.round()}）',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                        icon: Icons.edit_calendar_outlined,
                        color: palette.carbs,
                        label: '有記錄天數',
                        value: '${summary.daysWithRecords}',
                        unit: '／ $_days 天',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        icon: Icons.verified_outlined,
                        color: palette.success,
                        label: '達標天數',
                        value: '${summary.daysOnTarget}',
                        unit: '天（目標 ±10% 內）',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _weightTile(summary)),
                  ],
                ),
                const SizedBox(height: 22),

                // === 每日熱量長條圖 ===
                const SectionHeader(
                  icon: Icons.bar_chart_rounded,
                  title: '每日熱量',
                  subtitle: '虛線為你的每日目標；超過目標的日子會標成紅色。',
                ),
                if (summary.daysWithRecords == 0)
                  const EmptyState(
                    icon: Icons.insights_outlined,
                    message: '這段期間還沒有餐點紀錄。\n到「今日」分頁記錄幾筆，這裡就會出現趨勢。',
                  )
                else
                  SoftCard(
                    padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
                    child: SizedBox(
                      height: 210,
                      child: _CalorieBarChart(
                        summary: summary,
                        target: plan.calorieTarget,
                      ),
                    ),
                  ),

                // === 各餐別分佈 ===
                if (byType.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  SectionHeader(
                    icon: Icons.pie_chart_outline,
                    title: '各餐別熱量分佈',
                    color: palette.breakfast,
                    subtitle: _topMealTypeLine(byType, totalCalories),
                  ),
                  SoftCard(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      children: [
                        for (final e in byType)
                          _mealTypeRow(theme, e.$1, e.$2, totalCalories),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                const FootNote('＊平均值只計算「有記錄」的日子，避免忘記記錄的日子把數字拉低。'),
              ],
            ),
            const RecompView(),
          ],
        ),
      ),
    );
  }

  /// 「吃最多的是哪一餐」。未分類不列入比較（那不是一餐，是還沒標的舊資料）。
  String _topMealTypeLine(
      List<(MealType?, double)> byType, double totalCalories) {
    final named = byType.where((e) => e.$1 != null).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    if (named.isEmpty || totalCalories <= 0) {
      return '這段期間的紀錄還沒有標餐別。之後新增餐點時選一下，這裡就會出現分佈。';
    }
    final top = named.first;
    final pct = (top.$2 / totalCalories * 100).round();
    return '這段期間吃最多的是「${mealTypeLabel(top.$1)}」，佔總攝取的 $pct%。';
  }

  /// 單一餐別一列：名稱、熱量與佔比，加一條比例長條。
  Widget _mealTypeRow(
      ThemeData theme, MealType? type, double kcal, double total) {
    final ratio = total <= 0 ? 0.0 : (kcal / total).clamp(0.0, 1.0);
    final color = theme.palette.mealColor(type);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(mealTypeIcon(type), size: 16, color: color),
              const SizedBox(width: 6),
              Text(mealTypeLabel(type), style: theme.textTheme.bodyMedium),
              const Spacer(),
              Text(
                '${kcal.round()} 大卡 ・ ${(ratio * 100).round()}%',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GradientBar(value: ratio, color: color),
        ],
      ),
    );
  }

  Widget _weightTile(PeriodSummary summary) {
    final palette = Theme.of(context).palette;
    final change = summary.weightChangeKg;
    final String value;
    final String unit;
    if (change == null) {
      value = '—';
      unit = summary.weightStartKg == null ? '尚無體重紀錄' : '需要至少兩筆紀錄';
    } else {
      final sign = change > 0 ? '+' : '';
      value = '$sign${change.toStringAsFixed(1)}';
      unit =
          'kg（${summary.weightStartKg!.toStringAsFixed(1)} → ${summary.weightEndKg!.toStringAsFixed(1)}）';
    }
    return StatTile(
      icon: Icons.monitor_weight_outlined,
      color: change != null && change > 0 ? palette.warning : palette.success,
      label: '體重變化',
      value: value,
      unit: unit,
    );
  }
}

/// 每日熱量長條圖：超標的日子用錯誤色，並畫出目標虛線。
class _CalorieBarChart extends StatelessWidget {
  final PeriodSummary summary;
  final double target;

  const _CalorieBarChart({required this.summary, required this.target});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue =
        [summary.maxCalories, target].reduce((a, b) => a > b ? a : b);
    final maxY = maxValue <= 0 ? 100.0 : maxValue * 1.25;
    final count = summary.days.length;
    final labelStep = count <= 7 ? 1 : 5;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final d = summary.days[group.x].day;
              return BarTooltipItem(
                '${d.month}/${d.day}\n${rod.toY.round()} 大卡',
                TextStyle(
                  color: theme.colorScheme.onInverseSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < count; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: summary.days[i].calories,
                  // 由下往上的漸層，比單色長條有精神
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: summary.days[i].calories > target
                        ? [
                            theme.colorScheme.error.withValues(alpha: 0.55),
                            theme.colorScheme.error,
                          ]
                        : [
                            theme.colorScheme.primary.withValues(alpha: 0.55),
                            theme.colorScheme.primary,
                          ],
                  ),
                  width: count <= 7 ? 20 : 7,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: target,
              color: theme.colorScheme.onSurfaceVariant,
              strokeWidth: 1.5,
              dashArray: [6, 4],
            ),
          ],
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= count || i % labelStep != 0) {
                  return const SizedBox.shrink();
                }
                final d = summary.days[i].day;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${d.month}/${d.day}',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
