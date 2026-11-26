import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/activity.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets/activity_visuals.dart';
import '../widgets/common.dart';
import 'activity_form_screen.dart';
import 'exercise_library_screen.dart';

/// 運動分頁：本週 / 上週的次數與時間，以及所有運動紀錄（新到舊）。
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activities = ref.watch(activitiesProvider).value ?? const <Activity>[];
    final exercises = ref.watch(exercisesProvider).value ?? const <Exercise>[];
    final now = DateTime.now();
    final thisWeek = summarizeWeek(activities, now);
    final lastWeek =
        summarizeWeek(activities, DateTime(now.year, now.month, now.day - 7));

    return Scaffold(
      appBar: AppBar(
        title: const Text('運動紀錄'),
        actions: [
          IconButton(
            tooltip: '器材清單',
            icon: const Icon(Icons.fitness_center),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ExerciseLibraryScreen(),
            )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-activity', // 與其他分頁的 FAB 區分，避免 Hero tag 衝突
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const ActivityFormScreen(),
        )),
        icon: const Icon(Icons.add),
        label: const Text('記錄運動'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _WeekCard(thisWeek: thisWeek, lastWeek: lastWeek),
          const SizedBox(height: 22),
          if (activities.isEmpty)
            const EmptyState(
              icon: Icons.directions_run,
              message: '還沒有運動紀錄。\n按右下角「記錄運動」開始。',
            )
          else ...[
            SectionHeader(
              icon: Icons.event_note_outlined,
              title: '紀錄',
              color: theme.palette.breakfast,
              trailing: PillLabel(
                text: '${activities.length} 筆',
                color: theme.palette.breakfast,
              ),
            ),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final (i, a) in activities.indexed) ...[
                    if (i > 0)
                      const Divider(indent: 16, endIndent: 16, height: 1),
                    _ActivityTile(activity: a, exercises: exercises),
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

/// 本週次數與總時間，下面一行附上週當比較。
class _WeekCard extends StatelessWidget {
  final WeekSummary thisWeek;
  final WeekSummary lastWeek;
  const _WeekCard({required this.thisWeek, required this.lastWeek});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5);
    final s = thisWeek.start;

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                  icon: Icons.calendar_view_week,
                  color: theme.palette.breakfast,
                  size: 32),
              const SizedBox(width: 10),
              Text('本週（${s.month}/${s.day} 起）',
                  style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            thisWeek.sessions == 0 ? '這週還沒有運動紀錄' : thisWeek.describeCounts(),
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (thisWeek.sessions > 0) ...[
            const SizedBox(height: 2),
            Text('共 ${formatMinutes(thisWeek.total)}',
                style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 8),
          Text(
            lastWeek.sessions == 0
                ? '上週：沒有紀錄'
                : '上週：${lastWeek.describeCounts()}，共 ${formatMinutes(lastWeek.total)}',
            style: muted,
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends ConsumerWidget {
  final Activity activity;
  final List<Exercise> exercises;
  const _ActivityTile({required this.activity, required this.exercises});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final a = activity;
    final details = [
      shortDateWithWeekday(a.startedAt),
      formatClock(a.duration),
      if (a.kind == ActivityKind.strength && a.sets.isNotEmpty)
        '${a.sets.length} 個動作 ・ ${a.totalSets} 組',
      if (a.avgHr != null) '平均 ${a.avgHr} bpm',
      if (a.calories != null) '${a.calories!.round()} 大卡',
    ].join(' ・ ');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: IconBadge(
        icon: activityKindIcon(a.kind),
        color: activityKindColor(context, a.kind),
      ),
      title: Text(a.displayTitle),
      subtitle: Text(details),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ActivityFormScreen(initial: a),
      )),
      trailing: IconButton(
        tooltip: '刪除',
        visualDensity: VisualDensity.compact,
        icon: Icon(Icons.delete_outline,
            size: 20, color: theme.colorScheme.onSurfaceVariant),
        onPressed: () {
          final messenger = ScaffoldMessenger.of(context);
          final repo = ref.read(repositoryProvider);
          repo.deleteActivity(a.id!);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(SnackBar(
            content: Text('已刪除 ${a.startedAt.month}/${a.startedAt.day} 的「${a.displayTitle}」'),
            action: SnackBarAction(
              label: '復原',
              onPressed: () => repo.saveActivity(a.asNew()),
            ),
          ));
        },
      ),
    );
  }
}
