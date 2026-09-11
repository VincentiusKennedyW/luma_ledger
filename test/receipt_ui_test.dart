import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:luma_ledger/controllers/ledger_controller.dart';
import 'package:luma_ledger/core/models.dart';
import 'package:luma_ledger/data/database.dart';
import 'package:luma_ledger/receipts/receipt_inbox.dart';
import 'package:luma_ledger/ui/entry_form.dart';
import 'package:luma_ledger/ui/receipt_import.dart';
import 'package:luma_ledger/ui/theme.dart';
import 'receipt_parser_test.dart' show receiptExample;

class _Database implements Database {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SharedReceipt receipt;
  setUp(() {
    Get.testMode = true;
    final c = Get.put(
      LedgerController(LedgerDatabase(_Database())),
      permanent: true,
    );
    c.ledgers.add(const Ledger('l', 'Personal', 'IDR'));
    c.activeId.value = 'l';
    c.wallets.add(const Wallet('w', 'l', 'Main wallet', 0));
    c.categories.addAll(defaultCategories);
    receipt = SharedReceipt({
      'id': 'fictional',
      'path': '/not-an-image',
      'hash': 'fictional',
      'text': receiptExample,
    });
    Get.put(ReceiptInbox(), permanent: true).items.add(receipt);
  });
  tearDown(Get.reset);
  for (final size in [
    const Size(375, 812),
    const Size(844, 390),
    const Size(768, 1024),
  ]) {
    for (final scale in [1.0, 3.2]) {
      testWidgets('Receipt form and inbox reflow at $size, text$scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final page in [
          const ReceiptImportPage(),
          EntryFormPage(receipt: receipt),
        ]) {
          await tester.pumpWidget(
            GetMaterialApp(
              theme: lumaTheme(Brightness.dark),
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(scale),
                ),
                child: page,
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (page is EntryFormPage) {
            final save = find.byWidgetPredicate(
              (widget) => widget is FilledButton,
            );
            expect(tester.widget<FilledButton>(save).onPressed, isNull);
            await tester.ensureVisible(find.byType(CheckboxListTile));
            await tester.pumpAndSettle();
            await tester.tap(find.byType(CheckboxListTile));
            await tester.pumpAndSettle();
            await tester.tap(save);
            await tester.pumpAndSettle();
            expect(
              find.text('Choose the wallet you paid from.'),
              findsOneWidget,
            );
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }
      });
    }
  }
  testWidgets('Failed receipt cannot be confirmed or saved', (tester) async {
    final failed = SharedReceipt({
      'id': 'failed',
      'path': '/unused',
      'hash': 'failed',
      'text': receiptExample.replaceAll('berhasil', 'gagal'),
    });
    await tester.pumpWidget(
      GetMaterialApp(
        theme: lumaTheme(Brightness.light),
        home: EntryFormPage(receipt: failed),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).onChanged,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byWidgetPredicate((widget) => widget is FilledButton),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
