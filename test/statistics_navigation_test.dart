import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:luma_ledger/controllers/ledger_controller.dart';
import 'package:luma_ledger/core/models.dart';
import 'package:luma_ledger/data/database.dart';

class _UnusedDatabase implements Database {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'Statistics drill-down clears stale filters and matches actual expenses',
    () {
      final c = LedgerController(LedgerDatabase(_UnusedDatabase()));
      final now = DateTime.now();
      c.search.value = 'old query';
      c.searchInput.text = 'old query';
      c.reviewOnly.value = true;
      c.categoryFilter.value = 'shopping';
      c.walletFilter.value = 'other';
      c.entries.addAll([
        for (final date in [
          DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day + 1),
        ])
          Entry(
            id: '$date',
            ledgerId: 'l',
            walletId: 'w',
            date: date,
            amount: 100,
            kind: EntryKind.expense,
            description: 'Food',
            category: 'food',
          ),
        Entry(
          id: 'transfer',
          ledgerId: 'l',
          walletId: 'w',
          toWalletId: 'other',
          date: now,
          amount: 500,
          kind: EntryKind.transfer,
          description: 'Transfer',
          category: 'balance',
        ),
      ]);
      c.showStatisticsEntries(Period.month(now), category: 'food');
      expect(c.filtered.length, 1);
      expect(c.filtered.single.id, '${DateTime(now.year, now.month, now.day)}');
      expect(c.tab.value, 1);
      expect(c.searchInput.text, isEmpty);
      expect(c.reviewOnly.value, false);
      expect(c.walletFilter.value, 'all');
      c.searchInput.dispose();
      Get.reset();
    },
  );
}
