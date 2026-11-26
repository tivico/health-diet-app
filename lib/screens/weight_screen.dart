import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../domain/nutrition.dart';
import '../domain/weight_goal.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'add_weight_screen.dart';
import 'body_composition_section.dart';
import 'onboarding_screen.dart';

/// 體重追蹤：目標進度 + 體組成 + 趨勢折線圖 + 紀錄清單。
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (projection != null)
            _GoalCard(
              projection: projection,
              // 只有兩筆以上才談得上「進度」
              startKg: entries.length >= 2 ? entries.first.weightKg : null,
            )
          else if (profile != null)
            _SetGoalPrompt(profile: profile),
          const SizedBox(height: 22),
          const BodyCompositionSection(),
          const SizedBox(height: 22),
          if (entries.isEmpty)
            const EmptyState(
              icon: Icons.monitor_weight_outlined,
              message: '還沒有體重紀錄。\n按右下角「記錄體重」開始追蹤。',
            )
          else ...[
            const SectionHeader(
              icon: Icons.show_chart,
              title: '體重趨勢（近 90 天）',
              subtitle: '虛線是你的目標體重',
            ),
            SoftCard(
              padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
              child: SizedBox(
                height: 210,
                child: _WeightChart(
                  entries: entries,
                  targetKg: profile?.targetWeightKg,
                ),
              ),
            ),
            const SizedBox(height: 22),
            SectionHeader(
              icon: Icons.event_note_outlined,
              title: '紀錄',
              color: theme.palette.carbs,
              trailing: PillLabel(
                text: '${entries.length} 筆',
                color: theme.palette.carbs,
              ),
            ),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var i = entries.length - 1; i >= 0; i--) ...[
                    if (i < entries.length - 1)
                      const Divider(indent: 16, endIndent: 16, height: 1),
                    _WeightTile(
                      entry: entries[i],
                      // 和前一筆比較，才看得出這次是升是降
                      previousKg: i == 0 ? null : entries[i - 1].weightKg,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 單筆體重紀錄：左邊圖示、中間數字與日期、右邊與前一筆的差值。
class _WeightTile extends ConsumerWidget {
  final WeightEntry entry;
  final double? previousKg;

  const _WeightTile({required this.entry, this.previousKg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.palette;
    final delta = previousKg == null ? null : entry.weightKg - previousKg!;

    // 體重升降沒有絕對好壞，這裡只用「降＝綠、升＝橘」提供方向感。
    final deltaColor = delta == null || delta.abs() < 0.05
        ? palette.uncategorized
        : (delta < 0 ? palette.success : palette.warning);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: IconBadge(
        icon: Icons.monitor_weight_outlined,
        color: palette.carbs,
      ),
      title: Text('${entry.weightKg.toStringAsFixed(1)} kg'),
      subtitle: Text(_subtitle(entry)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (delta != null)
            PillLabel(
              text: _deltaText(delta),
              color: deltaColor,
              icon: delta.abs() < 0.05
                  ? Icons.remove
                  : (delta < 0
                      ? Icons.arrow_downward
                      : Icons.arrow_upward),
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
              repo.deleteWeight(entry.day);
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(SnackBar(
                content:
                    Text('已刪除 ${entry.weightKg.toStringAsFixed(1)} kg 的紀錄'),
                action: SnackBarAction(
                  label: '復原',
                  onPressed: () => repo.upsertWeight(
                    day: entry.day,
                    weightKg: entry.weightKg,
                    bodyFatPct: entry.bodyFatPct,
                  ),
                ),
              ));
            },
          ),
        ],
      ),
    );
  }

  static String _deltaText(double delta) {
    if (delta.abs() < 0.05) return '持平';
    return '${delta > 0 ? '+' : '−'}${delta.abs().toStringAsFixed(1)}';
  }

  static String _subtitle(WeightEntry e) {
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
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          IconBadge(icon: Icons.flag_outlined, color: theme.palette.carbs),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '設定目標體重，這裡就會顯示進度與預估達成時間。',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
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

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      shadow: false,
      gradient: LinearGradient(
        colors: theme.palette.weightGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                '目標體重',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: Colors.white),
              ),
              const Spacer(),
              if (p.reached)
                const _GlassChip(text: '已達成 🎉')
              else
                _GlassChip(
                  text: '目標 ${p.targetWeightKg.toStringAsFixed(1)} kg',
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            p.reached ? '已達成目標 🎉' : '還差 ${p.remainingAbsKg.toStringAsFixed(1)} 公斤',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '目前 ${p.currentWeightKg.toStringAsFixed(1)} '
            '→ 目標 ${p.targetWeightKg.toStringAsFixed(1)} kg',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                color: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '自最早一筆紀錄以來，已完成 ${(progress * 100).round()}%',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _etaText(p),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                if (!p.reached && !p.directionMismatch) ...[
                  const SizedBox(height: 8),
                  Text(
                    '＊以「1 公斤 ≒ 7700 大卡」線性估算。實際上體重下降後代謝也會下降，'
                    '真正需要的時間通常比這個久 —— 當作方向參考，不是保證。',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (p.warning != null) ...[
            const SizedBox(height: 10),
            _GlassPanel(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.favorite_outline,
                      size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.warning!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
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

/// 漸層卡上的半透明標籤。
class _GlassChip extends StatelessWidget {
  final String text;
  const _GlassChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// 漸層卡上的半透明說明區塊。
class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: child,
    );
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
    final palette = theme.palette;
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
    final line = palette.carbs;

    return LineChart(
      LineChartData(
        minY: minW - pad,
        maxY: maxW + pad,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${s.y.toStringAsFixed(1)} kg',
                  TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: line,
            barWidth: 3.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3.5,
                color: palette.surface,
                strokeWidth: 2.5,
                strokeColor: line,
              ),
            ),
            // 線下淡淡的漸層，看起來比一條光禿禿的折線有份量
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  line.withValues(alpha: 0.28),
                  line.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (targetKg != null)
              HorizontalLine(
                y: targetKg!,
                color: palette.success,
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
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final d = first.add(Duration(days: value.toInt()));
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
