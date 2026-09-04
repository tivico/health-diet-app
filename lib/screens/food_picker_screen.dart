import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/food_library.dart';
import '../providers.dart';

/// 挑選結果：回傳給新增餐點頁自動帶入欄位。
///
/// 兩個來源的型別不同（靜態食物庫的 [FoodItem] vs 使用者自己的 [MealEntry]），
/// 用這個小型別把「填表要用的東西」統一起來，呼叫端不必認識兩種來源。
class PickedFood {
  final String name;
  final double calories;
  final double proteinG;
  final double fatG;
  final double carbsG;

  const PickedFood({
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
  });

  PickedFood.fromLibrary(FoodItem f)
      : name = f.name,
        calories = f.calories,
        proteinG = f.proteinG,
        fatG = f.fatG,
        carbsG = f.carbsG;

  PickedFood.fromMeal(MealEntry m)
      : name = m.name,
        calories = m.calories,
        proteinG = m.proteinG,
        fatG = m.fatG,
        carbsG = m.carbsG;
}

/// 食物庫：先列出「最近吃過」，再列出內建食物庫；兩者都可搜尋。
///
/// 自己吃過的東西命中率遠高於整個食物庫，所以放最前面；
/// 而且那是自己調整過的數值，比估算的通用值更貼近實際。
class FoodPickerScreen extends ConsumerStatefulWidget {
  const FoodPickerScreen({super.key});

  @override
  ConsumerState<FoodPickerScreen> createState() => _FoodPickerScreenState();
}

class _FoodPickerScreenState extends ConsumerState<FoodPickerScreen> {
  final _query = TextEditingController();
  FoodCategory? _category;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.text.trim();
    final results = searchFoods(query, category: _category);

    // 分類只適用於內建食物庫，所以選了分類時不顯示「最近吃過」。
    final recent = _category != null
        ? const <MealEntry>[]
        : (ref.watch(recentFoodsProvider).value ?? const <MealEntry>[])
            .where((m) => query.isEmpty || m.name.contains(query))
            .toList();

    return Scaffold(
      // 這頁現在有兩個來源，標題不再叫「食物庫」，避免和下面的區塊標題重複
      appBar: AppBar(title: const Text('挑選食物')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: '搜尋食物，例如：便當、珍珠',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: const Text('全部'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                ),
                for (final c in FoodCategory.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(foodCategoryLabel(c)),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: (recent.isEmpty && results.isEmpty)
                ? Center(
                    child: Text('找不到符合的食物，可以直接手動輸入。',
                        style: TextStyle(color: theme.hintColor)),
                  )
                : ListView(
                    children: [
                      if (recent.isNotEmpty) ...[
                        _sectionHeader(theme, Icons.history, '最近吃過'),
                        for (final m in recent)
                          ListTile(
                            leading: Icon(Icons.history,
                                color: theme.colorScheme.primary),
                            title: Text(m.name),
                            subtitle: Text(_recentSubtitle(m)),
                            trailing: Text('${m.calories.round()} 大卡'),
                            onTap: () => Navigator.of(context)
                                .pop(PickedFood.fromMeal(m)),
                          ),
                        const Divider(height: 24),
                        _sectionHeader(theme, Icons.menu_book_outlined, '食物庫'),
                      ],
                      for (final f in results)
                        ListTile(
                          title: Text(f.name),
                          subtitle: Text(
                            '${f.serving} ・ 蛋白 ${f.proteinG.round()} / 脂 ${f.fatG.round()} / 碳 ${f.carbsG.round()} g',
                          ),
                          trailing: Text('${f.calories.round()} 大卡'),
                          onTap: () => Navigator.of(context)
                              .pop(PickedFood.fromLibrary(f)),
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '＊食物庫數值為常見份量的估算值，會因店家與份量而異；選取後仍可自行修改。',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, IconData icon, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  String _recentSubtitle(MealEntry m) =>
      '上次 ${m.eatenAt.month}/${m.eatenAt.day} ・ '
      '蛋白 ${m.proteinG.round()} / 脂 ${m.fatG.round()} / 碳 ${m.carbsG.round()} g';
}
