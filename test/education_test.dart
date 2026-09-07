import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/data/education_content.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/main.dart';
import 'package:health/providers.dart';

import 'fake_repository.dart';

void main() {
  // 衛教內容會影響使用者的健康決定，出處不能漏。
  // 這幾條是給「未來新增文章」的護欄，不是在測 Flutter。
  group('衛教文章的資料來源', () {
    test('每篇文章都要附至少一則資料來源', () {
      for (final a in educationArticles) {
        expect(a.sources, isNotEmpty, reason: '「${a.title}」沒有資料來源');
      }
    });

    test('來源網址都是可解析的 https 網址，且有說明支持文中哪個說法', () {
      for (final a in educationArticles) {
        for (final s in a.sources) {
          final uri = Uri.tryParse(s.url);
          expect(uri, isNotNull, reason: '「${a.title}」的來源網址無法解析：${s.url}');
          expect(uri!.scheme, 'https',
              reason: '「${a.title}」的來源不是 https：${s.url}');
          expect(uri.host, isNotEmpty, reason: '「${a.title}」的來源缺少網域：${s.url}');
          expect(s.title.trim(), isNotEmpty, reason: '「${a.title}」有來源缺少名稱');
          expect(s.note.trim(), isNotEmpty,
              reason: '「${a.title}」的來源「${s.title}」缺少說明');
        }
      }
    });

    test('同一篇文章不會重複列同一個來源', () {
      for (final a in educationArticles) {
        final urls = a.sources.map((s) => s.url).toList();
        expect(urls.toSet().length, urls.length,
            reason: '「${a.title}」有重複的來源網址');
      }
    });
  });

  testWidgets('切到衛教分頁 → 開啟文章 → 顯示內文', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = FakeHealthRepository(
      UserProfile(
        sex: Sex.female,
        age: 28,
        heightCm: 165,
        weightKg: 60,
        activity: ActivityLevel.light,
        goal: Goal.lose,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(fake)],
        child: const HealthApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 切到衛教分頁
    await tester.tap(find.text('衛教'));
    await tester.pumpAndSettle();
    expect(find.text('衛教知識'), findsOneWidget);

    // 點一篇文章
    await tester.tap(find.text('BMI 是參考，不是全部'));
    await tester.pumpAndSettle();

    // 進入詳細頁：離開列表頁、標題出現在詳細頁
    expect(find.text('衛教知識'), findsNothing);
    expect(find.text('BMI 是參考，不是全部'), findsWidgets);
  });
}
