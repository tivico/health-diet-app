import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/domain/nutrition.dart';
import 'package:health/screens/calculation_screen.dart';

void main() {
  testWidgets('計算方式頁列出各項公式', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: CalculationScreen(
          profile: UserProfile(
            sex: Sex.male,
            age: 30,
            heightCm: 180,
            weightKg: 80,
            activity: ActivityLevel.moderate,
            goal: Goal.lose,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('計算方式'), findsOneWidget);
    expect(find.textContaining('BMR'), findsWidgets);
    expect(find.text('每日熱量目標'), findsOneWidget);
    expect(find.textContaining('每日飲水量'), findsWidgets);
    expect(find.textContaining('BMI'), findsWidgets);
  });
}
