import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../controllers/ledger_controller.dart';
import '../core/models.dart';
import 'components.dart';

class PlanningPage extends StatelessWidget {
  const PlanningPage({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<LedgerController>();
    return Obx(
      () => PageBody(
        storageKey: 'plan',
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spending · ${DateFormat('MMMM yyyy').format(DateTime.now())}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  c.fmt(
                    Report(
                      c.entries.toList(),
                      Period.month(DateTime.now()),
                    ).expense,
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${c.budgets.length} active budgets · ${c.due.length} recurring entries due',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          SectionTitle(
            'Monthly budgets',
            action: 'Add budget',
            onTap: () => editBudget(context),
          ),
          if (c.budgets.isEmpty)
            EmptyState(
              title: 'Make space for your priorities',
              message:
                  'Set monthly limits for food, transport, shopping, or any category you choose.',
              icon: Icons.savings_outlined,
              action: 'Create a budget',
              onAction: () => editBudget(context),
            ),
          ...c.budgets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BudgetCard(b),
            ),
          ),
          const SectionTitle('Manage your money'),
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Wallets'),
                  subtitle: Text(
                    '${c.wallets.length} wallets · ${c.fmt(c.balance)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Get.toNamed('/wallets'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_repeat),
                  title: const Text('Recurring transactions'),
                  subtitle: Text(
                    '${c.recurring.length} schedules · ${c.due.length} due',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Get.toNamed('/recurring'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const ExpansionTile(
            key: PageStorageKey('budget-help'),
            tilePadding: EdgeInsets.zero,
            title: Text('About budgets'),
            children: [
              NoteBox(
                'Budgets repeat each calendar month and track expenses only. Investments are separate. Limits never block a transaction.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BudgetCard extends StatelessWidget {
  final DbRow budget;
  const BudgetCard(this.budget, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<LedgerController>(),
        cat = budget['category'] as String,
        limit = budget['amount'] as int;
    final report = Report(c.entries.toList(), Period.month(DateTime.now()));
    final spent = cat == '*'
        ? report.expense
        : report.expenses
              .where((e) => e.category == cat)
              .fold<int>(0, (n, e) => n + e.amount);
    final over = spent > limit;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryAvatar(cat),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cat == '*' ? 'Overall budget' : categoryLabel(cat),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Edit budget',
                onPressed: () => editBudget(context, budget: budget),
                icon: const Icon(Icons.more_horiz),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${c.fmt(spent)} of ${c.fmt(limit)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (spent / limit).clamp(0, 1),
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            color: over ? Theme.of(context).colorScheme.error : null,
          ),
          const SizedBox(height: 12),
          Text(
            over
                ? '${c.fmt(spent - limit)} over budget'
                : '${c.fmt(limit - spent)} left this month',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: over ? Theme.of(context).colorScheme.error : null,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> editBudget(BuildContext context, {DbRow? budget}) async {
  final c = Get.find<LedgerController>();
  var category = budget?['category'] as String? ?? '*';
  final amount = TextEditingController(
    text: budget == null ? '' : decimalMoney(budget['amount'] as int),
  );
  final form = GlobalKey<FormState>();
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(
          budget == null ? 'New monthly budget' : 'Edit monthly budget',
        ),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  itemHeight: null,
                  initialValue: category,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    const DropdownMenuItem(
                      value: '*',
                      child: Text('Overall budget'),
                    ),
                    ...c.categories
                        .where(
                          (cat) => ![
                            'income',
                            'investment',
                            'balance',
                          ].contains(cat),
                        )
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(categoryLabel(cat)),
                          ),
                        ),
                  ],
                  onChanged: (v) => setState(() => category = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Monthly limit (${c.currency})',
                  ),
                  validator: positiveMoneyValidator,
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (budget != null)
            TextButton(
              onPressed: () async {
                if (await confirm(
                  ctx,
                  'Delete budget?',
                  'Transactions will be kept.',
                )) {
                  final ok = await c.action(() async {
                    await c.store.db.delete(
                      'budgets',
                      where: 'id=?',
                      whereArgs: [budget['id']],
                    );
                  });
                  if (ok && ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Delete'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          Obx(
            () => FilledButton(
              onPressed: c.busy.value
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      final ok = await c.action(() async {
                        final existing = c.budgets.where(
                          (b) =>
                              b['category'] == category &&
                              b['id'] != budget?['id'],
                        );
                        if (existing.isNotEmpty) {
                          throw const FormatException(
                            'A budget for this category already exists. Edit the existing budget.',
                          );
                        }
                        await c.store.db.insert('budgets', {
                          'id': budget?['id'] ?? newId(),
                          'ledger_id': c.activeId.value,
                          'category': category,
                          'amount': parseMoney(amount.text),
                        }, conflictAlgorithm: ConflictAlgorithm.replace);
                      });
                      if (ok && ctx.mounted) Navigator.pop(ctx);
                    },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    ),
  );
  // Dialog route may still be animating when the future resolves.
}

String? positiveMoneyValidator(String? value) {
  try {
    if (parseMoney(value ?? '') <= 0) {
      return 'Enter an amount greater than zero.';
    }
  } catch (_) {
    return 'Use digits and a dot, without grouping separators.';
  }
  return null;
}

class WalletsPage extends StatelessWidget {
  const WalletsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<LedgerController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Your wallets')),
      body: Obx(
        () => PageBody(
          children: [
            Text(
              c.fmt(c.balance),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const Text('Total recorded balance'),
            const SizedBox(height: 24),
            ...c.wallets.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Panel(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: Text(w.name),
                    subtitle: Text(
                      '${c.fmt(c.walletBalance(w))}\nOpening balance: ${c.fmt(w.opening)}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => editWallet(context, wallet: w),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => editWallet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add wallet'),
            ),
            const NoteBox(
              'Use an opening balance for money you already had before your first tracked transaction. Transfers stay inside this ledger and currency. Imported snapshots are kept separately so balances are not counted twice.',
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> editWallet(BuildContext context, {Wallet? wallet}) async {
  final c = Get.find<LedgerController>(),
      name = TextEditingController(text: wallet?.name ?? ''),
      opening = TextEditingController(text: decimalMoney(wallet?.opening ?? 0)),
      form = GlobalKey<FormState>();
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(wallet == null ? 'Add a wallet' : 'Edit wallet'),
      content: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Wallet name',
                  hintText: 'Cash, Bank, GoPay…',
                ),
                validator: (s) => s == null || s.trim().isEmpty
                    ? 'Enter a wallet name.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: opening,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Opening balance (${c.currency})',
                  helperText: 'Before your first recorded transaction.',
                ),
                validator: (s) {
                  try {
                    parseMoney(s ?? '', signed: true);
                  } catch (_) {
                    return 'Enter a valid balance.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (wallet != null)
          TextButton(
            onPressed: () async {
              final used =
                  c.entries.any(
                    (e) => e.walletId == wallet.id || e.toWalletId == wallet.id,
                  ) ||
                  c.recurring.any((r) => r['wallet_id'] == wallet.id);
              if (used || c.wallets.length == 1) {
                c.notify(
                  'Keep at least one wallet. A wallet with transactions or schedules cannot be deleted.',
                );
                return;
              }
              if (await confirm(ctx, 'Delete wallet?', wallet.name)) {
                final ok = await c.action(() async {
                  await c.store.db.delete(
                    'wallets',
                    where: 'id=?',
                    whereArgs: [wallet.id],
                  );
                });
                if (ok && ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        Obx(
          () => FilledButton(
            onPressed: c.busy.value
                ? null
                : () async {
                    if (!form.currentState!.validate()) return;
                    final ok = await c.action(() async {
                      final row = {
                        'id': wallet?.id ?? newId(),
                        'ledger_id': c.activeId.value,
                        'name': name.text.trim(),
                        'opening': parseMoney(opening.text, signed: true),
                      };
                      if (wallet == null) {
                        await c.store.db.insert('wallets', row);
                      } else {
                        await c.store.db.update(
                          'wallets',
                          row,
                          where: 'id=?',
                          whereArgs: [wallet.id],
                        );
                      }
                    });
                    if (ok && ctx.mounted) Navigator.pop(ctx);
                  },
            child: const Text('Save'),
          ),
        ),
      ],
    ),
  );
}

class RecurringPage extends StatelessWidget {
  const RecurringPage({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<LedgerController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Recurring transactions')),
      body: Obx(
        () => PageBody(
          children: [
            const NoteBox(
              'Set up salary, subscriptions, gym memberships, bills or regular investments. Due entries wait for your confirmation; nothing is silently posted.',
            ),
            FilledButton.icon(
              onPressed: () => Get.to(() => const RecurringFormPage()),
              icon: const Icon(Icons.add),
              label: const Text('Add recurring transaction'),
            ),
            const SizedBox(height: 24),
            if (c.recurring.isEmpty)
              const EmptyState(
                title: 'One less thing to remember',
                message: 'Create a schedule for a transaction that repeats.',
                icon: Icons.event_repeat,
              ),
            ...c.recurring.map((r) {
              final due = !strictDate(
                r['next_date'] as String,
              ).isAfter(dayOnly(DateTime.now()));
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r['description'] as String,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit recurring transaction',
                            onPressed: () =>
                                Get.to(() => RecurringFormPage(rule: r)),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                      Text('${c.fmt(r['amount'] as int)} · ${r['frequency']}'),
                      const SizedBox(height: 6),
                      Text(
                        '${due ? 'Due' : 'Next'} ${DateFormat('d MMM yyyy').format(strictDate(r['next_date'] as String))} · ${c.walletName(r['wallet_id'] as String)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (due)
                            FilledButton(
                              onPressed: c.busy.value
                                  ? null
                                  : () => c.action(
                                      () => c.store.recordRecurring(r),
                                      success: 'Due transaction recorded.',
                                    ),
                              child: const Text('Record due entry'),
                            ),
                          OutlinedButton(
                            onPressed: c.busy.value
                                ? null
                                : () async {
                                    if (await confirm(
                                      context,
                                      'Skip this occurrence?',
                                      'The next date will advance without creating a transaction.',
                                      action: 'Skip',
                                    )) {
                                      await c.action(() async {
                                        final date = strictDate(
                                          r['next_date'] as String,
                                        );
                                        await c.store.db.update(
                                          'recurring',
                                          {
                                            'next_date': dateKey(
                                              nextOccurrence(
                                                date,
                                                r['frequency'] as String,
                                                r['anchor'] as int,
                                              ),
                                            ),
                                          },
                                          where: 'id=?',
                                          whereArgs: [r['id']],
                                        );
                                      });
                                    }
                                  },
                            child: const Text('Skip once'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class RecurringFormPage extends StatefulWidget {
  final DbRow? rule;
  const RecurringFormPage({super.key, this.rule});
  @override
  State<RecurringFormPage> createState() => _RecurringFormState();
}

class _RecurringFormState extends State<RecurringFormPage> {
  final c = Get.find<LedgerController>(), form = GlobalKey<FormState>();
  late final TextEditingController name, amount;
  late String wallet, category, frequency, kind;
  late DateTime date;
  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    name = TextEditingController(text: r?['description'] as String? ?? '');
    amount = TextEditingController(
      text: r == null ? '' : decimalMoney(r['amount'] as int),
    );
    wallet = r?['wallet_id'] as String? ?? c.wallets.first.id;
    category = r?['category'] as String? ?? 'subscription';
    frequency = r?['frequency'] as String? ?? 'monthly';
    kind = r?['kind'] as String? ?? 'expense';
    date = r == null
        ? dayOnly(DateTime.now())
        : strictDate(r['next_date'] as String);
  }

  @override
  void dispose() {
    name.dispose();
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.rule == null
            ? 'New recurring transaction'
            : 'Edit recurring transaction',
      ),
    ),
    body: Form(
      key: form,
      child: PageBody(
        children: [
          TextFormField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Description'),
            validator: (s) =>
                s == null || s.trim().isEmpty ? 'Add a description.' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Amount (${c.currency})'),
            validator: positiveMoneyValidator,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField(
            itemHeight: null,
            initialValue: kind,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Type'),
            items: ['expense', 'income', 'investment']
                .map(
                  (k) => DropdownMenuItem(
                    value: k,
                    child: Text(kindLabel(EntryKind.values.byName(k))),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => kind = v!),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField(
            itemHeight: null,
            initialValue: category,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Category'),
            items: c.categories
                .map(
                  (cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(categoryLabel(cat)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => category = v!),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField(
            itemHeight: null,
            initialValue: wallet,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Wallet'),
            items: c.wallets
                .map((w) => DropdownMenuItem(value: w.id, child: Text(w.name)))
                .toList(),
            onChanged: (v) => setState(() => wallet = v!),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField(
            itemHeight: null,
            isExpanded: true,
            initialValue: frequency,
            decoration: const InputDecoration(labelText: 'Repeats'),
            items: ['weekly', 'monthly', 'yearly']
                .map(
                  (f) => DropdownMenuItem(
                    value: f,
                    child: Text(f[0].toUpperCase() + f.substring(1)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => frequency = v!),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                firstDate: DateTime(1900),
                lastDate: DateTime(2200),
                initialDate: date,
              );
              if (d != null) setState(() => date = d);
            },
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text('Next date: ${DateFormat('d MMM yyyy').format(date)}'),
          ),
          const NoteBox(
            'Monthly dates keep their original day. A schedule on the 31st uses the last day of shorter months, then returns to the 31st.',
          ),
          Obx(
            () => FilledButton(
              onPressed: c.busy.value
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      final ok = await c.action(() async {
                        final data = {
                          'id': widget.rule?['id'] ?? newId(),
                          'ledger_id': c.activeId.value,
                          'wallet_id': wallet,
                          'description': name.text.trim(),
                          'amount': parseMoney(amount.text),
                          'kind': kind,
                          'category': category,
                          'frequency': frequency,
                          'next_date': dateKey(date),
                          'anchor':
                              widget.rule != null &&
                                  dateKey(date) == widget.rule!['next_date']
                              ? widget.rule!['anchor']
                              : date.day,
                          'active': 1,
                        };
                        await c.store.db.insert(
                          'recurring',
                          data,
                          conflictAlgorithm: ConflictAlgorithm.replace,
                        );
                      });
                      if (ok) Get.back();
                    },
              child: const Text('Save schedule'),
            ),
          ),
          if (widget.rule != null)
            TextButton(
              onPressed: () async {
                if (await confirm(
                  context,
                  'Delete this schedule?',
                  'Previously recorded transactions will be kept.',
                )) {
                  final ok = await c.action(() async {
                    await c.store.db.delete(
                      'recurring',
                      where: 'id=?',
                      whereArgs: [widget.rule!['id']],
                    );
                  });
                  if (ok) Get.back();
                }
              },
              child: const Text('Delete schedule'),
            ),
        ],
      ),
    ),
  );
}
