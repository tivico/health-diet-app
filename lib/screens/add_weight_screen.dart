import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// 記錄體重：可選擇日期（能補記過去），一天一筆、同日再記會覆寫。
class AddWeightScreen extends ConsumerStatefulWidget {
  const AddWeightScreen({super.key});

  @override
  ConsumerState<AddWeightScreen> createState() => _AddWeightScreenState();
}

class _AddWeightScreenState extends ConsumerState<AddWeightScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weight = TextEditingController();
  final _bodyFat = TextEditingController();
  late DateTime _day;
  bool _saving = false;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _day = _dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _weight.dispose();
    _bodyFat.dispose();
    super.dispose();
  }

  bool get _isToday => _day == _dateOnly(DateTime.now());

  Future<void> _pickDate() async {
    final today = _dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: today.subtract(const Duration(days: 730)), // 可補記兩年內
      lastDate: today, // 不能記未來
    );
    if (picked != null) {
      setState(() => _day = _dateOnly(picked));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final bf = _bodyFat.text.trim();
      await ref.read(repositoryProvider).upsertWeight(
            day: _day,
            weightKg: double.parse(_weight.text.trim()),
            bodyFatPct: bf.isEmpty ? null : double.parse(bf),
          );
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
    return Scaffold(
      appBar: AppBar(title: const Text('記錄體重')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('選擇日期並填入體重（一天一筆，同日會覆寫）。'),
            const SizedBox(height: 4),
            Text(
              '想補記前幾天的體重也可以，趨勢圖才看得出變化。',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                '${_day.year}/${_day.month}/${_day.day}${_isToday ? '（今天）' : ''}',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weight,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '體重',
                suffixText: 'kg',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return '請輸入體重';
                final n = double.tryParse(t);
                if (n == null || n < 20 || n > 400) return '體重需介於 20–400';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyFat,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '體脂率（選填）',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return null;
                final n = double.tryParse(t);
                if (n == null || n <= 0 || n >= 75) return '體脂率需介於 0–75';
                return null;
              },
            ),
            const SizedBox(height: 28),
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
}
