import 'package:flutter_test/flutter_test.dart';
import 'package:luma_ledger/core/models.dart';
import 'package:luma_ledger/data/csv_import.dart';

const header =
    'date,amount,description,category,isIncome,isBalanceForward,note';
Entry entry(EntryKind kind, int amount, {DateTime? date}) => Entry(
  id: newId(),
  ledgerId: 'ledger',
  walletId: 'wallet',
  date: date ?? DateTime(2026, 1, 5),
  amount: amount,
  kind: kind,
  description: 'Example',
  category: 'food',
);
void main() {
  group('Exact money', () {
    test('decimal amount is stored without floating point rounding', () {
      expect(parseMoney('0.29'), 29);
      expect(parseMoney('18000.0'), 1800000);
      expect(parseMoney('123.4500'), 12345);
      expect(decimalMoney(12345), '123.45');
      expect(decimalMoney(-1), '-0.01');
    });
    test(
      'rejects ambiguous, non-finite, over-precision and oversized amounts',
      () {
        for (final s in [
          '1,000',
          '18.000,50',
          'NaN',
          'Infinity',
          '1e8',
          '0.001',
          '-10',
          '9000000000001',
        ]) {
          expect(() => parseMoney(s), throwsFormatException, reason: s);
        }
      },
    );
    test('allows signed wallet opening balance', () {
      expect(parseMoney('-12.75', signed: true), -1275);
    });
  });
  group('CSV migration', () {
    test('normalizes category and preserves quoted multiline notes', () {
      final result = CsvImporter.parse(
        '$header\n2026-01-01,18000.0,"Lunch, coffee",Food,false,false,"two\nlines"',
        ledgerId: 'l',
        walletId: 'w',
      );
      expect(result.errors, isEmpty);
      expect(result.entries.single.category, 'food');
      expect(result.entries.single.note, 'two\nlines');
    });
    test('balance flag outranks income flag and investment is separate', () {
      final r = CsvImporter.parse(
        '$header\n2026-01-01,500,Previous balance,balance,true,true,\n2026-01-02,50,Fund,investment,false,false,\n2026-01-02,60,GoPay,balance,false,false,',
        ledgerId: 'l',
        walletId: 'w',
      );
      expect(r.entries.map((e) => e.kind), [
        EntryKind.checkpoint,
        EntryKind.investment,
        EntryKind.expense,
      ]);
      expect(r.entries.last.review, true);
    });
    test('repeat imports are skipped while identical transactions survive', () {
      const source =
          '$header\n2026-01-01,10,Lunch,food,false,false,\n2026-01-01,10,Lunch,food,false,false,';
      final one = CsvImporter.parse(source, ledgerId: 'l', walletId: 'w');
      expect(one.entries.length, 2);
      expect(one.entries.map((e) => e.importKey).toSet().length, 2);
      final two = CsvImporter.parse(
        source,
        ledgerId: 'l',
        walletId: 'w',
        existingKeys: one.entries.map((e) => e.importKey!).toSet(),
      );
      expect(two.entries, isEmpty);
      expect(two.duplicates, 2);
    });
    test('missing columns, dates, flags and bad amounts have row errors', () {
      expect(
        CsvImporter.parse(
          'wrong,header\n1,2',
          ledgerId: 'l',
          walletId: 'w',
        ).errors,
        isNotEmpty,
      );
      for (final line in [
        '2026-02-30,10,Food,food,false,false,',
        '2026-01-01,0,Food,food,false,false,',
        '2026-01-01,10,Food,food,yes,false,',
      ]) {
        expect(
          CsvImporter.parse(
            '$header\n$line',
            ledgerId: 'l',
            walletId: 'w',
          ).errors.length,
          1,
        );
      }
    });
    test('BOM and CRLF supported', () {
      final p = CsvImporter.parse(
        '\uFEFF$header\r\n2026-01-01,1,Food,food,false,false,\r\n',
        ledgerId: 'l',
        walletId: 'w',
      );
      expect(p.entries.length, 1);
      expect(p.errors, isEmpty);
    });
    test('export shields spreadsheet formula injection', () {
      expect(CsvImporter.safeCell('=CMD()'), "'=CMD()");
      expect(CsvImporter.safeCell('Lunch'), 'Lunch');
    });
  });
  group('Reports', () {
    test(
      'snapshots and transfers do not inflate cash flow; future excluded',
      () {
        final r = Report(
          [
            entry(EntryKind.income, 10000),
            entry(EntryKind.expense, 2500),
            entry(EntryKind.investment, 1000),
            entry(EntryKind.transfer, 5000),
            entry(EntryKind.checkpoint, 50000),
            entry(EntryKind.expense, 1000, date: DateTime(2026, 1, 20)),
          ],
          Period.month(DateTime(2026, 1)),
          now: DateTime(2026, 1, 10),
        );
        expect(r.income, 10000);
        expect(r.expense, 2500);
        expect(r.investment, 1000);
        expect(r.net, 6500);
        expect(r.retainedRate, .65);
        expect(r.dailyAverage, 250);
      },
    );
    test('empty income gives no misleading savings percentage', () {
      final r = Report(
        [entry(EntryKind.expense, 2500)],
        Period.month(DateTime(2026, 1)),
        now: DateTime(2026, 2),
      );
      expect(r.retainedRate, isNull);
      expect(r.net, -2500);
    });
    test('end boundary excludes first day of next month', () {
      final r = Report([
        entry(EntryKind.expense, 100, date: DateTime(2026, 2, 1)),
      ], Period.month(DateTime(2026, 1)));
      expect(r.expense, 0);
    });
  });
  group('Recurring schedules', () {
    test('Jan 31 goes to Feb 28 then returns to Mar 31', () {
      final feb = nextOccurrence(DateTime(2026, 1, 31), 'monthly', 31);
      expect(feb, DateTime(2026, 2, 28));
      expect(nextOccurrence(feb, 'monthly', 31), DateTime(2026, 3, 31));
    });
    test('leap day yearly recurrence', () {
      expect(
        nextOccurrence(DateTime(2024, 2, 29), 'yearly', 29),
        DateTime(2025, 2, 28),
      );
    });
  });
}
