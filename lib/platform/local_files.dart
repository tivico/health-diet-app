/// 在使用者自己的裝置上存檔、開檔（備份用）——全程不經過網路。
///
/// Web 版用瀏覽器內建的「下載」與「選擇檔案」視窗。其他平台還沒實作，
/// [LocalFiles.isSupported] 是 false，備份頁會退回「複製貼上文字」的做法。
library;

import 'local_files_stub.dart'
    if (dart.library.js_interop) 'local_files_web.dart' as impl;

abstract interface class LocalFiles {
  /// 這個平台能不能存檔 / 開檔。
  bool get isSupported;

  /// 把文字存成檔案（Web 版：瀏覽器直接下載，通常在「下載」資料夾）。
  Future<void> saveText({
    required String fileName,
    required String text,
    required String mimeType,
  });

  /// 讓使用者選一個檔案並讀出文字；使用者取消時回傳 null。
  ///
  /// [accept] 是選檔視窗預設篩選的檔案類型，例如 `['.json']`。
  Future<String?> openText({required List<String> accept});
}

/// 依平台建立實作（Web 以外目前是「不支援」）。
LocalFiles createLocalFiles() => impl.createLocalFiles();
