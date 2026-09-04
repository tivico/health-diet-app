import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../domain/nutrition.dart';
import '../domain/stats.dart';
import '../providers.dart';

/// 統計：近 7 / 30 天的每日熱量長條圖與摘要。
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

    return Scaffold(
      appBar: AppBar(title: const Text('統計')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
          const SizedBox(height: 16),

          // === 摘要數字 ===
          Row(
            children: [
              Expanded(
                child: _statCard(
                  theme,
                  '平均每日攝取',
                  summary.daysWithRecords == 0
                      ? '—'
                      : '${summary.averageCalories.round()}',
                  '大卡（目標 ${plan.calorieTarget.round()}）',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  theme,
                  '有記錄天數',
                  '${summary.daysWithRecords}',
                  '／ $_days 天',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  theme,
                  '達標天數',
                  '${summary.daysOnTarget}',
                  '天（目標 ±10% 內）',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _weightCard(theme, summary)),
            ],
          ),
          const SizedBox(height: 20),

          // === 每日熱量長條圖 ===
          Text('每日熱量', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '虛線為你的每日目標；超過目標的日子會標成紅色。',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 12),
          if (summary.daysWithRecords == 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    '這段期間還沒有餐點紀錄。\n到「今日」分頁記錄幾筆，這裡就會出現趨勢。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.hintColor),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: _CalorieBarChart(
                summary: summary,
                target: plan.calorieTarget,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            '＊平均值只計算「有記錄」的日子，避免忘記記錄的日子把數字拉低。',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _statCard(ThemeData theme, String label, String value, String unit) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor)),
              const SizedBox(height: 6),
              Text(value,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(unit, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      );

  Widget _weightCard(ThemeData theme, PeriodSummary summary) {
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
    return _statCard(theme, '體重變化', value, unit);
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
    final maxValue = [summary.maxCalories, target].reduce((a, b) => a > b ? a : b);
    final maxY = maxValue <= 0 ? 100.0 : maxValue * 1.25;
    final count = summary.days.length;
    final labelStep = count <= 7 ? 1 : 5;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barGroups: [
          for (var i = 0; i < count; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: summary.days[i].calories,
                  color: summary.days[i].calories > target
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  width: count <= 7 ? 22 : 7,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: target,
              color: theme.colorScheme.outline,
              strokeWidth: 2,
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
                style: const TextStyle(fontSize: 10),
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
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${d.month}/${d.day}',
                      style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
