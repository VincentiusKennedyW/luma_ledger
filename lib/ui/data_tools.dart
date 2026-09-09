import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/ledger_controller.dart';
import '../core/models.dart';
import '../data/csv_import.dart';
import 'components.dart';

Future<String?> pickTextFile(String extension) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: [extension],
    withData: true,
  );
  if (result == null) return null;
  final selected = result.files.single;
  if (selected.size > 20 * 1024 * 1024) {
    throw const FormatException('Choose a file smaller than 20 MB.');
  }
  final data = selected.bytes ?? await File(selected.path!).readAsBytes();
  return utf8.decode(data);
}

ImportPreview parseCsvJob(Map<String, Object> job) => CsvImporter.parse(
  job['source'] as String,
  ledgerId: job['ledger'] as String,
  walletId: job['wallet'] as String,
  existingKeys: (job['keys'] as List<String>).toSet(),
);

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});
  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  final c = Get.find<LedgerController>();
  late String wallet;
  ImportPreview? preview;
  bool loading = false;
  String? error;
  @override
  void initState() {
    super.initState();
    wallet = c.wallets.first.id;
  }

  Future<void> choose() async {
    setState(() {
      loading = true;
      error = null;
      preview = null;
    });
    try {
      final source = await pickTextFile('csv');
      if (source != null) {
        final result = await compute(parseCsvJob, {
          'source': source,
          'ledger': c.activeId.value,
          'wallet': wallet,
          'keys': c.entries
              .map((e) => e.importKey)
              .whereType<String>()
              .toList(),
        });
        if (mounted) setState(() => preview = result);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is FormatException
              ? e.message.toString()
              : 'Could not read this file. Choose a UTF-8 CSV and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Import transactions')),
    body: PageBody(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.file_upload_outlined,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Bring your history',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose a CSV file, review the preview, then import your transactions.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DESTINATION', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                '${c.ledger!.name} · ${c.currency}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                itemHeight: null,
                initialValue: wallet,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Import into wallet',
                ),
                items: c.wallets
                    .map(
                      (w) => DropdownMenuItem(value: w.id, child: Text(w.name)),
                    )
                    .toList(),
                onChanged: loading
                    ? null
                    : (v) => setState(() {
                        wallet = v!;
                        preview = null;
                      }),
              ),
            ],
          ),
        ),
        const ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text('Supported CSV format'),
          children: [
            NoteBox(
              'Supported columns: date, amount, description, category, isIncome, isBalanceForward, and optional note. Dates use YYYY-MM-DD. Your original export is supported directly.',
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: loading ? null : choose,
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file_outlined),
          label: Text(
            loading
                ? 'Reading your file…'
                : preview == null
                ? 'Choose CSV file'
                : 'Choose another file',
          ),
        ),
        if (error != null) NoteBox(error!, icon: Icons.error_outline),
        if (preview != null) ...[
          const SectionTitle('Import preview'),
          StatGrid([
            (
              'Ready to import',
              '${preview!.entries.length}',
              Icons.check_circle_outline,
            ),
            (
              'Already imported',
              '${preview!.duplicates}',
              Icons.content_copy_outlined,
            ),
            (
              'Rows with errors',
              '${preview!.errors.length}',
              Icons.error_outline,
            ),
            (
              'Balance snapshots',
              '${preview!.entries.where((e) => e.kind == EntryKind.checkpoint).length}',
              Icons.history,
            ),
          ]),
          ...preview!.warnings.map((w) => NoteBox(w)),
          if (preview!.errors.isNotEmpty)
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fix these rows before importing',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...preview!.errors
                      .take(20)
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(e),
                        ),
                      ),
                  if (preview!.errors.length > 20)
                    Text('And ${preview!.errors.length - 20} more errors.'),
                  const Text(
                    'No rows will be imported until this file is valid.',
                  ),
                ],
              ),
            ),
          if (preview!.entries.isNotEmpty) ...[
            const SectionTitle('First 5 records'),
            Panel(
              child: Column(
                children: preview!.entries
                    .take(5)
                    .map(
                      (e) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.description),
                        subtitle: Text(
                          '${dateKey(e.date)} · ${kindLabel(e.kind)}',
                        ),
                        trailing: Text(c.fmt(e.amount, compact: true)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Obx(
            () => FilledButton(
              onPressed:
                  c.busy.value ||
                      loading ||
                      preview!.errors.isNotEmpty ||
                      preview!.entries.isEmpty
                  ? null
                  : () async {
                      final count = preview!.entries.length;
                      final ok = await c.action(() async {
                        await c.store.importEntries(preview!.entries);
                      });
                      if (ok) {
                        c.allHistory();
                        Get.back();
                        c.notify(
                          '$count records imported. Your history is ready.',
                        );
                      }
                    },
              child: Text(
                c.busy.value
                    ? 'Importing…'
                    : 'Import ${preview!.entries.length} records',
              ),
            ),
          ),
        ],
        const NoteBox(
          'Identical repeat imports are skipped. Repeated identical rows within one file are preserved as separate transactions. If the original file is edited later, changed rows count as new records; review them before importing.',
        ),
      ],
    ),
  );
}

