# 資料庫與 Schema 變更指南

本專案是 **local-first**：所有資料都存在使用者自己的裝置（手機的 SQLite / 瀏覽器的
IndexedDB），**沒有伺服器**。這代表一件很重要的事：

> **資料庫升級只能發生在使用者的裝置上，而且只有一次機會。**
> 沒有「上線前先跑 migration 腳本」這種事 —— App 一開啟就會執行升級，
> 寫錯就是直接弄壞真人的資料。

所以任何 schema 變更都必須照下面的流程走。

---

## 目前的資料表

定義在 [`lib/data/database.dart`](../lib/data/database.dart)，目前 **schemaVersion = 3**。

| 資料表 | 用途 | 主鍵 |
|---|---|---|
| `UserProfiles` | 使用者基本資料（性別 / 年齡 / 身高 / 體重 / 體脂 / 活動量 / 目標 / 目標體重） | `id`（固定為 1，單一使用者） |
| `MealEntries` | 餐點紀錄（時間、名稱、熱量、三大營養素、餐別） | `id`（自動遞增） |
| `WeightEntries` | 體重紀錄，一天一筆 | `day`（當天午夜） |

`sex` / `activity` / `goal` / `mealType` 用 drift 的 `intEnum` 儲存，也就是**存 enum 的 index**。

> ⚠️ **因此 enum 的順序等同資料格式**：不可以在既有 enum 中間插入新值、
> 也不可以重新排序，只能往**最後面**加。否則舊資料會被解讀成別的意思。

---

## 版本升級是怎麼運作的

drift 在開啟資料庫時比對「檔案裡的版本」與「程式碼裡的 `schemaVersion`」：

| 情況 | drift 會做的事 |
|---|---|
| 資料庫不存在（新使用者） | 呼叫 `onCreate` → `m.createAll()` 依目前定義建表 |
| 檔案版本 < 程式碼版本（既有使用者升級） | 呼叫 `onUpgrade(m, from, to)` |
| 版本相同 | 什麼都不做，直接開啟 |

`onUpgrade` 採**逐版累加**寫法，因為使用者可能跳版升級
（例如很久沒更新，一次從 v1 跳到 v4）：

```dart
onUpgrade: (m, from, to) async {
  if (from < 2) {
    await m.addColumn(mealEntries, mealEntries.mealType);
  }
  if (from < 3) {
    await m.createTable(goals);
  }
  // 注意：用 if 而不是 else if，v1 的使用者要能一路跑完 2、3
}
```

---

## 改 schema 的標準流程

1. **修改 table 定義**（`lib/data/database.dart`）
2. **`schemaVersion` +1**
3. **在 `onUpgrade` 補上對應的 `if (from < 新版號) { ... }`**
4. **重新產生程式碼**
   ```powershell
   dart run build_runner build
   ```
5. **更新 repository、假 repo（`test/fake_repository.dart`）與備份格式**
6. **在 [`test/drift_migration_test.dart`](../test/drift_migration_test.dart) 加一條升級測試**
7. **留下 schema 快照**（給下一次的升級測試比對用）
   ```powershell
   dart run drift_dev schema dump lib/data/database.dart drift_schemas/
   ```
8. **`flutter analyze` + `flutter test`**
9. **實機驗證升級路徑**（見下方）

---

## 加欄位的注意事項

`addColumn` 對應 SQLite 的 `ALTER TABLE ADD COLUMN`，有兩個限制：

- 新欄位**必須是 nullable，或帶有預設值**（既有的列總得填點什麼）
- **不能加 primary key**，也不能改既有欄位的型別

實務上的選擇：

| 作法 | 既有資料會變成 | 適合的情境 |
|---|---|---|
| `.nullable()` | `null` | 舊資料「本來就沒有這個資訊」，例如餐別 → 顯示為「未分類」 |
| `.withDefault(...)` | 該預設值 | 有合理的預設語意，例如「是否啟用 = true」 |

**能用 nullable 就用 nullable** —— 硬塞一個預設值等於偽造使用者從來沒填過的資料。

至於**改欄位型別 / 改主鍵 / 刪欄位**，SQLite 不支援直接改，需要走
「建新表 → 搬資料 → 刪舊表 → 改名」。drift 提供 `m.alterTable(TableMigration(...))`
處理這件事，但風險高很多，動手前先確認真的無法用加欄位解決。

---

## 怎麼驗證升級沒壞

### 自動化 migration 測試

[`test/drift_migration_test.dart`](../test/drift_migration_test.dart) 會**真的建一個
舊版 schema 的 SQLite 檔案**、塞入「既有使用者」的資料，再用 `AppDatabase` 打開它，
確認 `onUpgrade` 有把資料完整帶上來：

- v1 → 最新版：個人資料 / 餐點 / 體重都在，新欄位為 null
- v2 → 最新版：已經標好的餐別不會被弄丟
- 升級後新欄位**寫得進去**（不是只讀得到 null）
- 版本相同時不會重跑升級

每條升級測試最後都會比對「升級後的欄位」與「全新安裝的欄位」是否一致 ——
這樣才能確定升級路徑跟 `onCreate` 收斂到同一個 schema，而不是各走各的。

> v1、v2 的舊 DDL 是**手寫重現**的（當時還沒開始留快照）。
> 上面那個「與全新安裝比對」的斷言就是用來確保重現得夠準。

### schema 快照（v3 起）

`drift_schemas/` 存放每一版的 schema 快照，由 `drift_dev schema dump` 產生。
之後版本變多時，可以用官方工具產生驗證用的輔助程式碼：

```powershell
dart run drift_dev schema generate drift_schemas/ test/drift_schemas/
```

### 整合測試（真實 SQL）

[`test/drift_repository_test.dart`](../test/drift_repository_test.dart) 用記憶體
SQLite 跑 `DriftHealthRepository`，涵蓋假 repo 測不到的部分：當日 `SUM` 加總
（含「沒有紀錄時是 0 而不是 NULL」）、日期區間的邊界、`intEnum` 的存取、
體重 upsert 的覆蓋行為、備份匯出入。

### 實機升級測試（仍然建議做）

自動化測試涵蓋不到真實裝置上的儲存層（Web 是 IndexedDB、行動平台是檔案）：

1. 改動**前**先用現有版本（例如線上 Demo）記幾筆餐點與體重
2. 部署新版後，在**同一個瀏覽器**重新整理（IndexedDB 會沿用，不要清除資料）
3. 確認：舊的餐點 / 體重 / 個人資料都還在，且新功能正常

> 使用者層還有一道安全網：App 內建**備份匯出 / 匯入**（今日分頁 → 💾）。
> 做有風險的 schema 變更前，可以先請使用者匯出一份。

---

## 版本紀錄

| 版本 | 內容 | 升級動作 |
|---|---|---|
| 1 | 初版：`UserProfiles` / `MealEntries` / `WeightEntries` | — |
| 2 | `MealEntries` 加入 `mealType`（餐別，nullable） | `addColumn`；既有餐點維持 `null` → 顯示「未分類」 |
| 3 | `UserProfiles` 加入 `targetWeightKg`（目標體重，nullable） | `addColumn`；既有使用者維持 `null` → 顯示設定引導 |

備份 JSON 的 `version` 跟著一起標（目前 3）。匯入時缺少後來才加的欄位
一律當作沒有，認不得的餐別名稱也一樣 ——
少一個標籤，總比整份備份匯不進來好。
