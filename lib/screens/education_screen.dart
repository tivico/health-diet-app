import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
          const FootNote(
              '＊每篇文章末皆附資料來源（衛福部 / 國民健康署等官方指引，以及同儕審查文獻），'
              '可點開自行查證。\n'
              '以上為一般衛教資訊，非醫療診斷；個別狀況請諮詢專業人員。'),
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
                if (article.sources.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  // 讓清單上就看得出這篇有出處可查
                  Row(
                    children: [
                      Icon(Icons.library_books_outlined, size: 13, color: color),
                      const SizedBox(width: 4),
                      Text(
                        '${article.sources.length} 則資料來源',
                        style: theme.textTheme.labelSmall?.copyWith(color: color),
                      ),
                    ],
                  ),
                ],
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
          if (article.sources.isNotEmpty) ...[
            const SizedBox(height: 24),
            SectionHeader(
              icon: Icons.library_books_outlined,
              title: '資料來源',
              color: color,
              subtitle: '點一下可開啟原始出處自行查證',
            ),
            for (final s in article.sources)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SourceCard(source: s, color: color),
              ),
          ],
          const SizedBox(height: 20),
          const FootNote('＊本資訊為一般衛教，非醫療診斷。'),
        ],
      ),
    );
  }
}

/// 一則資料來源：名稱、它支持文中的哪個說法，以及可點開的網址。
class _SourceCard extends StatelessWidget {
  final ArticleSource source;
  final Color color;

  const _SourceCard({required this.source, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoftCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _open(context, source.url),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(source.title, style: theme.textTheme.titleSmall),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            source.note,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          // 先讓使用者看得到要去哪個網站，再決定要不要點
          Text(
            _host(source.url),
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  static String _host(String url) => Uri.tryParse(url)?.host ?? url;

  Future<void> _open(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    final ok = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text('無法開啟連結：$url')));
    }
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
