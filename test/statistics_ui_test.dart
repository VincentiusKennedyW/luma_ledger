import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:luma_ledger/controllers/ledger_controller.dart';
import 'package:luma_ledger/core/models.dart';
import 'package:luma_ledger/core/statistics.dart';
import 'package:luma_ledger/data/database.dart';
import 'package:luma_ledger/main.dart';

class _Database implements Database {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late LedgerController c;
  late DateTime date;
  setUp(() {
    Get.testMode = true;
    final now = DateTime.now();
    date = DateTime(now.year, now.month - 1, 2);
    c = Get.put(LedgerController(LedgerDatabase(_Database())), permanent: true);
    c.ledgers.add(const Ledger('l', 'Personal', 'IDR'));
    c.activeId.value = 'l';
    c.wallets.add(const Wallet('w', 'l', 'Cash', 0));
    c.categories.addAll(defaultCategories);
    c.entries.add(
      Entry(
        id: 'expense',
        ledgerId: 'l',
        walletId: 'w',
        date: date,
        amount: 2500000,
        kind: EntryKind.expense,
        description: 'Lunch',
        category: 'food',
      ),
    );
    c.statisticsAnchor.value = DateTime(date.year, date.month);
    c.tab.value = 2;
  });
  tearDown(() => Get.reset());
  testWidgets(
    'Year opens month, day opens matching expenses, return retains month',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const LumaApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yearly'));
      await tester.pumpAndSettle();
      expect(c.statisticsScale.value, StatisticsScale.year);
      await tester.ensureVisible(find.text('Monthly breakdown'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Monthly breakdown'));
      await tester.pumpAndSettle();
      final month = find.text(DateFormat('MMMM').format(date));
      await tester.ensureVisible(month);
      await tester.pumpAndSettle();
      await tester.tap(month);
      await tester.pumpAndSettle();
      expect(c.statisticsScale.value, StatisticsScale.month);
      expect(c.statisticsAnchor.value, DateTime(date.year, date.month));
      await tester.ensureVisible(find.text('Daily breakdown'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daily breakdown'));
      await tester.pumpAndSettle();
      final day = find.text(DateFormat('EEE, d MMM').format(date));
      await tester.ensureVisible(day);
      await tester.pumpAndSettle();
      await tester.tap(day);
      await tester.pumpAndSettle();
      expect(c.tab.value, 1);
      expect(c.filtered.map((e) => e.id), ['expense']);
      await tester.tap(find.text('Insights').last);
      await tester.pumpAndSettle();
      expect(c.statisticsScale.value, StatisticsScale.month);
      expect(c.statisticsAnchor.value, DateTime(date.year, date.month));
      // Recreate expansions after storing a nonzero scroll offset. Their
      // boolean expansion state must not share the list's numeric position.
      c.statisticsScale.value = StatisticsScale.year;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('How to read this report'));
      await tester.pumpAndSettle();
      c.statisticsScale.value = StatisticsScale.month;
      await tester.pumpAndSettle();
      c.statisticsScale.value = StatisticsScale.year;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('All-time and custom reports remain accessible', (tester) async {
    await tester.pumpWidget(const LumaApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More report options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All time or custom dates'));
    await tester.pumpAndSettle();
    expect(find.text('Monthly & yearly statistics'), findsOneWidget);
    await tester.tap(find.text(c.period.value.label).first);
    await tester.pumpAndSettle();
    expect(find.text('All time'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Custom date range'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Custom date range'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('All time'),
      -100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('All time'));
    await tester.pumpAndSettle();
    expect(c.period.value.contains(date), true);
    expect(tester.takeException(), isNull);
  });
}
