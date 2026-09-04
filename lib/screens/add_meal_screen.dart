import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/food_library.dart';
import '../providers.dart';
import 'food_picker_screen.dart';

/// 新增或編輯一筆餐點：名稱 + 熱量（必填），三大營養素（選填）。
/// 帶入 [initial] 時為編輯模式（更新該筆），否則為新增模式。
/// 也可從「食物庫」挑選常見食物自動帶入欄位。
class AddMealScreen extends ConsumerStatefulWidget {
  final MealEntry? initial;
  const AddMealScreen({super.key, this.initial});

  @override
  ConsumerState<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends ConsumerState<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _calories;
  late final TextEditingController _protein;
  late final TextEditingController _fat;
  late final TextEditingController _carbs;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    _name = TextEditingController(text: m?.name ?? '');
    _calories = TextEditingController(text: _numText(m?.calories));
    _protein = TextEditingController(text: _numText(m?.proteinG));
    _fat = TextEditingController(text: _numText(m?.fatG));
    _carbs = TextEditingController(text: _numText(m?.carbsG));
  }

  String _numText(double? v) =>
      (v == null || v == 0) ? '' : v.toInt().toString();

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

  /// 從食物庫挑一個常見食物，自動帶入各欄位（仍可自行修改）。
  Future<void> _pickFromLibrary() async {
    final picked = await Navigator.of(context).push<FoodItem>(
      MaterialPageRoute(builder: (_) => const FoodPickerScreen()),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _name.text = picked.name;
      _calories.text = picked.calories.round().toString();
      _protein.text = picked.proteinG.round().toString();
      _fat.text = picked.fatG.round().toString();
      _carbs.text = picked.carbsG.round().toString();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(repositoryProvider);
      final initial = widget.initial;
      if (initial == null) {
        await repo.addMeal(
          eatenAt: DateTime.now(),
          name: _name.text.trim(),
          calories: _num(_calories),
          proteinG: _num(_protein),
          fatG: _num(_fat),
          carbsG: _num(_carbs),
        );
      } else {
        await repo.updateMeal(
          id: initial.id,
          eatenAt: initial.eatenAt, // 編輯不改時間
          name: _name.text.trim(),
          calories: _num(_calories),
          proteinG: _num(_protein),
          fatG: _num(_fat),
          carbsG: _num(_carbs),
        );
      }
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
    final isEditing = widget.initial != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? '編輯餐點' : '新增餐點')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OutlinedButton.icon(
              onPressed: _pickFromLibrary,
              icon: const Icon(Icons.search),
              label: const Text('從食物庫挑選'),
            ),
            const SizedBox(height: 16),
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
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        validator: (v) {
          final t = v?.trim() ?? '';
          if (t.isEmpty) return null; // 選填
          final n = double.tryParse(t);
          if (n == null || n < 0) return '需為非負';
          return null;
        },
      );
}
