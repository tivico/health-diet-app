/// 客製化健康建議：把使用者資料與營養計畫，轉成「怎麼吃 / 動 / 喝水 / 睡」等
/// 可執行的行動建議。純邏輯、無 UI 相依，方便測試。
///
/// 內容皆為一般性衛教建議，非醫療處方。
library;

import 'nutrition.dart';

class AdviceSection {
  final String title;
  final String headline;
  final List<String> points;

  const AdviceSection({
    required this.title,
    required this.headline,
    required this.points,
  });
}

/// 依使用者資料與營養計畫產生建議區塊。
List<AdviceSection> buildAdvice(UserProfile p, NutritionPlan plan) {
  return [
    AdviceSection(
      title: '你的重點',
      headline: _focusHeadline(plan.bmiCategory),
      points: _focusPoints(p, plan),
    ),
    AdviceSection(
      title: '怎麼吃',
      headline:
          '每天約 ${plan.calorieTarget.round()} 大卡、蛋白質約 ${plan.macros.proteinG.round()} 克',
      points: _eatingPoints(p),
    ),
    AdviceSection(
      title: '怎麼動',
      headline: '每週至少 150 分鐘活動 + 阻力訓練',
      points: _exercisePoints(p),
    ),
    AdviceSection(
      title: '喝水',
      headline: '每天約 ${_waterMl(p.weightKg)} c.c.',
      points: const [
        '以白開水為主，取代含糖飲料',
        '運動或天氣熱時再增加',
        '分散全天小口補充，別一次灌',
      ],
    ),
    AdviceSection(
      title: '睡覺',
      headline: '每天睡足 7–9 小時',
      points: const [
        '睡不夠會讓飢餓素上升、更想吃',
        '固定作息、睡前少滑手機',
        '好睡眠是體重管理的隱形夥伴',
      ],
    ),
  ];
}

/// 依體重估算每日建議飲水量（約 33 c.c./公斤，取整到百位）。此為粗略參考值。
int _waterMl(double kg) => (kg * 33 / 100).round() * 100;

String _focusHeadline(String bmiCategory) => switch (bmiCategory) {
      '過輕' => '健康增重，別過度限制',
      '過重' || '肥胖' => '溫和、可持續地調整',
      _ => '維持現在的好習慣',
    };

List<String> _focusPoints(UserProfile p, NutritionPlan plan) {
  final points = <String>[];
  switch (p.goal) {
    case Goal.lose:
      points.add('以溫和的熱量赤字慢慢減，不要極端節食');
      points.add('搭配運動比只靠少吃更能保留肌肉');
      points.add('看「週趨勢」，別被單日體重影響心情');
    case Goal.gain:
      points.add('吃得比消耗略多，並攝取足夠蛋白質');
      points.add('用阻力訓練把多吃的轉成肌肉');
      points.add('增重同樣要循序漸進');
    case Goal.maintain:
      points.add('維持規律的飲食與運動即可');
      points.add('偶爾放縱沒關係，重點是長期習慣');
  }
  if (plan.bmiCategory == '過重' || plan.bmiCategory == '肥胖') {
    points.add('以健康為目標、別急於求成');
  } else if (plan.bmiCategory == '過輕') {
    points.add('別怕吃，重點是營養密度與肌肉量');
  }
  return points;
}

List<String> _eatingPoints(UserProfile p) {
  final points = <String>[];
  switch (p.goal) {
    case Goal.lose:
      points.add('這是「溫和赤字」，不是挨餓');
    case Goal.gain:
      points.add('可少量多餐，幫助吃夠熱量');
    case Goal.maintain:
      points.add('均衡分配三餐');
  }
  points.add('原型食物為主，多蔬菜與纖維增加飽足');
  points.add('減少含糖飲料與精緻點心');
  points.add('細嚼慢嚥、七八分飽');
  return points;
}

List<String> _exercisePoints(UserProfile p) {
  final points = <String>[];
  if (p.activity == ActivityLevel.sedentary ||
      p.activity == ActivityLevel.light) {
    points.add('先從每天散步、多起身走動開始，再慢慢加量');
  }
  switch (p.goal) {
    case Goal.lose:
      points.add('有氧（快走 / 慢跑 / 騎車）幫助消耗');
      points.add('阻力訓練每週 2–3 次，減脂時保留肌肉');
    case Goal.gain:
      points.add('以阻力訓練為主，每週 3–4 次、漸進加重');
      points.add('有氧適量即可，別抵銷增肌所需熱量');
    case Goal.maintain:
      points.add('有氧與肌力訓練均衡搭配');
  }
  points.add('目標每天 7,000–10,000 步');
  return points;
}
