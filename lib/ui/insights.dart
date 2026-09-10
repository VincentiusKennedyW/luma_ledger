import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../controllers/ledger_controller.dart';
import '../core/models.dart';
import '../core/statistics.dart';
import 'components.dart';
import 'overview.dart' show RangeInsightsPage;

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});
  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  final c = Get.find<LedgerController>();
  bool customRange = false;

  void changeScale(StatisticsScale scale) {
    setState(() => customRange = false);
    c.statisticsScale.value = scale;
  }

  @override
  Widget build(BuildContext context) {
    if (customRange) {
      return Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => customRange = false),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Monthly & yearly statistics'),
            ),
          ),
          const Expanded(child: RangeInsightsPage()),
        ],
      );
    }
    return Obx(() {
      final s = c.statistics, r = s.report;
      final t = Theme.of(context), colors = t.colorScheme;
      final yearly = s.scale == StatisticsScale.year;
      return PageBody(
        storageKey: 'statistics-${s.scale.name}-${dateKey(s.period.start)}',
        children: [
          LayoutBuilder(
            builder: (context, bounds) {
              final selector = SegmentedButton<StatisticsScale>(
                key: const ValueKey('statistics-scale'),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: StatisticsScale.month,
                    label: Text('Monthly'),
                  ),
                  ButtonSegment(
                    value: StatisticsScale.year,
                    label: Text('Yearly'),
                  ),
                ],
                selected: {s.scale},
                onSelectionChanged: (v) => changeScale(v.first),
              );
              final more = PopupMenuButton<String>(
                tooltip: 'More report options',
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'range',
                    child: Text('All time or custom dates'),
                  ),
                ],
                onSelected: (_) => setState(() => customRange = true),
                icon: const Icon(Icons.more_horiz),
              );
              if (MediaQuery.textScalerOf(context).scale(1) > 1.4) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    selector,
                    Align(alignment: Alignment.centerRight, child: more),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: selector),
                  const SizedBox(width: 12),
                  more,
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _CalendarBand(s, onPick: () => _pickDate(s)),
          const SizedBox(height: 24),
          Text('Total expenses', style: t.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(c.fmt(r.expense), style: t.textTheme.displaySmall),
          const SizedBox(height: 10),
          Text(
            _comparisonText(s),
            style: t.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _SpendingChart(s),
          const SizedBox(height: 16),
          FinancialRow(
            'Income',
            c.fmt(r.income),
            color: colors.tertiary,
            onTap: r.income == 0
                ? null
                : () =>
                      c.showStatisticsEntries(s.period, kind: EntryKind.income),
          ),
          FinancialRow(
            'Expenses',
            c.fmt(r.expense),
            color: colors.secondary,
            onTap: r.expense == 0
                ? null
                : () => c.showStatisticsEntries(s.period),
          ),
          FinancialRow(
            'Invested',
            c.fmt(r.investment),
            color: colors.primary,
            onTap: r.investment == 0
                ? null
                : () => c.showStatisticsEntries(
                    s.period,
                    kind: EntryKind.investment,
                  ),
          ),
          const Divider(),
          FinancialRow('Net cash flow', c.fmt(r.net), emphasis: true),
          const SizedBox(height: 8),
          Text(
            '${s.cashEntryCount} income, expense & investment records · transfers and snapshots excluded',
            style: t.textTheme.bodySmall,
          ),
          if (!s.hasCurrentRecords) ...[
            const SizedBox(height: 24),
            EmptyState(
              title: 'No records for this ${yearly ? 'year' : 'month'}',
              message:
                  'Choose another period or add your first entry. Missing records do not mean no money was spent.',
              action: 'Add a transaction',
              onAction: () => Get.toNamed('/entry'),
            ),
          ],
          const SectionTitle('Compared with the previous period'),
          Text(
            s.isPartial
                ? 'Matching dates: ${s.previousPeriod.label}'
                : s.previousPeriod.label,
            style: t.textTheme.bodySmall,
          ),
          if (!s.hasPreviousRecords)
            const NoteBox(
              'No income, expense or investment records in the comparison period. There is no baseline to compare.',
            )
          else ...[
            FinancialRow('Previous expenses', c.fmt(s.previous.expense)),
            FinancialRow(
              'Expense difference',
              s.hasCurrentRecords
                  ? '${s.expenseDifference > 0 ? '+' : ''}${c.fmt(s.expenseDifference)}'
                  : 'No current records',
            ),
            FinancialRow('Previous income', c.fmt(s.previous.income)),
            FinancialRow('Previous net cash flow', c.fmt(s.previous.net)),
          ],
          const SizedBox(height: 12),
          ExpansionTile(
            key: PageStorageKey(
              'breakdown-${s.scale.name}-${dateKey(s.period.start)}',
            ),
            tilePadding: EdgeInsets.zero,
            title: Text(yearly ? 'Monthly breakdown' : 'Daily breakdown'),
            subtitle: Text(
              yearly
                  ? 'All 12 months · tap a month to explore'
                  : 'Every calendar day · tap to view expenses',
            ),
            children: [
              for (final b in s.buckets)
                _BucketRow(
                  b,
                  yearly: yearly,
                  onTap: b.isFuture
                      ? null
                      : () {
                          if (yearly) {
                            c.statisticsAnchor.value = b.period.start;
                            c.statisticsScale.value = StatisticsScale.month;
                          } else {
                            c.showStatisticsEntries(b.period);
                          }
                        },
                ),
            ],
          ),
          if (r.expenses.isNotEmpty) ...[
            const SectionTitle('Where your money went'),
            for (final entry in r.groupBy((e) => e.category).entries)
              _CategoryRow(entry.key, entry.value, s),
            const SectionTitle('Your spending rhythm'),
            FinancialRow('Daily average', c.fmt(s.dailyAverage)),
            Text(
              'Across ${s.elapsedDays} elapsed calendar days, including days with no recorded spending.',
              style: t.textTheme.bodySmall,
            ),
            if (yearly) ...[
              FinancialRow('Monthly average', c.fmt(s.monthlyAverage)),
              Text(
                'Across ${s.elapsedMonths} elapsed months${s.isPartial ? ', including this partial month' : ''}.',
                style: t.textTheme.bodySmall,
              ),
            ],
            FinancialRow('Average purchase', c.fmt(s.averagePurchase)),
            FinancialRow('Expense records', '${r.expenses.length}'),
            FinancialRow(
              'Days with spending',
              '${s.spendingDays} of ${s.elapsedDays}',
            ),
            FinancialRow(
              'Days without recorded spending',
              '${s.daysWithoutRecordedSpending}',
            ),
            FinancialRow(
              'Cash retained',
              r.retainedRate == null
                  ? 'No income'
                  : '${(r.retainedRate! * 100).toStringAsFixed(1)}%',
            ),
            if (s.peakBucket case final peak?) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Highest-spending ${yearly ? 'month' : 'day'}'),
                subtitle: Text(
                  '${peak.period.label}\n${c.fmt(peak.report.expense)}${peak.isPartial ? ' · in progress' : ''}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (yearly) {
                    c.statisticsAnchor.value = peak.period.start;
                    c.statisticsScale.value = StatisticsScale.month;
                  } else {
                    c.showStatisticsEntries(peak.period);
                  }
                },
              ),
            ],
            if (s.largestExpense case final biggest?)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Largest purchase'),
                subtitle: Text(
                  '${biggest.description}\n${DateFormat('d MMM yyyy').format(biggest.date)} · ${c.fmt(biggest.amount)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.toNamed('/entry', arguments: biggest),
              ),
            const SectionTitle('Wallet spending'),
            for (final w in c.wallets.where(
              (w) => r.expenses.any((e) => e.walletId == w.id),
            ))
              FinancialRow(
                w.name,
                c.fmt(
                  r.expenses
                      .where((e) => e.walletId == w.id)
                      .fold<int>(0, (n, e) => n + e.amount),
                ),
                onTap: () => c.showStatisticsEntries(s.period, wallet: w.id),
              ),
            const SizedBox(height: 16),
            ExpansionTile(
              key: const PageStorageKey('statistics-merchants'),
              tilePadding: EdgeInsets.zero,
              title: const Text('Top descriptions & merchants'),
              children: [
                RankingBars(
                  r.groupBy((e) => e.description),
                  maxItems: 10,
                  label: (s) => s,
                ),
              ],
            ),
            ExpansionTile(
              key: const PageStorageKey('statistics-weekdays'),
              tilePadding: EdgeInsets.zero,
              title: const Text('Spending by weekday'),
              children: [
                for (final day in r.groupBy((e) => '${e.date.weekday}').entries)
                  FinancialRow(
                    [
                      'Monday',
                      'Tuesday',
                      'Wednesday',
                      'Thursday',
                      'Friday',
                      'Saturday',
                      'Sunday',
                    ][int.parse(day.key) - 1],
                    c.fmt(day.value),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const ExpansionTile(
            key: PageStorageKey('statistics-help'),
            tilePadding: EdgeInsets.zero,
            title: Text('How to read this report'),
            children: [
              NoteBox(
                'Expenses exclude investments, transfers and balance snapshots. Net cash flow is income minus expenses and investment contributions. Cash retained divides net cash flow by income; it can be negative. Investments are contributions, not market value or returns. Future entries are excluded until their date. Partial periods compare matching calendar dates, clamped to the last available day. No records and zero recorded spending are not proof of zero real-world activity.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Get.toNamed('/export'),
            icon: const Icon(Icons.ios_share_outlined),
            label: const Text('Export data'),
          ),
        ],
      );
    });
  }

  Future<void> _pickDate(LedgerStatistics s) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: s.period.start.isAfter(now) ? now : s.period.start,
      firstDate: DateTime(1900),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      helpText: s.scale == StatisticsScale.year
          ? 'Choose a date in the year'
          : 'Choose a date in the month',
    );
    if (picked != null && mounted) {
      c.statisticsAnchor.value = DateTime(picked.year, picked.month);
    }
  }

  String _comparisonText(LedgerStatistics s) {
    if (s.isFuture) return 'Upcoming period · future entries excluded';
    final progress = s.isPartial
        ? 'To date · through ${DateFormat('d MMM').format(s.today)}. '
        : '';
    if (!s.hasCurrentRecords) return '${progress}No recorded activity.';
    if (!s.hasPreviousRecords) {
      return '${progress}No previous records to compare.';
    }
    final change = s.expenseChange;
    if (change == null) return '${progress}No previous spending baseline.';
    if (change == 0) {
      return '${progress}Same spending as the previous ${s.isPartial ? 'matching dates' : 'period'}.';
    }
    return '$progress${change.abs().toStringAsFixed(1)}% ${change > 0 ? 'more' : 'less'} spending than the previous ${s.isPartial ? 'matching dates' : 'period'}.';
  }
}

