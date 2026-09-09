import 'package:flutter_test/flutter_test.dart';
import 'package:luma_ledger/core/models.dart';
import 'package:luma_ledger/core/statistics.dart';

Entry entry(DateTime date, int amount, [EntryKind kind = EntryKind.expense]) =>
    Entry(
      id: '$date-$amount-$kind',
      ledgerId: 'l',
      walletId: 'w',
      date: date,
      amount: amount,
      kind: kind,
      description: 'Test entry',
      category: 'food',
    );
void main() {
  test('Calendar months compare to the actual previous month', () {
    final s = LedgerStatistics(
      [
        entry(DateTime(2026, 2, 1), 100),
        entry(DateTime(2026, 2, 28), 200),
        entry(DateTime(2026, 1, 31), 999),
        entry(DateTime(2026, 3, 31), 600),
      ],
      scale: StatisticsScale.month,
      anchor: DateTime(2026, 3),
      now: DateTime(2026, 4, 1),
    );
    expect(s.previous.expense, 300);
    expect(s.expenseChange, 100);
    expect(s.elapsedDays, 31);
    expect(s.buckets.length, 31);
  });
  test(
    'Partial month compares matching day cutoff and excludes future entries',
    () {
      final s = LedgerStatistics(
        [
          entry(DateTime(2026, 8, 9), 200),
          entry(DateTime(2026, 8, 10), 900),
          entry(DateTime(2026, 9, 9), 400),
          entry(DateTime(2026, 9, 10), 999),
        ],
        scale: StatisticsScale.month,
        anchor: DateTime(2026, 9),
        now: DateTime(2026, 9, 9),
      );
      expect(s.isPartial, true);
      expect(s.report.expense, 400);
      expect(s.previous.expense, 200);
      expect(s.elapsedDays, 9);
      expect(s.buckets[9].isFuture, true);
      expect(s.buckets[9].report.expense, 0);
    },
  );
  test('Leap day year-to-date comparison clamps to February 28', () {
    final s = LedgerStatistics(
      [
        entry(DateTime(2023, 2, 28), 100),
        entry(DateTime(2023, 3, 1), 500),
        entry(DateTime(2024, 2, 29), 200),
      ],
      scale: StatisticsScale.year,
      anchor: DateTime(2024),
      now: DateTime(2024, 2, 29),
    );
    expect(s.previousPeriod.end, DateTime(2023, 3, 1));
    expect(s.previous.expense, 100);
    expect(s.elapsedDays, 60);
    expect(s.elapsedMonths, 2);
    expect(s.buckets.length, 12);
    expect(s.buckets[2].status, 'Upcoming');
  });
  test(
    'January compares December of the prior year; full leap year has 366 days',
    () {
      final jan = LedgerStatistics(
        [],
        scale: StatisticsScale.month,
        anchor: DateTime(2026, 1),
        now: DateTime(2026, 2),
      );
      expect(jan.previousPeriod.start, DateTime(2025, 12));
      final year = LedgerStatistics(
        [],
        scale: StatisticsScale.year,
        anchor: DateTime(2024),
        now: DateTime(2026),
      );
      expect(year.elapsedDays, 366);
      expect(year.elapsedMonths, 12);
    },
  );
  test('Transfers and snapshots never become spending or cash flow', () {
    final d = DateTime(2026, 1, 1);
    final s = LedgerStatistics(
      [
        entry(d, 1000, EntryKind.income),
        entry(d, 200),
        entry(d, 100, EntryKind.investment),
        entry(d, 9000, EntryKind.transfer),
        entry(d, 80000, EntryKind.checkpoint),
      ],
      scale: StatisticsScale.year,
      anchor: d,
      now: DateTime(2026, 12, 31),
    );
    expect(s.report.net, 700);
    expect(s.report.expense, 200);
    expect(s.cashEntryCount, 3);
    expect(s.spendingDays, 1);
    expect(s.daysWithoutRecordedSpending, 364);
    expect(s.averagePurchase, 200);
    expect(s.peakBucket?.period.start, d);
    expect(s.buckets.fold<int>(0, (n, b) => n + b.report.net), s.report.net);
  });
  test('Missing baseline, zero income and future periods stay explicit', () {
    final s = LedgerStatistics(
      [entry(DateTime(2026, 9, 1), 900)],
      scale: StatisticsScale.month,
      anchor: DateTime(2026, 9),
      now: DateTime(2026, 9, 9),
    );
    expect(s.expenseChange, isNull);
    expect(s.hasPreviousRecords, false);
    expect(s.report.retainedRate, isNull);
    final future = LedgerStatistics(
      [],
      scale: StatisticsScale.month,
      anchor: DateTime(2027),
      now: DateTime(2026),
    );
    expect(future.elapsedDays, 0);
    expect(future.dailyAverage, 0);
    expect(future.largestExpense, isNull);
    expect(future.buckets.every((b) => b.isFuture), true);
  });
}
