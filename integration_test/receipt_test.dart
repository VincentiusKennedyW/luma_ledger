import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:luma_ledger/main.dart';
import 'package:luma_ledger/controllers/ledger_controller.dart';
import 'package:luma_ledger/data/database.dart';
import 'package:luma_ledger/core/models.dart';
import 'package:luma_ledger/receipts/receipt_inbox.dart';
import 'package:luma_ledger/receipts/receipt_parser.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Offline OCR, receipt review, mandatory wallet, SQLite duplicate and cleanup',
    (tester) async {
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = '${dir.path}/receipt-integration-isolated.db';
      await deleteDatabase(dbPath);
      final store = await LedgerDatabase.open(path: dbPath);
      final c = Get.put(LedgerController(store), permanent: true);
      final ledger = await store.createLedger(
        'Demo · fictional receipt',
        'IDR',
      );
      await c.initialize();
      await c.selectLedger(ledger.id);
      final inbox = Get.put(ReceiptInbox(), permanent: true);
      await inbox.start();
      // This integration test runs only on an isolated emulator installation.
      for (final item in inbox.items.toList()) {
        await inbox.discard(item.id);
      }
      final captureKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(key: captureKey, child: const LumaApp()),
      );
      await tester.pumpAndSettle();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 900, 1500),
        Paint()..color = Colors.white,
      );
      final painter = TextPainter(
        textDirection: TextDirection.ltr,
        text: const TextSpan(
          style: TextStyle(color: Colors.black, fontSize: 36, height: 1.6),
          text: '''wondr by BNI
DEMO - FICTIONAL RECEIPT
Pembayaran QRIS berhasil
Rp1
10 Sep 2026 - 12:25:52 WIB
Ref ID: 20260910000000000999
Penerima
TOKO CONTOH
KOTA CONTOH
Sumber dana
PEMILIK CONTOH
******000
Detail pembayaran
Nominal Rp1
Total Rp1
Nama issuer
BNI''',
        ),
      )..layout(maxWidth: 800);
      painter.paint(canvas, const Offset(50, 50));
      final picture = recorder.endRecording();
      final image = await picture.toImage(900, 1500);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${dir.path}/fictional-receipt.png');
      await file.writeAsBytes(png!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
      painter.dispose();
      await ReceiptInbox.channel.invokeMethod<void>('importFile', {
        'path': file.path,
      });
      for (var i = 0; i < 120; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)),
        );
        await tester.pump();
        if (inbox.items.isNotEmpty && !inbox.items.first.reading) break;
      }
      expect(inbox.items, hasLength(1));
      final item = inbox.items.single;
      expect(item.error, isNull);
      expect(item.draft.amount, 100);
      expect(item.draft.merchant, 'TOKO CONTOH');
      expect(item.draft.date, DateTime(2026, 9, 10));
      expect(item.draft.status, ReceiptStatus.successful);
      expect(item.draft.reference, '20260910000000000999');
      await tester.pumpAndSettle();
      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        final boundary =
            captureKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        binding.reportData ??= {};
        final captures =
            binding.reportData!.putIfAbsent(
                  'captures',
                  () => <String, dynamic>{},
                )
                as Map<String, dynamic>;
        captures[name] = base64Encode(data!.buffer.asUint8List());
        image.dispose();
      }

      await capture('receipt-inbox');
      await tester.tap(find.text('Review transaction'));
      await tester.pumpAndSettle();
      await capture('receipt-review');
      await c.changeTheme('dark');
      await tester.pumpAndSettle();
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      await tester.pumpAndSettle();
      await capture('receipt-review-large-dark');
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await c.changeTheme('light');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, '1'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.byWidgetPredicate((widget) => widget is FilledButton),
      );
      expect(button.onPressed, isNull);
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save transaction'));
      await tester.pumpAndSettle();
      expect(c.entries, isEmpty);
      expect(find.text('Choose the wallet you paid from.'), findsOneWidget);
      final wallet = find.byType(DropdownButtonFormField<String>).first;
      await tester.ensureVisible(wallet);
      await tester.pumpAndSettle();
      await tester.tap(wallet);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Main wallet').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await capture('receipt-review-details');
      await tester.tap(find.text('Save transaction'));
      await tester.pumpAndSettle();
      expect(c.entries, hasLength(1));
      final saved = c.entries.single;
      expect(saved.amount, 100);
      expect(saved.walletId, c.wallets.single.id);
      expect(saved.category, 'other');
      expect(inbox.items, isEmpty);
      expect(await File(item.path).exists(), false);
      expect(
        await store.receiptMatch(
          ledger.id,
          item.draft.importKey,
          100,
          saved.date,
          'TOKO CONTOH',
        ),
        isNotNull,
      );
      expect(
        await store.receiptMatch(
          ledger.id,
          'different-key',
          100,
          saved.date,
          'toko contoh',
        ),
        isNotNull,
      );
      expect(
        await store.receiptMatch(
          'other-ledger',
          item.draft.importKey,
          100,
          saved.date,
          'TOKO CONTOH',
        ),
        isNull,
      );
      await expectLater(
        store.saveEntry(
          Entry(
            id: newId(),
            ledgerId: ledger.id,
            walletId: saved.walletId,
            date: saved.date,
            amount: 100,
            kind: EntryKind.expense,
            description: 'TOKO CONTOH',
            category: 'other',
            importKey: saved.importKey,
          ),
        ),
        throwsA(isA<DatabaseException>()),
      );
      // Receipt keys remain present in the ordinary JSON backup format.
      final rows = await store.rows('entries', ledgerId: ledger.id);
      expect(rows.single['import_key'], item.draft.importKey);
      await file.delete();
      expect(tester.takeException(), isNull);
      await store.db.close();
      await deleteDatabase(dbPath);
      Get.reset();
    },
  );
}
