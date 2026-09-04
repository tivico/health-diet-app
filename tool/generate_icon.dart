/// 產生各平台 App 圖示（不需要美術軟體，也不需要額外套件工具，用程式畫）。
///
/// 設計：品牌綠底 + 白色圓環 + 中心圓點 —— 呼應 App 儀表板的「熱量圓環」。
///
/// 執行：dart run tool/generate_icon.dart
///
/// 會產生／覆寫：
///   assets/icon/app_icon.png            主圖（1024）
///   assets/icon/app_icon_foreground.png Android 自適應圖示前景（透明底）
///   android/app/src/main/res/mipmap-*/ic_launcher.png
///   ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png
///   web/favicon.png、web/icons/*.png
///
/// 註：專案的 image 套件為 3.x，顏色以 int 表示（img.getColor）。
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const _size = 1024;

/// Android 各密度的啟動圖示尺寸。
const _androidIcons = <String, int>{
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

/// iOS AppIcon 圖示集（檔名對應邊長，需與既有 Contents.json 一致）。
const _iosIcons = <String, int>{
  'Icon-App-20x20@1x.png': 20,
  'Icon-App-20x20@2x.png': 40,
  'Icon-App-20x20@3x.png': 60,
  'Icon-App-29x29@1x.png': 29,
  'Icon-App-29x29@2x.png': 58,
  'Icon-App-29x29@3x.png': 87,
  'Icon-App-40x40@1x.png': 40,
  'Icon-App-40x40@2x.png': 80,
  'Icon-App-40x40@3x.png': 120,
  'Icon-App-60x60@2x.png': 120,
  'Icon-App-60x60@3x.png': 180,
  'Icon-App-76x76@1x.png': 76,
  'Icon-App-76x76@2x.png': 152,
  'Icon-App-83.5x83.5@2x.png': 167,
  'Icon-App-1024x1024@1x.png': 1024,
};

void main() {
  final green = img.getColor(0x2E, 0x7D, 0x5B); // 品牌種子色
  final white = img.getColor(0xFF, 0xFF, 0xFF);
  final clear = img.getColor(0, 0, 0, 0); // 透明

  // 主圖示：綠底 + 白環 + 中心點（不含透明通道，iOS 要求不透明）
  final icon = img.Image(_size, _size, channels: img.Channels.rgb);
  _fillAll(icon, green);
  _ring(icon, 340, 215, white);
  _disc(icon, 95, white);

  // Android 自適應圖示前景：透明底 + 白色圖形，縮小以符合安全區（約內側 66%）
  final fg = img.Image(_size, _size, channels: img.Channels.rgba);
  _fillAll(fg, clear);
  _ring(fg, 290, 183, white);
  _disc(fg, 81, white);

  Directory('assets/icon').createSync(recursive: true);
  _write(icon, 'assets/icon/app_icon.png');
  _write(fg, 'assets/icon/app_icon_foreground.png');

  // Android 啟動圖示
  for (final entry in _androidIcons.entries) {
    final dir = 'android/app/src/main/res/${entry.key}';
    Directory(dir).createSync(recursive: true);
    _writeResized(icon, '$dir/ic_launcher.png', entry.value);
  }

  // iOS AppIcon
  const iosDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  if (Directory(iosDir).existsSync()) {
    for (final entry in _iosIcons.entries) {
      _writeResized(icon, '$iosDir/${entry.key}', entry.value);
    }
  }

  // Web：瀏覽器分頁 favicon 與 PWA 圖示
  Directory('web/icons').createSync(recursive: true);
  _writeResized(icon, 'web/favicon.png', 64);
  _writeResized(icon, 'web/icons/Icon-192.png', 192);
  _writeResized(icon, 'web/icons/Icon-512.png', 512);
  _writeResized(icon, 'web/icons/Icon-maskable-192.png', 192);
  _writeResized(icon, 'web/icons/Icon-maskable-512.png', 512);

  stdout.writeln('已產生 Android / iOS / Web 圖示');
}

void _write(img.Image im, String path) =>
    File(path).writeAsBytesSync(img.encodePng(im));

void _writeResized(img.Image src, String path, int size) {
  final resized = img.copyResize(src,
      width: size, height: size, interpolation: img.Interpolation.average);
  _write(resized, path);
}

void _fillAll(img.Image im, int c) {
  for (var y = 0; y < im.height; y++) {
    for (var x = 0; x < im.width; x++) {
      im.setPixel(x, y, c);
    }
  }
}

/// 畫實心圓環（外半徑 [outer]、內半徑 [inner]）。
void _ring(img.Image im, double outer, double inner, int c) {
  final cx = im.width / 2, cy = im.height / 2;
  for (var y = 0; y < im.height; y++) {
    for (var x = 0; x < im.width; x++) {
      final dx = x - cx, dy = y - cy;
      final d = math.sqrt(dx * dx + dy * dy);
      if (d <= outer && d >= inner) im.setPixel(x, y, c);
    }
  }
}

/// 畫實心圓。
void _disc(img.Image im, double r, int c) {
  final cx = im.width / 2, cy = im.height / 2;
  for (var y = 0; y < im.height; y++) {
    for (var x = 0; x < im.width; x++) {
      final dx = x - cx, dy = y - cy;
      if (dx * dx + dy * dy <= r * r) im.setPixel(x, y, c);
    }
  }
}
