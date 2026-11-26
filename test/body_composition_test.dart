import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/body_composition.dart';

/// 兩次量測（虛構的測試數字，落在一般體組成報告的常見範圍）。
final _mar2 = BodyComposition(
  day: DateTime(2026, 3, 2, 8, 30),
  values: {
    BodyMetric.weight: 72.4,
    BodyMetric.fatMass: 18.5,
    BodyMetric.skeletalMuscle: 31.0,
    BodyMetric.waist: 84.0,
  },
);
final _mar30 = BodyComposition(
  day: DateTime(2026, 3, 30),
  values: {
    BodyMetric.weight: 71.6,
    BodyMetric.fatMass: 17.9,
    BodyMetric.skeletalMuscle: 30.7,
    BodyMetric.waist: 82.8,
    BodyMetric.hip: 99.5,
  },
);

void main() {
  test('量測日只留日期（一天一筆）', () {
    expect(_mar2.day, DateTime(2026, 3, 2));
  });

  test('BMI 用個人資料的身高算；腰臀比要腰圍、臀圍都有', () {
    expect(_mar30.bmiWith(175).toStringAsFixed(1), '23.4');
    expect(_mar30.waistHipRatio!.toStringAsFixed(2), '0.83');
    expect(_mar2.waistHipRatio, isNull, reason: '3/2 沒量臀圍');
  });

  test('變化量：兩次都有量才算', () {
    expect(deltaOf(BodyMetric.fatMass, _mar2, _mar30), closeTo(-0.6, 1e-9));
    expect(deltaOf(BodyMetric.hip, _mar2, _mar30), isNull);
  });

  group('變化方向', () {
    test('脂肪、腰圍下降是好事；骨骼肌下降不是', () {
      expect(changeOf(BodyMetric.fatMass, -0.6), Change.better);
      expect(changeOf(BodyMetric.waist, -1.2), Change.better);
      expect(changeOf(BodyMetric.skeletalMuscle, -0.3), Change.worse);
      expect(changeOf(BodyMetric.skeletalMuscle, 0.2), Change.better);
    });

    test('體重不判好壞：增肌減脂時體重不一定會降', () {
      expect(changeOf(BodyMetric.weight, -0.8), Change.neutral);
      expect(changeOf(BodyMetric.weight, 0.5), Change.neutral);
    });

    test('小到顯示不出來的變化算持平', () {
      expect(changeOf(BodyMetric.fatMass, 0.04), Change.flat);
      expect(changeOf(BodyMetric.fatMass, -0.04), Change.flat);
    });
  });

  test('數值與變化量的顯示', () {
    expect(formatBodyValue(1580), '1580');
    expect(formatBodyValue(9), '9');
    expect(formatBodyValue(71.6), '71.6');
    expect(formatBodyDelta(-0.6), '−0.6');
    expect(formatBodyDelta(0.2), '+0.2');
    expect(formatBodyDelta(0.01), '持平');
  });

  test('每個項目的合理範圍都設對了', () {
    for (final m in BodyMetric.values) {
      expect(m.min, lessThan(m.max), reason: m.label);
    }
    // 「是體重的一部分」只該標在重量類項目上
    for (final m in BodyMetric.values.where((m) => m.partOfWeight)) {
      expect(m.unit, 'kg', reason: m.label);
    }
  });
}
