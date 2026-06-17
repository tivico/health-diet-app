import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runApp(const ProviderScope(child: HealthApp()));
}

class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '健康飲控',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2E7D5B),
        useMaterial3: true,
      ),
      home: const HomeGate(),
    );
  }
}

/// 啟動時的分流：依「是否已有使用者資料」決定顯示引導設定還是主畫面。
/// 因為讀的是 reactive 的 profileProvider，存檔後會自動切換。
class HomeGate extends ConsumerWidget {
  const HomeGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    return profileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('載入資料時發生錯誤：\n$e', textAlign: TextAlign.center),
          ),
        ),
      ),
      data: (profile) =>
          profile == null ? const OnboardingScreen() : const HomeShell(),
    );
  }
}
