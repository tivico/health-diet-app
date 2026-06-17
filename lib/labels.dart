/// 把 domain 列舉轉成中文顯示字串（展示層用，與計算邏輯分開）。
library;

import 'domain/nutrition.dart';

String sexLabel(Sex s) => s == Sex.male ? '男' : '女';

String activityLabel(ActivityLevel a) => switch (a) {
      ActivityLevel.sedentary => '久坐（幾乎不運動）',
      ActivityLevel.light => '輕度（每週運動 1–3 天）',
      ActivityLevel.moderate => '中度（每週運動 3–5 天）',
      ActivityLevel.active => '高度（每週運動 6–7 天）',
      ActivityLevel.veryActive => '極高（體力勞動／一天兩練）',
    };

String goalLabel(Goal g) => switch (g) {
      Goal.lose => '減脂',
      Goal.maintain => '維持體重',
      Goal.gain => '增肌',
    };
