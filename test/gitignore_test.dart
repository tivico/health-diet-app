import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health/data/backup_file.dart';

/// 個人資料不進版控的護欄。
///
/// repo 是公開的。App 匯出的備份檔、CSV 裡是使用者的全部紀錄，
/// 就算不小心存進專案資料夾，也必須被 .gitignore 擋下、不能被 commit。
/// 用 App 實際產生的檔名來比對：改了檔名卻忘了改 .gitignore，這裡就會失敗。
void main() {
  final rules = [
    for (final line in File('.gitignore').readAsLinesSync())
      if (line.trim().isNotEmpty && !line.trim().startsWith('#')) line.trim(),
  ];

  /// .gitignore 的萬用字元規則（這裡只用到 *）是否擋得住這個檔名。
  bool ignored(String fileName) => rules.any((rule) {
        final pattern = RegExp.escape(rule).replaceAll(r'\*', '[^/]*');
        return RegExp('^$pattern\$').hasMatch(fileName);
      });

  test('備份檔、餐點 CSV、體重 CSV 都不會被 Git 收進來', () {
    final day = DateTime(2026, 3, 5);
    for (final name in [
      backupFileName(day),
      mealsCsvFileName(day),
      weightsCsvFileName(day),
    ]) {
      expect(ignored(name), isTrue, reason: '$name 沒有被 .gitignore 擋下');
    }
  });

  test('程式碼本身不會被誤擋', () {
    expect(ignored('backup_file.dart'), isFalse);
    expect(ignored('pubspec.lock'), isFalse);
  });
}
