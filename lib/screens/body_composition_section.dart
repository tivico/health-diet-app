import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/body_composition.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'body_composition_form_screen.dart';
import 'body_composition_history_screen.dart';

/// 體重分頁裡的「體組成」區塊：最新一次量測與上一次的比較，以及記錄、看全部的入口。
class BodyCompositionSection extends ConsumerWidget {
  const BodyCompositionSection({super.key});

  /// 摘要卡列出的項目（有量到才顯示）。
  static const _highlights = [
    BodyMetric.weight,
    BodyMetric.bodyFat,
    BodyMetric.fatMass,
    BodyMetric.skeletalMuscle,
    BodyMetric.muscleMass,
    BodyMetric.waist,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entries =
        ref.watch(bodyCompositionsProvider).value ?? const <BodyComposition>[];
    final heightCm = ref.watch(profileProvider).value?.heightCm;
    final latest = entries.isEmpty ? null : entries.last;
    final previous = entries.length >= 2 ? entries[entries.length - 2] : null;

    void openForm() => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              BodyCompositionFormScreen(defaultSource: latest?.source),
        ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: Icons.accessibility_new,
          title: '體組成',
          subtitle: '體脂計、InBody 的量測報告',
          color: theme.palette.protein,
          trailing: TextButton.icon(
            onPressed: openForm,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('記錄'),
          ),
        ),
        if (latest == null)
          _EmptyPrompt(onRecord: openForm)
        else
          _LatestCard(
            latest: latest,
            previous: previous,
            heightCm: heightCm,
            count: entries.length,
          ),
      ],
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  final VoidCallback onRecord;
  const _EmptyPrompt({required this.onRecord});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '有體脂計或 InBody 報告的話，可以記下脂肪量、骨骼肌、腰圍——'
            '增肌減脂時體重不一定會降，看這些才知道身體實際怎麼變。',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onRecord,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('記錄第一筆體組成'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 最新一次量測：重點項目的數值，以及和上一次比的變化。
class _LatestCard extends StatelessWidget {
  final BodyComposition latest;
  final BodyComposition? previous;
  final double? heightCm;
  final int count;

  const _LatestCard({
    required this.latest,
    required this.previous,
    required this.heightCm,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5);
    final d = latest.day;
    final p = previous?.day;
    final metrics = [
      for (final m in BodyCompositionSection._highlights)
        if (latest.valueOf(m) != null) m,
    ];
    final whr = latest.waistHipRatio;
    final extras = [
      if (heightCm != null)
        'BMI ${latest.bmiWith(heightCm!).toStringAsFixed(1)}',
      if (whr != null) '腰臀比 ${whr.toStringAsFixed(2)}',
      ?latest.source,
      ?latest.note,
    ];

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${d.year}/${d.month}/${d.day} 量測',
                  style: theme.textTheme.titleSmall),
              const Spacer(),
              if (p != null) Text('與 ${p.month}/${p.day} 相比', style: muted),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < metrics.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _metricCell(context, metrics[i])),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < metrics.length
                      ? _metricCell(context, metrics[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
          if (extras.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(extras.join(' ・ '), style: muted),
          ],
          const SizedBox(height: 8),
          Text(
            '家用體脂計會受水分、飲食、生理期與量測時間影響：'
            '盡量在相近條件下量，看多次的趨勢，不要只看一次的升降。',
            style: muted,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const BodyCompositionHistoryScreen(),
              )),
              child: Text('全部紀錄（$count 筆）'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCell(BuildContext context, BodyMetric m) {
    final theme = Theme.of(context);
    final palette = theme.palette;
    final value = latest.valueOf(m)!;
    final delta = previous == null ? null : deltaOf(m, previous!, latest);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          m.label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: formatBodyValue(value),
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (m.unit.isNotEmpty)
              // 百分比緊接數字（24.6%），其他單位前空一格（71.6 kg）
              TextSpan(
                text: m.unit == '%' ? m.unit : ' ${m.unit}',
                style: theme.textTheme.bodySmall,
              ),
          ]),
        ),
        if (delta != null) ...[
          const SizedBox(height: 4),
          PillLabel(
            text: formatBodyDelta(delta),
            // 綠＝往好的方向、橘＝反方向、灰＝沒有好壞之分（例如體重）或持平
            color: switch (changeOf(m, delta)) {
              Change.better => palette.success,
              Change.worse => palette.warning,
              Change.neutral || Change.flat => palette.uncategorized,
            },
            icon: delta.abs() < 0.05
                ? Icons.remove
                : (delta < 0 ? Icons.arrow_downward : Icons.arrow_upward),
          ),
        ],
      ],
    );
  }
}