class _CalendarBand extends StatelessWidget {
  final LedgerStatistics s;
  final VoidCallback onPick;
  const _CalendarBand(this.s, {required this.onPick});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<LedgerController>(),
        t = Theme.of(context),
        colors = t.colorScheme;
    final yearly = s.scale == StatisticsScale.year;
    final next = yearly
        ? DateTime(s.anchor.year + 1, s.anchor.month)
        : DateTime(s.anchor.year, s.anchor.month + 1);
    final canNext = !(yearly ? DateTime(next.year) : next).isAfter(s.today);
    void step(int delta) => c.statisticsAnchor.value = yearly
        ? DateTime(s.anchor.year + delta, s.anchor.month)
        : DateTime(s.anchor.year, s.anchor.month + delta);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous ${yearly ? 'year' : 'month'}',
            onPressed: s.period.start.isAfter(DateTime(1900))
                ? () => step(-1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: TextButton(
              onPressed: onPick,
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                child: Text(
                  s.period.label,
                  key: ValueKey(s.period.label),
                  textAlign: TextAlign.center,
                  style: t.textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next ${yearly ? 'year' : 'month'}',
            onPressed: canNext ? () => step(1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class FinancialRow extends StatelessWidget {
  final String label, value;
  final bool emphasis;
  final Color? color;
  final VoidCallback? onTap;
  const FinancialRow(
    this.label,
    this.value, {
    super.key,
    this.emphasis = false,
    this.color,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final labelText = Text(
      label,
      style: emphasis ? t.textTheme.titleMedium : t.textTheme.bodyMedium,
    );
    final amount = Text(
      value,
      style: (emphasis ? t.textTheme.titleLarge : t.textTheme.titleMedium)
          ?.copyWith(color: color ?? t.colorScheme.onSurface),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: LayoutBuilder(
            builder: (context, bounds) {
              if (MediaQuery.textScalerOf(context).scale(1) > 1.4 ||
                  bounds.maxWidth < 290) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [labelText, const SizedBox(height: 6), amount],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 5, child: labelText),
                  const SizedBox(width: 12),
                  Flexible(flex: 6, child: amount),
                  if (onTap != null)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.chevron_right, size: 18),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BucketRow extends StatelessWidget {
  final StatisticsBucket bucket;
  final bool yearly;
  final VoidCallback? onTap;
  const _BucketRow(this.bucket, {required this.yearly, this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<LedgerController>(),
        t = Theme.of(context),
        r = bucket.report;
    final title = DateFormat(
      yearly ? 'MMMM' : 'EEE, d MMM',
    ).format(bucket.period.start);
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          onTap: onTap,
          title: Text(title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                bucket.isFuture
                    ? 'Upcoming · excluded from actuals'
                    : '${c.fmt(r.expense)} expenses',
                style: t.textTheme.titleMedium,
              ),
              if (!bucket.isFuture)
                Text(
                  yearly
                      ? 'Income ${c.fmt(r.income)}\nInvested ${c.fmt(r.investment)} · Net ${c.fmt(r.net)}\n${bucket.status}'
                      : '${r.expenses.length} expense records · ${bucket.status}',
                ),
            ],
          ),
          trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        ),
        const Divider(),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final int amount;
  final LedgerStatistics s;
  const _CategoryRow(this.category, this.amount, this.s);
  @override
  Widget build(BuildContext context) {
    final c = Get.find<LedgerController>(), t = Theme.of(context);
    final share = amount / s.report.expense;
    final count = s.report.expenses.where((e) => e.category == category).length;
    final baseline = s.previous.expenses
        .where((e) => e.category == category)
        .fold<int>(0, (n, e) => n + e.amount);
    final delta = baseline == 0 ? null : (amount - baseline) / baseline * 100;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => c.showStatisticsEntries(s.period, category: category),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(categoryLabel(category), style: t.textTheme.titleMedium),
                  Text(c.fmt(amount), style: t.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${(share * 100).toStringAsFixed(1)}% of expenses · $count ${count == 1 ? 'record' : 'records'}',
                style: t.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: share,
                minHeight: 4,
                color: t.colorScheme.secondary,
                backgroundColor: t.colorScheme.outlineVariant,
                semanticsLabel: '${categoryLabel(category)} share',
                semanticsValue: '${(share * 100).toStringAsFixed(1)} percent',
              ),
              const SizedBox(height: 8),
              Text(
                delta == null
                    ? 'No previous spending baseline'
                    : delta == 0
                    ? 'Same as previous period'
                    : '${delta.abs().toStringAsFixed(1)}% ${delta > 0 ? 'more' : 'less'} than previous ${s.isPartial ? 'matching dates' : 'period'}',
                style: t.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpendingChart extends StatelessWidget {
  final LedgerStatistics s;
  const _SpendingChart(this.s);
  @override
  Widget build(BuildContext context) {
    final c = Get.find<LedgerController>(), t = Theme.of(context);
    final yearly = s.scale == StatisticsScale.year;
    final maxAmount = s.buckets.fold<int>(
      0,
      (n, b) => math.max(n, b.report.expense),
    );
    final ticks = yearly
        ? <int, String>{0: 'Jan', 3: 'Apr', 7: 'Aug', 11: 'Dec'}
        : <int, String>{
            0: '1',
            9: '10',
            19: '20',
            s.buckets.length - 1: '${s.buckets.length}',
          };
    return Semantics(
      image: true,
      label:
          '${yearly ? 'Monthly' : 'Daily'} expense chart for ${s.period.label}. Total ${c.fmt(s.report.expense)}. Exact values in the ${yearly ? 'monthly' : 'daily'} breakdown below.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            children: [
              Text(
                yearly ? 'Monthly expenses' : 'Daily expenses',
                style: t.textTheme.bodySmall,
              ),
              Text(
                maxAmount == 0
                    ? 'No recorded spending'
                    : 'Peak ${c.fmt(maxAmount, compact: true)}',
                style: t.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 124,
            child: CustomPaint(
              painter: _ExpensePainter(
                s.buckets,
                maxAmount,
                t.colorScheme.secondary,
                t.colorScheme.outlineVariant,
                t.colorScheme.surfaceContainerLow,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: MediaQuery.textScalerOf(context).scale(16),
            child: CustomPaint(
              painter: _AxisPainter(
                ticks,
                s.buckets.length,
                t.textTheme.bodySmall!,
                MediaQuery.textScalerOf(context),
                Directionality.of(context),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Baseline 0${s.buckets.any((b) => b.isFuture) ? ' · shaded dates are upcoming' : ''}',
            style: t.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ExpensePainter extends CustomPainter {
  final List<StatisticsBucket> buckets;
  final int maxAmount;
  final Color spending, line, upcoming;
  _ExpensePainter(
    this.buckets,
    this.maxAmount,
    this.spending,
    this.line,
    this.upcoming,
  );
  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / buckets.length;
    final paint = Paint();
    for (var i = 0; i < buckets.length; i++) {
      final b = buckets[i];
      if (b.isFuture) {
        paint.color = upcoming;
        canvas.drawRect(Rect.fromLTWH(i * step, 0, step, size.height), paint);
      }
      if (b.report.expense > 0 && maxAmount > 0) {
        final height = b.report.expense / maxAmount * (size.height - 6);
        paint.color = spending;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              i * step + step * .18,
              size.height - height,
              step * .64,
              height,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      }
    }
    paint
      ..color = line
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ExpensePainter old) =>
      old.buckets != buckets ||
      old.spending != spending ||
      old.line != line ||
      old.upcoming != upcoming;
}

class _AxisPainter extends CustomPainter {
  final Map<int, String> ticks;
  final int count;
  final TextStyle style;
  final TextScaler scaler;
  final TextDirection direction;
  _AxisPainter(this.ticks, this.count, this.style, this.scaler, this.direction);
  @override
  void paint(Canvas canvas, Size size) {
    for (final tick in ticks.entries) {
      final painter = TextPainter(
        text: TextSpan(text: tick.value, style: style),
        textScaler: scaler,
        textDirection: direction,
      )..layout(maxWidth: size.width);
      final x = ((tick.key + .5) * size.width / count - painter.width / 2)
          .clamp(0.0, math.max(0.0, size.width - painter.width));
      painter.paint(canvas, Offset(x.toDouble(), 0));
    }
  }

  @override
  bool shouldRepaint(covariant _AxisPainter old) =>
      old.ticks != ticks ||
      old.style != style ||
      old.scaler != scaler ||
      old.direction != direction;
}
