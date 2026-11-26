import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/enable_csp.dart';

/// 對外連線白名單（CSP）的護欄測試。
///
/// 白名單一旦被放寬，App 就可能把紀錄送到別的網站，畫面上卻完全看不出來。
/// 所以「允許哪些外部網址」寫死在這裡：要新增來源，必須同時改 web/index.html
/// 和這份清單——讓每一次放寬都是刻意的決定（流程見 docs/SECURITY.md）。
const _allowedExternalSources = {
  'https://www.gstatic.com/flutter-canvaskit/', // Flutter 繪圖引擎（CanvasKit）
  'https://fonts.gstatic.com/s/', // Google 字型
};

/// 把 CSP 字串拆成「指令 → 來源清單」。
Map<String, List<String>> _parse(String policy) {
  final result = <String, List<String>>{};
  for (final directive in policy.split(';')) {
    final tokens = directive.trim().split(RegExp(r'\s+'));
    if (tokens.first.isEmpty) continue;
    result[tokens.first] = tokens.skip(1).toList();
  }
  return result;
}

void main() {
  final indexHtml = File('web/index.html').readAsStringSync();
  final deployYml = File('.github/workflows/deploy.yml').readAsStringSync();
  final csp = _parse(activeCspPolicy(enableCsp(indexHtml)) ?? '');

  test('原始 index.html 的白名單是註解狀態（開發模式才不會白畫面）', () {
    expect(activeCspPolicy(indexHtml), isNull);
  });

  test('正式版建置後白名單會生效', () {
    expect(activeCspPolicy(enableCsp(indexHtml)), isNotNull);
  });

  test('沒有特別允許的，一律只准連本站', () {
    expect(csp['default-src'], ["'self'"]);
  });

  test('外部網址只能是白名單裡的', () {
    final external = {
      for (final sources in csp.values)
        for (final s in sources)
          if (s.startsWith('http://') || s.startsWith('https://')) s,
    };
    expect(external.difference(_allowedExternalSources), isEmpty,
        reason: '要新增來源，請照 docs/SECURITY.md 的步驟，並更新本測試的白名單');
  });

  test('不能用萬用字元或整個協定放行', () {
    for (final MapEntry(key: directive, value: sources) in csp.entries) {
      for (final s in sources) {
        expect(s.contains('*'), isFalse, reason: '$directive 不該用 *');
        expect(const ['http:', 'https:', 'ws:', 'wss:'], isNot(contains(s)),
            reason: '$directive 不該整個放行 $s');
      }
    }
  });

  test('程式只能來自檔案，不能動態執行字串或內嵌程式', () {
    expect(csp['script-src'], isNot(contains("'unsafe-eval'")));
    expect(csp['script-src'], isNot(contains("'unsafe-inline'")));
  });

  test('外掛、表單送出、網址基準都鎖住', () {
    expect(csp['object-src'], ["'none'"]);
    expect(csp['form-action'], ["'none'"]);
    expect(csp['base-uri'], ["'self'"]);
  });

  test('找不到標記時建置工具會報錯，不會悄悄做出沒有白名單的版本', () {
    expect(() => enableCsp('<html><head></head></html>'), throwsFormatException);
  });

  test('部署流程會用 --csp 建置並啟用白名單', () {
    expect(deployYml, contains('--csp'));
    expect(deployYml, contains('dart run tool/enable_csp.dart'));
  });
}
