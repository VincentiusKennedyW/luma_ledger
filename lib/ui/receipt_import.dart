import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ledger_controller.dart';
import '../receipts/receipt_inbox.dart';
import '../receipts/receipt_parser.dart';
import '../core/models.dart';
import 'components.dart';
import 'entry_form.dart';

class ReceiptImportPage extends StatelessWidget {
  const ReceiptImportPage({super.key});
  @override
  Widget build(BuildContext context) {
    final inbox = Get.find<ReceiptInbox>(), c = Get.find<LedgerController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Import receipt')),
      body: Obx(
        () => PageBody(
          children: [
            Text(
              'From your bank to your ledger',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'After paying, choose Share → Luma Ledger in your bank app. You can also choose a saved receipt image.',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: inbox.pick,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Choose receipt image'),
            ),
            if (inbox.error.value != null) NoteBox(inbox.error.value!),
            const SectionTitle('Save into'),
            if (c.ledgers.any((l) => l.currency == 'IDR'))
              DropdownButtonFormField<String>(
                key: ValueKey(c.activeId.value),
                initialValue: c.currency == 'IDR' && c.ledger != null
                    ? c.activeId.value
                    : null,
                isExpanded: true,
                itemHeight: null,
                decoration: const InputDecoration(labelText: 'IDR ledger'),
                items: c.ledgers
                    .where((l) => l.currency == 'IDR')
                    .map(
                      (l) => DropdownMenuItem(value: l.id, child: Text(l.name)),
                    )
                    .toList(),
                onChanged: c.busy.value
                    ? null
                    : (id) {
                        if (id != null) c.action(() => c.selectLedger(id));
                      },
              )
            else
              const NoteBox(
                'Create an IDR ledger from Overview first, then return here. Your pending receipt stays on this device for up to 24 hours.',
              ),
            const SectionTitle('Waiting for review'),
            if (inbox.items.isEmpty)
              const NoteBox(
                'No receipts yet. Nothing is recorded until you review and save.',
              ),
            for (final item in inbox.items) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: item.reading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.receipt_long_outlined),
                title: Text(
                  item.reading
                      ? 'Reading on this device…'
                      : item.error != null
                      ? 'Could not read receipt'
                      : item.draft.merchant ?? 'Shared receipt',
                ),
                subtitle: Text(
                  item.error ??
                      (item.reading
                          ? 'No upload needed'
                          : item.draft.amount == null
                          ? 'Check and complete the details'
                          : moneyLabel(item.draft)),
                ),
              ),
              if (!item.reading)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed:
                          item.error != null ||
                              c.ledger == null ||
                              c.currency != 'IDR' ||
                              c.wallets.isEmpty ||
                              c.busy.value
                          ? null
                          : () async {
                              await Get.to(
                                () => EntryFormPage(receipt: item),
                                preventDuplicates: false,
                              );
                            },
                      child: const Text('Review transaction'),
                    ),
                    TextButton(
                      onPressed: () => showReceiptImage(context, item.path),
                      child: const Text('View receipt'),
                    ),
                  ],
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () async {
                    if (await confirm(
                      context,
                      'Discard receipt?',
                      'Remove the pending image and its extracted text from Luma?',
                      action: 'Discard',
                    )) {
                      await inbox.discard(item.id);
                    }
                  },
                  child: const Text('Discard receipt'),
                ),
              ),
              const Divider(),
            ],
            const SizedBox(height: 16),
            const Text(
              'Receipt reading suggests details; it does not verify a payment with your bank. Wondr QRIS labels are supported. Other layouts may need manual corrections.',
            ),
            const SizedBox(height: 12),
            Text(
              'Images and extracted text stay on this device, outside backups. They are removed after saving or discarding; unopened drafts expire when Luma next starts after 24 hours.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String moneyLabel(ReceiptDraft d) =>
      '${money(d.amount!, 'IDR')} · check before saving';
}

Future<void> showReceiptImage(BuildContext context, String path) async {
  await Get.to<void>(
    () => Scaffold(
      appBar: AppBar(title: const Text('Receipt image')),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: .5,
            maxScale: 5,
            child: Image.file(
              File(path),
              semanticLabel: 'Original shared receipt; pinch to zoom',
              errorBuilder: (_, _, _) => const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'The image is no longer available. Share it again from your bank app.',
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    transition: MediaQuery.disableAnimationsOf(context)
        ? Transition.noTransition
        : Transition.native,
    preventDuplicates: false,
  );
}

/// Does not interrupt an existing form; incoming receipts remain in the inbox.
class ReceiptArrival extends StatefulWidget {
  final Widget child;
  const ReceiptArrival({super.key, required this.child});
  @override
  State<ReceiptArrival> createState() => _ReceiptArrivalState();
}

class _ReceiptArrivalState extends State<ReceiptArrival> {
  Worker? worker;
  final seen = <String>{};
  String? seenError;
  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<ReceiptInbox>()) return;
    final inbox = Get.find<ReceiptInbox>();
    void changed() {
      if (!mounted) return;
      final fresh = inbox.items
          .map((i) => i.id)
          .where((id) => !seen.contains(id))
          .toList();
      seen.addAll(fresh);
      final newError =
          inbox.error.value != null && inbox.error.value != seenError;
      seenError = inbox.error.value;
      if (fresh.isEmpty && !newError) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (Get.currentRoute == '/') {
          Get.toNamed('/receipts');
        } else if (Get.currentRoute != '/receipts') {
          Get.find<LedgerController>().notify(
            inbox.error.value ??
                'Receipt received. Open Import receipt from Overview after finishing here.',
          );
        }
      });
    }

    worker = ever(inbox.revision, (_) => changed());
    WidgetsBinding.instance.addPostFrameCallback((_) => changed());
  }

  @override
  void dispose() {
    worker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
