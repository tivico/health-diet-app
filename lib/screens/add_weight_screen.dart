import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// 記錄今天的體重（一天一筆；同日再記會覆寫）。
class AddWeightScreen extends ConsumerStatefulWidget {
  const AddWeightScreen({super.key});

  @override
  ConsumerState<AddWeightScreen> createState() => _AddWeightScreenState();
}

class _AddWeightScreenState extends ConsumerState<AddWeightScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weight = TextEditingController();
  final _bodyFat = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _weight.dispose();
    _bodyFat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final bf = _bodyFat.text.trim();
      await ref.read(repositoryProvider).upsertWeight(
            day: DateTime.now(),
            weightKg: double.parse(_weight.text.trim()),
            bodyFatPct: bf.isEmpty ? null : double.parse(bf),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('儲存失敗：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('記錄體重')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('記錄今天的體重（一天一筆，同日會更新）。'),
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
