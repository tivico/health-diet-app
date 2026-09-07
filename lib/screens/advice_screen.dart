import 'package:flutter/material.dart';

import '../domain/nutrition.dart';
import '../domain/recommendations.dart';
import '../labels.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'calculation_screen.dart';

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
    final palette = theme.palette;

    final bf = profile.bodyFatPct;
    final who =
        '${sexLabel(profile.sex)}・${profile.age} 歲・${profile.heightCm.toInt()} cm・'
        '${profile.weightKg.toInt()} kg${bf != null ? '・體脂 ${bf.toInt()}%' : ''}';

    return Scaffold(
      appBar: AppBar(title: const Text('你的健康建議')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          // 一眼看到「這是為你算的」——資料摘要 + 每日熱量目標
          SoftCard(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            shadow: false,
            gradient: LinearGradient(
              colors: palette.heroGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '依你的資料（$who）為你整理：',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${plan.calorieTarget.round()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '大卡 / 天',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 用 Wrap：窄螢幕上三個標籤放不下時會自動換行，不會擠爆
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _macroChip('蛋白 ${plan.macros.proteinG.round()}g'),
                    _macroChip('脂肪 ${plan.macros.fatG.round()}g'),
                    _macroChip('碳水 ${plan.macros.carbsG.round()}g'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final s in sections) ...[
            _AdviceCard(section: s),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => CalculationScreen(profile: profile)),
              ),
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: const Text('查看背後的計算公式'),
            ),
          ),
          const SizedBox(height: 16),
          const FootNote('＊以上為一般性建議，非醫療處方；有特殊健康狀況請諮詢專業。'),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('開始使用', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _macroChip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

/// 一則建議：彩色圖示 + 標題 + 一句重點 + 條列做法。
class _AdviceCard extends StatelessWidget {
  final AdviceSection section;
  const _AdviceCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = _styleFor(context, section.title);

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, color: color, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text(section.title, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            section.headline,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          for (final pt in section.points)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      pt,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 依建議標題挑圖示與顏色；認不得的標題用中性的勾勾。
  (IconData, Color) _styleFor(BuildContext context, String title) {
    final theme = Theme.of(context);
    final palette = theme.palette;
    return switch (title) {
      '你的重點' => (Icons.stars_outlined, theme.colorScheme.primary),
      '怎麼吃' => (Icons.restaurant_menu, palette.breakfast),
      '怎麼動' => (Icons.directions_run, palette.success),
      '喝水' => (Icons.water_drop_outlined, palette.carbs),
      '睡覺' => (Icons.bedtime_outlined, palette.dinner),
      _ => (Icons.check_circle_outline, theme.colorScheme.primary),
    };
  }
}
