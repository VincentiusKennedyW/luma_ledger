import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/models.dart';
import '../core/statistics.dart';
import '../data/database.dart';

class LedgerController extends GetxController {
  final LedgerDatabase store;
  LedgerController(this.store);
  final ledgers = <Ledger>[].obs,
      wallets = <Wallet>[].obs,
      entries = <Entry>[].obs;
  final categories = <String>[].obs;
  final budgets = <DbRow>[].obs, recurring = <DbRow>[].obs;
  final activeId = ''.obs, tab = 0.obs, busy = false.obs, theme = 'light'.obs;
  final period = Period.month(DateTime.now()).obs;
  final statisticsScale = StatisticsScale.month.obs;
  final statisticsAnchor = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  ).obs;
  LedgerStatistics get statistics => LedgerStatistics(
    entries.toList(),
    scale: statisticsScale.value,
    anchor: statisticsAnchor.value,
  );

  void showStatisticsEntries(
    Period range, {
    EntryKind kind = EntryKind.expense,
    String category = 'all',
    String wallet = 'all',
  }) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    period.value = Period(
      range.start,
      range.end.isAfter(tomorrow) ? tomorrow : range.end,
      range.label,
    );
    search.value = '';
    searchInput.clear();
    typeFilter.value = kind.name;
    categoryFilter.value = category;
    walletFilter.value = wallet;
    reviewOnly.value = false;
    tab.value = 1;
  }

  final searchInput = TextEditingController();
  final search = ''.obs,
      typeFilter = 'all'.obs,
      categoryFilter = 'all'.obs,
      walletFilter = 'all'.obs;
  final reviewOnly = false.obs;
  Ledger? get ledger => ledgers.firstWhereOrNull((l) => l.id == activeId.value);
  String get currency => ledger?.currency ?? 'IDR';
  String fmt(int n, {bool compact = false}) =>
      money(n, currency, compact: compact);
  ThemeMode get themeMode => switch (theme.value) {
    'dark' => ThemeMode.dark,
    'light' => ThemeMode.light,
    _ => ThemeMode.system,
  };
  Future<void> initialize() async {
    theme.value = await store.setting('theme') ?? 'light';
    await refreshAll();
    final saved = await store.setting('active_ledger');
    await selectLedger(
      ledgers.firstWhereOrNull((l) => l.id == saved)?.id ??
          ledgers.firstOrNull?.id ??
          '',
    );
  }

  Future<void> refreshAll() async {
    ledgers.assignAll((await store.rows('ledgers')).map(Ledger.fromRow));
    if (!ledgers.any((l) => l.id == activeId.value)) {
      activeId.value = ledgers.firstOrNull?.id ?? '';
    }
    await reload();
  }

  Future<void> reload() async {
    if (activeId.isEmpty) {
      entries.clear();
      wallets.clear();
      budgets.clear();
      recurring.clear();
      categories.clear();
      return;
    }
    final id = activeId.value;
    final data = await Future.wait([
      store.rows('wallets', ledgerId: id),
      store.rows('entries', ledgerId: id),
      store.rows('categories', ledgerId: id),
      store.rows('budgets', ledgerId: id),
      store.rows('recurring', ledgerId: id),
    ]);
    wallets.assignAll(data[0].map(Wallet.fromRow));
    entries.assignAll(
      data[1].map(Entry.fromRow).toList()..sort((a, b) {
        final d = b.date.compareTo(a.date);
        return d == 0 ? b.id.compareTo(a.id) : d;
      }),
    );
    categories.assignAll(
      data[2].map((r) => r['name'] as String).toList()..sort(),
    );
    budgets.assignAll(data[3]);
    recurring.assignAll(
      data[4]..sort(
        (a, b) =>
            (a['next_date'] as String).compareTo(b['next_date'] as String),
      ),
    );
  }

  Future<void> selectLedger(String id) async {
    activeId.value = id;
    search.value = '';
    searchInput.clear();
    typeFilter.value = 'all';
    categoryFilter.value = 'all';
    walletFilter.value = 'all';
    reviewOnly.value = false;
    await store.setSetting('active_ledger', id);
    await reload();
  }

  Future<bool> action(Future<void> Function() work, {String? success}) async {
    if (busy.value) return false;
    busy.value = true;
    try {
      await work();
      await refreshAll();
      if (success != null) notify(success);
      return true;
    } catch (e) {
      notify(
        e is FormatException
            ? e.message.toString()
            : 'Could not save your changes. Please try again.',
        'Something went wrong',
      );
      return false;
    } finally {
      busy.value = false;
    }
  }

  void notify(String message, [String title = 'Luma']) {
    Get.showSnackbar(
      GetSnackBar(
        title: title,
        message: message,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        snackPosition: SnackPosition.TOP,
      ),
    );
  }

  Report get report => Report(entries.toList(), period.value);
  List<Entry> get filtered {
    final query = search.value.toLowerCase();
    return entries
        .where(
          (e) =>
              period.value.contains(e.date) &&
              (typeFilter.value == 'all' || e.kind.name == typeFilter.value) &&
              (categoryFilter.value == 'all' ||
                  e.category == categoryFilter.value) &&
              (walletFilter.value == 'all' ||
                  e.walletId == walletFilter.value ||
                  e.toWalletId == walletFilter.value) &&
              (!reviewOnly.value || e.review) &&
              (query.isEmpty ||
                  '${e.description} ${e.note} ${e.category}'
                      .toLowerCase()
                      .contains(query)),
        )
        .toList();
  }

  int walletBalance(Wallet wallet) => entries
      .where((e) => !e.date.isAfter(dayOnly(DateTime.now())))
      .fold(wallet.opening, (n, e) {
        if (e.kind == EntryKind.checkpoint) return n;
        if (e.kind == EntryKind.transfer) {
          return n +
              (e.toWalletId == wallet.id ? e.amount : 0) -
              (e.walletId == wallet.id ? e.amount : 0);
        }
        return e.walletId != wallet.id
            ? n
            : n + (e.kind == EntryKind.income ? e.amount : -e.amount);
      });
  int get balance => wallets.fold(0, (n, w) => n + walletBalance(w));
  List<DbRow> get due => recurring
      .where(
        (r) =>
            r['active'] == 1 &&
            !strictDate(
              r['next_date'] as String,
            ).isAfter(dayOnly(DateTime.now())),
      )
      .toList();
  String walletName(String? id) =>
      wallets.firstWhereOrNull((w) => w.id == id)?.name ?? 'Wallet';
  Future<void> changeTheme(String value) async {
    theme.value = value;
    await store.setSetting('theme', value);
    Get.changeThemeMode(themeMode);
  }

  void allHistory() {
    final first = entries.isEmpty ? DateTime.now() : entries.last.date;
    final last = entries.isEmpty ? DateTime.now() : entries.first.date;
    period.value = Period(
      DateTime(first.year, first.month, 1),
      DateTime(last.year, last.month + 1, 1),
      'All time',
    );
  }

  Future<void> createLedger(String name, String currency) async {
    final l = await store.createLedger(name, currency);
    await refreshAll();
    await selectLedger(l.id);
    period.value = Period.month(DateTime.now());
  }

  Future<void> createDemo() async {
    await createLedger('Demo · fictional data', 'IDR');
    final now = DateTime.now(), wallet = wallets.first.id;
    final list = <Entry>[];
    void add(
      DateTime date,
      int value,
      EntryKind kind,
      String desc,
      String cat,
    ) {
      list.add(
        Entry(
          id: newId(),
          ledgerId: activeId.value,
          walletId: wallet,
          date: date,
          amount: value * 100,
          kind: kind,
          description: desc,
          category: cat,
        ),
      );
    }

    for (var m = 5; m >= 0; m--) {
      final first = DateTime(now.year, now.month - m, 1);
      add(first, 8500000, EntryKind.income, 'Monthly salary', 'income');
      final limit = m == 0 ? now.day : 27;
      for (var d = 1; d <= limit; d += 2) {
        add(
          DateTime(first.year, first.month, d),
          18000 + d * 1000,
          EntryKind.expense,
          d % 3 == 0 ? 'Morning coffee' : 'Lunch at the corner',
          'food',
        );
        if (d % 3 == 1) {
          add(
            DateTime(first.year, first.month, d),
            35000,
            EntryKind.expense,
            'Fuel stop',
            'transport',
          );
        }
      }
      add(first, 850000, EntryKind.expense, 'Monthly groceries', 'shopping');
      add(first, 350000, EntryKind.expense, 'Gym membership', 'gym');
      add(
        first,
        1250000,
        EntryKind.investment,
        'Monthly investing',
        'investment',
      );
      add(first, 120000, EntryKind.expense, 'Internet plan', 'bills');
    }
    await store.importEntries(list);
    await store.db.insert('budgets', {
      'id': newId(),
      'ledger_id': activeId.value,
      'category': 'food',
      'amount': 180000000,
    });
    await store.db.insert('budgets', {
      'id': newId(),
      'ledger_id': activeId.value,
      'category': 'shopping',
      'amount': 150000000,
    });
    await store.db.insert('recurring', {
      'id': newId(),
      'ledger_id': activeId.value,
      'wallet_id': wallet,
      'description': 'Gym membership',
      'category': 'gym',
      'amount': 35000000,
      'kind': 'expense',
      'frequency': 'monthly',
      'next_date': dateKey(DateTime(now.year, now.month + 1, 1)),
      'anchor': 1,
      'active': 1,
    });
    await reload();
  }

  @override
  void onClose() {
    searchInput.dispose();
    super.onClose();
  }
}
