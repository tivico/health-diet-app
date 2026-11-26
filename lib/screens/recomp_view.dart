import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/education_content.dart';
import '../domain/activity.dart';
import '../domain/body_composition.dart';
import '../domain/meal_type.dart';
import '../domain/nutrition.dart';
import '../domain/recomp.dart';
import '../domain/stats.dart' show dateOnly;
import '../labels.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'body_composition_form_screen.dart';
import 'education_screen.dart';

/// 增肌減脂分析：同一段期間裡的體組成變化、訓練與飲食，一起看才知道身體實際怎麼變。
class RecompView extends ConsumerStatefulWidget {
  const RecompView({super.key});

  @override
  ConsumerState<RecompView> createState() => _RecompViewState();
}

class _RecompViewState extends ConsumerState<RecompView> {
  RecompPeriod _period = RecompPeriod.weeks12;

  /// 「全部」時餐點往回查的天數上限（查詢需要一個範圍）。
  static const _allDays = 3650;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final bodies =
        ref.watch(bodyCompositionsProvider).value ?? const <BodyComposition>[];
    final activities = ref.watch(activitiesProvider).value ?? const <Activity>[];
    final exercises = ref.watch(exercisesProvider).value ?? const <Exercise>[];
    final meals = ref.watch(statsMealsProvider(_period.days ?? _allDays)).value ??
        const <MealEntry>[];
    final weights =
        ref.watch(weightHistoryProvider).value ?? const <WeightEntry>[];

    final today = dateOnly(DateTime.now());
    final from = switch (_period.days) {
      final days? => today.subtract(Duration(days: days - 1)),
      // 「全部」：從最早的一筆紀錄開始
      null => _earliest([
            for (final b in bodies) b.day,
            for (final a in activities) a.startedAt,
            for (final m in meals) m.eatenAt,
          ]) ??
          today,
    };

    final inPeriod = [
      for (final b in bodies)
        if (!b.day.isBefore(from)) b,
    ];
    final change = bodyChangeSince(bodies, from);
    // 訓練、飲食從「這段期間裡第一筆紀錄」起算：剛開始記錄的人，
    // 不會因為還沒開始記的那幾週，被算成「幾乎沒運動」「記錄天數不到一半」。
    final trainingFrom = _later(from,
        activities.isEmpty ? null : dateOnly(activities.last.startedAt));
    final dietFrom = _later(from, _earliest([for (final m in meals) m.eatenAt]));
    final training =
        summarizeTraining(activities, from: trainingFrom, to: today);
    final diet = summarizeDiet([
      for (final m in meals)
        (
          eatenAt: m.eatenAt,
          calories: m.calories,
          proteinG: m.proteinG,
          type: m.mealType,
        ),
    ], from: dietFrom, to: today);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Center(
          child: SegmentedButton<RecompPeriod>(
            segments: [
              for (final p in RecompPeriod.values)
                ButtonSegment(value: p, label: Text(p.label)),
            ],
            selected: {_period},
            onSelectionChanged: (s) => setState(() => _period = s.first),
          ),
        ),
        const SizedBox(height: 18),
        if (change == null)
          _NeedMeasurements(count: inPeriod.length)
        else
          _BodyChangeCard(change: change),
        if (inPeriod.length >= 2) ...[
          const SizedBox(height: 22),
          SectionHeader(
            icon: Icons.show_chart,
            title: '體組成趨勢',
            color: Theme.of(context).palette.protein,
          ),
          SoftCard(
            padding: const EdgeInsets.fromLTRB(8, 18, 20, 12),
            child: _BodyTrendChart(entries: inPeriod),
          ),
        ],
        const SizedBox(height: 22),
        _TrainingSection(
          training: training,
          exercises: exercises,
          countedFrom: trainingFrom == from ? null : trainingFrom,
        ),
        const SizedBox(height: 22),
        _DietSection(
          diet: diet,
          plan: nutritionPlan(profile),
          weightKg: _latestWeight(bodies, weights) ?? profile.weightKg,
          countedFrom: dietFrom == from ? null : dietFrom,
        ),
        const SizedBox(height: 20),
        const FootNote('＊體組成只比較這段期間的第一次和最後一次量測，0.5 公斤以內的變化當作看不出來。'
            '本頁只是整理你的紀錄，不是醫療建議。'),
      ],
    );
  }

  static DateTime _later(DateTime a, DateTime? b) =>
      b != null && b.isAfter(a) ? b : a;

  static DateTime? _earliest(List<DateTime> dates) {
    if (dates.isEmpty) return null;
    final first = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    return dateOnly(first);
  }

  /// 最近一次的體重：體組成和體重紀錄，誰比較新用誰。
  static double? _latestWeight(
      List<BodyComposition> bodies, List<WeightEntry> weights) {
    final b = bodies.isEmpty ? null : bodies.last;
    final w = weights.isEmpty ? null : weights.last;
    if (b == null) return w?.weightKg;
    if (w == null) return b.weightKg;
    return w.day.isAfter(b.day) ? w.weightKg : b.weightKg;
  }
}

