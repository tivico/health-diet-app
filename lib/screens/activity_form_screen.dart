import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/activity.dart';
import '../providers.dart';
import '../widgets/activity_visuals.dart';
import '../widgets/common.dart';
import 'exercise_library_screen.dart';

/// 記錄（或修改）一次運動。照手錶上的數字填，報告上有的再填就好（只有時長必填）。
///
/// 肌力訓練另外列出每台器材的「重量 × 每組次數 × 組數」，可以一鍵複製上次。
class ActivityFormScreen extends ConsumerStatefulWidget {
  const ActivityFormScreen({super.key, this.initial});

  /// 要修改的那筆；null 代表新增。
  final Activity? initial;

  @override
  ConsumerState<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

/// 肌力訓練裡的一列動作（畫面上的輸入狀態）。
class _SetRow {
  _SetRow({this.exerciseId, ExerciseSet? from})
      : weight = TextEditingController(text: _num(from?.weight)),
        reps = TextEditingController(text: from?.reps?.toString() ?? ''),
        sets = TextEditingController(text: from?.sets?.toString() ?? '');

  final key = UniqueKey();
  int? exerciseId;
  final TextEditingController weight;
  final TextEditingController reps;
  final TextEditingController sets;

  void dispose() {
    weight.dispose();
    reps.dispose();
    sets.dispose();
  }
}

/// 帶入原本的數字：整數不顯示小數點，其他保留原始精度。
String _num(double? v) {
  if (v == null) return '';
  return v == v.roundToDouble() ? v.round().toString() : v.toString();
}

class _ActivityFormScreenState extends ConsumerState<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ActivityKind _kind;
  late DateTime _date;
  late TimeOfDay _time;
  late final TextEditingController _title;
  late final TextEditingController _duration;
  late final TextEditingController _distance;
  late final TextEditingController _calories;
  late final TextEditingController _activeCalories;
  late final TextEditingController _avgHr;
  late final TextEditingController _maxHr;
  late final TextEditingController _feeling;
  late final List<TextEditingController> _zones;
  final List<_SetRow> _rows = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    final start = a?.startedAt ?? DateTime.now();
    _kind = a?.kind ?? ActivityKind.cardio;
    _date = DateTime(start.year, start.month, start.day);
    _time = TimeOfDay(hour: start.hour, minute: start.minute);
    _title = TextEditingController(text: a?.title ?? '');
    _duration =
        TextEditingController(text: a == null ? '' : formatClock(a.duration));
    _distance = TextEditingController(text: _num(a?.distanceKm));
    _calories = TextEditingController(text: _num(a?.calories));
    _activeCalories = TextEditingController(text: _num(a?.activeCalories));
    _avgHr = TextEditingController(text: a?.avgHr?.toString() ?? '');
    _maxHr = TextEditingController(text: a?.maxHr?.toString() ?? '');
    _feeling = TextEditingController(text: a?.feeling ?? '');
    _zones = [
      for (final z in a?.zones ?? Activity.noZones)
        TextEditingController(text: z == null ? '' : formatClock(z)),
    ];
    for (final s in a?.sets ?? const <ExerciseSet>[]) {
      _rows.add(_SetRow(exerciseId: s.exerciseId, from: s));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _duration,
      _distance,
      _calories,
      _activeCalories,
      _avgHr,
      _maxHr,
      _feeling,
      ..._zones,
    ]) {
      c.dispose();
    }
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  // ---- 驗證 ----

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  String? _number(String? raw, double min, double max, {bool whole = false}) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) return null;
    final n = whole ? int.tryParse(t)?.toDouble() : double.tryParse(t);
    if (n == null) return whole ? '請輸入整數' : '請輸入數字';
    if (n < min || n > max) return '需介於 ${_fmt(min)}–${_fmt(max)}';
    return null;
  }

  String? _validateDuration(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) return '請輸入時長';
    final d = parseClock(t);
    if (d == null) return '格式像 31:49 或 1:00:53';
    if (d == Duration.zero) return '時長要大於 0';
    if (d > const Duration(hours: 24)) return '不會超過 24 小時';
    return null;
  }

  String? _validateZone(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) return null;
    final z = parseClock(t);
    if (z == null) return '格式像 21:06';
    final total = parseClock(_duration.text);
    if (total != null && z > total) return '不會超過總時長';
    return null;
  }

  String? _validateActiveCalories(String? raw) {
    final basic = _number(raw, 0, 5000);
    if (basic != null) return basic;
    final active = double.tryParse(raw?.trim() ?? '');
    final total = double.tryParse(_calories.text.trim());
    if (active != null && total != null && active > total) return '不會超過總熱量';
    return null;
  }

  String? _validateMaxHr(String? raw) {
    final basic = _number(raw, 30, 250, whole: true);
    if (basic != null) return basic;
    final max = int.tryParse(raw?.trim() ?? '');
    final avg = int.tryParse(_avgHr.text.trim());
    if (max != null && avg != null && max < avg) return '不會低於平均心率';
    return null;
  }

  static String? _textOrNull(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  // ---- 操作 ----

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: today.subtract(const Duration(days: 3650)),
      lastDate: today, // 不能記未來
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  /// 選器材：從清單挑，或當場新增一台。
  Future<void> _pickExercise(_SetRow row, List<Exercise> exercises) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final e in exercises)
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(e.name),
                subtitle: Text('單位 ${e.unit.label}'),
                selected: e.id == row.exerciseId,
                onTap: () => Navigator.pop(ctx, e.id),
              ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('新增器材…'),
              onTap: () => Navigator.pop(ctx, -1),
            ),
          ],
        ),
      ),
    );
    if (!mounted || picked == null) return;
    final id = picked == -1 ? await showExerciseDialog(context) : picked;
    if (id != null && mounted) setState(() => row.exerciseId = id);
  }

  void _copyFrom(Activity last) {
    setState(() {
      for (final r in _rows) {
        r.dispose();
      }
      _rows
        ..clear()
        ..addAll([
          for (final s in last.sets) _SetRow(exerciseId: s.exerciseId, from: s),
        ]);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    double? real(TextEditingController c) => double.tryParse(c.text.trim());
    int? whole(TextEditingController c) => int.tryParse(c.text.trim());

    final activity = Activity(
      id: widget.initial?.id,
      startedAt: DateTime(
          _date.year, _date.month, _date.day, _time.hour, _time.minute),
      kind: _kind,
      title: _textOrNull(_title.text),
      duration: parseClock(_duration.text)!,
      distanceKm: _kind == ActivityKind.strength ? null : real(_distance),
      calories: real(_calories),
      activeCalories: real(_activeCalories),
      avgHr: whole(_avgHr),
      maxHr: whole(_maxHr),
      zones: [for (final z in _zones) parseClock(z.text)],
      feeling: _textOrNull(_feeling.text),
      garminActivityId: widget.initial?.garminActivityId,
      sets: _kind != ActivityKind.strength
          ? const []
          : [
              for (final r in _rows)
                if (r.exerciseId != null)
                  ExerciseSet(
                    exerciseId: r.exerciseId!,
                    weight: real(r.weight),
                    reps: whole(r.reps),
                    sets: whole(r.sets),
                  ),
            ],
    );

    setState(() => _saving = true);
    try {
      await ref.read(repositoryProvider).saveActivity(activity);
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('儲存失敗：$e')));
    }
  }

  // ---- 畫面 ----

  @override
  Widget build(BuildContext context) {
    final activities = ref.watch(activitiesProvider).value ?? const <Activity>[];
    final exercises = ref.watch(exercisesProvider).value ?? const <Exercise>[];
    final recent =
        widget.initial == null ? recentTitled(activities) : const <Activity>[];
    final last = lastStrengthSession(activities, excludeId: widget.initial?.id);
    final tint = activityKindColor(context, _kind);

    Widget pair(Widget a, Widget b) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            const SizedBox(width: 12),
            Expanded(child: b),
          ],
        );

    TextFormField numberField(
      TextEditingController c,
      String label, {
      String? suffix,
      String? Function(String?)? validator,
      Key? key,
    }) =>
        TextFormField(
          key: key,
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, suffixText: suffix),
          validator: validator,
        );

    return Scaffold(
      appBar: AppBar(title: Text(widget.initial == null ? '記錄運動' : '修改運動')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            SoftCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<ActivityKind>(
                    segments: [
                      for (final k in ActivityKind.values)
                        ButtonSegment(
                          value: k,
                          label: Text(k.label),
                          icon: Icon(activityKindIcon(k), size: 18),
                        ),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (s) => setState(() => _kind = s.first),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _title,
                    maxLength: 60,
                    decoration: const InputDecoration(
                      labelText: '名稱（選填）',
                      hintText: '例如 慢跑、重訓、游泳',
                      counterText: '',
                    ),
                  ),
                  if (recent.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final r in recent)
                          ActionChip(
                            avatar: Icon(activityKindIcon(r.kind), size: 16),
                            label: Text(r.title!),
                            onPressed: () => setState(() {
                              _title.text = r.title!;
                              _kind = r.kind;
                            }),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  pair(
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(shortDateWithWeekday(_date)),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule, size: 18),
                      label: Text(_time.format(context)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('activity-duration'),
                    controller: _duration,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: '時長',
                      hintText: '例如 31:49 或 1:00:53',
                    ),
                    validator: _validateDuration,
                  ),
                  const SizedBox(height: 14),
                  pair(
                    numberField(_calories, '總熱量',
                        suffix: '大卡',
                        key: const ValueKey('activity-calories'),
                        validator: (v) => _number(v, 0, 5000)),
                    numberField(_activeCalories, '動態熱量',
                        suffix: '大卡',
                        key: const ValueKey('activity-active-calories'),
                        validator: _validateActiveCalories),
                  ),
                  const SizedBox(height: 14),
                  pair(
                    numberField(_avgHr, '平均心率',
                        suffix: 'bpm',
                        key: const ValueKey('activity-avg-hr'),
                        validator: (v) => _number(v, 30, 250, whole: true)),
                    numberField(_maxHr, '最高心率',
                        suffix: 'bpm',
                        key: const ValueKey('activity-max-hr'),
                        validator: _validateMaxHr),
                  ),
                  if (_kind != ActivityKind.strength) ...[
                    const SizedBox(height: 14),
                    pair(
                      numberField(_distance, '距離（選填）',
                          suffix: '公里',
                          key: const ValueKey('activity-distance'),
                          validator: (v) => _number(v, 0, 500)),
                      const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
            if (_kind == ActivityKind.strength) ...[
              const SizedBox(height: 22),
              SectionHeader(
                icon: Icons.fitness_center,
                title: '動作',
                subtitle: '每台器材一列：重量 × 每組次數 × 組數',
                color: tint,
              ),
              SoftCard(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, row) in _rows.indexed) ...[
                      if (i > 0) const Divider(height: 24),
                      _setRow(row, exercises),
                    ],
                    if (_rows.isNotEmpty) const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        TextButton.icon(
                          onPressed: () => setState(() => _rows.add(_SetRow())),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('新增動作'),
                        ),
                        if (last != null)
                          TextButton.icon(
                            onPressed: () => _copyFrom(last),
                            icon: const Icon(Icons.content_copy, size: 18),
                            label: Text(
                                '複製上次（${last.startedAt.month}/${last.startedAt.day}）'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            SectionHeader(
              icon: Icons.favorite_outline,
              title: '心率區間（選填）',
              subtitle: '照手錶上每個區間的時間填，例如 21:06',
              color: tint,
            ),
            SoftCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                children: [
                  for (var i = 0; i < 5; i += 2) ...[
                    if (i > 0) const SizedBox(height: 14),
                    pair(
                      _zoneField(i),
                      i + 1 < 5 ? _zoneField(i + 1) : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            SectionHeader(
                icon: Icons.edit_note, title: '感受與備註（選填）', color: tint),
            SoftCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: TextFormField(
                controller: _feeling,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: '例如 跳得很開心、後段沒力、睡不好所以降強度',
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('儲存', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zoneField(int i) => TextFormField(
        key: ValueKey('activity-zone-${i + 1}'),
        controller: _zones[i],
        keyboardType: TextInputType.datetime,
        decoration: InputDecoration(labelText: 'Zone ${i + 1}'),
        validator: _validateZone,
      );

  /// 一列動作：器材（選單）＋重量 × 每組次數 × 組數。
  Widget _setRow(_SetRow row, List<Exercise> exercises) {
    final theme = Theme.of(context);
    final exercise = exercises.where((e) => e.id == row.exerciseId).firstOrNull;
    final index = _rows.indexOf(row);

    return Column(
      key: row.key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FormField<int>(
                key: ValueKey('set-${index + 1}-exercise'),
                validator: (_) => row.exerciseId == null ? '請選擇器材' : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pickExercise(row, exercises),
                      icon: const Icon(Icons.fitness_center, size: 18),
                      label: Text(
                        exercise?.name ?? '選擇器材',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 4),
                        child: Text(
                          field.errorText!,
                          style: TextStyle(
                              color: theme.colorScheme.error, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: '移除這個動作',
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _rows.remove(row);
                row.dispose();
              }),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey('set-${index + 1}-weight'),
                controller: row.weight,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: '重量', suffixText: exercise?.unit.label),
                validator: (v) => _number(v, 0, 1000),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                key: ValueKey('set-${index + 1}-reps'),
                controller: row.reps,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '每組次數'),
                validator: (v) => _number(v, 1, 1000, whole: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                key: ValueKey('set-${index + 1}-sets'),
                controller: row.sets,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '組數'),
                validator: (v) => _number(v, 1, 100, whole: true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
