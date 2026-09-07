import 'package:flutter/material.dart';

import '../theme.dart';
import 'dashboard_screen.dart';
import 'education_screen.dart';
import 'stats_screen.dart';
import 'weight_screen.dart';

/// 主畫面外殼：底部導覽切換「今日 / 體重 / 統計 / 衛教」。
/// 用 IndexedStack 保留各分頁狀態（切回來不會重置捲動位置等）。
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [
    DashboardScreen(),
    WeightScreen(),
    StatsScreen(),
    EducationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      // 導覽列上緣加一道細線與淡陰影，和內容區分開
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.palette.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.palette.shadow,
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.local_dining_outlined),
              selectedIcon: Icon(Icons.local_dining),
              label: '今日',
            ),
            NavigationDestination(
              icon: Icon(Icons.monitor_weight_outlined),
              selectedIcon: Icon(Icons.monitor_weight),
              label: '體重',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: '統計',
            ),
            NavigationDestination(
              icon: Icon(Icons.eco_outlined),
              selectedIcon: Icon(Icons.eco),
              label: '衛教',
            ),
          ],
        ),
      ),
    );
  }
}