/// 帶正負號、一位小數：+0.6、−1.1。
String _signed(double v) =>
    '${v >= 0 ? '+' : '−'}${v.abs().toStringAsFixed(1)}';

Color _changeColor(BuildContext context, BodyMetric metric, double delta) {
  final palette = Theme.of(context).palette;
  return switch (changeOf(metric, delta)) {
    Change.better => palette.success,
    Change.worse => palette.warning,
    Change.neutral || Change.flat => palette.uncategorized,
  };
}

class _NeedMeasurements extends StatelessWidget {
  final int count;
  const _NeedMeasurements({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                  icon: Icons.accessibility_new, color: theme.palette.protein),
              const SizedBox(width: 10),
              Text('體組成變化', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            count == 0
                ? '這段期間還沒有體組成量測。'
                : '這段期間只有 1 次體組成量測，至少要兩次才能比較。',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '記下體脂計或 InBody 報告，就能看出體重的變化來自脂肪還是肌肉。',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const BodyCompositionFormScreen(),
            )),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('記錄體組成'),
          ),
        ],
      ),
    );
  }
}

/// 期間內第一次 → 最後一次：判讀、各項變化，以及體重變化的拆解。
class _BodyChangeCard extends StatelessWidget {
  final BodyChange change;
  const _BodyChangeCard({required this.change});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.palette;
    final c = change;
    final v = c.verdict;
    final toneColor = switch (v.tone) {
      Tone.good => palette.success,
      Tone.caution => palette.warning,
      Tone.neutral => palette.carbs,
    };
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5);
    final muscle = c.muscleMetric;
    final waist = deltaOf(BodyMetric.waist, c.first, c.last);
    final cells = [
      ('體重', c.weightDelta, BodyMetric.weight, 'kg'),
      (c.fatEstimated ? '脂肪量（推算）' : '脂肪量', c.fatDelta, BodyMetric.fatMass, 'kg'),
      if (muscle != null) (muscle.label, c.muscleDelta, muscle, 'kg'),
      if (waist != null) ('腰圍', waist, BodyMetric.waist, 'cm'),
    ];
    final f = c.first.day;
    final l = c.last.day;

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('體組成變化', style: theme.textTheme.titleMedium),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${f.month}/${f.day} → ${l.month}/${l.day} ・ ${c.count} 次量測',
                  style: muted,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: toneColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.field),
              border: Border.all(color: toneColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800, color: toneColor),
                ),
                const SizedBox(height: 4),
                Text(v.detail,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < cells.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _cell(context, cells[i])),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < cells.length
                      ? _cell(context, cells[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
          if (c.fatDelta case final fat?) ...[
            const SizedBox(height: 12),
            Text(
              '體重 ${_signed(c.weightDelta)} kg ＝ 脂肪 ${_signed(fat)} ＋ '
              '非脂肪 ${_signed(c.nonFatDelta!)}（肌肉、水分、肝醣等）',
              style: muted,
            ),
          ],
          if (c.count == 2) ...[
            const SizedBox(height: 10),
            InfoNote(
              color: palette.carbs,
              text: '只有兩次量測，先當參考。之後在相近的條件下多量幾次，趨勢會更可靠。',
            ),
          ],
        ],
      ),
    );
  }

  Widget _cell(BuildContext context,
      (String, double?, BodyMetric, String) cell) {
    final theme = Theme.of(context);
    final (label, delta, metric, unit) = cell;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        if (delta == null)
          Text('—', style: theme.textTheme.titleMedium)
        else
          PillLabel(
            text: '${formatBodyDelta(delta)}'
                '${delta.abs() < 0.05 ? '' : ' $unit'}',
            color: _changeColor(context, metric, delta),
            icon: delta.abs() < 0.05
                ? Icons.remove
                : (delta < 0 ? Icons.arrow_downward : Icons.arrow_upward),
          ),
      ],
    );
  }
}

