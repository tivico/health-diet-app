import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/nutrition.dart';
import '../labels.dart';
import '../providers.dart';
import 'advice_screen.dart';

/// 引導設定 / 編輯資料：輸入基本資料 → 存進本地資料庫。
///
/// - 首次（[initial] 為 null）：存檔後跳出客製化健康建議，再由 HomeGate 顯示主畫面。
/// - 編輯（帶入 [initial]）：被 push 上來，存檔後返回上一頁。
class OnboardingScreen extends ConsumerStatefulWidget {
  final UserProfile? initial;
  const OnboardingScreen({super.key, this.initial});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  late Sex _sex;
  late Goal _goal;
  late ActivityLevel _activity;
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _bodyFat;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _sex = p?.sex ?? Sex.female;
    _goal = p?.goal ?? Goal.lose;
    _activity = p?.activity ?? ActivityLevel.light;
    _age = TextEditingController(text: p?.age.toString() ?? '28');
    _height = TextEditingController(text: p?.heightCm.toStringAsFixed(0) ?? '165');
    _weight = TextEditingController(text: p?.weightKg.toStringAsFixed(0) ?? '65');
    _bodyFat =
        TextEditingController(text: p?.bodyFatPct?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _bodyFat.dispose();
    super.dispose();
  }

  String? _validateNumber(
    String? v, {
    required String label,
    required double min,
    required double max,
    bool required = true,
  }) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) {
      return required ? '請輸入$label' : null;
    }
    final n = double.tryParse(text);
    if (n == null) return '$label需為數字';
    if (n < min || n > max) return '$label需介於 ${min.toInt()}–${max.toInt()}';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final bodyFatText = _bodyFat.text.trim();
    final profile = UserProfile(
      sex: _sex,
      age: int.parse(_age.text.trim()),
      heightCm: double.parse(_height.text.trim()),
      weightKg: double.parse(_weight.text.trim()),
      activity: _activity,
      goal: _goal,
      bodyFatPct: bodyFatText.isEmpty ? null : double.parse(bodyFatText),
    );

    // 先抓好 navigator / messenger，避免 await 後再用 context。
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(repositoryProvider).saveProfile(profile);
      if (widget.initial == null) {
        // 首次建立 → 顯示客製化健康建議（背後 HomeGate 已切到主畫面）。
        navigator.push(
          MaterialPageRoute(builder: (_) => AdviceScreen(profile: profile)),
        );
      } else if (navigator.canPop()) {
        navigator.pop(); // 編輯模式 → 返回
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('儲存失敗：$e')));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? '編輯個人資料' : '建立你的個人資料')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '告訴我們一些基本資料，計算你的每日熱量與營養目標。',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            _label('性別'),
            SegmentedButton<Sex>(
              segments: const [
                ButtonSegment(value: Sex.female, label: Text('女')),
                ButtonSegment(value: Sex.male, label: Text('男')),
              ],
              selected: {_sex},
              onSelectionChanged: (s) => setState(() => _sex = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '年齡',
                suffixText: '歲',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  _validateNumber(v, label: '年齡', min: 1, max: 120),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _height,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '身高',
                suffixText: 'cm',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  _validateNumber(v, label: '身高', min: 50, max: 250),
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
              validator: (v) =>
                  _validateNumber(v, label: '體重', min: 20, max: 400),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyFat,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '體脂率（選填）',
                suffixText: '%',
                helperText: '有填的話會用更準的公式計算',
                border: OutlineInputBorder(),
              ),
              validator: (v) => _validateNumber(v,
                  label: '體脂率', min: 1, max: 74, required: false),
            ),
            const SizedBox(height: 16),
            _label('活動量'),
            DropdownButtonFormField<ActivityLevel>(
              initialValue: _activity,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: ActivityLevel.values
                  .map((a) =>
                      DropdownMenuItem(value: a, child: Text(activityLabel(a))))
                  .toList(),
              onChanged: (a) => setState(() => _activity = a ?? _activity),
            ),
            const SizedBox(height: 16),
            _label('目標'),
            SegmentedButton<Goal>(
              segments: const [
                ButtonSegment(value: Goal.lose, label: Text('減脂')),
                ButtonSegment(value: Goal.maintain, label: Text('維持')),
                ButtonSegment(value: Goal.gain, label: Text('增肌')),
              ],
              selected: {_goal},
              onSelectionChanged: (s) => setState(() => _goal = s.first),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? '儲存' : '計算我的每日目標',
                      style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
}
