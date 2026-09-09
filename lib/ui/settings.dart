import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ledger_controller.dart';
import 'components.dart';
import 'data_tools.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<LedgerController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Obx(
        () => PageBody(
          children: [
            const SectionTitle('Your ledgers'),
            Panel(
              child: Column(
                children: c.ledgers
                    .map(
                      (l) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          l.id == c.activeId.value
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                        ),
                        selected: l.id == c.activeId.value,
                        title: Text(l.name),
                        subtitle: Text(l.currency),
                        enabled: !c.busy.value,
                        onTap: () => c.action(() => c.selectLedger(l.id)),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => newLedgerDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create another ledger'),
            ),
            const SectionTitle('Make it yours'),
            Panel(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    itemHeight: null,
                    initialValue: c.theme.value,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Appearance'),
                    items: const [
                      DropdownMenuItem(
                        value: 'system',
                        child: Text('Follow device'),
                      ),
                      DropdownMenuItem(value: 'light', child: Text('Light')),
                      DropdownMenuItem(value: 'dark', child: Text('Dark')),
                    ],
                    onChanged: (v) => c.changeTheme(v!),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.category_outlined),
                    title: const Text('Categories'),
                    subtitle: Text(
                      '${c.categories.length} categories in this ledger',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.to(() => const CategoriesPage()),
                  ),
                ],
              ),
            ),
            const SectionTitle('Your data'),
            Panel(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.upload_file_outlined),
                    title: const Text('Import CSV'),
                    subtitle: const Text('Bring your existing history'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.toNamed('/import'),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.ios_share_outlined),
                    title: const Text('Export & backup'),
                    subtitle: const Text('Take your data with you'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.toNamed('/export'),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.science_outlined),
                    title: const Text('Explore a demo ledger'),
                    subtitle: const Text('Separate, fictional example data'),
                    trailing: const Icon(Icons.chevron_right),
                    enabled: !c.busy.value,
                    onTap: () => c.action(
                      () => c.createDemo(),
                      success: 'Fictional demo ledger created.',
                    ),
                  ),
                ],
              ),
            ),
            const SectionTitle('About Luma'),
            const NoteBox(
              'Luma 1.1 · On-device storage\n\nNo account, ads or analytics. Everything works offline. Each ledger has its own currency, wallets and history. Currency is fixed after creation to prevent accidental relabeling of money.\n\nThis app does not encrypt its database. Device security and OS backups protect your local files; exported backups are plain JSON. No bank connection or market-price tracking is included.',
            ),
            TextButton.icon(
              onPressed: () async {
                final l = c.ledger;
                if (l == null) return;
                if (await confirm(
                  context,
                  'Delete ${l.name}?',
                  'All transactions, wallets, budgets and schedules in this ledger will be permanently removed. Export a backup first if you need to keep them.',
                )) {
                  final ok = await c.action(() async {
                    await c.store.db.transaction((txn) async {
                      for (final table in [
                        'entries',
                        'recurring',
                        'budgets',
                        'categories',
                        'wallets',
                      ]) {
                        await txn.delete(
                          table,
                          where: 'ledger_id=?',
                          whereArgs: [l.id],
                        );
                      }
                      await txn.delete(
                        'ledgers',
                        where: 'id=?',
                        whereArgs: [l.id],
                      );
                    });
                  });
                  if (ok) Get.offAllNamed('/');
                }
              },
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              label: Text(
                'Delete current ledger',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> newLedgerDialog(BuildContext context) async {
  final c = Get.find<LedgerController>(),
      name = TextEditingController(),
      form = GlobalKey<FormState>();
  var currency = 'IDR';
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Create a ledger'),
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
                    labelText: 'Ledger name',
                    hintText: 'Personal, Household…',
                  ),
                  validator: (s) =>
                      s == null || s.trim().isEmpty ? 'Enter a name.' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField(
                  itemHeight: null,
                  isExpanded: true,
                  initialValue: currency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  items: ['IDR', 'USD', 'EUR', 'SGD', 'AUD']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (s) => setState(() => currency = s!),
                ),
                const NoteBox(
                  'Each ledger has separate wallets and reports. No currency conversion is performed.',
                ),
              ],
            ),
          ),
        ),
        actions: [
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
                      final ok = await c.action(
                        () => c.createLedger(name.text, currency),
                      );
                      if (ok && ctx.mounted) Navigator.pop(ctx);
                    },
              child: const Text('Create'),
            ),
          ),
        ],
      ),
    ),
  );
}

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<LedgerController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: Obx(
        () => PageBody(
          children: [
            const NoteBox(
              'Categories are flexible. Your imported names are normalized to lowercase, so Food and food stay together. Existing transaction history is preserved.',
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final name = TextEditingController(),
                    form = GlobalKey<FormState>();
                await showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Add a category'),
                    content: Form(
                      key: form,
                      child: TextFormField(
                        controller: name,
                        maxLength: 60,
                        decoration: const InputDecoration(
                          labelText: 'Category name',
                        ),
                        validator: (s) {
                          if (s == null ||
                              s.trim().isEmpty ||
                              s.trim() == '*') {
                            return 'Enter a category name.';
                          }
                          if (c.categories.contains(s.trim().toLowerCase())) {
                            return 'This category already exists.';
                          }
                          return null;
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () async {
                          if (!form.currentState!.validate()) return;
                          final ok = await c.action(() async {
                            await c.store.db.insert('categories', {
                              'ledger_id': c.activeId.value,
                              'name': name.text.trim().toLowerCase(),
                            });
                          });
                          if (ok && ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add category'),
            ),
            const SizedBox(height: 16),
            ...c.categories.map(
              (cat) => ListTile(
                leading: CategoryAvatar(cat),
                title: Text(cat),
                subtitle: Text(
                  '${c.entries.where((e) => e.category == cat).length} transactions',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final c = Get.find<LedgerController>(),
      name = TextEditingController(text: 'Personal'),
      form = GlobalKey<FormState>();
  String currency = 'IDR';
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Form(
        key: form,
        child: PageBody(
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/luma-icon.png',
                    width: 48,
                    height: 48,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'luma',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.savings_outlined,
                    size: 38,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your money.\nA little clearer.',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Everyday tracking, useful insights, and a plan that fits your life.',
                  ),
                ],
              ),
            ),
            const SectionTitle('Create your first ledger'),
            TextFormField(
              controller: name,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Your ledger name'),
              validator: (s) => s == null || s.trim().isEmpty
                  ? 'Enter a name for your ledger.'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              itemHeight: null,
              isExpanded: true,
              initialValue: currency,
              decoration: const InputDecoration(labelText: 'Currency'),
              items: const [
                DropdownMenuItem(
                  value: 'IDR',
                  child: Text('IDR · Indonesian rupiah'),
                ),
                DropdownMenuItem(value: 'USD', child: Text('USD · US dollar')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR · Euro')),
                DropdownMenuItem(
                  value: 'SGD',
                  child: Text('SGD · Singapore dollar'),
                ),
                DropdownMenuItem(
                  value: 'AUD',
                  child: Text('AUD · Australian dollar'),
                ),
              ],
              onChanged: (v) => setState(() => currency = v!),
            ),
            const SizedBox(height: 28),
            Obx(
              () => FilledButton(
                onPressed: c.busy.value
                    ? null
                    : () {
                        if (form.currentState!.validate()) {
                          c.action(() => c.createLedger(name.text, currency));
                        }
                      },
                child: Text(
                  c.busy.value ? 'Getting ready…' : 'Start my ledger',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => TextButton(
                onPressed: c.busy.value
                    ? null
                    : () => c.action(() => c.createDemo()),
                child: const Text('Take a look around with demo data'),
              ),
            ),
            TextButton(
              onPressed: () => restoreBackup(context),
              child: const Text('Restore an existing backup'),
            ),
            const NoteBox(
              'No sign-up. No internet required. Import your CSV after setup.',
              icon: Icons.lock_outline,
            ),
          ],
        ),
      ),
    ),
  );
}
