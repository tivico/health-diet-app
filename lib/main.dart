import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runApp(const ProviderScope(child: HealthApp()));
}

class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  /// 主題種子色（淺色 / 深色共用同一個品牌色）。
  static const _seed = Color(0xFF2E7D5B);

  /// 依亮/暗色產生主題。
  /// 表單欄位統一設定成「灰底」，全 App 風格一致（不必每個欄位各自設定）。
  static ThemeData _themeFor(Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '健康飲控',
      debugShowCheckedModeBanner: false,
      theme: _themeFor(Brightness.light),
      darkTheme: _themeFor(Brightness.dark),
      themeMode: ThemeMode.system, // 跟隨系統深/淺色
      // 介面文字（含日期選擇器等系統元件）使用繁體中文。
      locale: const Locale('zh', 'TW'),
      supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
