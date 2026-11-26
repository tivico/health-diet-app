import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'local_files.dart';

LocalFiles createLocalFiles() => const _BrowserLocalFiles();

/// 用瀏覽器內建的下載與選檔視窗。檔案內容只在這台裝置的瀏覽器裡處理，
/// 不會連到任何網站，所以不需要動對外連線白名單（見 docs/SECURITY.md）。
class _BrowserLocalFiles implements LocalFiles {
  const _BrowserLocalFiles();

  @override
  bool get isSupported => true;

  @override
  Future<void> saveText({
    required String fileName,
    required String text,
    required String mimeType,
  }) async {
    // 把文字包成瀏覽器記憶體裡的檔案（Blob），再用一個看不見的下載連結觸發下載。
    final blob = web.Blob(
      <JSAny>[text.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final link = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName;
    web.document.body!.appendChild(link); // Firefox 要連結在頁面上才會下載
    link.click();
    link.remove();
    // 下載開始後就用不到這個暫時網址了；等一下再釋放，避免下載還沒讀完。
    Timer(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
  }

  @override
  Future<String?> openText({required List<String> accept}) {
    final completer = Completer<String?>();
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = accept.join(',');
    input.setAttribute('hidden', '');

    void finish(String? text) {
      input.remove();
      if (!completer.isCompleted) completer.complete(text);
    }

    void onChange(web.Event _) {
      final file = input.files?.item(0);
      if (file == null) {
        finish(null);
        return;
      }
      file.text().toDart.then(
        (text) => finish(text.toDart),
        onError: (Object error, StackTrace stack) {
          input.remove();
          if (!completer.isCompleted) completer.completeError(error, stack);
        },
      );
    }

    input.addEventListener('change', onChange.toJS);
    // 使用者按「取消」。較舊的瀏覽器不會發出這個事件——那就只是什麼都不發生。
    input.addEventListener('cancel', ((web.Event _) => finish(null)).toJS);
    // 有些瀏覽器（如 Safari）要元素在頁面上，才會回報使用者選了哪個檔。
    web.document.body!.appendChild(input);
    input.click();
    return completer.future;
  }
}
