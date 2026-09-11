import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../core/models.dart';
import '../controllers/ledger_controller.dart';
import 'components.dart';
import 'theme.dart';
import '../receipts/receipt_inbox.dart';
import '../receipts/receipt_parser.dart';
import 'receipt_import.dart' show showReceiptImage;

class EntryFormPage extends StatefulWidget {
  final Entry? entry;
  final EntryKind initialKind;
  final SharedReceipt? receipt;
  const EntryFormPage({
    super.key,
    this.entry,
    this.receipt,
    this.initialKind = EntryKind.expense,
  });
  @override
  State<EntryFormPage> createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryFormPage> {
  final c = Get.find<LedgerController>(), form = GlobalKey<FormState>();
  late final TextEditingController amount, description, note;
  final amountFocus = FocusNode();
  late EntryKind kind;
  late DateTime date;
  late String? wallet;
  late String category;
  late String ledgerId;
  ReceiptDraft? draft;
  bool receiptConfirmed = false;
  String? toWallet;
  bool dirty = false, saving = false;
  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    ledgerId = c.activeId.value;
    draft = widget.receipt?.draft;
    amount = TextEditingController(
      text: e == null
          ? draft?.amount == null
                ? ''
                : decimalMoney(
                    draft!.amount!,
                  ).replaceFirst(RegExp(r'\.00$'), '')
          : decimalMoney(e.amount).replaceFirst(RegExp(r'\.00$'), ''),
    );
    description = TextEditingController(
      text: e?.description ?? draft?.merchant ?? '',
    );
    note = TextEditingController(text: e?.note ?? '');
    kind = e?.kind ?? widget.initialKind;
    date = e?.date ?? draft?.date ?? dayOnly(DateTime.now());
    wallet = e?.walletId ?? (draft == null ? c.wallets.first.id : null);
    category =
        e?.category ??
        (kind == EntryKind.income
            ? 'income'
            : kind == EntryKind.investment
            ? 'investment'
            : draft == null
            ? 'food'
            : 'other');
    toWallet = e?.toWalletId;
    dirty = draft != null;
  }

  @override
  void dispose() {
    amount.dispose();
    description.dispose();
    note.dispose();
    amountFocus.dispose();
    super.dispose();
  }

