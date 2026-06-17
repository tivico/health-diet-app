import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// 手動新增一筆餐點：名稱 + 熱量（必填），三大營養素（選填）。
class AddMealScreen extends ConsumerStatefulWidget {
  const AddMealScreen({super.key});

  @override
  ConsumerState<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends ConsumerState<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _fat = TextEditingController();
  final _carbs = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _calories.dispose();
    _protein.dispose();
    _fat.dispose();
    _carbs.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(repositoryProvider).addMeal(
            eatenAt: DateTime.now(),
            name: _name.text.trim(),
            calories: _num(_calories),
            proteinG: _num(_protein),
            fatG: _num(_fat),
            carbsG: _num(_carbs),
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
      appBar: AppBar(title: const Text('新增餐點')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: '餐點名稱',
                hintText: '例如：雞腿便當',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '請輸入餐點名稱' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _calories,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '熱量',
                suffixText: '大卡',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return '請輸入熱量';
                final n = double.tryParse(t);
                if (n == null || n < 0) return '熱量需為非負數字';
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text('三大營養素（選填，公克）',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _macroField(_protein, '蛋白質')),
                const SizedBox(width: 8),
                Expanded(child: _macroField(_fat, '脂肪')),
                const SizedBox(width: 8),
                Expanded(child: _macroField(_carbs, '碳水')),
              ],
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

  Widget _macroField(TextEditingController c, String label) => TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration:
            InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (v) {
          final t = v?.trim() ?? '';
          if (t.isEmpty) return null; // 選填
          final n = double.tryParse(t);
          if (n == null || n < 0) return '需為非負';
          return null;
        },
      );
}
