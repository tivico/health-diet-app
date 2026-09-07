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

/// 一篇文章的資料來源。
///
/// 衛教內容要能被查證才有份量，所以每篇都附出處：以台灣官方指引（衛福部 /
/// 國健署）為主，需要實證支持的說法再補上同儕審查的文獻。
/// [note] 寫的是「這個來源支持文中哪一句」，讓來源不只是裝飾。
class ArticleSource {
  /// 來源名稱（機構出版品，或「作者 等，期刊，年份」）。
  final String title;

  /// 這個來源支持文中的哪個說法。
  final String note;

  final String url;

  const ArticleSource({
    required this.title,
    required this.note,
    required this.url,
  });
}

class Article {
  final String id;
  final ArticleCategory category;
  final String title;
  final String summary;

  /// 內文；段落之間以兩個換行分隔。
  final String body;

  /// 資料來源，依「台灣官方 → 國際文獻」排序。
  final List<ArticleSource> sources;

  const Article({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.body,
    this.sources = const [],
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
    sources: [
      ArticleSource(
        title: '衛生福利部國民健康署－成人健康體位標準',
        note: '我國 18 歲以上成人 BMI 分級：過輕 <18.5、健康 18.5–24、過重 24–27、肥胖 ≥27。',
        url: 'https://www.hpa.gov.tw/Pages/Detail.aspx?nodeid=542&pid=9737',
      ),
      ArticleSource(
        title: 'World Health Organization－Obesity and overweight (fact sheet)',
        note: 'WHO 明言 BMI 只是體脂肪的「替代指標」（surrogate marker），'
            '診斷肥胖時可再搭配腰圍等測量。',
        url: 'https://www.who.int/news-room/fact-sheets/detail/obesity-and-overweight',
      ),
    ],
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
    sources: [
      ArticleSource(
        title: 'Orsama AL 等，Obesity Facts，2014;7(1):36–47',
        note: '追蹤 80 位成人共 4,657 筆每日體重，發現體重有穩定的「週節律」'
            '（週末上升、平日下降），屬正常波動而非脂肪增減。',
        url: 'https://karger.com/ofa/article/7/1/36/240088/',
      ),
    ],
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
    sources: [
      ArticleSource(
        title: 'Gardner CD 等，JAMA，2018（DIETFITS 隨機對照試驗）',
        note: '609 位過重成人隨機分派健康低脂或健康低碳飲食 12 個月，'
            '兩組體重變化沒有顯著差異（−5.3 vs −6.0 公斤）。',
        url: 'https://jamanetwork.com/journals/jama/fullarticle/2673150',
      ),
      ArticleSource(
        title: '衛生福利部國民健康署－每日飲食建議量',
        note: '官方均衡飲食把「全穀雜糧類」列為六大類食物之一並訂有建議份數，'
            '而非應該避免的食物。',
        url: 'https://www.hpa.gov.tw/Pages/Detail.aspx?nodeid=544&pid=728',
      ),
    ],
  ),
  Article(
    id: 'myth-spot-reduction',
    category: ArticleCategory.myth,
    title: '局部瘦身做得到嗎？',
    summary: '脂肪是全身性消耗，無法指定某部位先瘦。',
    body: '「狂做仰臥起坐就能瘦肚子」是常見迷思。實驗把受試者分成「只做腹部訓練」'
        '與「不訓練」兩組、飲食熱量相同，六週後兩組的腹部脂肪沒有差別；'
        '另一個設計更巧妙的研究讓受試者只訓練單腳，結果訓練腳的脂肪也沒有掉得比較多。\n\n'
        '針對特定部位的運動能強化該處的肌肉，但要減脂，仍取決於整體的熱量平衡'
        '與全身性活動。\n\n'
        '（近年有少數研究認為特定條件下可能有極小幅度的局部效果，學界尚無定論；'
        '但可以確定的是，那個幅度遠不足以取代整體熱量管理。）\n\n'
        '想要線條好看：以飲食控制為主來「減脂」，搭配阻力訓練來「增肌」，'
        '雙管齊下效果最好。',
    sources: [
      ArticleSource(
        title: 'Vispute SS 等，J Strength Cond Res，2011;25(9):2559–2564',
        note: '腹部訓練組（每週 5 天、共 6 週）與對照組在相同熱量下，'
            '腹部脂肪與腰圍皆無顯著差異。',
        url: 'https://pubmed.ncbi.nlm.nih.gov/21804427/',
      ),
      ArticleSource(
        title: 'Ramírez-Campillo R 等，J Strength Cond Res，2013;27(8):2219–2224',
        note: '受試者只以非慣用腳訓練 12 週，訓練腳的區域脂肪並未比未訓練腳'
            '減少更多，支持脂肪為全身性消耗。',
        url: 'https://pubmed.ncbi.nlm.nih.gov/23222084/',
      ),
    ],
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
    sources: [
      ArticleSource(
        title: 'Fothergill E 等，Obesity，2016;24:1612–1619',
        note: '極端減重競賽的參賽者六年後平均復胖 41 公斤，'
            '靜息代謝率仍比基期低約 704 大卡／天，顯示代謝適應會持續存在。',
        url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC4989512',
      ),
      ArticleSource(
        title: '衛生福利部國民健康署－成人肥胖防治實證指引',
        note: '以 GRADE 評定證據等級的官方指引，涵蓋成人過重／肥胖的評估與'
            '飲食、運動、心理介入，供臨床工作者參考。',
        url: 'https://www.hpa.gov.tw/Pages/EBook.aspx?nodeid=1788',
      ),
    ],
  ),

  // ===== 飲食基礎 =====
  Article(
    id: 'diet-calorie-deficit',
    category: ArticleCategory.diet,
    title: '熱量赤字：減脂的核心',
    summary: '攝取 < 消耗就會減重；小赤字、長期累積最實際。',
    body: '體重管理的底層邏輯是能量收支：攝取 < 消耗會減重、> 會增重、≈ 則維持。\n\n'
        '常見的換算是「每累積 7700 大卡赤字 ≒ 減 1 公斤」。這個數字方便估算，'
        '但要知道它是簡化過的：實際減下來的不只有脂肪，而且體重下降後代謝也會跟著下降，'
        '所以真正需要的時間通常比線性推算來得久。把它當方向，不要當保證。\n\n'
        '也因此「每天小赤字、長期累積」會比激烈節食更實際也更安全。\n\n'
        '做法：先用 App 估出你的 TDEE 與每日目標，記錄幾天餐點後對照實際結果，'
        '再微調。重點始終是——可持續。',
    sources: [
      ArticleSource(
        title: 'Hall KD，Int J Obes，2008',
        note: '指出「固定熱量換算固定體重」的經驗法則過度簡化：'
            '減重同時會流失部分非脂肪組織，所需赤字因人而異。',
        url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC2376744',
      ),
      ArticleSource(
        title: '衛生福利部國民健康署－成人肥胖防治實證指引',
        note: '以 GRADE 評定證據等級的官方指引，肥胖介入章節涵蓋飲食與運動。',
        url: 'https://www.hpa.gov.tw/Pages/EBook.aspx?nodeid=1788',
      ),
    ],
  ),
  Article(
    id: 'diet-protein',
    category: ArticleCategory.diet,
    title: '蛋白質為什麼重要',
    summary: '減脂期足夠蛋白質能保留肌肉、增加飽足感。',
    body: '在減脂期，足夠的蛋白質能幫助保留肌肉、增加飽足感，並提高食物的熱效應'
        '（消化吸收本身也會消耗熱量）。\n\n'
        '一般活動者大約每公斤體重 1.2–1.6 克；有做阻力訓練或正在減脂者可再高一些——'
        '統合分析顯示增肌效益大約在每公斤 1.6 克附近就達到高原，'
        '再往上加沒有明顯額外好處（信賴區間上緣約 2.2 克）。'
        '常見來源有豆、魚、蛋、肉與乳製品。\n\n'
        '本 App 會依你的目標，自動把蛋白質目標訂得高一些。',
    sources: [
      ArticleSource(
        title: '衛生福利部國民健康署－國人膳食營養素參考攝取量（DRIs）第八版',
        note: '我國官方的蛋白質建議攝取量基準（含蛋白質專章）。',
        url: 'https://www.hpa.gov.tw/Pages/Detail.aspx?nodeid=4248&pid=12285',
      ),
      ArticleSource(
        title: 'Morton RW 等，Br J Sports Med，2018;52(6):376–384',
        note: '49 篇研究、1,863 位受試者的統合分析：蛋白質對阻力訓練增肌的效益'
            '在每公斤約 1.62 克達到高原。',
        url: 'https://pubmed.ncbi.nlm.nih.gov/28698222/',
      ),
    ],
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
        '偶爾吃了「破戒」的一餐並不會毀掉一切，重點是整體與長期。\n\n'
        '這不只是心理安慰：研究把飲食控制分成「彈性」與「僵化」兩種型態，'
        '僵化的全有全無式節食反而和更容易失控暴食、體重控制較差有關；'
        '彈性控制則與較低的 BMI 與較高的減重成功率有關。',
    sources: [
      ArticleSource(
        title: 'Westenhoefer J 等，Int J Eat Disord，1999;26(1):53–64',
        note: '建立並驗證「彈性 / 僵化」飲食控制量表：僵化控制與較高 BMI、'
            '更頻繁的暴食相關；彈性控制與較好的體重控制相關。',
        url: 'https://pubmed.ncbi.nlm.nih.gov/10349584/',
      ),
      ArticleSource(
        title: '衛生福利部－國健署首度公布國人「我的餐盤」（新聞稿）',
        note: '官方以「菜比水果多一點、飯跟蔬菜一樣多」等比例口訣推廣均衡飲食，'
            '訴求份量比例而非禁止特定食物。',
        url: 'https://www.mohw.gov.tw/cp-3794-41108-1.html',
      ),
    ],
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
        '・衛福部安心專線：1925（依舊愛我，24 小時免付費心理支持）\n'
        '・生命線：1995\n'
        '・張老師專線：1980\n\n'
        '本 App 不提供醫療診斷；遇到困擾，請諮詢專業人員。',
    sources: [
      ArticleSource(
        title: '衛生福利部心理健康司－全國諮詢及救援服務專線',
        note: '官方公告的求助專線：安心專線 1925、生命線 1995、張老師 1980。',
        url: 'https://dep.mohw.gov.tw/DOMHAOH/cp-327-8715-107.html',
      ),
      ArticleSource(
        title: 'NICE guideline NG69－Eating disorders: recognition and treatment',
        note: '英國國家健康與照護卓越研究院的飲食障礙指引：'
            '強調及早辨識與轉介專業治療，本文的警訊描述依此改寫為衛教語言。',
        url: 'https://www.nice.org.uk/guidance/ng69',
      ),
    ],
  ),
];
