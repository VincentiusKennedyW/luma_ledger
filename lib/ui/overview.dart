import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/ledger_controller.dart';
import '../core/models.dart';
import 'components.dart';
import 'theme.dart';

void showCategory(LedgerController c, String cat) {
  c.search.value = '';
  c.searchInput.clear();
  c.walletFilter.value = 'all';
  c.reviewOnly.value = false;
  c.categoryFilter.value = cat;
  c.typeFilter.value = 'expense';
  c.tab.value = 1;
}

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<LedgerController>(),
        t = Theme.of(context),
        scheme = t.colorScheme;
    return Obx(() {
      final report = c.report,
          recent = c.entries
              .where((e) => !e.date.isAfter(dayOnly(DateTime.now())))
              .take(4)
              .toList();
      final categories = report.groupBy((e) => e.category);
      return PageBody(
        storageKey: 'overview',
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recorded balance',
                        style: t.textTheme.bodyMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'View wallets',
                      onPressed: () => Get.toNamed('/wallets'),
                      icon: Icon(
                        Icons.north_east_rounded,
                        color: scheme.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                Text(
                  c.fmt(c.balance),
                  style: t.textTheme.displaySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 15,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '${c.wallets.length} ${c.wallets.length == 1 ? 'wallet' : 'wallets'} · as of today',
                        style: t.textTheme.bodySmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: scheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, size) => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final item in [
                  (EntryKind.expense, Icons.north_east_rounded, 'Expense'),
                  (EntryKind.income, Icons.south_west_rounded, 'Income'),
                  (EntryKind.transfer, Icons.swap_horiz_rounded, 'Transfer'),
                ])
                  SizedBox(
                    width: MediaQuery.textScalerOf(context).scale(1) > 1.4
                        ? size.maxWidth
                        : (size.maxWidth - 20) / 3,
                    child: OutlinedButton.icon(
                      key: ValueKey('quick-${item.$1.name}'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () =>
                          Get.toNamed('/entry', arguments: item.$1),
                      icon: Icon(item.$2, size: 16),
                      label: Text(item.$3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const PeriodPicker(),
          const SizedBox(height: 12),
          StatGrid([
            ('Income', c.fmt(report.income), Icons.south_west_rounded),
            ('Expenses', c.fmt(report.expense), Icons.north_east_rounded),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                Text(
                  'Invested  ${c.fmt(report.investment)}',
                  style: t.textTheme.bodySmall,
                ),
                Text('Net  ${c.fmt(report.net)}', style: t.textTheme.bodySmall),
              ],
            ),
          ),
          SectionTitle(
            'Recent activity',
            action: 'See all',
            onTap: () {
              c.allHistory();
              c.tab.value = 1;
            },
          ),
          if (recent.isEmpty)
            EmptyState(
              title: 'Add your first transaction',
              message: 'Start with today, or import your existing CSV.',
              action: 'Import history',
              onAction: () => Get.toNamed('/import'),
            )
          else
            ...recent.map(
              (e) => EntryTile(
                e,
                onTap: () => Get.toNamed('/entry', arguments: e),
              ),
            ),
          if (c.due.isNotEmpty) ...[
            const SizedBox(height: 16),
            Panel(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_repeat),
                title: Text('${c.due.length} recurring entries due'),
                subtitle: const Text('Review and record'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.toNamed('/recurring'),
              ),
            ),
          ],
          if (c.entries.any((e) => e.review))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.rule_rounded),
              title: Text(
                '${c.entries.where((e) => e.review).length} transactions need review',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                c.allHistory();
                c.reviewOnly.value = true;
                c.tab.value = 1;
              },
            ),
          if (categories.isNotEmpty) ...[
            SectionTitle(
              'Spending breakdown',
              action: 'Full report',
              onTap: () => c.tab.value = 2,
            ),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpendingStrip(categories),
                  const SizedBox(height: 10),
                  RankingBars(
                    categories,
                    label: categoryLabel,
                    maxItems: 3,
                    onTap: (cat) => showCategory(c, cat),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    });
  }
}

class SpendingStrip extends StatelessWidget {
  final Map<String, int> values;
  const SpendingStrip(this.values, {super.key});
  @override
  Widget build(BuildContext context) {
    final total = values.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 12,
          child: Row(
            children: values.entries.indexed
                .map(
                  (v) => Expanded(
                    flex: math.max(1, (v.$2.value / total * 10000).round()),
                    child: Container(
                      margin: const EdgeInsets.only(right: 2),
                      color: [
                        const Color(0xFF087A50),
                        const Color(0xFF4CAF7F),
                        const Color(0xFF83CAA1),
                        const Color(0xFFB0DDC2),
                        const Color(0xFFD7EDE0),
                      ][v.$1 % 5],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<LedgerController>(), t = Theme.of(context);
    return Obx(() {
      final list = c.filtered,
          active =
              c.categoryFilter.value != 'all' ||
              c.walletFilter.value != 'all' ||
              c.reviewOnly.value ||
              !['all', 'expense', 'income'].contains(c.typeFilter.value);
      return CustomScrollView(
        key: const PageStorageKey('transactions'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: c.searchInput,
                              onChanged: (v) => c.search.value = v,
                              decoration: const InputDecoration(
                                hintText: 'Search transactions',
                                prefixIcon: Icon(Icons.search_rounded),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filledTonal(
                            tooltip: 'Filter transactions',
                            onPressed: () => transactionFilters(context),
                            icon: Icon(
                              active ? Icons.filter_alt : Icons.tune_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const PeriodPicker(),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final item in [
                            ('all', 'All'),
                            ('expense', 'Expenses'),
                            ('income', 'Income'),
                          ])
                            ChoiceChip(
                              label: Text(item.$2),
                              selected: c.typeFilter.value == item.$1,
                              onSelected: (_) => c.typeFilter.value = item.$1,
                            ),
                          if (active)
                            ActionChip(
                              label: const Text('Filters active'),
                              avatar: const Icon(
                                Icons.filter_alt_outlined,
                                size: 16,
                              ),
                              onPressed: () => transactionFilters(context),
                            ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 4),
                        child: Text(
                          '${list.length} transactions',
                          style: t.textTheme.bodySmall,
                        ),
                      ),
                      if (list.isEmpty)
                        EmptyState(
                          title: 'No transactions found',
                          message:
                              'Change your filters or record a transaction.',
                          action: 'Add transaction',
                          onAction: () => Get.toNamed('/entry'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.builder(
              itemCount: list.length,
              itemBuilder: (context, i) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (i == 0 ||
                          dateKey(list[i].date) != dateKey(list[i - 1].date))
                        Container(
                          margin: const EdgeInsets.only(top: 14, bottom: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: t.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            DateFormat('EEEE, d MMM yyyy').format(list[i].date),
                            style: t.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      EntryTile(
                        list[i],
                        onTap: () => Get.toNamed('/entry', arguments: list[i]),
                      ),
                      const Divider(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      );
    });
  }
}

Future<void> transactionFilters(BuildContext context) async {
  final c = Get.find<LedgerController>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: .75,
        maxChildSize: .95,
        minChildSize: .4,
        expand: false,
        builder: (ctx, scroll) => Obx(
          () => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Text(
                'Filter transactions',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SectionTitle('Type'),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final kind in [
                    'all',
                    ...EntryKind.values.map((k) => k.name),
                  ])
                    ChoiceChip(
                      label: Text(
                        kind == 'all'
                            ? 'All types'
                            : kindLabel(EntryKind.values.byName(kind)),
                      ),
                      selected: c.typeFilter.value == kind,
                      onSelected: (_) => c.typeFilter.value = kind,
                    ),
                ],
              ),
              const SectionTitle('Category'),
              DropdownButtonFormField<String>(
                initialValue: c.categoryFilter.value,
                itemHeight: null,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('All categories'),
                  ),
                  ...c.categories.map(
                    (cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(categoryLabel(cat)),
                    ),
                  ),
                ],
                onChanged: (v) => c.categoryFilter.value = v!,
              ),
              const SectionTitle('Wallet'),
              DropdownButtonFormField<String>(
                initialValue: c.walletFilter.value,
                itemHeight: null,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('All wallets'),
                  ),
                  ...c.wallets.map(
                    (w) => DropdownMenuItem(value: w.id, child: Text(w.name)),
                  ),
                ],
                onChanged: (v) => c.walletFilter.value = v!,
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Needs review only'),
                value: c.reviewOnly.value,
                onChanged: (v) => c.reviewOnly.value = v,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Show ${c.filtered.length} transactions'),
              ),
              TextButton(
                onPressed: () {
                  c.typeFilter.value = 'all';
                  c.categoryFilter.value = 'all';
                  c.walletFilter.value = 'all';
                  c.reviewOnly.value = false;
                },
                child: const Text('Reset filters'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<LedgerController>(), t = Theme.of(context);
    return Obx(() {
      final r = c.report,
          previousPeriod = c.period.value.previous(),
          previous = Report(c.entries.toList(), previousPeriod);
      final complete = !c.period.value.end.isAfter(
        dayOnly(DateTime.now()).add(const Duration(days: 1)),
      );
      final change = previous.expense == 0
          ? null
          : (r.expense - previous.expense) / previous.expense * 100;
      return PageBody(
        storageKey: 'insights',
        children: [
          const PeriodPicker(),
          const SizedBox(height: 20),
          Text('Total expenses', style: t.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(c.fmt(r.expense), style: t.textTheme.displaySmall),
          const SizedBox(height: 10),
          Text(
            !complete
                ? 'Period in progress · through today'
                : change == null
                ? 'No previous spending to compare'
                : '${change.abs().toStringAsFixed(1)}% ${change >= 0 ? 'more' : 'less'} than the preceding ${previousPeriod.end.difference(previousPeriod.start).inDays} days',
            style: t.textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          StatGrid([
            (
              'Daily average',
              c.fmt(r.dailyAverage),
              Icons.calendar_today_outlined,
            ),
            (
              'Cash retained',
              r.retainedRate == null
                  ? 'No income'
                  : '${(r.retainedRate! * 100).toStringAsFixed(1)}%',
              Icons.savings_outlined,
            ),
          ]),
          const SectionTitle('Cash flow'),
          const CashFlowChart(),
          const SectionTitle('Spending by category'),
          if (r.expenses.isEmpty)
            const EmptyState(
              title: 'No expenses this period',
              message: 'Choose a different period to explore your spending.',
            )
          else
            Panel(
              child: Column(
                children: [
                  SpendingStrip(r.groupBy((e) => e.category)),
                  const SizedBox(height: 12),
                  RankingBars(
                    r.groupBy((e) => e.category),
                    label: categoryLabel,
                    onTap: (cat) => showCategory(c, cat),
                  ),
                ],
              ),
            ),
          if (r.expenses.isNotEmpty) ...[
            const SectionTitle('Top purchases'),
            Panel(
              child: RankingBars(
                r.groupBy((e) => e.description),
                maxItems: 10,
                label: (s) => s,
              ),
            ),
            const SectionTitle('Spending by weekday'),
            Panel(
              child: RankingBars(
                r.groupBy((e) => '${e.date.weekday}'),
                label: (s) => [
                  'Monday',
                  'Tuesday',
                  'Wednesday',
                  'Thursday',
                  'Friday',
                  'Saturday',
                  'Sunday',
                ][int.parse(s) - 1],
              ),
            ),
          ],
          const SectionTitle('Income & investments'),
          StatGrid([
            ('Income', c.fmt(r.income), Icons.south_west),
            ('Invested', c.fmt(r.investment), Icons.show_chart),
            ('Net cash flow', c.fmt(r.net), Icons.waterfall_chart),
            (
              'Expense records',
              '${r.expenses.length}',
              Icons.receipt_long_outlined,
            ),
          ]),
          const SizedBox(height: 16),
          const ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('How totals are calculated'),
            children: [
              NoteBox(
                'Expenses exclude investments, transfers and balance snapshots. Net cash flow is income minus expenses and investments. Cash retained is net cash flow divided by income. Daily average includes elapsed calendar days. Investments track contributions, not market value.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Get.toNamed('/export'),
            icon: const Icon(Icons.ios_share_outlined),
            label: const Text('Export report'),
          ),
        ],
      );
    });
  }
}

class CashFlowChart extends StatelessWidget {
  const CashFlowChart({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<LedgerController>();
    final incomeColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.mint
        : AppColors.forest;
    final outflowColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF557D65)
        : const Color(0xFFBDE7CE);
    final rangeEnd = c.period.value.end.subtract(const Duration(days: 1));
    final selected = rangeEnd.isAfter(DateTime.now())
        ? DateTime.now()
        : rangeEnd;
    final end = DateTime(selected.year, selected.month);
    final months = List.generate(
      6,
      (i) => Period.month(DateTime(end.year, end.month - 5 + i)),
    );
    final reports = months.map((p) => Report(c.entries.toList(), p)).toList();
    final maxAmount = reports.fold<int>(
      1,
      (n, r) => math.max(n, math.max(r.income, r.expense + r.investment)),
    );
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _legend(context, incomeColor, 'Income'),
              _legend(context, outflowColor, 'Expenses + investments'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '6 months ending ${DateFormat('MMM yyyy').format(end)} · tap a month',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            c.fmt(maxAmount, compact: true),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Divider(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(6, (i) {
              final r = reports[i];
              return Expanded(
                child: Semantics(
                  label:
                      '${months[i].label}. Income ${c.fmt(r.income)}, outflow ${c.fmt(r.expense + r.investment)}',
                  button: true,
                  child: InkWell(
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (ctx) => SafeArea(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                months[i].label,
                                style: Theme.of(ctx).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 20),
                              StatGrid([
                                ('Income', c.fmt(r.income), Icons.south_west),
                                (
                                  'Expenses',
                                  c.fmt(r.expense),
                                  Icons.north_east,
                                ),
                                (
                                  'Invested',
                                  c.fmt(r.investment),
                                  Icons.show_chart,
                                ),
                                (
                                  'Net cash flow',
                                  c.fmt(r.net),
                                  Icons.waterfall_chart,
                                ),
                              ]),
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  c.period.value = months[i];
                                  c.typeFilter.value = 'all';
                                  c.categoryFilter.value = 'all';
                                  c.walletFilter.value = 'all';
                                  c.reviewOnly.value = false;
                                  c.search.value = '';
                                  c.searchInput.clear();
                                  c.tab.value = 1;
                                },
                                child: const Text('View transactions'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 120,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _bar(r.income / maxAmount, incomeColor),
                                const SizedBox(width: 4),
                                _bar(
                                  (r.expense + r.investment) / maxAmount,
                                  outflowColor,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            MediaQuery.textScalerOf(context).scale(1) > 1.4
                                ? DateFormat(
                                    'MMMM',
                                  ).format(months[i].start).substring(0, 1)
                                : DateFormat('MMM').format(months[i].start),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('View exact values'),
            children: List.generate(
              6,
              (i) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(months[i].label),
                subtitle: Text(
                  'Income ${c.fmt(reports[i].income)}\nOutflow ${c.fmt(reports[i].expense + reports[i].investment)}',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double value, Color color) => Flexible(
    child: Container(
      width: 18,
      height: math.max(value * 120, 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
      ),
    ),
  );
  Widget _legend(BuildContext context, Color color, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Flexible(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
    ],
  );
}
