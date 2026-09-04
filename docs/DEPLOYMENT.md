# 部署說明

本專案目前透過 **GitHub Actions + GitHub Pages** 自動部署 Web 版。

🔗 線上網址：<https://tivico.github.io/health-diet-app/>

---

## 一、目前的部署架構

```
你在本機改程式
      │
      │  git push（推到 main）
      ▼
┌─────────────────────────────────────────┐
│           GitHub Actions                 │
│                                          │
│  ci.yml      → flutter analyze + test    │  守門：確認沒改壞
│  deploy.yml  → flutter build web         │  建置：產生靜態檔
│                 → 上傳 → 部署 Pages       │  發布
└─────────────────────────────────────────┘
      │
      ▼
  https://tivico.github.io/health-diet-app/
```

重點：**Flutter Web 編譯後就是一堆靜態檔案**（HTML / JS / wasm / 圖片），
GitHub Pages 只負責把這些檔案送給瀏覽器，**沒有任何後端在跑**。

---

## 二、首次設定（只需做一次）

1. Repo → **Settings → Pages**
2. **Build and deployment → Source** 選 **「GitHub Actions」**
   - ⚠️ 不要選 "Deploy from a branch"（那是舊式、直接發布分支檔案的模式；
     我們的網站要先 build 才存在，所以必須用 GitHub Actions）
3. 到 **Actions → Deploy to GitHub Pages → Run workflow** 手動跑一次
   （因為第一次自動跑時 Pages 還沒啟用）

設定完成後就不需要再碰了。

---

## 三、日常使用：改了東西怎麼上線

**什麼都不用做，push 就會自動部署。**

```bash
git add -A
git commit -m "feat: 你的修改"
git push
```

推上去之後：

| 時間 | 發生什麼 |
|---|---|
| 0 秒 | push 完成，兩個 workflow 同時啟動 |
| ~2 分鐘 | CI 跑完（analyze + 32 項測試） |
| ~2–3 分鐘 | Deploy 跑完，網站更新 |

> 💡 看到舊畫面？Flutter Web 有 service worker 快取，
> 按 **Ctrl + F5**（強制重新整理）即可。

### 手動觸發部署

不想改程式但想重新部署時：
**Actions → Deploy to GitHub Pages → Run workflow → Run workflow**

（workflow 裡有設 `workflow_dispatch` 就是為了這個。）

---

## 四、關鍵設定說明

### `--base-href` 一定要設

```yaml
flutter build web --release --base-href /health-diet-app/
```

因為 Pages 把網站掛在 `https://tivico.github.io/**health-diet-app**/` 這個
**子路徑**下，不是網域根目錄。沒設的話，所有資源會去根目錄找而全部 404。

> 如果之後改用自訂網域（掛在根目錄），要把它改成 `--base-href /`。

### drift 的 Web 資源

`web/sqlite3.wasm` 與 `web/drift_worker.js` 必須存在於版控中，
build 時會自動複製到 `build/web/`。少了它們，網站會開得起來但**資料庫初始化失敗**。

Pages 沒辦法設定 COOP/COEP 標頭，所以 drift 會自動退回 **IndexedDB** 模式
（與本機開發時相同），資料一樣存得住。

---

## 五、隱私說明（重要）

這是 **local-first** App：

- 每位訪客的資料存在**他自己瀏覽器**的 IndexedDB
- **沒有伺服器**，資料不會上傳、也不會互相看到
- 你本機的餐點與體重紀錄，不會因為網站公開而外流

---

## 六、其他平台（尚未設定）

| 平台 | 指令 | 前置需求 |
|---|---|---|
| Android APK | `flutter build apk --release` | Android SDK、簽章金鑰 |
| Android AAB（上架用） | `flutter build appbundle --release` | 同上 + Play Console |
| iOS | `flutter build ipa --release` | macOS + Xcode + Apple Developer 帳號 |

目前開發機尚未安裝 Android SDK，因此這些流程還沒建立。

---

## 七、GitHub Pages vs Docker 部署

### 先釐清：這兩個不是同一類東西