Future<void> shareText(
  BuildContext context,
  String text,
  String name,
  String mime,
) async {
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null
      ? const Rect.fromLTWH(0, 0, 1, 1)
      : box.localToGlobal(Offset.zero) & box.size;
  final temp = await getTemporaryDirectory();
  final file = File('${temp.path}/$name');
  await file.writeAsBytes(Uint8List.fromList(utf8.encode(text)), flush: true);
  await Share.shareXFiles([
    XFile(file.path, mimeType: mime),
  ], sharePositionOrigin: origin);
}

class ExportPage extends StatelessWidget {
  const ExportPage({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<LedgerController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Export & backup')),
      body: PageBody(
        children: [
          const NoteBox(
            'You own your data. Save a complete backup to restore wallets, budgets, schedules and transaction history on another device. Exports contain financial information; choose where to save them.',
          ),
          Panel(
            child: Column(
              children: [
                _item(
                  context,
                  'Complete backup',
                  'All ledgers and settings · restorable JSON',
                  Icons.backup_outlined,
                  () async {
                    final backup = await c.store.backup();
                    if (!context.mounted) return;
                    await shareText(
                      context,
                      backup,
                      'luma-backup-${dateKey(DateTime.now())}.json',
                      'application/json',
                    );
                  },
                ),
                const Divider(),
                _item(
                  context,
                  'Transactions CSV',
                  'Current ledger · all dates',
                  Icons.table_chart_outlined,
                  () async {
                    await shareText(
                      context,
                      CsvImporter.export(c.entries.toList()),
                      'luma-transactions-${dateKey(DateTime.now())}.csv',
                      'text/csv',
                    );
                  },
                ),
                const Divider(),
                _item(
                  context,
                  'Period report',
                  '${c.period.value.label} · summary and categories',
                  Icons.analytics_outlined,
                  () async {
                    final r = c.report;
                    final rows = <List<Object>>[
                      ['Luma report', c.period.value.label],
                      ['Currency', c.currency],
                      ['Start inclusive', dateKey(c.period.value.start)],
                      ['End exclusive', dateKey(c.period.value.end)],
                      ['Actuals through', dateKey(DateTime.now())],
                      ['Income', decimalMoney(r.income)],
                      ['Expenses', decimalMoney(r.expense)],
                      ['Investments', decimalMoney(r.investment)],
                      ['Net cash flow', decimalMoney(r.net)],
                      ['Daily average', decimalMoney(r.dailyAverage)],
                      ['Category', 'Amount'],
                      ...r
                          .groupBy((e) => e.category)
                          .entries
                          .map(
                            (e) => [
                              CsvImporter.safeCell(categoryLabel(e.key)),
                              decimalMoney(e.value),
                            ],
                          ),
                    ];
                    await shareText(
                      context,
                      const ListToCsvConverter().convert(rows),
                      'luma-report-${dateKey(DateTime.now())}.csv',
                      'text/csv',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => restoreBackup(context),
            icon: const Icon(Icons.settings_backup_restore),
            label: const Text('Restore a JSON backup'),
          ),
          const NoteBox(
            'CSV is for analysis and legacy imports. Use a JSON backup for full-fidelity restoration, including wallet transfers. Text that could become a spreadsheet formula is escaped during CSV export.',
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Future<void> Function() work,
  ) {
    final c = Get.find<LedgerController>();
    return Obx(
      () => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        enabled: !c.busy.value,
        onTap: () => c.action(work),
      ),
    );
  }
}

Future<void> restoreBackup(BuildContext context) async {
  final c = Get.find<LedgerController>();
  try {
    final source = await pickTextFile('json');
    if (source == null) return;
    final decoded = jsonDecode(source);
    if (decoded is! Map ||
        decoded['format'] != 'luma-ledger' ||
        decoded['version'] != 1 ||
        decoded['ledgers'] is! List ||
        decoded['entries'] is! List) {
      throw const FormatException('Choose a Luma version 1 JSON backup.');
    }
    if (!context.mounted) return;
    if (!await confirm(
      context,
      'Replace device data?',
      'This backup contains ${(decoded['ledgers'] as List).length} ledgers and ${(decoded['entries'] as List).length} transactions. It will replace all current ledgers, wallets, budgets and schedules on this device. Export a backup first if you want to keep them.',
      action: 'Restore backup',
    )) {
      return;
    }
    final ok = await c.action(() async {
      await c.store.restore(source);
      await c.initialize();
    }, success: 'Backup restored.');
    if (ok) {
      Get.changeThemeMode(c.themeMode);
      Get.offAllNamed('/');
    }
  } catch (e) {
    c.notify(
      e is FormatException
          ? e.message.toString()
          : 'This backup could not be read. Your current data is unchanged.',
      'Restore failed',
    );
  }
}
