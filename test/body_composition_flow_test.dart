import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/body_composition.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/main.dart';
import 'package:health/providers.dart';
import 'package:health/theme.dart';
import 'package:health/widgets/common.dart';

import 'fake_repository.dart';

// 以下數字都是虛構的測試值。
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

/// 3/2、3/30 兩次量測：脂肪降、骨骼肌也降、體重降 1 公斤。
Future<FakeHealthRepository> _withTwoMeasurements() async {
  final fake = _fake();
  await fake.upsertBodyComposition(BodyComposition(
    day: DateTime(2026, 3, 2),
    values: {
      BodyMetric.weight: 73,
      BodyMetric.fatMass: 18.5,
      BodyMetric.skeletalMuscle: 31.0,
    },
  ));
  await fake.upsertBodyComposition(BodyComposition(
    day: DateTime(2026, 3, 30),
    values: {
      BodyMetric.weight: 72,
      BodyMetric.fatMass: 17.9,
      BodyMetric.skeletalMuscle: 30.7,
    },
  ));
  return fake;
}

Future<void> _pumpWeightTab(WidgetTester tester, FakeHealthRepository fake) async {
  tester.view.physicalSize = const Size(1080, 3200);
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
  await tester.tap(find.text('體重'));
  await tester.pumpAndSettle();
}

Finder _field(BodyMetric m) => find.byKey(ValueKey('body-${m.name}'));

Finder get _save => find.widgetWithText(FilledButton, '儲存');

Future<List<double>> _weights(FakeHealthRepository fake) async => [
      for (final w
          in await fake.watchWeightsBetween(DateTime(2000), DateTime(2100)).first)
        w.weightKg,
    ];

void main() {
  testWidgets('沒有紀錄時顯示引導；記錄第一筆後出現摘要卡，體重也一起記下', (tester) async {
    final fake = _fake();
    await _pumpWeightTab(tester, fake);

    await tester.tap(find.text('記錄第一筆體組成'));
    await tester.pumpAndSettle();
    expect(find.text('記錄體組成'), findsOneWidget);

    await tester.enterText(_field(BodyMetric.weight), '71.6');
    await tester.enterText(_field(BodyMetric.bodyFat), '25.1');
    await tester.enterText(_field(BodyMetric.skeletalMuscle), '30.7');
    await tester.enterText(_field(BodyMetric.waist), '82.8');
    await tester.enterText(_field(BodyMetric.hip), '99.5');
    await tester.enterText(
        find.widgetWithText(TextFormField, '量測工具'), 'InBody');
    await tester.tap(_save);
    await tester.pumpAndSettle();

    // 回到體重分頁：摘要卡列出有量到的項目，第一筆沒有「和上次比」
    expect(find.textContaining(' 量測'), findsOneWidget);
    expect(find.text('30.7 kg'), findsOneWidget);
    expect(find.text('82.8 cm'), findsOneWidget);
    expect(find.textContaining('相比'), findsNothing);
    expect(find.textContaining('BMI 23.4 ・ 腰臀比 0.83 ・ InBody'), findsOneWidget);
    expect(find.text('全部紀錄（1 筆）'), findsOneWidget);

    // 「同時記到體重紀錄」預設開著
    expect(await _weights(fake), [71.6]);
  });

  testWidgets('兩次量測：和上次比的變化，好壞用顏色分，體重不分好壞', (tester) async {
    await _pumpWeightTab(tester, await _withTwoMeasurements());

    expect(find.text('與 3/2 相比'), findsOneWidget);
    final palette = Theme.of(tester.element(find.text('與 3/2 相比'))).palette;
    Color pill(String text) =>
        tester.widget<PillLabel>(find.widgetWithText(PillLabel, text)).color;

    expect(pill('−0.6'), palette.success, reason: '脂肪量下降');
    expect(pill('−0.3'), palette.warning, reason: '骨骼肌下降');
    expect(pill('−1'), palette.uncategorized, reason: '體重只標方向，不判好壞');
  });

  testWidgets('沒填體重、打錯字（超出範圍、超過體重）都會擋下來', (tester) async {
    final fake = _fake();
    await _pumpWeightTab(tester, fake);
    await tester.tap(find.text('記錄第一筆體組成'));
    await tester.pumpAndSettle();

    await tester.enterText(_field(BodyMetric.fatMass), '17.9');
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.text('請輸入體重'), findsOneWidget);

    await tester.enterText(_field(BodyMetric.weight), '71.6');
    await tester.enterText(_field(BodyMetric.skeletalMuscle), '307');
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.text('需介於 3–150'), findsOneWidget);

    await tester.enterText(_field(BodyMetric.skeletalMuscle), '30.7');
    await tester.enterText(_field(BodyMetric.fatMass), '80');
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.text('不會超過體重'), findsOneWidget);

    expect(find.text('記錄體組成'), findsOneWidget, reason: '還停在記錄頁');
    expect(await fake.watchBodyCompositions().first, isEmpty);
  });

  testWidgets('關掉「同時記到體重紀錄」就不會動到體重紀錄', (tester) async {
    final fake = _fake();
    await _pumpWeightTab(tester, fake);
    await tester.tap(find.text('記錄第一筆體組成'));
    await tester.pumpAndSettle();

    await tester.enterText(_field(BodyMetric.weight), '71.6');
    await tester.tap(find.text('同時記到體重紀錄'));
    await tester.tap(_save);
    await tester.pumpAndSettle();

    expect(await fake.watchBodyCompositions().first, hasLength(1));
    expect(await _weights(fake), isEmpty);
  });

  testWidgets('紀錄清單：點一筆可以修改，刪除可以復原', (tester) async {
    final fake = await _withTwoMeasurements();
    await _pumpWeightTab(tester, fake);

    await tester.tap(find.text('全部紀錄（2 筆）'));
    await tester.pumpAndSettle();
    expect(find.text('體組成紀錄'), findsOneWidget);

    // 修改 3/30 那筆：原本的數字會帶進來
    await tester.tap(find.text('72 kg'));
    await tester.pumpAndSettle();
    expect(find.text('修改體組成'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '30.7'), findsOneWidget);
    await tester.enterText(_field(BodyMetric.weight), '71.5');
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.text('71.5 kg'), findsOneWidget);

    // 刪除最新那筆，再按「復原」
    await tester.tap(find.byTooltip('刪除').first);
    await tester.pumpAndSettle();
    expect(find.text('71.5 kg'), findsNothing);
    await tester.tap(find.text('復原'));
    await tester.pumpAndSettle();
    expect(find.text('71.5 kg'), findsOneWidget);
    expect(await fake.watchBodyCompositions().first, hasLength(2));
  });
}
