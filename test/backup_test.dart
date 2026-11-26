import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/data/backup_file.dart';
import 'package:health/data/csv_export.dart';
import 'package:health/domain/meal_type.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/providers.dart';
import 'package:health/screens/backup_screen.dart';

import 'fake_local_files.dart';
import 'fake_repository.dart';

UserProfile _profile() => UserProfile(
      sex: Sex.female,
      age: 28,
      heightCm: 165,
      weightKg: 60,
      activity: ActivityLevel.light,
      goal: Goal.lose,
    );

/// 有一筆午餐（2026-06-17 12:30 雞腿便當）的使用者。
Future<FakeHealthRepository> _withLunch() async {
  final repo = FakeHealthRepository(_profile());
  await repo.addMeal(
    eatenAt: DateTime(2026, 6, 17, 12, 30),
    name: '雞腿便當',
    calories: 800,
    proteinG: 35,
    fatG: 25,
    carbsG: 90,
    mealType: MealType.lunch,
  );
  return repo;
}

Future<List<String>> _mealNamesOn(FakeHealthRepository repo, DateTime day) async =>
    [for (final m in await repo.watchMealsOn(day).first) m.name];

Future<void> _pumpBackup(
  WidgetTester tester,
  FakeHealthRepository repo,
  FakeLocalFiles files,
) async {
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        localFilesProvider.overrideWithValue(files),
      ],
      child: const MaterialApp(home: BackupScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('匯出再匯入可還原資料', () async {
    final src = FakeHealthRepository(_profile());
    await src.addMeal(
      eatenAt: DateTime(2026, 6, 17, 12),
      name: '午餐',
      calories: 600,
      proteinG: 30,
      fatG: 20,
      carbsG: 70,
    );
    await src.upsertWeight(day: DateTime(2026, 6, 17), weightKg: 59, bodyFatPct: 25);

    final json = await src.exportJson();

    final dst = FakeHealthRepository();
    await dst.importJson(json);

    expect(await dst.getProfile(), isNotNull);
    final meals = await dst.watchMealsOn(DateTime(2026, 6, 17)).first;
    expect(meals.length, 1);
    expect(meals.first.name, '午餐');
    final weights = await dst
        .watchWeightsBetween(DateTime(2026, 6, 1), DateTime(2026, 6, 30))
        .first;
    expect(weights.length, 1);
    expect(weights.first.weightKg, 59);
  });

  group('能存檔的平台（Web 版）', () {
    testWidgets('下載備份檔：檔名帶日期，內容是完整備份', (tester) async {
      final files = FakeLocalFiles();
      await _pumpBackup(tester, await _withLunch(), files);

      await tester.tap(find.widgetWithText(FilledButton, '下載備份檔'));
      await tester.pumpAndSettle();

      final file = files.saved.single;
      expect(file.fileName,
          matches(RegExp(r'^健康飲控備份-\d{4}-\d{2}-\d{2}\.json$')));
      expect(file.mimeType, 'application/json');
      final summary = summarizeBackup(file.text)!;
      expect(summary.hasProfile, isTrue);
      expect(summary.mealCount, 1);
      expect(find.textContaining('已下載「${file.fileName}」'), findsOneWidget);
    });

    testWidgets('下載餐點 CSV：開頭有 BOM（Excel 中文才不會亂碼），不另外顯示預覽',
        (tester) async {
      final files = FakeLocalFiles();
      await _pumpBackup(tester, await _withLunch(), files);

      await tester.tap(find.widgetWithText(OutlinedButton, '餐點 CSV'));
      await tester.pumpAndSettle();

      final file = files.saved.single;
      expect(file.fileName,
          matches(RegExp(r'^健康飲控-餐點-\d{4}-\d{2}-\d{2}\.csv$')));
      expect(file.mimeType, 'text/csv');
      expect(file.text, startsWith('$kUtf8Bom日期,時間,餐別,品項'));
      expect(file.text, contains('2026-06-17,12:30,午餐,雞腿便當,800'));
      expect(find.textContaining('目前顯示'), findsNothing);
    });

    testWidgets('選擇備份檔還原：先顯示內容摘要，確認後才覆蓋', (tester) async {
      final source = await _withLunch();
      await source.upsertWeight(day: DateTime(2026, 6, 17), weightKg: 59);
      final files = FakeLocalFiles()..fileToOpen = await source.exportJson();

      final target = FakeHealthRepository(_profile());
      await target.addMeal(
        eatenAt: DateTime(2026, 1, 1, 9),
        name: '會被覆蓋掉',
        calories: 111,
        proteinG: 0,
        fatG: 0,
        carbsG: 0,
      );
      await _pumpBackup(tester, target, files);

      await tester.tap(find.widgetWithText(FilledButton, '選擇備份檔'));
      await tester.pumpAndSettle();
      expect(files.lastAccept, contains('.json'));
      expect(find.text('還原備份？'), findsOneWidget);
      expect(find.textContaining('備份內容：個人資料、餐點 1 筆、體重 1 筆'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '還原'));
      await tester.pumpAndSettle();

      expect(find.text('已還原備份'), findsOneWidget);
      expect(await _mealNamesOn(target, DateTime(2026, 6, 17)), ['雞腿便當']);
      expect(await _mealNamesOn(target, DateTime(2026, 1, 1)), isEmpty);
    });

    testWidgets('確認時按取消：資料不變', (tester) async {
      final files = FakeLocalFiles()
        ..fileToOpen = await FakeHealthRepository(_profile()).exportJson();
      final target = await _withLunch();
      await _pumpBackup(tester, target, files);

      await tester.tap(find.widgetWithText(FilledButton, '選擇備份檔'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '取消'));
      await tester.pumpAndSettle();

      expect(await _mealNamesOn(target, DateTime(2026, 6, 17)), ['雞腿便當']);
    });

    testWidgets('選到不是備份的檔案（例如 CSV）：提醒，而且不會覆蓋', (tester) async {
      final files = FakeLocalFiles()
        ..fileToOpen = '日期,時間,餐別,品項\r\n2026-06-17,12:30,午餐,雞腿便當,800\r\n';
      final target = await _withLunch();
      await _pumpBackup(tester, target, files);

      await tester.tap(find.widgetWithText(FilledButton, '選擇備份檔'));
      await tester.pumpAndSettle();

      expect(find.textContaining('這不是健康飲控的備份'), findsOneWidget);
      expect(find.text('還原備份？'), findsNothing);
      expect(await _mealNamesOn(target, DateTime(2026, 6, 17)), ['雞腿便當']);
    });

    testWidgets('選檔時按取消：什麼都不會發生', (tester) async {
      final files = FakeLocalFiles(); // fileToOpen 是 null = 使用者按了取消
      await _pumpBackup(tester, await _withLunch(), files);

      await tester.tap(find.widgetWithText(FilledButton, '選擇備份檔'));
      await tester.pumpAndSettle();

      expect(find.text('還原備份？'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('貼上文字還原：開頭多了 BOM 也能還原', (tester) async {
      final backup = await (await _withLunch()).exportJson();
      final target = FakeHealthRepository(_profile());
      await _pumpBackup(tester, target, FakeLocalFiles());

      await tester.enterText(find.byType(TextField), '$kUtf8Bom$backup');
      await tester.tap(find.widgetWithText(OutlinedButton, '還原貼上的文字'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '還原'));
      await tester.pumpAndSettle();

      expect(await _mealNamesOn(target, DateTime(2026, 6, 17)), ['雞腿便當']);
    });
  });

  group('不能存檔的平台：退回複製貼上', () {
    testWidgets('產生備份文字後出現「複製」按鈕', (tester) async {
      await _pumpBackup(
          tester, FakeHealthRepository(_profile()), FakeLocalFiles(isSupported: false));

      expect(find.text('備份與還原'), findsOneWidget);
      expect(find.text('下載備份檔'), findsNothing);
      expect(find.text('選擇備份檔'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, '產生備份文字'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(OutlinedButton, '複製到剪貼簿'), findsOneWidget);
      expect(find.text('目前顯示：備份（JSON）'), findsOneWidget);
    });

    testWidgets('匯出餐點 CSV，預覽出現標題列（貼上用，不加 BOM）', (tester) async {
      await _pumpBackup(tester, await _withLunch(), FakeLocalFiles(isSupported: false));

      // CSV 是單向的檢視格式，畫面上要講清楚
      expect(find.textContaining('不能用來還原'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, '餐點 CSV'));
      await tester.pumpAndSettle();

      expect(find.text('目前顯示：餐點 CSV'), findsOneWidget);
      expect(find.textContaining('日期,時間,餐別,品項'), findsOneWidget);
      expect(find.textContaining(kUtf8Bom), findsNothing);
      expect(find.textContaining('2026-06-17,12:30,午餐,雞腿便當,800'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '複製到剪貼簿'), findsOneWidget);
    });
  });
}
