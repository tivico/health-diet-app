import 'package:health/platform/local_files.dart';

/// 測試用的假存檔 / 開檔：記下存了哪些檔，選檔時回傳預先準備好的內容。
class FakeLocalFiles implements LocalFiles {
  FakeLocalFiles({this.isSupported = true});

  @override
  final bool isSupported;

  /// 下次選檔要回傳的內容；null 代表使用者按了取消。
  String? fileToOpen;

  /// 上次選檔視窗篩選的檔案類型。
  List<String>? lastAccept;

  final saved = <({String fileName, String text, String mimeType})>[];

  @override
  Future<void> saveText({
    required String fileName,
    required String text,
    required String mimeType,
  }) async =>
      saved.add((fileName: fileName, text: text, mimeType: mimeType));

  @override
  Future<String?> openText({required List<String> accept}) async {
    lastAccept = accept;
    return fileToOpen;
  }
}
