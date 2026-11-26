# 資安說明：對外連線白名單

本專案是 **local-first**：所有紀錄只存在使用者自己的裝置，沒有伺服器，App 裡也沒有任何上傳資料的程式。
所以「資料在傳輸途中或伺服器上被偷」這類風險本來就不存在，剩下最主要的風險是：

> **放進 App 裡的第三方程式**。同一個網頁裡的程式共用同一份權限，
> 只要其中一個套件有惡意（或被人掉包），它就讀得到所有紀錄，還能偷偷傳出去。
> 這種從套件下手的攻擊叫「供應鏈攻擊」。

防線有兩道：**慎選套件**（見最後一節），以及這份文件的主角——**對外連線白名單**。

---

## 白名單是什麼

正式版的 `index.html` 裡有一條內容安全政策（Content Security Policy，CSP），
告訴瀏覽器：這個頁面只准從下列來源載入檔案、或把資料送出去，其餘一律擋下。
就算某個套件被植入惡意程式，也沒辦法把紀錄傳到別的網站。

| 來源 | 用途 |
|---|---|
| 本站（`'self'`） | App 本體、`sqlite3.wasm`、`drift_worker.js`、圖示 |
| `https://www.gstatic.com/flutter-canvaskit/` | Google 提供的 Flutter 繪圖引擎（CanvasKit） |
| `https://fonts.gstatic.com/s/` | Google 字型（繁中字型等，Flutter 依畫面需要下載） |

另外幾個設定：

| 設定 | 為什麼需要 |
|---|---|
| `'wasm-unsafe-eval'` | 允許執行 WebAssembly（繪圖引擎與 SQLite 需要） |
| 樣式的 `'unsafe-inline'` | Flutter 會在頁面上動態加入樣式；樣式要連到外部仍受白名單限制 |
| 圖片的 `data:` / `blob:` | 瀏覽器內部產生的圖片，不會連到外部 |
| `object-src 'none'`、`form-action 'none'`、`base-uri 'self'` | 鎖住外掛、表單送出、網址基準這幾條較少見的管道 |

### 能擋什麼、擋不住什麼

- ✅ **擋得住**：程式偷偷連線（fetch / XHR / WebSocket），以及載入白名單外的程式、圖片、樣式、字型。
- ❌ **擋不住**：把整個頁面導到別的網站或另開新視窗（衛教文章的「資料來源」連結就是這樣開的，
  這種會在畫面上看得到）；以及瀏覽器的即時通訊（WebRTC）通道（目前白名單管不到）。

所以白名單是**第二道防線**，「慎選套件」仍然是第一道。

---

## 為什麼開發模式沒有白名單

`flutter run` 的開發模式會在頁面上執行內嵌程式（熱重載用），白名單會把它擋掉而**白畫面**。
因此 `web/index.html` 裡的白名單平常包在一組註解標記裡：

```html
<!-- CSP-BEGIN
<meta http-equiv="Content-Security-Policy" content="...">
CSP-END -->
```

正式版建置後，由 [`tool/enable_csp.dart`](../tool/enable_csp.dart) 拿掉這兩行標記，白名單才生效。
部署流程（`.github/workflows/deploy.yml`）每次都會跑這一步；找不到標記時這一步會**失敗**，
不會悄悄部署出沒有白名單的版本。

> ⚠️ 不要把白名單直接改成生效狀態，也不要刪掉標記——前者會讓開發模式白畫面，後者會讓部署失敗。

---

## 在本機檢查正式版

```powershell
flutter build web --release --csp      # --csp：不產生「執行時才動態生成程式碼」的寫法
dart run tool/enable_csp.dart          # 啟用白名單
python -m http.server 8090 --directory build/web
```

打開 <http://localhost:8090>，按 `F12` 開 Console。
如果出現 **`violates the following Content Security Policy directive`**，
就表示有東西想連到白名單以外的地方——先查清楚是誰、為什麼，再決定要不要加進白名單。

---

## 要新增來源時（例如之後接 Garmin API）

1. **先確認真的需要、來源可信**（見下一節的檢查清單）。
2. **只加在需要的指令、盡量寫到路徑**：例如呼叫 API 只加在 `connect-src`，
   寫 `https://api.example.com/v1/` 而不是整個網域。
3. **同步更新 [`test/web_csp_test.dart`](../test/web_csp_test.dart) 的 `_allowedExternalSources`**
   ——沒改的話測試會失敗，這是刻意的：每一次放寬都要是明確的決定。
4. **在本機檢查正式版**（上一節）：Console 沒有違規訊息、功能正常。
5. **commit 訊息寫清楚為什麼要加**。

---

## 加入第三方套件前的檢查清單

1. **查來源**：官方或長期維護的知名專案；不用來路不明的鏡像或改版（同名不代表是同一份程式）。
2. **鎖版本**：`pubspec.lock` 記錄每個套件的版本與指紋（`sha256`），下載的檔案被動過就對不上；
   升級前先看它改了什麼。
3. **自己存一份**：需要的靜態檔放進 `web/`（像 `sqlite3.wasm`），由本站提供，不在執行時從外部網站載入。
4. **需要對外連線**，就走上一節的流程加進白名單。
