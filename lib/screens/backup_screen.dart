import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backup_file.dart';
import '../data/csv_export.dart';
import '../data/health_repository.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 備份與還原。
///
/// Web 版：下載備份檔（.json）、選擇備份檔還原；CSV 直接下載成試算表檔案。
/// 不能存檔的平台（目前是 Web 以外）退回原本的做法：產生文字 → 複製貼上。
/// 兩邊都保留「貼上文字還原」，以前複製保存的文字備份也還原得回來。
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

typedef _BuildText = Future<String> Function(HealthRepository repo);

class _BackupScreenState extends ConsumerState<BackupScreen> {
  String? _exported;
  String? _exportedName;
  final _importCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _importCtrl.dispose();
    super.dispose();
  }

  /// 產生文字並顯示在下方預覽區，給使用者複製（JSON 備份與各種 CSV 共用同一塊）。
  Future<void> _preview(String name, _BuildText build) async {
    setState(() => _busy = true);
    final text = await build(ref.read(repositoryProvider));
    if (!mounted) return;
    setState(() {
      _exported = text;
      _exportedName = name;
      _busy = false;
    });
  }

  /// 存成檔案。[forExcel] 會在開頭加 BOM，Excel 開起來中文才不會亂碼。
  Future<void> _download(
    String fileName,
    _BuildText build, {
    required String mimeType,
    bool forExcel = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final text = await build(ref.read(repositoryProvider));
      await ref.read(localFilesProvider).saveText(
            fileName: fileName,
            text: forExcel ? '$kUtf8Bom$text' : text,
            mimeType: mimeType,
          );
      messenger.showSnackBar(
          SnackBar(content: Text('已下載「$fileName」，通常在「下載」資料夾')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('下載失敗：$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    final data = _exported;
    if (data == null) return;
    await Clipboard.setData(ClipboardData(text: data));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('已複製到剪貼簿')));
  }

  Future<void> _restoreFromFile() async {
    // 瀏覽器只准「使用者剛按下按鈕」時開選檔視窗，所以一進來就開，不先做別的事。
    final text = await ref
        .read(localFilesProvider)
        .openText(accept: const ['.json', 'application/json']);
    if (text == null || !mounted) return; // 使用者取消
    await _restore(text);
  }

  /// 先確認是本 App 的備份、讓使用者看過內容摘要，確定後才覆蓋現有資料。
  Future<void> _restore(String rawText) async {
    // trim() 也會去掉 BOM（記事本存檔可能加上的隱形開頭字元），不去掉 JSON 會解析失敗
    final text = rawText.trim();
    if (text.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final summary = summarizeBackup(text);
    if (summary == null) {
      messenger.showSnackBar(const SnackBar(
          content: Text('這不是健康飲控的備份（可能是 CSV 或其他檔案），資料沒有變動。')));
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('還原備份？'),
        content: Text('備份內容：${summary.describe()}。\n\n'
            '這會「覆蓋」目前所有資料，確定要還原嗎？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('還原')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(repositoryProvider).importJson(text);
      messenger.showSnackBar(const SnackBar(content: Text('已還原備份')));
    } catch (e) {
      // 還原在資料庫交易裡進行，失敗會整筆退回
      messenger.showSnackBar(SnackBar(content: Text('還原失敗，目前的資料沒有變動：$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSaveFiles = ref.watch(localFilesProvider).isSupported;

    return Scaffold(
      appBar: AppBar(title: const Text('備份與還原')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SectionHeader(
            icon: Icons.cloud_download_outlined,
            title: '匯出備份',
            subtitle: canSaveFiles
                ? '下載一個備份檔，存到雲端硬碟、隨身碟，或寄給自己保存。'
                    '檔案裡有你全部的紀錄，不要公開分享。'
                : '產生一段文字，複製後貼到記事本 / 雲端 / 訊息裡保存。',
          ),
          SoftCard(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoNote(
                  color: theme.colorScheme.primary,
                  text: '紀錄只存在這台裝置上：清除瀏覽器資料、換電腦或換手機就會不見，記得定期備份。',
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: canSaveFiles
                      ? FilledButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _download(
                                    backupFileName(DateTime.now()),
                                    (repo) => repo.exportJson(),
                                    mimeType: 'application/json',
                                  ),
                          icon: const Icon(Icons.download_outlined, size: 18),
                          label: const Text('下載備份檔'),
                        )
                      : FilledButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _preview(
                                  '備份（JSON）', (repo) => repo.exportJson()),
                          icon: const Icon(Icons.description_outlined, size: 18),
                          label: const Text('產生備份文字'),
                        ),
                ),
                if (canSaveFiles)
                  Center(
                    child: TextButton(
                      onPressed: _busy
                          ? null
                          : () => _preview(
                              '備份（JSON）', (repo) => repo.exportJson()),
                      child: const Text('改用文字備份（複製貼上）'),
                    ),
                  ),
                const SizedBox(height: 20),
                Text('匯出試算表（CSV）', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  canSaveFiles
                      ? '給 Excel / Google 試算表看的格式，下載後直接開啟即可。'
                      : '給 Excel / Google 試算表看的格式。'
                          '貼上後若擠在同一欄，用試算表的「資料剖析 / 分隔成不同欄」以逗號分隔即可。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                InfoNote(
                  icon: Icons.warning_amber_rounded,
                  color: theme.palette.warning,
                  text: canSaveFiles
                      ? 'CSV 只能拿來看，不能用來還原 —— 要備份請用上面的「下載備份檔」。'
                      : 'CSV 只能拿來看，不能用來還原 —— 要備份請用上面的「產生備份文字」。',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => canSaveFiles
                                ? _download(
                                    mealsCsvFileName(DateTime.now()),
                                    (repo) => repo.exportMealsCsv(),
                                    mimeType: 'text/csv',
                                    forExcel: true,
                                  )
                                : _preview(
                                    '餐點 CSV', (repo) => repo.exportMealsCsv()),
                        icon: const Icon(Icons.table_chart_outlined, size: 18),
                        label: const Text('餐點 CSV'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => canSaveFiles
                                ? _download(
                                    weightsCsvFileName(DateTime.now()),
                                    (repo) => repo.exportWeightsCsv(),
                                    mimeType: 'text/csv',
                                    forExcel: true,
                                  )
                                : _preview('體重 CSV',
                                    (repo) => repo.exportWeightsCsv()),
                        icon:
                            const Icon(Icons.monitor_weight_outlined, size: 18),
                        label: const Text('體重 CSV'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_exported != null) ...[
            const SizedBox(height: 12),
            SoftCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description_outlined,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text('目前顯示：${_exportedName ?? ''}',
                          style: theme.textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.field),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(_exported!,
                          style: const TextStyle(fontSize: 12, height: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _copy,
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('複製到剪貼簿'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 26),
          SectionHeader(
            icon: Icons.restore,
            title: '還原備份',
            color: theme.palette.warning,
            subtitle: canSaveFiles
                ? '選擇先前下載的備份檔，還原資料（會覆蓋現有資料）。'
                : '貼上先前匯出的備份文字，還原資料（會覆蓋現有資料）。',
          ),
          SoftCard(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (canSaveFiles) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _restoreFromFile,
                      icon: const Icon(Icons.folder_open_outlined, size: 18),
                      label: const Text('選擇備份檔'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('或貼上備份文字', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: _importCtrl,
                  maxLines: canSaveFiles ? 3 : 6,
                  decoration: const InputDecoration(
                    hintText: '在這裡貼上備份文字…',
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: canSaveFiles
                      ? OutlinedButton.icon(
                          onPressed:
                              _busy ? null : () => _restore(_importCtrl.text),
                          icon: const Icon(Icons.upload_outlined, size: 18),
                          label: const Text('還原貼上的文字'),
                        )
                      : FilledButton.icon(
                          onPressed:
                              _busy ? null : () => _restore(_importCtrl.text),
                          icon: const Icon(Icons.upload_outlined, size: 18),
                          label: const Text('還原'),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