/// 脂肪量與肌肉在期間內的走勢（兩條線，單位都是公斤）。
class _BodyTrendChart extends StatelessWidget {
  final List<BodyComposition> entries;
  const _BodyTrendChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.palette;
    final first = entries.first.day;
    double x(BodyComposition b) => b.day.difference(first).inDays.toDouble();

    // 肌肉用骨骼肌；這段期間都沒量骨骼肌的話改用肌肉量
    final muscleMetric =
        entries.any((b) => b.valueOf(BodyMetric.skeletalMuscle) != null)
            ? BodyMetric.skeletalMuscle
            : BodyMetric.muscleMass;
    final series = [
      ('脂肪量', palette.fat, [
        for (final b in entries)
          if (fatMassOf(b) case final v?) FlSpot(x(b), v),
      ]),
      (muscleMetric.label, palette.protein, [
        for (final b in entries)
          if (b.valueOf(muscleMetric) case final v?) FlSpot(x(b), v),
      ]),
    ].where((s) => s.$3.isNotEmpty).toList();

    if (series.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text('這段期間的量測沒有脂肪量或肌肉的數字。',
            style: theme.textTheme.bodySmall),
      );
    }
    final values = [for (final s in series) for (final p in s.$3) p.y];
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY) * 0.25).clamp(0.5, 5.0);

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: LineChart(
            LineChartData(
              minY: minY - pad,
              maxY: maxY + pad,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                  getTooltipItems: (spots) => [
                    for (final s in spots)
                      LineTooltipItem(
                        '${series[s.barIndex].$1} ${s.y.toStringAsFixed(1)} kg',
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
                for (final (_, color, spots) in series)
                  LineChartBarData(
                    spots: spots,
                    color: color,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 3.5,
                        color: palette.surface,
                        strokeWidth: 2.5,
                        strokeColor: color,
                      ),
                    ),
                  ),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    // 不另外標最上 / 最下的值，否則會和整數刻度疊在一起
                    minIncluded: false,
                    maxIncluded: false,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(0),
                      style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      // 每天都會問一次，只在有量測的日子標日期
                      final match = entries.where((b) => x(b) == value);
                      if (match.isEmpty) return const SizedBox.shrink();
                      final d = match.first.day;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('${d.month}/${d.day}',
                            style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant)),
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
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          children: [
            for (final (label, color, _) in series)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text('$label（kg）', style: theme.textTheme.bodySmall),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// 一個大數字配一行說明（訓練、飲食卡片共用）。
Widget _figure(BuildContext context, String label, String value,
    {String? note}) {
  final theme = Theme.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 2),
      Text(value,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800)),
      if (note != null)
        Text(note,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    ],
  );
}

class _TrainingSection extends StatelessWidget {
  final TrainingSummary training;
  final List<Exercise> exercises;

