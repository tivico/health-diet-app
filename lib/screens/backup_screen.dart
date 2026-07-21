import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// 備份與還原：匯出所有資料成文字（複製保存）、貼上文字還原。
/// 用純文字 copy/paste，跨平台且不需額外套件；之後可再加檔案下載。
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  String? _exported;
  final _importCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _importCtrl.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    final json = await ref.read(repositoryProvider).exportJson();
    if (!mounted) return;
    setState(() {
      _exported = json;
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
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.download_outlined),
            label: const Text('產生備份'),
          ),
          if (_exported != null) ...[
            const SizedBox(height: 12),
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
