/// 衛教內容（靜態精選文章）。
///
/// 這些是一般性的健康/營養衛教資訊，**非醫療診斷**；
/// 內容刻意強調「健康、可持續、不極端」與身心健康，呼應 App 的責任設計。
library;

enum ArticleCategory { concept, myth, diet, safety }

String categoryLabel(ArticleCategory c) => switch (c) {
      ArticleCategory.concept => '正確觀念',
      ArticleCategory.myth => '迷思破解',
      ArticleCategory.diet => '飲食基礎',
      ArticleCategory.safety => '身心健康',
    };

class Article {
  final String id;
  final ArticleCategory category;
  final String title;
  final String summary;

  /// 內文；段落之間以兩個換行分隔。
  final String body;

  const Article({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.body,
  });
}

const List<Article> educationArticles = [
  // ===== 正確觀念 =====
  Article(
    id: 'bmi-is-a-reference',
    category: ArticleCategory.concept,
    title: 'BMI 是參考，不是全部',
    summary: 'BMI 方便但有侷限，搭配體脂、腰圍與健康指標一起看。',
    body: 'BMI 用身高與體重估算，方便快速，但有它的盲點：它分不出脂肪與肌肉，'
        '肌肉量高的人 BMI 可能偏高，卻很健康；它也沒考慮脂肪分布與年齡差異。\n\n'
        '台灣以 BMI 18.5–24 為健康範圍，但請把它當成「方向」而非唯一標準，'
        '搭配體脂率、腰圍、體能與健康檢查數值一起看，會更貼近真實狀況。\n\n'
        '最重要的是：不要為了讓 BMI 數字好看而採取激烈手段。健康是長期的事。',
  ),
  Article(
    id: 'weight-fluctuates',
    category: ArticleCategory.concept,
    title: '體重會自然波動，別被單日數字綁架',
    summary: '一天上下 1–2 公斤多是水分，看「週趨勢」才準。',
    body: '一天之內體重上下浮動 1–2 公斤是很正常的，主因是水分、鹽分、肝醣存量、'
        '排便與女性生理週期，並不是脂肪真的增減。\n\n'
        '脂肪的變化通常要以「週」為單位才看得準。建議在固定條件下量測'
        '（例如早晨起床、如廁後、空腹），並觀察「週平均」與長期趨勢。\n\n'
        '本 App 的體重趨勢圖就是為此設計——看曲線方向，而不是糾結單日數字。',
  ),

  // ===== 迷思破解 =====
  Article(
    id: 'myth-no-carbs',
    category: ArticleCategory.myth,
    title: '不吃澱粉就會瘦？破解碳水迷思',
    summary: '減重關鍵是整體熱量赤字，不是單一營養素。',
    body: '減重的關鍵是「整體熱量赤字」，而不是完全不碰某一種營養素。\n\n'
        '低碳或生酮初期體重下降較快，但很大一部分是肝醣與水分流失，不全是脂肪。'
        '完全不吃澱粉很難長期維持，還可能影響運動表現、專注力與情緒。\n\n'
        '比較務實的做法：選擇全穀與原型澱粉、控制總量，而不是「完全戒除」。'
        '可持續，才有意義。',
  ),
  Article(
    id: 'myth-spot-reduction',
    category: ArticleCategory.myth,
    title: '局部瘦身做得到嗎？',
    summary: '脂肪是全身性消耗，無法指定某部位先瘦。',
    body: '「狂做仰臥起坐就能瘦肚子」是常見迷思。脂肪的消耗是全身性的，'
        '身體不會因為你練某個部位就「優先」消耗那裡的脂肪。\n\n'
        '針對特定部位的運動能強化該處的肌肉，但要減脂，仍取決於整體的熱量平衡'
        '與全身性活動。\n\n'
        '想要線條好看：以飲食控制為主來「減脂」，搭配阻力訓練來「增肌」，'
        '雙管齊下效果最好。',
  ),
  Article(
    id: 'myth-crash-diet',
    category: ArticleCategory.myth,
    title: '極端節食為什麼常失敗',
    summary: '溜溜球效應的根源；溫和赤字才留得住成果。',
    body: '極端低熱量（例如一天只吃幾百大卡）短期掉重很快，但代價不小：'
        '容易流失肌肉、代謝適應、情緒與專注力下降，而且極難長期維持，'
        '常以「報復性進食」收場——這就是溜溜球效應。\n\n'
        '比較有效的是「溫和赤字」：大約每日總消耗（TDEE）減少 10–20%，'
        '搭配足夠的蛋白質與阻力訓練。慢一點，但成果留得住。\n\n'
        '這也是為什麼本 App 的每日熱量目標設有「安全下限」——不鼓勵極端節食。',
  ),

  // ===== 飲食基礎 =====
  Article(
    id: 'diet-calorie-deficit',
    category: ArticleCategory.diet,
    title: '熱量赤字：減脂的核心',
    summary: '攝取 < 消耗就會減重；小赤字、長期累積最實際。',
    body: '體重管理的底層邏輯是能量收支：攝取 < 消耗會減重、> 會增重、≈ 則維持。\n\n'
        '大約每累積 7700 大卡的赤字，對應約 1 公斤脂肪。因此「每天小赤字、'
        '長期累積」會比激烈節食更實際也更安全。\n\n'
        '做法：先用 App 估出你的 TDEE 與每日目標，記錄幾天餐點後對照實際結果，'
        '再微調。重點始終是——可持續。',
  ),
  Article(
    id: 'diet-protein',
    category: ArticleCategory.diet,
    title: '蛋白質為什麼重要',
    summary: '減脂期足夠蛋白質能保留肌肉、增加飽足感。',
    body: '在減脂期，足夠的蛋白質能幫助保留肌肉、增加飽足感，並提高食物的熱效應'
        '（消化吸收本身也會消耗熱量）。\n\n'
        '一般活動者大約每公斤體重 1.2–1.6 克；有運動或正在減脂者，可拉高到'
        '約 1.6–2.2 克。常見來源有豆、魚、蛋、肉與乳製品。\n\n'
        '本 App 會依你的目標，自動把蛋白質目標訂得高一些。',
  ),
  Article(
    id: 'diet-flexible',
    category: ArticleCategory.diet,
    title: '彈性飲食：80/20 原則',
    summary: '八成原型食物、兩成喜歡的食物，兼顧營養與心理。',
    body: '健康飲食不必非黑即白。「80/20 原則」是指大約八成的時候選擇營養密度高的'
        '原型食物，留兩成的空間給自己喜歡的食物。\n\n'
        '這樣能同時兼顧營養與「心理上的可持續性」——把焦點放在整體飲食模式，'
        '而不是單獨一餐的對與錯。\n\n'
        '偶爾吃了「破戒」的一餐並不會毀掉一切，重點是整體與長期。',
  ),

  // ===== 身心健康（重要、謹慎）=====
  Article(
    id: 'safety-disordered-eating',
    category: ArticleCategory.safety,
    title: '當飲食控制變成壓力：認識飲食障礙與求助',
    summary: '飲食控制應是健康工具，不是懲罰。出現警訊請尋求專業協助。',
    body: '飲食控制應該是讓你更健康、更有彈性的工具，而不是焦慮或懲罰的來源。\n\n'
        '如果出現以下情況，請特別留意：對體重或體型過度執著到影響日常生活與情緒、'
        '極度限制進食、暴食後用催吐或過量運動來「補償」、因為吃東西而產生強烈罪惡感、'
        '刻意逃避與人聚餐。這些可能是飲食障礙（如厭食症、暴食症）的徵兆。\n\n'
        '飲食障礙是需要被認真對待的健康議題，與「意志力」無關。你的體重，'
        '不等於你的價值。\n\n'
        '如果你或身邊的人正為此困擾，尋求專業協助（身心科／精神科醫師、'
        '臨床心理師、營養師）是勇敢而有效的一步。\n\n'
        '台灣求助資源：\n'
        '・衛福部安心專線：1925（24 小時免費心理支持）\n'
        '・生命線：1995\n\n'
        '本 App 不提供醫療診斷；遇到困擾，請諮詢專業人員。',
  ),
];
