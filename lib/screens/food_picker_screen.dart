import 'package:flutter/material.dart';

import '../data/food_library.dart';

/// 食物庫：搜尋 / 分類挑選常見食物，選取後回傳給新增餐點頁自動帶入。
class FoodPickerScreen extends StatefulWidget {
  const FoodPickerScreen({super.key});

  @override
  State<FoodPickerScreen> createState() => _FoodPickerScreenState();
}

class _FoodPickerScreenState extends State<FoodPickerScreen> {
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
    final results = searchFoods(_query.text, category: _category);

    return Scaffold(
      appBar: AppBar(title: const Text('食物庫')),
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
            child: results.isEmpty
                ? Center(
                    child: Text('找不到符合的食物，可以直接手動輸入。',
                        style: TextStyle(color: theme.hintColor)),
                  )
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (_, i) {
                      final f = results[i];
                      return ListTile(
                        title: Text(f.name),
                        subtitle: Text(
                          '${f.serving} ・ 蛋白 ${f.proteinG.round()} / 脂 ${f.fatG.round()} / 碳 ${f.carbsG.round()} g',
                        ),
                        trailing: Text('${f.calories.round()} 大卡'),
                        onTap: () => Navigator.of(context).pop(f),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '＊數值為常見份量的估算值，會因店家與份量而異；選取後仍可自行修改。',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