  /// 第一筆運動紀錄比期間開頭晚時，從那天起算（副標題會寫出來）。
  final DateTime? countedFrom;
  const _TrainingSection({
    required this.training,
    required this.exercises,
    this.countedFrom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.palette;
    final t = training;
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5);
    final names = {for (final e in exercises) e.id: e};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: Icons.fitness_center,
          title: '訓練',
          subtitle: switch (countedFrom) {
            final d? => '從第一筆運動紀錄（${d.month}/${d.day}）起算，共 ${t.weeks} 週',
            null => '這段期間共 ${t.weeks} 週',
          },
          color: palette.dinner,
        ),
        SoftCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: t.sessions == 0
              ? Text('這段期間沒有運動紀錄。到「運動」分頁記錄後，這裡會整理每週頻率和器材重量的變化。',
                  style: muted)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _figure(context, '平均每週',
                              '${t.sessionsPerWeek.toStringAsFixed(1)} 次'),
                        ),
                        Expanded(
                          child:
                              _figure(context, '總時間', formatMinutes(t.total)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [
                        for (final k in ActivityKind.values)
                          if ((t.counts[k] ?? 0) > 0)
                            '${k.label} 每週 ${t.perWeek(k).toStringAsFixed(1)} 次',
                      ].join(' ・ '),
                      style: muted,
                    ),
                    if (t.perWeek(ActivityKind.strength) <
                        kStrengthDaysPerWeek) ...[
                      const SizedBox(height: 10),
                      InfoNote(
                        color: palette.dinner,
                        text: '肌力訓練平均每週不到 $kStrengthDaysPerWeek 次。'
                            'WHO 建議成人每週至少 $kStrengthDaysPerWeek 天做肌力訓練，減脂時也比較能保住肌肉。',
                      ),
                    ],
                    if (t.progress.isNotEmpty) ...[
                      const Divider(height: 28),
                      Text('器材重量（這段期間第一次 → 最近一次）',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      for (final p in t.progress)
                        _progressRow(context, p, names[p.exerciseId]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _progressRow(
      BuildContext context, ExerciseProgress p, Exercise? exercise) {
    final theme = Theme.of(context);
    final palette = theme.palette;
    final unit = exercise?.unit.label ?? '';
    String fmt(double v) =>
        v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
    final a = p.first.set.weight;
    final b = p.last.set.weight;
    final d = p.weightDelta;
    final String range;
    if (p.records == 1) {
      range = b == null ? '只有一次紀錄' : '${fmt(b)} $unit（只有一次紀錄）';
    } else {
      range = a == null || b == null ? '—' : '${fmt(a)} → ${fmt(b)} $unit';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(exercise?.name ?? '（已刪除的器材）',
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(range,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          if (p.records > 1 && d != null) ...[
            const SizedBox(width: 8),
            PillLabel(
              text: d.abs() < 0.05 ? '持平' : '${d > 0 ? '+' : '−'}${fmt(d.abs())}',
              color: d.abs() < 0.05
                  ? palette.uncategorized
                  : (d > 0 ? palette.success : palette.warning),
            ),
          ],
        ],
      ),
    );
  }
}

class _DietSection extends StatelessWidget {
  final DietSummary diet;
  final NutritionPlan plan;
  final double weightKg;

  /// 第一筆餐點紀錄比期間開頭晚時，從那天起算（副標題會寫出來）。
  final DateTime? countedFrom;
  const _DietSection({
    required this.diet,
    required this.plan,
    required this.weightKg,
    this.countedFrom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.palette;
    final d = diet;
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5);
    final perKg = d.avgProtein / weightKg;
    final enough = perKg >= kRecompProteinGPerKg;
    final article =
        educationArticles.where((a) => a.id == 'diet-protein').firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: Icons.restaurant_outlined,
          title: '飲食',
          subtitle: !d.hasData
              ? null
              : '有記錄的 ${d.loggedDays}／${d.totalDays} 天'
                  '${countedFrom == null ? '' : '（從第一筆餐點紀錄 ${countedFrom!.month}/${countedFrom!.day} 起算）'}',
          color: palette.breakfast,
        ),
        SoftCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: !d.hasData
              ? Text('這段期間沒有餐點紀錄。', style: muted)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _figure(context, '平均每日熱量',
                              '${d.avgCalories.round()} 大卡',
                              note: '目標 ${plan.calorieTarget.round()}'),
                        ),
                        Expanded(
                          child: _figure(context, '平均每日蛋白質',
                              '${d.avgProtein.round()} g',
                              note: '目標 ${plan.macros.proteinG.round()} g'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InfoNote(
                      text: '蛋白質約每公斤體重 ${perKg.toStringAsFixed(1)} 克'
                          '（搭配肌力訓練建議 ${kRecompProteinGPerKg.toStringAsFixed(1)} 克以上）',
                      color: enough ? palette.success : palette.warning,
                      icon: enough
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                    ),
                    if (d.proteinByMeal.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text('各餐蛋白質（平均每天）', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final type in [...MealType.values, null])
                            if (d.proteinByMeal[type] case final g?)
                              PillLabel(
                                text: '${mealTypeLabel(type)} ${g.round()} g',
                                color: palette.mealColor(type),
                                icon: mealTypeIcon(type),
                              ),
                        ],
                      ),
                    ],
                    if (d.coverage < 0.5) ...[
                      const SizedBox(height: 12),
                      InfoNote(
                        color: palette.warning,
                        icon: Icons.warning_amber_rounded,
                        text: '記錄天數不到一半，平均值的參考性有限：只算有記錄的日子，'
                            '但常漏記的那幾餐還是可能讓數字偏低。',
                      ),
                    ],
                    if (article != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () =>
                              Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ArticleDetailScreen(article: article),
                          )),
                          icon: const Icon(Icons.menu_book_outlined, size: 18),
                          label: Text('看衛教：${article.title}'),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
