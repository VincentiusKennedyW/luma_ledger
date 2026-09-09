import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:luma_ledger/controllers/ledger_controller.dart';
import 'package:luma_ledger/core/models.dart';
import 'package:luma_ledger/data/database.dart';
import 'package:luma_ledger/ui/overview.dart';
import 'package:luma_ledger/ui/planning.dart';
import 'package:luma_ledger/ui/entry_form.dart';
import 'package:luma_ledger/ui/theme.dart';
import 'package:luma_ledger/ui/settings.dart';
import 'package:luma_ledger/ui/data_tools.dart';
import 'package:luma_ledger/main.dart';

class UnusedDatabase implements Database {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late LedgerController c;
  setUp(() {
    Get.testMode = true;
    WidgetController.hitTestWarningShouldBeFatal = true;
    c = Get.put(LedgerController(LedgerDatabase(UnusedDatabase())));
    c.ledgers.add(const Ledger('l', 'Personal', 'IDR'));
    c.activeId.value = 'l';
    c.wallets.add(const Wallet('w', 'l', 'Main wallet', 0));
    c.categories.addAll(defaultCategories);
    c.budgets.add({
      'id': 'budget',
      'ledger_id': 'l',
      'category': 'food',
      'amount': 10000000,
    });
    c.entries.addAll([
      Entry(
        id: '1',
        ledgerId: 'l',
        walletId: 'w',
        date: DateTime.now(),
        amount: 950000000,
        kind: EntryKind.income,
        description: 'Monthly salary',
        category: 'income',
      ),
      Entry(
        id: '2',
        ledgerId: 'l',
        walletId: 'w',
        date: DateTime.now(),
        amount: 1800000,
        kind: EntryKind.expense,
        description: 'Lunch with a longer description',
        category: 'food',
      ),
    ]);
  });
  tearDown(() => Get.reset());
  for (final size in [
    const Size(375, 812),
    const Size(844, 390),
    const Size(768, 1024),
  ]) {
    for (final scale in [1.0, 2.0, 3.2]) {
      for (final dark in [false, true]) {
        testWidgets(
          'Core screens ${size.width} × ${size.height}, text $scale, dark $dark',
          (tester) async {
            final oldHandler = FlutterError.onError;
            FlutterError.onError = (details) {
              debugPrint(details.toString());
              oldHandler!(details);
            };
            addTearDown(() => FlutterError.onError = oldHandler);
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            for (final page in [
              const AppShell(),
              const WelcomePage(),
              const OverviewPage(),
              const TransactionsPage(),
              const InsightsPage(),
              const PlanningPage(),
              const EntryFormPage(),
              const SettingsPage(),
              const ImportPage(),
              const ExportPage(),
              const WalletsPage(),
              const RecurringPage(),
            ]) {
              await tester.pumpWidget(
                GetMaterialApp(
                  theme: lumaTheme(dark ? Brightness.dark : Brightness.light),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(scale),
                      disableAnimations: true,
                    ),
                    child: child!,
                  ),
                  home: Scaffold(body: page),
                ),
              );
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: '${page.runtimeType}',
              );
              final scroll = find.byType(Scrollable).first;
              await tester.drag(scroll, const Offset(0, -700));
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: 'Scrolled ${page.runtimeType}',
              );
              await tester.pumpWidget(const SizedBox());
            }
          },
        );
      }
    }
  }
}
