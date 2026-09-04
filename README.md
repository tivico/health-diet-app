# 健康飲控 App（專案開發中）

[![CI](https://github.com/tivico/health-diet-app/actions/workflows/ci.yml/badge.svg)](https://github.com/tivico/health-diet-app/actions/workflows/ci.yml)
[![Deploy](https://github.com/tivico/health-diet-app/actions/workflows/deploy.yml/badge.svg)](https://github.com/tivico/health-diet-app/actions/workflows/deploy.yml)

🔗 **線上 Demo**：<https://tivico.github.io/health-diet-app/>　｜　📄 **[部署說明](docs/DEPLOYMENT.md)**
> 打開就能直接試用。資料只存在**你自己的瀏覽器**（local-first），不會上傳到任何伺服器。

> 拍照記錄三餐、估算熱量與營養素，依個人資料（身高 / 體重 / 體脂 / 活動量）算出
> 每日目標，並提供正確的體重與體態衛教。面向台灣一般想減重 / 做飲食控制的大眾。

這是一個以「**好維護、可長期演進**」為原則的個人專案 / 作品集。

**目前定位**：自用與親友試用；食物辨識採**自建的開源模型**（不依賴付費 API）。
待功能夠深入、夠穩定後，再考慮商業化。

## 設計原則（為什麼這樣選）

1. **單一程式碼** — 用 Flutter 一套碼涵蓋 Android / iOS / Web，少一套要維護。
2. **本地優先（local-first）** — 資料存在手機本地，**沒有伺服器要顧**，維護負擔最低。
3. **辨識模組可抽換** — 最難的食物辨識藏在一個乾淨介面後面，將來要換實作不影響其他部分。

## 系統架構

```
┌────────────────────────────────────────────────┐
│             Flutter App（單一程式碼）             │
│               Android / iOS / Web                 │
│                                                   │
│   UI：底部導覽（今日 / 體重 / 衛教）+ Riverpod      │
│   業務邏輯（Dart）                                │
│   ├─ 營養計算（BMR / TDEE / 目標 / 營養素 / BMI）  │
│   ├─ 食物辨識模組（介面）──▶ 手機端開源模型        │
│   └─ HealthRepository ──▶ drift（SQLite / WASM）   │
└────────────────────────────────────────────────┘
          （未來若需朋友間同步 → 託管 Supabase，可選）
```

## 技術棧

| 層 | 技術 |
|---|---|
| App 框架 | Flutter（Dart）— 一套碼跑 Android / iOS / Web |
| 狀態管理 | Riverpod（`flutter_riverpod`） |
| 本地資料庫 | drift（SQLite；行動平台原生、Web 走 WASM + IndexedDB） |
| 圖表 | `fl_chart`（體重趨勢） |
| 食物辨識 | 手機端開源模型（`tflite_flutter` / ONNX，介面可抽換）— 待開發 |
| 雲端（可選 / 未來） | Supabase（託管；朋友間同步時才用） |

## 開發路線圖

**第一階段：App 骨架與核心（完成）**
- [x] `flutter create` 專案，能在 Chrome 預覽跑起來
- [x] 營養計算邏輯（移植成 Dart + 單元測試）
- [x] 引導設定流程（身高 / 體重 / 體脂 / 活動量 / 目標）
- [x] 每日目標儀表板（熱量 + 三大營養素）
- [x] 本地資料庫（drift；資料持久化、reactive、跨 Web + 行動）

**第二階段：記錄與視覺化（完成）**
- [x] 餐點記錄（手動）+ 今日追蹤（目標 vs 已吃 vs 剩餘）
- [x] 體重記錄 + 趨勢圖（`fl_chart`）
- [x] 衛教知識（正確觀念 / 迷思破解 / 飲食基礎 / 身心健康，含求助資源）
- [x] 底部導覽（今日 / 體重 / 統計 / 衛教）

**第三階段：拍照辨識**
- [ ] 拍照 → 手機端開源模型辨識 → 熱量查表 → 使用者調整份量

**第四階段：加值（功能穩定後）**
- [x] 切換日期看歷史（看任一天的餐點與加總）
- [x] 編輯餐點（點清單項目即可修改）
- [x] 常用食物快選（台灣在地食物庫，約 50 樣）
- [x] 週 / 月統計（每日熱量長條圖、平均攝取、達標天數、體重變化）
- [ ] 提醒推播、（之後）Supabase 同步

## 功能現況

- **今日**：熱量圓環（目標 / 已吃 / 剩餘）、三大營養素、記錄 / 編輯 / 刪除餐點（可復原、可從**台灣食物庫**快選）、切換日期看歷史。
- **體重**：記錄體重 / 體脂，**可補記過去日期**，近 90 天趨勢折線圖。
- **統計**：近 7 / 30 天每日熱量長條圖（含目標虛線）、平均攝取、有記錄天數、達標天數、體重變化。
- **衛教**：分類文章，含破除迷思與飲食障礙識別 + 台灣求助專線。
- **健康建議**：填完資料後給客製化的「怎麼吃 / 動 / 睡 / 喝水」行動建議（也可隨時再看）+ 計算公式透明呈現。
- **備份**：一鍵把所有資料匯出成文字（複製保存），貼回即可還原（跨裝置搬家、防資料遺失）。
- **外觀**：深色模式跟隨系統；介面為繁體中文（含日期選擇器）；自訂 App 圖示與名稱「健康飲控」。

## 安全與責任設計

- **熱量下限**：每日目標設有安全下限（女 1200 / 男 1500 大卡），不鼓勵極端節食。
- **估算非精準**：拍照熱量為估算值，份量由使用者調整，僅供方向性參考。
- **非醫療建議**：本 App 不取代專業醫療或營養師診斷；衛教內含求助資源。

## 開發進度

- ✅ 三大分頁（今日 / 體重 / 衛教）皆可用；資料本地持久化、跨 Web + 行動
- ✅ Git 版控；**18 項測試全過**（單元 + Widget 流程測試）
- 🔨 下一步：拍照辨識（需 Android SDK + 實體手機）或功能深化

## 開發指令

```powershell
flutter test                                          # 跑單元 / Widget 測試
flutter run -d chrome --web-port=8081                 # 在 Chrome 預覽（含熱重載）
flutter analyze                                       # 靜態檢查
dart run build_runner build                           # 改 drift schema 後重新產生程式碼
dart run tool/generate_icon.dart                      # 重新產生各平台 App 圖示
```

> **Web 須知**：drift 在 Web 需要 `web/sqlite3.wasm` 與 `web/drift_worker.js`
> 兩個靜態資源（已隨專案附上，版本對應 drift 2.34 / sqlite3 3.3.3）。
