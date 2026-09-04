import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../domain/nutrition.dart';
import '../domain/weight_goal.dart';
import '../providers.dart';
import 'add_weight_screen.dart';
import 'onboarding_screen.dart';

/// 體重追蹤：目標進度 + 趨勢折線圖 + 紀錄清單。
class WeightScreen extends ConsumerWidget {
  const WeightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watchWeightsBetween 已依日期由舊到新排序。
    final entries =
        ref.watch(weightHistoryProvider).value ?? const <WeightEntry>[];
    final profile = ref.watch(profileProvider).value;
    final theme = Theme.of(context);

    // 有紀錄就以最新一筆為「目前體重」，比個人資料裡的數字貼近現況。
    final projection = profile == null
        ? null
        : projectWeightGoal(
            profile: profile,
            plan: nutritionPlan(profile),
            currentWeightKg: entries.isEmpty ? null : entries.last.weightKg,
          );

    return Scaffold(
      appBar: AppBar(title: const Text('體重追蹤')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-weight', // 與今日分頁的 FAB 區分，避免 Hero tag 衝突
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddWeightScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('記錄體重'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          if (projection != null)
            _GoalCard(
              projection: projection,
              // 只有兩筆以上才談得上「進度」
              startKg: entries.length >= 2 ? entries.first.weightKg : null,
            )
          else if (profile != null)
            _SetGoalPrompt(profile: profile),
          const SizedBox(height: 20),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                '還沒有體重紀錄。\n按右下角「記錄體重」開始追蹤。',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.hintColor),
              ),
            )
          else ...[
            Text('體重趨勢（近 90 天）', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: _WeightChart(
                entries: entries,
                targetKg: profile?.targetWeightKg,
              ),
            ),
            const SizedBox(height: 20),
            Text('紀錄', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (final e in entries.reversed)
                    ListTile(
                      title: Text('${e.weightKg.toStringAsFixed(1)} kg'),
                      subtitle: Text(_subtitle(e)),
                      trailing: IconButton(
                        tooltip: '刪除',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          final messenger = ScaffoldMessenger.of(context);
                          final repo = ref.read(repositoryProvider);
                          repo.deleteWeight(e.day);
                          messenger.hideCurrentSnackBar();
                          messenger.showSnackBar(SnackBar(
                            content: Text(
                                '已刪除 ${e.weightKg.toStringAsFixed(1)} kg 的紀錄'),
                            action: SnackBarAction(
                              label: '復原',
                              onPressed: () => repo.upsertWeight(
                                day: e.day,
                                weightKg: e.weightKg,
                                bodyFatPct: e.bodyFatPct,
                              ),
                            ),
                          ));
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _subtitle(WeightEntry e) {
    final date = '${e.day.year}/${e.day.month}/${e.day.day}';
    if (e.bodyFatPct == null) return date;
    return '$date ・ 體脂 ${e.bodyFatPct!.toStringAsFixed(1)}%';
  }
}

/// 還沒設定目標體重時的引導（不設定也完全能用，所以語氣輕）。
class _SetGoalPrompt extends StatelessWidget {
  final UserProfile profile;
  const _SetGoalPrompt({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            Icon(Icons.flag_outlined, color: theme.hintColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '設定目標體重，這裡就會顯示進度與預估達成時間。',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OnboardingScreen(initial: profile),
                ),
              ),
              child: const Text('去設定'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 目標體重卡片：還差多少、進度、預估達成時間，以及健康區間提醒。
class _GoalCard extends StatelessWidget {
  final WeightGoalProjection projection;

  /// 期間內最早一筆體重，用來算進度；只有一筆紀錄時為 null。
  final double? startKg;

  const _GoalCard({required this.projection, this.startKg});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = projection;
    final progress = startKg == null
        ? null
        : weightGoalProgress(
            startKg: startKg!,
            currentKg: p.currentWeightKg,
            targetKg: p.targetWeightKg,
          );

    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_outlined, size: 20),
                const SizedBox(width: 8),
                Text('目標體重', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '目前 ${p.currentWeightKg.toStringAsFixed(1)} '
              '→ 目標 ${p.targetWeightKg.toStringAsFixed(1)} kg',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 6),
            Text(
              p.reached
                  ? '已達成目標 🎉'
                  : '還差 ${p.remainingAbsKg.toStringAsFixed(1)} 公斤',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor:
                      theme.colorScheme.onSecondaryContainer.withValues(
                    alpha: 0.15,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '自最早一筆紀錄以來，已完成 ${(progress * 100).round()}%',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Text(_etaText(p), style: theme.textTheme.bodyMedium),
            if (!p.reached && !p.directionMismatch) ...[
              const SizedBox(height: 6),
              Text(
                '＊以「1 公斤 ≒ 7700 大卡」線性估算。實際上體重下降後代謝也會下降，'
                '真正需要的時間通常比這個久 —— 當作方向參考，不是保證。',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor),
              ),
            ],
            if (p.warning != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(p.warning!,
                          style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _etaText(WeightGoalProjection p) {
    if (p.reached) return '維持目前的習慣就好，不需要再往下追。';
    if (p.directionMismatch) {
      return '目前的每日熱量目標不會朝這個體重前進。'
          '到「今日」分頁右上角的「編輯資料」調整目標（減脂 / 維持 / 增肌），'
          '或修改目標體重。';
    }
    final weeks = p.weeksToTarget!;
    final d = p.estimatedDate!;
    final pace = p.weeklyChangeKg.abs().toStringAsFixed(2);
    if (weeks > 104) {
      return '照目前的每日熱量目標（每週約 $pace 公斤），要超過兩年才會達成。'
          '可以考慮增加活動量，或把目標拆成幾個階段。';
    }
    return '照目前的每日熱量目標（每週約 $pace 公斤），'
        '約 $weeks 週達成，大約在 ${d.year}/${d.month}/${d.day}。';
  }
}

class _WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;

  /// 有設定目標體重時，在圖上畫一條水平虛線。
  final double? targetKg;

  const _WeightChart({required this.entries, this.targetKg});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = entries.first.day;

    final spots = [
      for (final e in entries)
        FlSpot(e.day.difference(first).inDays.toDouble(), e.weightKg),
    ];
    // Y 軸範圍要含目標線，否則設定了目標卻看不到那條線。
    final values = [
      for (final e in entries) e.weightKg,
      ?targetKg,
    ];
    final minW = values.reduce((a, b) => a < b ? a : b);
    final maxW = values.reduce((a, b) => a > b ? a : b);
    final pad = ((maxW - minW) * 0.25).clamp(1.0, 5.0);

    return LineChart(
      LineChartData(
        minY: minW - pad,
        maxY: maxW + pad,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (targetKg != null)
              HorizontalLine(
                y: targetKg!,
                color: theme.colorScheme.tertiary,
                strokeWidth: 2,
                dashArray: [6, 4],
              ),
          ],
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final d = first.add(Duration(days: value.toInt()));
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child:
                      Text('${d.month}/${d.day}', style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
