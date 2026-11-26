import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/activity.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 新增或修改器材的對話框；存好回傳器材 id，取消回傳 null。
///
/// [unitLocked]：已經有紀錄的器材不能改單位，否則舊的重量會被誤讀（20 lb 變成 20 kg）。
Future<int?> showExerciseDialog(
  BuildContext context, {
  Exercise? initial,
  bool unitLocked = false,
}) =>
    showDialog<int>(
      context: context,
      builder: (_) => _ExerciseDialog(initial: initial, unitLocked: unitLocked),
    );

class _ExerciseDialog extends ConsumerStatefulWidget {
  final Exercise? initial;
  final bool unitLocked;
  const _ExerciseDialog({this.initial, required this.unitLocked});

  @override
  ConsumerState<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends ConsumerState<_ExerciseDialog> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late WeightUnit _unit = widget.initial?.unit ?? WeightUnit.kg;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '請輸入器材名稱');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final id = await ref.read(repositoryProvider).saveExercise(
          Exercise(id: widget.initial?.id, name: name, unit: _unit));
      if (mounted) Navigator.pop(context, id);
    } on DuplicateExerciseNameException catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    } on StateError catch (e) {
      setState(() {
        _saving = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.initial == null ? '新增器材' : '修改器材'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: 60,
            decoration: InputDecoration(
              labelText: '名稱',
              hintText: '例如 划船機（第一台）',
              errorText: _error,
              counterText: '',
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 14),
          Text('重量單位', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<WeightUnit>(
            segments: [
              for (final u in WeightUnit.values)
                ButtonSegment(value: u, label: Text(u.label)),
            ],
            selected: {_unit},
            onSelectionChanged: widget.unitLocked
                ? null
                : (s) => setState(() => _unit = s.first),
          ),
          const SizedBox(height: 6),
          Text(
            widget.unitLocked
                ? '已經有紀錄，單位不能改（舊的重量會被誤讀）。'
                : '照器材上的刻度選；同一台器材之後都用這個單位。',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
            onPressed: _saving ? null : _save, child: const Text('儲存')),
      ],
    );
  }
}

/// 器材清單：每台器材最近一次的重量；點進去看歷次紀錄。
class ExerciseLibraryScreen extends ConsumerWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exercises = ref.watch(exercisesProvider).value ?? const <Exercise>[];
    final activities = ref.watch(activitiesProvider).value ?? const <Activity>[];

    return Scaffold(
      appBar: AppBar(title: const Text('器材清單')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-exercise',
        onPressed: () => showExerciseDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('新增器材'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          InfoNote(
            icon: Icons.lightbulb_outline,
            color: theme.palette.dinner,
            text: '每台器材建一個名字，例如「划船機（第一台）」。'
                '不同器材的重量不能互比（滑輪比例、力臂都不一樣），進步只跟同一台比。',
          ),
          const SizedBox(height: 16),
          if (exercises.isEmpty)
            const EmptyState(
              icon: Icons.fitness_center,
              message: '還沒有器材。\n記錄肌力訓練時可以直接新增，也可以先在這裡建好。',
            )
          else
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final (i, e) in exercises.indexed) ...[
                    if (i > 0)
                      const Divider(indent: 16, endIndent: 16, height: 1),
                    _ExerciseTile(
                        exercise: e, history: historyOf(e.id!, activities)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ExerciseTile extends ConsumerWidget {
  final Exercise exercise;
  final List<ExerciseRecord> history;
  const _ExerciseTile({required this.exercise, required this.history});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final e = exercise;
    final last = history.isEmpty ? null : history.last;
    final muted = theme.colorScheme.onSurfaceVariant;

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 12, right: 4),
      leading: IconBadge(icon: Icons.fitness_center, color: theme.palette.dinner),
      title: Text(e.name),
      subtitle: Text(last == null
          ? '單位 ${e.unit.label} ・ 還沒有紀錄'
          : '${last.date.month}/${last.date.day} ・ '
              '${describeExerciseSet(last.set, e.unit)}'),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ExerciseProgressScreen(exerciseId: e.id!),
      )),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: '修改',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.edit_outlined, size: 20, color: muted),
            onPressed: () => showExerciseDialog(context,
                initial: e, unitLocked: history.isNotEmpty),
          ),
          IconButton(
            tooltip: '刪除',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.delete_outline, size: 20, color: muted),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final deleted =
                  await ref.read(repositoryProvider).deleteExercise(e.id!);
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(SnackBar(
                content: Text(deleted
                    ? '已刪除「${e.name}」'
                    : '「${e.name}」已經有紀錄，不能刪除（紀錄會對不到器材）'),
              ));
            },
          ),
        ],
      ),
    );
  }
}

/// 一台器材的歷次紀錄（新到舊），和上一次比重量。
class ExerciseProgressScreen extends ConsumerWidget {
  const ExerciseProgressScreen({super.key, required this.exerciseId});
  final int exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.palette;
    final exercises = ref.watch(exercisesProvider).value ?? const <Exercise>[];
    final activities = ref.watch(activitiesProvider).value ?? const <Activity>[];
    final exercise = exercises.where((e) => e.id == exerciseId).firstOrNull;
    if (exercise == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('器材')),
        body: const Center(child: Text('找不到這台器材')),
      );
    }
    final history = historyOf(exerciseId, activities);

    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (history.isEmpty)
            const EmptyState(
              icon: Icons.trending_up,
              message: '還沒有紀錄。\n記錄肌力訓練時選這台器材，這裡就會列出每次的重量。',
            )
          else ...[
            SectionHeader(
              icon: Icons.trending_up,
              title: '每次的重量',
              subtitle: '單位 ${exercise.unit.label} ・ 和上一次比',
              color: palette.dinner,
            ),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var i = history.length - 1; i >= 0; i--) ...[
                    if (i < history.length - 1)
                      const Divider(indent: 16, endIndent: 16, height: 1),
                    ListTile(
                      title: Text(
                          describeExerciseSet(history[i].set, exercise.unit)),
                      subtitle: Text('${history[i].date.year}/'
                          '${history[i].date.month}/${history[i].date.day}'),
                      trailing: _weightChange(
                        context,
                        history[i].set.weight,
                        i == 0 ? null : history[i - 1].set.weight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            const FootNote('重量下降不一定是退步：休息一陣子後，先用輕一點的重量很正常。'),
          ],
        ],
      ),
    );
  }

  /// 和上一次比的重量變化：加重標綠、減輕標橘、一樣標灰。
  Widget? _weightChange(BuildContext context, double? now, double? before) {
    if (now == null || before == null) return null;
    final palette = Theme.of(context).palette;
    final d = now - before;
    String fmt(double v) =>
        v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
    if (d.abs() < 0.05) {
      return PillLabel(
          text: '持平', color: palette.uncategorized, icon: Icons.remove);
    }
    return PillLabel(
      text: '${d > 0 ? '+' : '−'}${fmt(d.abs())}',
      color: d > 0 ? palette.success : palette.warning,
      icon: d > 0 ? Icons.arrow_upward : Icons.arrow_downward,
    );
  }
}
