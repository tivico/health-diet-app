import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/activity.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/main.dart';
import 'package:health/providers.dart';
import 'package:health/theme.dart';
import 'package:health/widgets/common.dart';

import 'fake_repository.dart';

// 以下都是虛構的測試資料。
FakeHealthRepository _fake() => FakeHealthRepository(
      UserProfile(
        sex: Sex.female,
        age: 35,
        heightCm: 175,
        weightKg: 72,
        activity: ActivityLevel.light,
        goal: Goal.lose,
      ),
    );

Future<void> _pumpActivityTab(
    WidgetTester tester, FakeHealthRepository fake) async {
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [repositoryProvider.overrideWithValue(fake)],
      child: const HealthApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('運動'));
  await tester.pumpAndSettle();
}

Finder _key(String k) => find.byKey(ValueKey(k));

Finder get _fab => find.widgetWithText(FloatingActionButton, '記錄運動');

Finder get _save => find.widgetWithText(FilledButton, '儲存');

void main() {
  testWidgets('記錄一次有氧：清單和本週摘要都出現', (tester) async {
    final fake = _fake();
    await _pumpActivityTab(tester, fake);
    expect(find.text('這週還沒有運動紀錄'), findsOneWidget);

    await tester.tap(_fab);
    await tester.pumpAndSettle();
    expect(find.text('記錄運動'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, '名稱（選填）'), '慢跑');
    await tester.enterText(_key('activity-duration'), '31:49');
    await tester.enterText(_key('activity-calories'), '214');
    await tester.enterText(_key('activity-avg-hr'), '142');
    await tester.enterText(_key('activity-max-hr'), '171');
    await tester.enterText(_key('activity-zone-3'), '17:02');
    await tester.tap(_save);
    await tester.pumpAndSettle();

    final saved = (await fake.watchActivities().first).single;
    expect(saved.kind, ActivityKind.cardio);
    expect(saved.duration, const Duration(minutes: 31, seconds: 49));
    expect(saved.zones[2], const Duration(minutes: 17, seconds: 2));
    expect(saved.zones[0], isNull);

    expect(find.text('慢跑'), findsOneWidget);
    expect(find.textContaining('31:49 ・ 平均 142 bpm ・ 214 大卡'), findsOneWidget);
    expect(find.text('有氧 1 次'), findsOneWidget);
  });

  testWidgets('記錄肌力訓練：當場新增器材，填重量 × 每組次數 × 組數', (tester) async {
    final fake = _fake();
    await _pumpActivityTab(tester, fake);
    await tester.tap(_fab);
    await tester.pumpAndSettle();

    await tester.tap(find.text('肌力'));
    await tester.pumpAndSettle();
    await tester.enterText(_key('activity-duration'), '36:30');
    await tester.tap(find.text('新增動作'));
    await tester.pumpAndSettle();

    // 選器材 → 清單裡還沒有 → 當場新增
    await tester.tap(find.text('選擇器材'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新增器材…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '名稱'), '划船機 A');
    await tester.tap(find.widgetWithText(FilledButton, '儲存').last);
    await tester.pumpAndSettle();
    expect(find.text('划船機 A'), findsOneWidget);

    await tester.enterText(_key('set-1-weight'), '20');
    await tester.enterText(_key('set-1-reps'), '10');
    await tester.enterText(_key('set-1-sets'), '3');
    await tester.tap(_save);
    await tester.pumpAndSettle();

    final saved = (await fake.watchActivities().first).single;
    expect(saved.kind, ActivityKind.strength);
    expect(saved.sets.single.weight, 20);
    expect(saved.sets.single.reps, 10);
    expect(find.textContaining('1 個動作 ・ 3 組'), findsOneWidget);
    expect(find.text('肌力 1 次'), findsOneWidget);
  });

  testWidgets('一鍵帶入最近的名稱、複製上次，改一個重量；器材頁看得到每次的變化',
      (tester) async {
    final fake = _fake();
    final rower = await fake
        .saveExercise(const Exercise(name: '划船機 A', unit: WeightUnit.kg));
    final press = await fake
        .saveExercise(const Exercise(name: '胸推機', unit: WeightUnit.lb));
    await fake.saveActivity(Activity(
      startedAt: DateTime.now().subtract(const Duration(days: 7)),
      kind: ActivityKind.strength,
      title: '健身房',
      duration: const Duration(minutes: 30),
      sets: [
        ExerciseSet(exerciseId: rower, weight: 20, reps: 10, sets: 3),
        ExerciseSet(exerciseId: press, weight: 25, reps: 10, sets: 3),
      ],
    ));
    await _pumpActivityTab(tester, fake);
    await tester.tap(_fab);
    await tester.pumpAndSettle();

    // 點「最近用過」的名稱：名稱和種類一起帶入
    await tester.tap(find.widgetWithText(ActionChip, '健身房'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('複製上次'));
    await tester.pumpAndSettle();
    expect(find.text('划船機 A'), findsOneWidget);
    expect(find.text('胸推機'), findsOneWidget);

    await tester.enterText(_key('set-1-weight'), '22.5');
    await tester.enterText(_key('activity-duration'), '32:00');
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(await fake.watchActivities().first, hasLength(2));

    await tester.tap(find.byTooltip('器材清單'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('划船機 A'));
    await tester.pumpAndSettle();
    expect(find.text('22.5 kg × 10 下 × 3 組'), findsOneWidget);
    expect(find.text('20 kg × 10 下 × 3 組'), findsOneWidget);
    final palette = Theme.of(tester.element(find.text('每次的重量'))).palette;
    expect(
      tester.widget<PillLabel>(find.widgetWithText(PillLabel, '+2.5')).color,
      palette.success,
    );
  });

  testWidgets('時長必填、格式要對；最高心率不會低於平均；肌力的動作要選器材', (tester) async {
    final fake = _fake();
    await _pumpActivityTab(tester, fake);
    await tester.tap(_fab);
    await tester.pumpAndSettle();

    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.text('請輸入時長'), findsOneWidget);

    await tester.enterText(_key('activity-duration'), '31:99');
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.text('格式像 31:49 或 1:00:53'), findsOneWidget);

    await tester.enterText(_key('activity-duration'), '31:49');
    await tester.enterText(_key('activity-avg-hr'), '150');
    await tester.enterText(_key('activity-max-hr'), '140');
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.text('不會低於平均心率'), findsOneWidget);

    await tester.enterText(_key('activity-max-hr'), '170');
    await tester.tap(find.text('肌力'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新增動作'));
    await tester.pumpAndSettle();
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.text('請選擇器材'), findsOneWidget);

    expect(await fake.watchActivities().first, isEmpty);
  });

  testWidgets('點一筆可以修改；刪除可以復原', (tester) async {
    final fake = _fake();
    await fake.saveActivity(Activity(
      startedAt: DateTime.now(),
      kind: ActivityKind.cardio,
      title: '慢跑',
      duration: const Duration(minutes: 30),
    ));
    await _pumpActivityTab(tester, fake);

    await tester.tap(find.text('慢跑'));
    await tester.pumpAndSettle();
    expect(find.text('修改運動'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '30:00'), findsOneWidget);
    await tester.enterText(_key('activity-duration'), '45:00');
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.textContaining('45:00'), findsOneWidget);

    await tester.tap(find.byTooltip('刪除'));
    await tester.pumpAndSettle();
    expect(find.text('慢跑'), findsNothing);
    await tester.tap(find.text('復原'));
    await tester.pumpAndSettle();
    expect(find.text('慢跑'), findsOneWidget);
    expect(await fake.watchActivities().first, hasLength(1));
  });

  testWidgets('器材清單：名稱不能重複；有紀錄的器材單位鎖住、不能刪', (tester) async {
    final fake = _fake();
    final used = await fake
        .saveExercise(const Exercise(name: '划船機 A', unit: WeightUnit.kg));
    await fake.saveActivity(Activity(
      startedAt: DateTime.now(),
      kind: ActivityKind.strength,
      duration: const Duration(minutes: 30),
      sets: [ExerciseSet(exerciseId: used, weight: 20, reps: 10, sets: 3)],
    ));
    await _pumpActivityTab(tester, fake);
    await tester.tap(find.byTooltip('器材清單'));
    await tester.pumpAndSettle();

    // 同名器材擋下來；換個名字就能新增
    await tester.tap(find.widgetWithText(FloatingActionButton, '新增器材'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '名稱'), '划船機 A');
    await tester.tap(find.widgetWithText(FilledButton, '儲存'));
    await tester.pumpAndSettle();
    expect(find.text('已經有叫「划船機 A」的器材了'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, '名稱'), '腿推機');
    await tester.tap(find.widgetWithText(FilledButton, '儲存'));
    await tester.pumpAndSettle();
    expect(find.text('腿推機'), findsOneWidget);

    // 有紀錄的器材：單位鎖住（清單依名稱排序，划船機 A 在前）
    await tester.tap(find.byTooltip('修改').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('單位不能改'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    // 有紀錄的不能刪；沒紀錄的可以
    await tester.tap(find.byTooltip('刪除').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('已經有紀錄，不能刪除'), findsOneWidget);
    await tester.tap(find.byTooltip('刪除').last);
    await tester.pumpAndSettle();
    expect(find.text('腿推機'), findsNothing);
  });
}
