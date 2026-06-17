import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../providers.dart';
import 'add_weight_screen.dart';

/// 體重追蹤：趨勢折線圖 + 紀錄清單。
class WeightScreen extends ConsumerWidget {
  const WeightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watchWeightsBetween 已依日期由舊到新排序。
    final entries =
        ref.watch(weightHistoryProvider).value ?? const <WeightEntry>[];
    final theme = Theme.of(context);

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
      body: entries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '還沒有體重紀錄。\n按右下角「記錄體重」開始追蹤。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.hintColor),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                Text('體重趨勢（近 90 天）', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                SizedBox(height: 220, child: _WeightChart(entries: entries)),
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
                            onPressed: () =>
                                ref.read(repositoryProvider).deleteWeight(e.day),
                          ),
                        ),
                    ],
                  ),
                ),
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

class _WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;
  const _WeightChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = entries.first.day;

    final spots = [
      for (final e in entries)
        FlSpot(e.day.difference(first).inDays.toDouble(), e.weightKg),
    ];
    final weights = entries.map((e) => e.weightKg).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
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
