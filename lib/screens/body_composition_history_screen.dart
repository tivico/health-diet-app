import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/body_composition.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'body_composition_form_screen.dart';

/// 全部的體組成紀錄（新到舊）。點一筆可以修改，垃圾桶可以刪除（可復原）。
class BodyCompositionHistoryScreen extends ConsumerWidget {
  const BodyCompositionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries =
        ref.watch(bodyCompositionsProvider).value ?? const <BodyComposition>[];

    return Scaffold(
      appBar: AppBar(title: const Text('體組成紀錄')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (entries.isEmpty)
            const EmptyState(
              icon: Icons.accessibility_new,
              message: '還沒有體組成紀錄。',
            )
          else
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var i = entries.length - 1; i >= 0; i--) ...[
                    if (i < entries.length - 1)
                      const Divider(indent: 16, endIndent: 16, height: 1),
                    _BodyCompositionTile(entry: entries[i]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BodyCompositionTile extends ConsumerWidget {
  final BodyComposition entry;
  const _BodyCompositionTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final e = entry;
    final bodyFat = e.valueOf(BodyMetric.bodyFat);
    String part(BodyMetric m) {
      final v = e.valueOf(m);
      return v == null ? '' : '${m.label} ${formatBodyValue(v)} ${m.unit}';
    }

    final details = [
      '${e.day.year}/${e.day.month}/${e.day.day}',
      part(BodyMetric.skeletalMuscle),
      part(BodyMetric.waist),
      ?e.source,
    ].where((s) => s.isNotEmpty).join(' ・ ');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: IconBadge(
          icon: Icons.accessibility_new, color: theme.palette.protein),
      title: Text('${formatBodyValue(e.weightKg)} kg'
          '${bodyFat == null ? '' : ' ・ 體脂 ${formatBodyValue(bodyFat)}%'}'),
      subtitle: Text(details),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => BodyCompositionFormScreen(initial: e),
      )),
      trailing: IconButton(
        tooltip: '刪除',
        visualDensity: VisualDensity.compact,
        icon: Icon(Icons.delete_outline,
            size: 20, color: theme.colorScheme.onSurfaceVariant),
        onPressed: () {
          final messenger = ScaffoldMessenger.of(context);
          final repo = ref.read(repositoryProvider);
          repo.deleteBodyComposition(e.day);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(SnackBar(
            content: Text('已刪除 ${e.day.month}/${e.day.day} 的體組成紀錄'),
            action: SnackBarAction(
              label: '復原',
              onPressed: () => repo.upsertBodyComposition(e),
            ),
          ));
        },
      ),
    );
  }
}
