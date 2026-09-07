import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/food_library.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '搜尋食物，例如：便當、珍珠',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '清除',
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => setState(_query.clear),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: const Text('全部'),
                    selected: _category == null,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                ),
                for (final c in FoodCategory.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      avatar: Icon(
                        foodCategoryIcon(c),
                        size: 16,
                        color: _categoryColor(context, c),
                      ),
                      label: Text(foodCategoryLabel(c)),
                      selected: _category == c,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: (recent.isEmpty && results.isEmpty)
                ? const Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: EmptyState(
                      icon: Icons.search_off,
                      message: '找不到符合的食物，\n可以回上一頁直接手動輸入。',
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                    children: [
                      if (recent.isNotEmpty) ...[
                        SectionHeader(
                          icon: Icons.history,
                          title: '最近吃過',
                          color: theme.colorScheme.primary,
                          subtitle: '自己記過的數值，比通用估算更貼近實際',
                        ),
                        for (final m in recent)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PickCard(
                              icon: Icons.history,
                              color: theme.colorScheme.primary,
                              name: m.name,
                              detail: _recentSubtitle(m),
                              calories: m.calories,
                              onTap: () => Navigator.of(context)
                                  .pop(PickedFood.fromMeal(m)),
                            ),
                          ),
                        const SizedBox(height: 12),
                        SectionHeader(
                          icon: Icons.menu_book_outlined,
                          title: '食物庫',
                          color: theme.palette.carbs,
                        ),
                      ],
                      for (final f in results)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PickCard(
                            icon: foodCategoryIcon(f.category),
                            color: _categoryColor(context, f.category),
                            name: f.name,
                            detail:
                                '${f.serving} ・ 蛋白 ${f.proteinG.round()} / 脂 ${f.fatG.round()} / 碳 ${f.carbsG.round()} g',
                            calories: f.calories,
                            onTap: () => Navigator.of(context)
                                .pop(PickedFood.fromLibrary(f)),
                          ),
                        ),
                    ],
                  ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 6, 16, 14),
            child: FootNote(
                '＊食物庫數值為常見份量的估算值，會因店家與份量而異；選取後仍可自行修改。'),
          ),
        ],
      ),
    );
  }

  String _recentSubtitle(MealEntry m) =>
      '上次 ${m.eatenAt.month}/${m.eatenAt.day} ・ '
      '蛋白 ${m.proteinG.round()} / 脂 ${m.fatG.round()} / 碳 ${m.carbsG.round()} g';
}

/// 可挑選的一列食物（最近吃過與食物庫共用同一種卡片）。
class _PickCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String name;
  final String detail;
  final double calories;
  final VoidCallback onTap;

  const _PickCard({
    required this.icon,
    required this.color,
    required this.name,
    required this.detail,
    required this.calories,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(icon: icon, color: color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PillLabel(text: '${calories.round()} 大卡', color: color),
        ],
      ),
    );
  }
}

/// 食物分類的圖示。
IconData foodCategoryIcon(FoodCategory c) => switch (c) {
      FoodCategory.rice => Icons.rice_bowl_outlined,
      FoodCategory.noodle => Icons.ramen_dining_outlined,
      FoodCategory.snack => Icons.lunch_dining_outlined,
      FoodCategory.breakfast => Icons.free_breakfast_outlined,
      FoodCategory.drink => Icons.local_cafe_outlined,
      FoodCategory.dessert => Icons.icecream_outlined,
      FoodCategory.store => Icons.storefront_outlined,
    };

Color _categoryColor(BuildContext context, FoodCategory c) {
  final palette = Theme.of(context).palette;
  return switch (c) {
    FoodCategory.rice => palette.fat,
    FoodCategory.noodle => palette.warning,
    FoodCategory.snack => palette.protein,
    FoodCategory.breakfast => palette.success,
    FoodCategory.drink => palette.carbs,
    FoodCategory.dessert => palette.dinner,
    FoodCategory.store => palette.uncategorized,
  };
}
