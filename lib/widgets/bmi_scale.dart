/// BMI 刻度條：把數字放回「過輕 / 健康 / 過重 / 肥胖」的區間裡看。
///
/// 單看一個 BMI 數字沒有感覺；畫成刻度尺並標出自己的位置，
/// 才知道離健康區間有多遠——也符合衛教頁「BMI 是參考，不是全部」的說法。
library;

import 'package:flutter/material.dart';

import '../theme.dart';

/// 刻度尺的顯示範圍（超出的值會貼齊兩端）。
const double _minBmi = 15;
const double _maxBmi = 32;

class BmiScale extends StatelessWidget {
  final double bmi;
  const BmiScale({super.key, required this.bmi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.palette;

    // (區間上界, 顏色)：與 bmiCategoryTaiwan 的分級一致。
    final bands = <(double, Color)>[
      (18.5, palette.carbs),
      (24.0, palette.success),
      (27.0, palette.warning),
      (_maxBmi, theme.colorScheme.error),
    ];

    final position =
        ((bmi.clamp(_minBmi, _maxBmi) - _minBmi) / (_maxBmi - _minBmi))
            .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return SizedBox(
              height: 26,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Row(
                        children: [
                          for (var i = 0; i < bands.length; i++)
                            Expanded(
                              // flex 依區間寬度分配，刻度才是等比例的
                              flex: (((bands[i].$1) -
                                          (i == 0 ? _minBmi : bands[i - 1].$1)) *
                                      10)
                                  .round(),
                              child: Container(height: 12, color: bands[i].$2),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // 目前 BMI 的位置標記：深色細柱 + 白邊，在任何色帶上都看得見
                  Positioned(
                    left: (width * position - 6).clamp(0.0, width - 12),
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 26,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: palette.surface, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        // 分界數字，對齊各區間的右緣
        Row(
          children: [
            for (var i = 0; i < bands.length; i++)
              Expanded(
                flex: (((bands[i].$1) - (i == 0 ? _minBmi : bands[i - 1].$1)) *
                        10)
                    .round(),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    i == bands.length - 1 ? '' : _tick(bands[i].$1),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static String _tick(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
