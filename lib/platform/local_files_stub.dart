import 'local_files.dart';

/// Web 以外的平台：還沒實作存檔 / 開檔，備份頁會改用複製貼上。
LocalFiles createLocalFiles() => const _UnsupportedLocalFiles();

class _UnsupportedLocalFiles implements LocalFiles {
  const _UnsupportedLocalFiles();

  @override
  bool get isSupported => false;

  @override
  Future<void> saveText({
    required String fileName,
    required String text,
    required String mimeType,
  }) async =>
      throw UnsupportedError('這個平台還不支援存檔');

  @override
  Future<String?> openText({required List<String> accept}) async =>
      throw UnsupportedError('這個平台還不支援開檔');
}