  Future<void> leave() async {
    if (saving) return;
    if (!dirty ||
        await confirm(
          context,
          'Discard changes?',
          'Your transaction has unsaved changes.',
          action: 'Discard',
        )) {
      if (mounted) {
        setState(() => dirty = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Get.back();
        });
      }
    }
  }

  Future<void> save() async {
    if (saving) return;
    if (c.activeId.value != ledgerId) {
      c.notify('The active ledger changed. Reopen this form before saving.');
      return;
    }
    if (draft != null &&
        (!receiptConfirmed || draft!.status == ReceiptStatus.failed)) {
      c.notify(
        'Check the receipt details before saving. Failed or pending payments cannot be imported.',
      );
      return;
    }
    if (!form.currentState!.validate()) {
      amountFocus.requestFocus();
      return;
    }
    final entry = Entry(
      id: widget.entry?.id ?? newId(),
      ledgerId: ledgerId,
      walletId: wallet!,
      date: date,
      amount: parseMoney(amount.text),
      kind: kind,
      description: description.text.trim(),
      category: kind == EntryKind.transfer
          ? 'balance'
          : kind == EntryKind.checkpoint
          ? 'balance'
          : category,
      note: note.text.trim(),
      toWalletId: kind == EntryKind.transfer ? toWallet : null,
      importKey: widget.entry?.importKey ?? draft?.importKey,
      review: false,
    );
    setState(() => saving = true);
    var ok = false;
    try {
      if (draft != null) {
        final existing = await c.store.receiptMatch(
          ledgerId,
          draft!.importKey,
          entry.amount,
          entry.date,
          entry.description,
        );
        if (!mounted) return;
        if (existing != null) {
          if (existing.importKey == draft!.importKey) {
            c.notify(
              'This receipt is already recorded in this ledger. Discard it from the receipt inbox.',
            );
            return;
          }
          if (!await confirm(
            context,
            'Possible duplicate',
            'An expense with this date, amount and description already exists. Save another expense?',
            action: 'Save another',
          )) {
            return;
          }
        }
      }
      if (!mounted) return;
      ok = await c.action(() => c.store.saveEntry(entry));
      if (ok && widget.receipt != null) {
        try {
          await Get.find<ReceiptInbox>().discard(widget.receipt!.id);
        } catch (_) {
          c.notify(
            'Transaction saved. Discard its pending receipt from Import receipt.',
          );
        }
      }
    } catch (_) {
      c.notify(
        'Could not check or save this receipt. Your draft is still here; try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
          if (ok) dirty = false;
        });
      }
    }
    if (ok && mounted) {
      HapticFeedback.lightImpact();
      Get.back();
      c.notify(
        widget.entry == null ? 'Transaction added.' : 'Transaction updated.',
      );
    }
  }

  Future<void> chooseCategory() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: .65,
          maxChildSize: .9,
          minChildSize: .35,
          expand: false,
          builder: (ctx, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Text(
                'Choose category',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (ctx, size) {
                  final columns = MediaQuery.textScalerOf(ctx).scale(1) > 1.4
                      ? 1
                      : 3;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: c.categories
                        .where((cat) => cat != 'balance')
                        .map(
                          (cat) => SizedBox(
                            width:
                                (size.maxWidth - 10 * (columns - 1)) / columns,
                            child: Material(
                              color: cat == category
                                  ? Theme.of(ctx).colorScheme.primaryContainer
                                  : Theme.of(
                                      ctx,
                                    ).colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => Navigator.pop(ctx, cat),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                    horizontal: 8,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        categoryIcon(cat),
                                        color: Theme.of(
                                          ctx,
                                        ).colorScheme.primary,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        categoryLabel(cat),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(
                                          ctx,
                                        ).textTheme.labelMedium,
                                      ),
                                      if (cat == category)
                                        const Icon(Icons.check, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        category = selected;
        dirty = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.entry != null;
    return PopScope(
      canPop: !dirty && !saving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            onPressed: leave,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(
            editing
                ? 'Edit transaction'
                : draft != null
                ? 'Review receipt'
                : 'Add transaction',
          ),
          actions: editing
              ? [
                  PopupMenuButton<String>(
                    tooltip: 'Transaction actions',
                    onSelected: (value) async {
                      if (value == 'duplicate') {
                        final ok = await c.action(
                          () => c.store.saveEntry(
                            widget.entry!.copy(
                              id: newId(),
                              date: dayOnly(DateTime.now()),
                              clearImport: true,
                            ),
                          ),
                        );
                        if (ok) {
                          Get.back();
                          c.notify('Transaction duplicated for today.');
                        }
                      } else if (await confirm(
                        context,
                        'Delete this transaction?',
                        'This changes your wallet balance and reports. You can undo immediately.',
                      )) {
                        final original = widget.entry!;
                        final ok = await c.action(() async {
                          await c.store.db.delete(
                            'entries',
                            where: 'id=?',
                            whereArgs: [original.id],
                          );
                        });
                        if (ok) {
                          setState(() => dirty = false);
                          Get.back();
                          Get.showSnackbar(
                            GetSnackBar(
                              message: 'Transaction deleted',
                              duration: const Duration(seconds: 8),
                              mainButton: TextButton(
                                onPressed: () async {
                                  Get.closeCurrentSnackbar();
                                  await c.action(
                                    () => c.store.saveEntry(original),
                                    success: 'Transaction restored.',
                                  );
                                },
                                child: const Text('Undo'),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Text('Duplicate for today'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete transaction'),
                      ),
                    ],
                  ),
                ]
              : null,
        ),
        body: Form(
          key: form,
          onChanged: () {
            if (!dirty) setState(() => dirty = true);
          },
          child: Column(
            children: [
              Expanded(
                child: PageBody(
                  children: [
                    if (draft != null) ...[
                      Text(
                        draft!.provider == null
                            ? 'Shared payment receipt'
                            : '${draft!.provider} payment receipt',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      NoteBox(
                        draft!.status == ReceiptStatus.failed
                            ? 'This receipt appears failed, pending or refunded. It cannot be saved as a completed expense.'
                            : 'Check the amount, merchant and date against the image. Choose the wallet you paid from and the correct category.',
                      ),
                      if (!draft!.rupiah)
                        const NoteBox(
                          'No rupiah currency was detected. Only IDR receipts are supported; do not enter a foreign-currency amount here.',
                        ),
                      if (draft!.date == null)
                        const NoteBox(
                          'The transaction date could not be read. Today is shown; choose the date on your receipt.',
                        ),
                      if (draft!.reference != null)
                        Text(
                          'Reference: ${draft!.reference}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            showReceiptImage(context, widget.receipt!.path),
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('View receipt image'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (widget.entry?.review ?? false)
                      const NoteBox(
                        'This imported top-up may be a transfer. Choose a destination wallet if both sides are tracked. Saving confirms your classification.',
                      ),
                    if (draft == null)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: EntryKind.values
                            .where(
                              (k) =>
                                  k != EntryKind.checkpoint ||
                                  kind == EntryKind.checkpoint,
                            )
                            .map(
                              (k) => ChoiceChip(
                                label: Text(
                                  k == EntryKind.investment
                                      ? 'Invest'
                                      : kindLabel(k),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 6,
                                ),
                                selected: kind == k,
                                onSelected: (_) => setState(() {
                                  kind = k;
                                  dirty = true;
                                  if (k == EntryKind.income) {
                                    category = 'income';
                                  }
                                  if (k == EntryKind.investment) {
                                    category = 'investment';
                                  }
                                  if (k == EntryKind.expense &&
                                      [
                                        'income',
                                        'investment',
                                        'balance',
                                      ].contains(category)) {
                                    category = 'food';
                                  }
                                }),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: amount,
                      focusNode: amountFocus,
                      style: Theme.of(context).textTheme.displaySmall,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount (${c.currency})',
                        hintText: '0',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        hintStyle: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        contentPadding: const EdgeInsets.all(22),
                      ),
                      validator: (v) {
                        try {
                          if (parseMoney(v ?? '') <= 0) {
                            return 'Enter an amount greater than zero.';
                          }
                        } catch (e) {
                          return e is FormatException
                              ? e.message.toString()
                              : 'Enter a valid amount.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: description,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 200,
                      decoration: InputDecoration(
                        labelText: kind == EntryKind.income
                            ? 'Income description'
                            : 'What was it for?',
                        hintText: 'e.g. Lunch, fuel, monthly salary',
                        counterText: '',
                        prefixIcon: const Icon(Icons.edit_note_rounded),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Add a description to find this transaction later.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      itemHeight: null,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      initialValue: wallet,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: kind == EntryKind.transfer
                            ? 'From wallet'
                            : 'Wallet',
                      ),
                      items: c.wallets
                          .map(
                            (w) => DropdownMenuItem(
                              value: w.id,
                              child: Text(w.name),
                            ),
                          )
                          .toList(),
                      validator: (v) =>
                          v == null ? 'Choose the wallet you paid from.' : null,
                      onChanged: (v) => setState(() {
                        wallet = v!;
                        if (toWallet == wallet) toWallet = null;
                        dirty = true;
                      }),
                    ),
                    if (kind == EntryKind.transfer) ...[
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        itemHeight: null,
                        initialValue: toWallet,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'To wallet',
                        ),
                        items: c.wallets
                            .where((w) => w.id != wallet)
                            .map(
                              (w) => DropdownMenuItem(
                                value: w.id,
                                child: Text(w.name),
                              ),
                            )
                            .toList(),
                        validator: (v) => v == null
                            ? 'Choose a different destination wallet.'
                            : null,
                        onChanged: (v) => setState(() {
                          toWallet = v;
                          dirty = true;
                        }),
                      ),
                      const NoteBox(
                        'Transfers move money between wallets without increasing income or spending. Record any fee as a separate expense.',
                      ),
                    ],
                    if (![
                      EntryKind.transfer,
                      EntryKind.checkpoint,
                    ].contains(kind)) ...[
                      const SizedBox(height: 20),
                      Material(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: CategoryAvatar(category),
                          title: const Text('Category'),
                          subtitle: Text(categoryLabel(category)),
                          trailing: const Icon(Icons.expand_more_rounded),
                          onTap: chooseCategory,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final selected = await showDatePicker(
                          context: context,
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2200),
                          initialDate: date,
                        );
                        if (selected != null) {
                          setState(() {
                            date = selected;
                            dirty = true;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(DateFormat('EEEE, d MMMM yyyy').format(date)),
                    ),
                    if (draft != null)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: receiptConfirmed,
                        onChanged: draft!.status == ReceiptStatus.failed
                            ? null
                            : (v) =>
                                  setState(() => receiptConfirmed = v ?? false),
                        title: const Text(
                          'I checked the image: this payment succeeded, is in IDR, and the details above are correct.',
                        ),
                      ),
                    if (date.isAfter(dayOnly(DateTime.now())))
                      const NoteBox(
                        'This future transaction will appear as scheduled. It enters actual balances and reports on its date.',
                      ),
                    if (kind == EntryKind.checkpoint)
                      const NoteBox(
                        'A balance snapshot is a historical reference only. It never changes wallet balances or income.',
                      ),
                    const SizedBox(height: 20),
                    ExpansionTile(
                      key: const PageStorageKey('entry-note'),
                      initiallyExpanded: note.text.isNotEmpty,
                      tilePadding: EdgeInsets.zero,
                      leading: const Icon(Icons.notes_rounded),
                      title: const Text('Add a note'),
                      children: [
                        TextFormField(
                          controller: note,
                          maxLines: 3,
                          maxLength: 2000,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Note (optional)',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          saving ||
                              (draft != null &&
                                  (!receiptConfirmed ||
                                      draft!.status == ReceiptStatus.failed))
                          ? null
                          : save,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        saving
                            ? 'Saving…'
                            : editing
                            ? 'Save changes'
                            : 'Save transaction',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
