import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/health_repository.dart';
import '../providers.dart';

/// 備份與還原：匯出所有資料成文字（複製保存）、貼上文字還原。
/// 另外可匯出 CSV 給試算表檢視（單向，不能用來還原）。
/// 用純文字 copy/paste，跨平台且不需額外套件；之後可再加檔案下載。
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

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

  /// 產生匯出內容並顯示在下方預覽區（JSON 備份與各種 CSV 共用同一塊）。
  Future<void> _generate(
      String name, Future<String> Function(HealthRepository repo) build) async {
    setState(() => _busy = true);
    final text = await build(ref.read(repositoryProvider));
    if (!mounted) return;
    setState(() {
      _exported = text;
      _exportedName = name;
      _busy = false;
    });
  }

  Future<void> _copy() async {
    final data = _exported;
    if (data == null) return;
    await Clipboard.setData(ClipboardData(text: data));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('已複製到剪貼簿')));
  }

  Future<void> _import() async {
    final text = _importCtrl.text.trim();
    if (text.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('還原備份？'),
        content: const Text('這會「覆蓋」目前所有資料，確定要還原嗎？'),
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
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(repositoryProvider).importJson(text);
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(const SnackBar(content: Text('已還原備份')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger
          .showSnackBar(SnackBar(content: Text('還原失敗（備份文字格式不正確？）：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('備份與還原')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('匯出備份',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('產生一段文字，複製後貼到記事本 / 雲端 / 訊息裡保存。',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor)),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _generate('備份（JSON）', (repo) => repo.exportJson()),
            icon: const Icon(Icons.download_outlined),
            label: const Text('產生備份'),
          ),
          const SizedBox(height: 24),
          Text('匯出試算表（CSV）',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            '給 Excel / Google 試算表看的格式。'
            '貼上後若擠在同一欄，用試算表的「資料剖析 / 分隔成不同欄」以逗號分隔即可。',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 4),
          Text('⚠️ CSV 只能拿來看，不能用來還原 —— 要備份請用上面的「產生備份」。',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _generate(
                          '餐點 CSV', (repo) => repo.exportMealsCsv()),
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text('餐點 CSV'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _generate(
                          '體重 CSV', (repo) => repo.exportWeightsCsv()),
                  icon: const Icon(Icons.monitor_weight_outlined),
                  label: const Text('體重 CSV'),
                ),
              ),
            ],
          ),
          if (_exported != null) ...[
            const SizedBox(height: 16),
            Text('目前顯示：${_exportedName ?? ''}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(_exported!,
                    style: const TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _copy,
              icon: const Icon(Icons.copy),
              label: const Text('複製到剪貼簿'),
            ),
          ],
          const Divider(height: 40),
          Text('還原備份',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('貼上先前匯出的備份文字，還原資料（會覆蓋現有資料）。',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor)),
          const SizedBox(height: 8),
          TextField(
            controller: _importCtrl,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: '在這裡貼上備份文字…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy ? null : _import,
            icon: const Icon(Icons.upload_outlined),
            label: const Text('還原'),
          ),
        ],
      ),
    );
  }
}
