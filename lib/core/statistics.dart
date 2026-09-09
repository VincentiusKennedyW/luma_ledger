import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'models.dart';

enum StatisticsScale { month, year }

/// Calendar reporting over one ledger. Dates are calendar dates, not instants.
/// Callers supply entries from the selected ledger only.
class LedgerStatistics {
  final StatisticsScale scale;
  final DateTime anchor, today;
  final List<Entry> _entries;
  late final Period period = scale == StatisticsScale.month
      ? Period.month(anchor)
      : Period.year(anchor);
  late final Report report = Report(_entries, period, now: today);
  late final DateTime cutoff = _earlier(
    DateTime(today.year, today.month, today.day + 1),
    period.end,
  );
  bool get isFuture => !today.isBefore(period.start) ? false : true;
  bool get isPartial => !isFuture && cutoff.isBefore(period.end);
  int get elapsedDays => math.max(0, _calendarDays(period.start, cutoff));
  int get elapsedMonths => isFuture
      ? 0
      : scale == StatisticsScale.month
      ? 1
      : isPartial
      ? today.month
      : 12;

  LedgerStatistics(
    List<Entry> entries, {
    required this.scale,
    required this.anchor,
    DateTime? now,
  }) : today = dayOnly(now ?? DateTime.now()),
       _entries = List.unmodifiable(entries);

  late final Period previousPeriod = _comparisonPeriod();
  late final Report previous = Report(_entries, previousPeriod, now: today);
  bool get hasCurrentRecords => report.entries.any(_isCashEntry);
  bool get hasPreviousRecords => previous.entries.any(_isCashEntry);
  double? get expenseChange =>
      !hasCurrentRecords || !hasPreviousRecords || previous.expense == 0
      ? null
      : (report.expense - previous.expense) / previous.expense * 100;
  int get expenseDifference => report.expense - previous.expense;
  int get dailyAverage =>
      elapsedDays == 0 ? 0 : (report.expense / elapsedDays).round();
  int get monthlyAverage =>
      elapsedMonths == 0 ? 0 : (report.expense / elapsedMonths).round();
  int get averagePurchase => report.expenses.isEmpty
      ? 0
      : (report.expense / report.expenses.length).round();
  int get spendingDays =>
      report.expenses.map((e) => dateKey(e.date)).toSet().length;
  int get daysWithoutRecordedSpending =>
      math.max(0, elapsedDays - spendingDays);
  Entry? get largestExpense => report.expenses.isEmpty
      ? null
      : report.expenses.reduce((a, b) => a.amount >= b.amount ? a : b);
  int get cashEntryCount => report.entries.where(_isCashEntry).length;

  late final List<StatisticsBucket> buckets = List.generate(
    scale == StatisticsScale.year
        ? 12
        : DateTime(anchor.year, anchor.month + 1, 0).day,
    (i) {
      final start = scale == StatisticsScale.year
          ? DateTime(anchor.year, i + 1)
          : DateTime(anchor.year, anchor.month, i + 1);
      final end = scale == StatisticsScale.year
          ? DateTime(anchor.year, i + 2)
          : DateTime(anchor.year, anchor.month, i + 2);
      final range = Period(
        start,
        end,
        DateFormat(
          scale == StatisticsScale.year ? 'MMMM yyyy' : 'd MMM yyyy',
        ).format(start),
      );
      return StatisticsBucket(
        range,
        Report(_entries, range, now: today),
        today,
      );
    },
  );
  StatisticsBucket? get peakBucket {
    final spending = buckets.where((b) => b.report.expense > 0);
    return spending.isEmpty
        ? null
        : spending.reduce(
            (a, b) => a.report.expense >= b.report.expense ? a : b,
          );
  }

  Period _comparisonPeriod() {
    final base = scale == StatisticsScale.month
        ? Period.month(DateTime(anchor.year, anchor.month - 1))
        : Period.year(DateTime(anchor.year - 1));
    if (isFuture) return Period(base.start, base.start, 'No elapsed period');
    if (!isPartial) return base;
    final month = scale == StatisticsScale.month
        ? base.start.month
        : today.month;
    final day = math.min(
      today.day,
      DateTime(base.start.year, month + 1, 0).day,
    );
    final end = DateTime(base.start.year, month, day + 1);
    return Period(
      base.start,
      end,
      '${DateFormat('d MMM yyyy').format(base.start)} – ${DateFormat('d MMM yyyy').format(DateTime(end.year, end.month, end.day - 1))}',
    );
  }
}

class StatisticsBucket {
  final Period period;
  final Report report;
  final DateTime today;
  const StatisticsBucket(this.period, this.report, this.today);
  bool get isFuture => period.start.isAfter(today);
  bool get isPartial =>
      !isFuture &&
      period.end.isAfter(DateTime(today.year, today.month, today.day + 1));
  bool get hasRecords => report.entries.any(_isCashEntry);
  String get status => isFuture
      ? 'Upcoming'
      : !hasRecords
      ? 'No records'
      : isPartial
      ? 'In progress'
      : 'Recorded';
}

bool _isCashEntry(Entry e) => [
  EntryKind.income,
  EntryKind.expense,
  EntryKind.investment,
].contains(e.kind);
DateTime _earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
int _calendarDays(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
