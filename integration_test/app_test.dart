import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:luma_ledger/core/statistics.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:luma_ledger/controllers/ledger_controller.dart';
import 'package:luma_ledger/core/models.dart';
import 'package:luma_ledger/data/csv_import.dart';
import 'package:luma_ledger/data/database.dart';
import 'package:luma_ledger/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late LedgerDatabase store;
  late String path;
  setUpAll(() async {
    path = p.join(await getDatabasesPath(), 'luma-integration-isolated.db');
    await deleteDatabase(path);
    store = await LedgerDatabase.open(path: path);
  });
  tearDownAll(() async {
    await store.db.close();
    await deleteDatabase(path);
    Get.reset();
  });
  testWidgets(
    'SQLite migrations, isolation, import, transfer, schedules and atomic restore',
    (tester) async {
      final ledger = await store.createLedger('Test ledger', 'IDR');
      final wallet =
          (await store.rows('wallets', ledgerId: ledger.id)).first['id']
              as String;
      const source =
          'date,amount,description,category,isIncome,isBalanceForward,note\n2026-01-01,100000,Salary,income,true,false,\n2026-01-01,500000,Prior balance,balance,true,true,\n2026-01-02,18000,Lunch,Food,false,false,\n2026-01-02,20000,Investment,investment,false,false,';
      final preview = CsvImporter.parse(
        source,
        ledgerId: ledger.id,
        walletId: wallet,
      );
      expect(await store.importEntries(preview.entries), 4);
      expect(await store.importEntries(preview.entries), 0);
      final secondWallet = newId();
      await store.db.insert('wallets', {
        'id': secondWallet,
        'ledger_id': ledger.id,
        'name': 'Cash',
        'opening': 0,
      });
      final transfer = Entry(
        id: newId(),
        ledgerId: ledger.id,
        walletId: wallet,
        toWalletId: secondWallet,
        date: DateTime(2026, 1, 3),
        amount: 1000000,
        kind: EntryKind.transfer,
        description: 'ATM withdrawal',
        category: 'balance',
      );
      await store.saveEntry(transfer);
      final c = Get.put(LedgerController(store));
      await c.initialize();
      await c.selectLedger(ledger.id);
      expect(c.balance, 6200000);
      expect(
        c.walletBalance(c.wallets.firstWhere((w) => w.id == secondWallet)),
        1000000,
      );
      final other = await store.createLedger('Other person', 'USD');
      final otherWallet =
          (await store.rows('wallets', ledgerId: other.id)).first['id']
              as String;
      await expectLater(
        store.saveEntry(
          Entry(
            id: newId(),
            ledgerId: ledger.id,
            walletId: otherWallet,
            date: DateTime.now(),
            amount: 100,
            kind: EntryKind.expense,
            description: 'Wrong ledger',
            category: 'food',
          ),
        ),
        throwsFormatException,
      );
      await expectLater(
        store.importEntries([
          Entry(
            id: newId(),
            ledgerId: ledger.id,
            walletId: wallet,
            date: DateTime.now(),
            amount: 100,
            kind: EntryKind.expense,
            description: 'Rolled back',
            category: 'food',
          ),
          Entry(
            id: newId(),
            ledgerId: ledger.id,
            walletId: 'missing',
            date: DateTime.now(),
            amount: 100,
            kind: EntryKind.expense,
            description: 'Invalid',
            category: 'food',
          ),
        ]),
        throwsFormatException,
      );
      expect((await store.rows('entries')).length, 5);
      final rule = <String, Object?>{
        'id': newId(),
        'ledger_id': ledger.id,
        'wallet_id': wallet,
        'description': 'Monthly plan',
        'category': 'subscription',
        'amount': 10000,
        'kind': 'expense',
        'frequency': 'monthly',
        'next_date': '2026-01-31',
        'anchor': 31,
        'active': 1,
      };
      await store.db.insert('recurring', rule);
      await store.recordRecurring(rule);
      await store.recordRecurring(rule);
      expect((await store.rows('entries')).length, 6);
      expect((await store.rows('recurring')).single['next_date'], '2026-02-28');
      final backup = await store.backup();
      final corrupt = jsonDecode(backup) as Map<String, dynamic>;
      (corrupt['entries'] as List).first['wallet_id'] = 'nonexistent';
      await expectLater(
        store.restore(jsonEncode(corrupt)),
        throwsFormatException,
      );
      expect((await store.rows('entries')).length, 6);
      await store.restore(backup);
      expect((await store.rows('entries')).length, 6);
      await store.db.close();
      store = await LedgerDatabase.open(path: path);
      expect((await store.rows('entries')).length, 6);
      Get.reset();
    },
  );
  testWidgets('Daily entry workflow and native screen captures', (
    tester,
  ) async {
    final c = Get.put(LedgerController(store));
    await c.initialize();
    await c.createDemo();
    final captureKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: captureKey, child: const LumaApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Overview'), findsWidgets);
    expect(tester.takeException(), isNull);
    final originalCount = c.entries.length;
    await tester.tap(find.byTooltip('Add transaction'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount (IDR)'),
      '18500',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'What was it for?'),
      'Integration lunch',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save transaction'));
    await tester.pumpAndSettle();
    expect(c.entries.length, originalCount + 1);
    expect(c.entries.any((e) => e.description == 'Integration lunch'), true);
    // Allow the success toast to finish before captures.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      final boundary =
          captureKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = await getApplicationDocumentsDirectory();
      await File(
        '${directory.path}/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      binding.reportData ??= <String, dynamic>{};
      final captures =
          binding.reportData!.putIfAbsent('captures', () => <String, dynamic>{})
              as Map<String, dynamic>;
      captures[name] = base64Encode(bytes.buffer.asUint8List());
    }

    await capture('luma-overview');
    await tester.tap(find.byTooltip('Add transaction'));
    await tester.pumpAndSettle();
    await capture('luma-add');
    await tester.tap(find.text('Category'));
    await tester.pumpAndSettle();
    await capture('luma-categories');
    Get.back();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quick-income')));
    await tester.pumpAndSettle();
    expect(find.text('Income description'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(find.text('Integration lunch'), findsOneWidget);
    await capture('luma-activity');
    await tester.tap(find.byTooltip('Filter transactions'));
    await tester.pumpAndSettle();
    await capture('luma-filters');
    await tester.tap(find.text('Investment'));
    await tester.pumpAndSettle();
    expect(c.typeFilter.value, 'investment');
    await tester.tap(find.text('Reset filters'));
    await tester.pumpAndSettle();
    expect(c.typeFilter.value, 'all');
    Get.back();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insights').last);
    await tester.pumpAndSettle();
    await capture('luma-insights');
    await tester.tap(find.text('Yearly'));
    await tester.pumpAndSettle();
    expect(c.statisticsScale.value, StatisticsScale.year);
    await capture('luma-yearly');
    await tester.ensureVisible(find.text('Monthly breakdown'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly breakdown'));
    await tester.pumpAndSettle();
    await capture('luma-monthly-breakdown');
    final currentMonth = find.text(DateFormat('MMMM').format(DateTime.now()));
    await tester.ensureVisible(currentMonth);
    await tester.pumpAndSettle();
    await tester.tap(currentMonth);
    await tester.pumpAndSettle();
    expect(c.statisticsScale.value, StatisticsScale.month);
    await capture('luma-month-drilldown');
    await tester.ensureVisible(find.text('Daily breakdown'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily breakdown'));
    await tester.pumpAndSettle();
    final firstDay = DateTime(DateTime.now().year, DateTime.now().month);
    final dayRow = find.text(DateFormat('EEE, d MMM').format(firstDay));
    await tester.ensureVisible(dayRow);
    await tester.pumpAndSettle();
    await tester.tap(dayRow);
    await tester.pumpAndSettle();
    expect(c.tab.value, 1);
    expect(
      c.filtered.every(
        (e) => e.kind == EntryKind.expense && e.date == firstDay,
      ),
      true,
    );
    await capture('luma-day-expenses');
    await tester.tap(find.text('Insights').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Where your money went'));
    await tester.pumpAndSettle();
    await capture('luma-categories-report');
    c.statisticsScale.value = StatisticsScale.year;
    await c.changeTheme('dark');
    await tester.pumpAndSettle();
    tester
        .state<ScrollableState>(
          find
              .ancestor(
                of: find.text('Yearly'),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    await capture('luma-yearly-dark');
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    await tester.pumpAndSettle();
    await capture('luma-large-text');
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await tester.pumpAndSettle();
    await c.changeTheme('light');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan').last);
    await tester.pumpAndSettle();
    await capture('luma-plan');
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await capture('luma-settings');
    Get.back();
    await tester.pumpAndSettle();
    Get.toNamed('/import');
    await tester.pumpAndSettle();
    await capture('luma-import');
    Get.back();
    await tester.pumpAndSettle();
    c.tab.value = 0;
    await c.changeTheme('dark');
    await tester.pumpAndSettle();
    await capture('luma-dark');
    await c.changeTheme('light');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
