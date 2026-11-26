/// 正式版建置後，啟用 web/index.html 裡的對外連線白名單（CSP）。
///
/// 白名單平常包在 `<!-- CSP-BEGIN` / `CSP-END -->` 這組註解裡：開發模式
/// （flutter run）會在頁面上執行內嵌程式，白名單開著會被擋到白畫面。
/// 這支程式把建置結果裡的這兩行標記拿掉，白名單就生效了。
///
/// 執行（deploy.yml 也是這兩行）：
///   flutter build web --release --csp
///   dart run tool/enable_csp.dart
///
/// 找不到標記時直接以錯誤結束——寧可部署失敗，也不要悄悄部署出沒有白名單的版本。
/// 說明見 docs/SECURITY.md。
library;

import 'dart:io';

const cspBeginMarker = '<!-- CSP-BEGIN';
const cspEndMarker = 'CSP-END -->';

final _htmlComment = RegExp(r'<!--[\s\S]*?-->');
final _cspMeta = RegExp(
    r'<meta\s+http-equiv="Content-Security-Policy"\s+content="([^"]*)"');

/// 真正會生效的白名單內容（去掉 HTML 註解後還在的那份）；沒有則為 null。
String? activeCspPolicy(String html) =>
    _cspMeta.firstMatch(html.replaceAll(_htmlComment, ''))?.group(1);

/// 拿掉白名單外層的兩行註解標記，回傳啟用後的 HTML。
///
/// 兩個標記必須各剛好一行、順序正確，否則丟出 [FormatException]。
String enableCsp(String html) {
  final lines = html.split('\n');
  final begins = [
    for (var i = 0; i < lines.length; i++)
      if (lines[i].trim().startsWith(cspBeginMarker)) i,
  ];
  final ends = [
    for (var i = 0; i < lines.length; i++)
      if (lines[i].trim() == cspEndMarker) i,
  ];
  if (begins.length != 1 || ends.length != 1 || ends.single < begins.single) {
    throw const FormatException('找不到成對的 CSP-BEGIN / CSP-END 標記（各要剛好一行）');
  }
  // 先刪後面那行，前面那行的行號才不會跑掉。
  lines
    ..removeAt(ends.single)
    ..removeAt(begins.single);
  return lines.join('\n');
}

void main(List<String> args) {
  final path = args.isEmpty ? 'build/web/index.html' : args.single;
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('找不到 $path，請先執行 flutter build web --release --csp');
    exit(1);
  }

  final html = file.readAsStringSync();
  // 重複執行也沒關係：已經啟用過就直接結束。
  if (!html.contains(cspBeginMarker) && activeCspPolicy(html) != null) {
    stdout.writeln('白名單已是啟用狀態：$path');
    return;
  }

  final String enabled;
  try {
    enabled = enableCsp(html);
  } on FormatException catch (e) {
    stderr.writeln('$path：${e.message}');
    exit(1);
  }
  if (activeCspPolicy(enabled) == null) {
    stderr.writeln('$path：拿掉標記後仍找不到生效的白名單，請檢查 web/index.html');
    exit(1);
  }
  file.writeAsStringSync(enabled);
  stdout.writeln('已啟用對外連線白名單（CSP）：$path');
}
