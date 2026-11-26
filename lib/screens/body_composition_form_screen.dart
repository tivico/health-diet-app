import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/body_composition.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 記錄（或修改）一次體組成量測：一天一筆，同日再記會覆寫。
///
/// 除了體重都是選填——體脂計 / InBody 報告上有的再填就好。
class BodyCompositionFormScreen extends ConsumerStatefulWidget {
  const BodyCompositionFormScreen({super.key, this.initial, this.defaultSource});

  /// 要修改的那筆；null 代表新增。
  final BodyComposition? initial;

  /// 新增時預填的量測工具（沿用上一筆，例如「InBody」）。
  final String? defaultSource;

  @override
  ConsumerState<BodyCompositionFormScreen> createState() =>
      _BodyCompositionFormScreenState();
}

class _BodyCompositionFormScreenState
    extends ConsumerState<BodyCompositionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<BodyMetric, TextEditingController> _fields = {
    for (final m in BodyMetric.values)
      m: TextEditingController(text: _initialText(m)),
  };
  late final _source = TextEditingController(
      text: widget.initial?.source ?? widget.defaultSource ?? '');
  late final _note = TextEditingController(text: widget.initial?.note ?? '');
  late DateTime _day;
  bool _alsoWeight = true;
  bool _saving = false;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _day = widget.initial?.day ?? _dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    _source.dispose();
    _note.dispose();
    super.dispose();
  }

  /// 修改時帶入原本的數字；保留原始精度（71.65 不會變成 71.7）。
  String _initialText(BodyMetric m) {
    final v = widget.initial?.valueOf(m);
    if (v == null) return '';
    return v == v.roundToDouble() ? v.round().toString() : v.toString();
  }

  bool get _isToday => _day == _dateOnly(DateTime.now());

  Future<void> _pickDate() async {
    final today = _dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: today.subtract(const Duration(days: 3650)), // 舊報告也能補記
      lastDate: today, // 不能記未來
    );
    if (picked != null) setState(() => _day = _dateOnly(picked));
  }

  String? _validate(BodyMetric m, String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) return m == BodyMetric.weight ? '請輸入體重' : null;
    final n = double.tryParse(t);
    if (n == null) return '請輸入數字';
    if (n < m.min || n > m.max) {
      return '需介於 ${formatBodyValue(m.min)}–${formatBodyValue(m.max)}';
    }
    if (m.partOfWeight) {
      final weight = double.tryParse(_fields[BodyMetric.weight]!.text.trim());
      if (weight != null && n >= weight) return '不會超過體重';
    }
    return null;
  }

  static String? _textOrNull(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(repositoryProvider);
    final entry = BodyComposition(
      day: _day,
      values: {
        for (final MapEntry(key: m, value: c) in _fields.entries)
          if (double.tryParse(c.text.trim()) case final double v) m: v,
      },
      source: _textOrNull(_source.text),
      note: _textOrNull(_note.text),
    );

    setState(() => _saving = true);
    try {
      await repo.upsertBodyComposition(entry);
      // 修改時改了日期：新的那天已經寫好，把原本那天的拿掉
      final original = widget.initial;
      if (original != null && original.day != entry.day) {
        await repo.deleteBodyComposition(original.day);
      }
      if (_alsoWeight) {
        await repo.upsertWeight(
          day: entry.day,
          weightKg: entry.weightKg,
          bodyFatPct: entry.valueOf(BodyMetric.bodyFat),
        );
      }
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('儲存失敗：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = theme.palette.protein;
    List<BodyMetric> group(MetricGroup g) =>
        [for (final m in BodyMetric.values) if (m.group == g) m];

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.initial == null ? '記錄體組成' : '修改體組成')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            InfoNote(
              icon: Icons.lightbulb_outline,
              color: tint,
              text: '照體脂計或 InBody 報告填寫，報告上有的再填就好（只有體重必填）。\n'
                  '一天一筆，同一天再記會覆寫。',
            ),
            const SizedBox(height: 20),
            SoftCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('量測日期', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(
                        '${_day.year}/${_day.month}/${_day.day}${_isToday ? '（今天）' : ''}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _fieldGrid(group(MetricGroup.main)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SectionHeader(
                icon: Icons.analytics_outlined,
                title: '其他指標（選填）',
                color: tint),
            SoftCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: _fieldGrid(group(MetricGroup.other)),
            ),
            const SizedBox(height: 22),
            SectionHeader(
              icon: Icons.straighten,
              title: '圍度（選填）',
              subtitle: '捲尺量的，或報告上有的',
              color: tint,
            ),
            SoftCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: _fieldGrid(group(MetricGroup.circumference)),
            ),
            const SizedBox(height: 22),
            SectionHeader(
                icon: Icons.edit_note, title: '來源與備註（選填）', color: tint),
            SoftCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                children: [
                  TextFormField(
                    controller: _source,
                    maxLength: 40,
                    decoration: const InputDecoration(
                      labelText: '量測工具',
                      hintText: '例如 InBody、體脂計的 App 名稱',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _note,
                    maxLength: 200,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: '量測條件',
                      hintText: '例如 早上空腹、生理期第 2 天',
                      helperText: '之後比較時，才知道兩次的條件是否相近',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _alsoWeight,
              onChanged: (v) => setState(() => _alsoWeight = v),
              title: const Text('同時記到體重紀錄'),
              subtitle: const Text('體重趨勢圖和目標進度會用到；同一天原本的體重會被覆寫'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            const SizedBox(height: 16),
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

  /// 兩欄一列的數字欄位，手機上不會拉得太長。
  Widget _fieldGrid(List<BodyMetric> metrics) {
    Widget field(BodyMetric m) => TextFormField(
          key: ValueKey('body-${m.name}'),
          controller: _fields[m],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: m.label,
            suffixText: m.unit.isEmpty ? null : m.unit,
          ),
          validator: (v) => _validate(m, v),
        );

    return Column(
      children: [
        for (var i = 0; i < metrics.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: field(metrics[i])),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < metrics.length
                    ? field(metrics[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
