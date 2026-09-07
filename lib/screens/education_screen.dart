import 'package:flutter/material.dart';

import '../data/education_content.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 衛教知識：依分類列出文章，點入看內文。內容皆為靜態資料、不需資料庫。
class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('衛教知識')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          for (final cat in ArticleCategory.values) ...[
            SectionHeader(
              icon: _categoryIcon(cat),
              title: categoryLabel(cat),
              color: _categoryColor(context, cat),
            ),
            for (final a in educationArticles.where((x) => x.category == cat))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ArticleCard(article: a),
              ),
            const SizedBox(height: 12),
          ],
          const FootNote('＊以上為一般衛教資訊，非醫療診斷；個別狀況請諮詢專業人員。'),
        ],
      ),
    );
  }
}

/// 文章卡片：左邊分類色圖示，右邊標題與摘要。
class _ArticleCard extends StatelessWidget {
  final Article article;
  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _categoryColor(context, article.category);

    return SoftCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(
            icon: _categoryIcon(article.category),
            color: color,
            size: 42,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(article.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  article.summary,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class ArticleDetailScreen extends StatelessWidget {
  final Article article;
  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _categoryColor(context, article.category);

    return Scaffold(
      appBar: AppBar(title: Text(article.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // 標題區塊用分類色的淡底，讓每篇文章有自己的個性
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconBadge(
                      icon: _categoryIcon(article.category),
                      color: color,
                      solid: true,
                      size: 34,
                    ),
                    const SizedBox(width: 10),
                    PillLabel(
                      text: categoryLabel(article.category),
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  article.title,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            padding: const EdgeInsets.all(18),
            // 用 SelectableText 讓使用者能複製內容（例如求助專線號碼）。
            child: SelectableText(
              article.body,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.75),
            ),
          ),
          const SizedBox(height: 20),
          const FootNote('＊本資訊為一般衛教，非醫療診斷。'),
        ],
      ),
    );
  }
}

IconData _categoryIcon(ArticleCategory c) => switch (c) {
      ArticleCategory.concept => Icons.lightbulb_outline,
      ArticleCategory.myth => Icons.psychology_outlined,
      ArticleCategory.diet => Icons.local_dining_outlined,
      ArticleCategory.safety => Icons.favorite_outline,
    };

Color _categoryColor(BuildContext context, ArticleCategory c) {
  final theme = Theme.of(context);
  return switch (c) {
    ArticleCategory.concept => theme.colorScheme.primary,
    ArticleCategory.myth => theme.palette.warning,
    ArticleCategory.diet => theme.palette.carbs,
    ArticleCategory.safety => theme.palette.protein,
  };
}
