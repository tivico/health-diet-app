import 'package:flutter/material.dart';

import '../data/education_content.dart';

/// 衛教知識：依分類列出文章，點入看內文。內容皆為靜態資料、不需資料庫。
class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('衛教知識')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (final cat in ArticleCategory.values) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Text(categoryLabel(cat), style: theme.textTheme.titleMedium),
            ),
            for (final a in educationArticles.where((x) => x.category == cat))
              Card(
                child: ListTile(
                  title: Text(a.title),
                  subtitle: Text(a.summary),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => ArticleDetailScreen(article: a)),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 12),
          Text(
            '＊以上為一般衛教資訊，非醫療診斷；個別狀況請諮詢專業人員。',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            textAlign: TextAlign.center,
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
    return Scaffold(
      appBar: AppBar(title: Text(article.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(label: Text(categoryLabel(article.category))),
          ),
          const SizedBox(height: 12),
          Text(
            article.title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // 用 SelectableText 讓使用者能複製內容（例如求助專線號碼）。
          SelectableText(
            article.body,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 24),
          Text(
            '＊本資訊為一般衛教，非醫療診斷。',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}
