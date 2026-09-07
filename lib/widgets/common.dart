/// 各畫面共用的視覺元件：卡片、區塊標題、圖示徽章、統計格、進度條、空狀態。
///
/// 目的是讓「同一種東西長得一樣」——顏色、圓角與間距都集中在這裡調整，
/// 各畫面只描述內容，不各自刻樣式。
library;

import 'package:flutter/material.dart';

import '../theme.dart';

/// 圓角卡片：比 Material 的 Card 再軟一點（無邊框、淡陰影），
/// 也支援漸層背景與點擊。
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double radius;

  /// 是否加上淡陰影。放在有色背景上時關掉會比較乾淨。
  final bool shadow;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.gradient,
    this.onTap,
    this.radius = AppRadius.card,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? theme.palette.surface) : null,
        gradient: gradient,
        borderRadius: borderRadius,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: theme.palette.shadow,
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// 小圖示徽章：帶色底的圓角方塊，用來替清單項目與標題增加辨識度。
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  /// 實心（色底白圖）或淡底（淡色底、彩色圖）。
  final bool solid;

  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 38,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: solid ? color : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        icon,
        size: size * 0.52,
        color: solid ? Colors.white : color,
      ),
    );
  }
}

/// 區塊標題：左邊一個圖示徽章，右邊可放補充資訊或按鈕。
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.color,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          IconBadge(icon: icon, color: tint, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// 小標籤：用於「小計」「百分比」等次要資訊。
class PillLabel extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const PillLabel({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// 統計格：一個數字配一行說明，左上角有色圖示。
class StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String unit;

  const StatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, color: color, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 圓角進度條：軌道 + 漸層填色，超過 100% 會自動變成警示色。
class GradientBar extends StatelessWidget {
  final double value; // 0–1；超過 1 視為超標
  final Color color;
  final double height;

  const GradientBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 10,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final over = value > 1.0;
    final shown = value.clamp(0.0, 1.0);
    final fill = over ? theme.colorScheme.error : color;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(
            height: height,
            color: color.withValues(alpha: 0.16),
          ),
          FractionallySizedBox(
            widthFactor: shown == 0 ? 0.0001 : shown,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [fill.withValues(alpha: 0.75), fill],
                ),
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 空狀態：一個柔和的圓形圖示配一段說明，比單純一行灰字友善。
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color? color;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.primary;

    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 30, color: tint),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// 提醒橫幅：淡色底 + 圖示，用在安全提醒、免責說明等。
class InfoNote extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const InfoNote({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// 頁尾的免責 / 補充說明（各畫面重複出現，抽成同一個樣式）。
class FootNote extends StatelessWidget {
  final String text;
  const FootNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          height: 1.5,
        ),
      ),
    );
  }
}
