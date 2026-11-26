import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 建置環境版本的護欄測試。
///
/// CI 和部署沒寫死 Flutter 版本的話，GitHub 每次都會裝「當下最新版」：
/// 同一份程式碼可能哪天突然檢查不過，部署出去的也不是本機測過的版本（2026-11 發生過）。
/// 升級 Flutter 時，開發機和兩個 workflow 要一起改（步驟見 docs/DEPLOYMENT.md）。
void main() {
  final workflows = {
    for (final name in ['ci.yml', 'deploy.yml'])
      name: File('.github/workflows/$name').readAsStringSync(),
  };

  test('CI 和部署都寫死同一個 Flutter 版本', () {
    final versions = {
      for (final MapEntry(key: name, value: yml) in workflows.entries)
        name: RegExp(r'flutter-version:\s*(\d+\.\d+\.\d+)')
            .firstMatch(yml)
            ?.group(1),
    };
    expect(versions.values, everyElement(isNotNull),
        reason: '每個 workflow 都要寫 flutter-version（完整版本號）：$versions');
    expect(versions.values.toSet(), hasLength(1),
        reason: 'CI 和部署要用同一版：$versions');
  });

  test('第三方 action 鎖在固定的 commit，不用會被改指的標籤', () {
    for (final MapEntry(key: name, value: yml) in workflows.entries) {
      for (final match in RegExp(r'uses:\s*(\S+)').allMatches(yml)) {
        final action = match.group(1)!;
        if (action.startsWith('actions/')) continue; // GitHub 官方提供的
        expect(action, matches(RegExp(r'@[0-9a-f]{40}$')),
            reason: '$name 的 $action 要鎖在 40 碼的 commit SHA');
      }
    }
  });
}