| | GitHub Pages | Docker |
|---|---|---|
| **本質** | 一種**靜態檔案託管服務** | 一種**打包與執行技術** |
| **提供什麼** | 直接給你一個網址 | 只給你「可執行的容器」，**還需要一台機器來跑它** |

所以嚴格來說是「**Pages** vs **Docker + 一台主機**」的比較。

### 比較表

| 面向 | GitHub Pages | Docker（＋雲端主機 / VPS） |
|---|---|---|
| 能跑後端程式 | ❌ 不行，只有靜態檔 | ✅ 可以（API、資料庫、模型推論、排程） |
| 費用 | 公開 repo **免費** | 需要主機費用（部分平台有免費額度，條件常變動） |
| 維運負擔 | **零**，GitHub 全包 | 要自己顧：系統更新、安全性、監控、備份 |
| HTTPS 憑證 | 自動、免費 | 要自己設（Nginx / Caddy + Let's Encrypt） |
| 部署速度 | push → 約 2–3 分鐘 | 依設定，通常也是數分鐘 |
| 環境一致性 | 不適用 | ✅ 強項：徹底解決「在我電腦上明明可以跑」 |
| 擴充性 | 靜態內容無限，但**只能靜態** | ✅ 想加什麼服務都行 |
| 學習價值 | 低（很簡單） | 高（DevOps 基礎能力） |
| **適合本專案嗎** | ✅ **現階段最適合** | ⏳ 之後有後端需求再說 |

### 為什麼本專案現在用 Pages 就夠

這個 App 是 **local-first、純前端**：

- 資料存瀏覽器，沒有伺服器要跑
- 編譯產物就是一包靜態檔
- 用 Docker 等於「租一台機器、裝 nginx、只為了發送幾個靜態檔」——
  能做，但沒有帶來任何 Pages 給不了的好處，還多了費用與維運

### 什麼時候該改用 Docker？

出現以下任一需求時，就值得換：

1. **自架後端 API**（例如不用 Supabase，自己寫使用者系統）
2. **伺服器端跑食物辨識模型**（模型太大不適合放手機端時）
3. **需要資料庫**（PostgreSQL 等）與 App 一起部署
4. **背景排程工作**（每日統計、推播通知）
5. 想學 / 想展示 **DevOps 能力**（作品集加分）

### 如果哪天要 Docker 化，大概長這樣

```dockerfile
# ---- 階段一：建置 ----
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web --release

# ---- 階段二：只留靜態檔，塞進輕量 nginx ----
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
```

```bash
docker build -t health-diet-app .
docker run -p 8080:80 health-diet-app   # 開 http://localhost:8080
```

> 🔑 **關鍵洞察**：注意第二階段裡面「只有 nginx + 那包靜態檔」——
> 跟 GitHub Pages 幫你託管的**完全是同一批檔案**。
> 差別只在於「**誰負責把檔案送出去、誰負責顧那台機器**」。
> 這也是為什麼純前端專案用 Pages 是最划算的選擇。

### 中間選項（介於兩者之間）

如果之後只需要「一點點後端」，不必直接跳到 Docker：

| 服務 | 特性 |
|---|---|
| **Vercel / Netlify / Cloudflare Pages** | 靜態託管 + serverless 函式，免維運 |
| **Firebase Hosting** | 靜態託管 + Cloud Functions |
| **Supabase** | 託管的 PostgreSQL + 認證 + API（本專案 README 提到的未來選項） |

---

## 八、常見問題排查

| 症狀 | 可能原因 | 解法 |
|---|---|---|
| 網址 404 | Pages 的 Source 沒設成 GitHub Actions | 見「首次設定」 |
| 頁面白畫面、資源 404 | `--base-href` 沒設或設錯 | 檢查 deploy.yml 的 base-href 是否為 `/health-diet-app/` |
| App 開得起來但資料存不了 | `sqlite3.wasm` / `drift_worker.js` 沒被打包 | 確認兩個檔案在 `web/` 且有進版控 |
| 看到的還是舊版 | service worker 快取 | `Ctrl + F5` 強制重新整理 |
| Deploy workflow 失敗 | 權限或 Pages 未啟用 | 看 Actions 的錯誤訊息；確認 Settings → Pages → Source |
