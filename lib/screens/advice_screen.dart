import 'package:flutter/material.dart';

import '../domain/nutrition.dart';
import '../domain/recommendations.dart';
import '../labels.dart';

/// 客製化健康建議頁：依個人資料給出「怎麼吃 / 動 / 喝水 / 睡」等行動建議。
/// 首次建立資料後會自動顯示；也可從儀表板隨時再看。
class AdviceScreen extends StatelessWidget {
  final UserProfile profile;
  const AdviceScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final plan = nutritionPlan(profile);
    final sections = buildAdvice(profile, plan);
    final theme = Theme.of(context);

    final bf = profile.bodyFatPct;
    final who =
        '${sexLabel(profile.sex)}・${profile.age} 歲・${profile.heightCm.toInt()} cm・'
        '${profile.weightKg.toInt()} kg${bf != null ? '・體脂 ${bf.toInt()}%' : ''}';

    return Scaffold(
      appBar: AppBar(title: const Text('你的健康建議')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('依你的資料（$who）為你整理：', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          for (final s in sections)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(s.headline,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: theme.colorScheme.primary)),
                    const SizedBox(height: 8),
                    for (final pt in s.points)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('・'),
                            Expanded(child: Text(pt)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            '＊以上為一般性建議，非醫療處方；有特殊健康狀況請諮詢專業。',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('開始使用', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
