import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../core/models.dart';
import '../controllers/ledger_controller.dart';
import 'theme.dart';

class PageBody extends StatelessWidget {
  final List<Widget> children;
  final String? storageKey;
  const PageBody({super.key, required this.children, this.storageKey});
  @override
  Widget build(BuildContext context) => ListView(
    key: PageStorageKey(storageKey),
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ],
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  const SectionTitle(this.title, {super.key, this.action, this.onTap});
  @override
  Widget build(BuildContext context) {
    final heading = Text(title, style: Theme.of(context).textTheme.titleMedium);
    final button = action == null
        ? null
        : TextButton(onPressed: onTap, child: Text(action!));
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: MediaQuery.textScalerOf(context).scale(1) > 1.4
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [heading, if (button != null) button],
            )
          : Row(
              children: [
                Expanded(child: heading),
                if (button != null) button,
              ],
            ),
    );
  }
}

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: padding, child: child),
  );
}

class NoteBox extends StatelessWidget {
  final String text;
  final IconData icon;
  const NoteBox(this.text, {super.key, this.icon = Icons.info_outline});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  final String title, message;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.receipt_long_outlined,
    this.action,
    this.onAction,
  });
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      children: [
        const SizedBox(height: 12),
        Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (action != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: OutlinedButton(onPressed: onAction, child: Text(action!)),
          ),
        const SizedBox(height: 12),
      ],
    ),
  );
}

class CategoryAvatar extends StatelessWidget {
  final String category;
  final EntryKind? kind;
  const CategoryAvatar(this.category, {super.key, this.kind});
  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ExcludeSemantics(
        child: Icon(
          kind == EntryKind.transfer
              ? Icons.swap_horiz
              : kind == EntryKind.checkpoint
              ? Icons.history_outlined
              : categoryIcon(category),
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.primary
              : color,
          size: 22,
        ),
      ),
    );
  }
}

class EntryTile extends StatelessWidget {
  final Entry entry;
  final VoidCallback? onTap;
  const EntryTile(this.entry, {super.key, this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<LedgerController>(),
        t = Theme.of(context),
        scheme = t.colorScheme;
    final prefix = entry.kind == EntryKind.income
        ? '+'
        : [EntryKind.transfer, EntryKind.checkpoint].contains(entry.kind)
        ? ''
        : '−';
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    final amount = Text(
      '$prefix${c.fmt(entry.amount)}',
      textAlign: large ? TextAlign.start : TextAlign.end,
      style: t.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: entry.kind == EntryKind.income
            ? scheme.primary
            : scheme.onSurface,
      ),
    );
    final status = entry.review
        ? 'Needs review'
        : entry.kind == EntryKind.checkpoint
        ? 'Snapshot · excluded'
        : entry.date.isAfter(dayOnly(DateTime.now()))
        ? 'Scheduled'
        : null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CategoryAvatar(entry.category, kind: entry.kind),
              const SizedBox(width: 12),
              Expanded(
                flex: large ? 1 : 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.description,
                      maxLines: large ? null : 2,
                      overflow: large ? null : TextOverflow.ellipsis,
                      style: t.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${categoryLabel(entry.category)} · ${c.walletName(entry.walletId)}',
                      style: t.textTheme.bodySmall,
                    ),
                    if (status != null)
                      Text(
                        status,
                        style: t.textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    if (large) ...[const SizedBox(height: 6), amount],
                  ],
                ),
              ),
              if (!large) ...[
                const SizedBox(width: 10),
                Expanded(flex: 4, child: amount),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StatGrid extends StatelessWidget {
  final List<(String, String, IconData)> items;
  const StatGrid(this.items, {super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final columns = MediaQuery.textScalerOf(context).scale(1) > 1.5
          ? 1
          : items.length == 1
          ? 1
          : 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: items
            .map(
              (item) => SizedBox(
                width: (size.maxWidth - 12 * (columns - 1)) / columns,
                child: Panel(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        item.$3,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.$1,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.$2,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class PeriodPicker extends StatelessWidget {
  const PeriodPicker({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<LedgerController>();
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerLow,
                ),
                onPressed: () => choosePeriod(context),
                icon: const Icon(Icons.calendar_month_outlined, size: 17),
                label: Text(c.period.value.label),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Previous month',
            onPressed: () => c.period.value = Period.month(
              DateTime(
                c.period.value.start.year,
                c.period.value.start.month - 1,
              ),
            ),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Next month',
            onPressed: () => c.period.value = Period.month(
              DateTime(
                c.period.value.start.year,
                c.period.value.start.month + 1,
              ),
            ),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

Future<void> choosePeriod(BuildContext context) async {
  final c = Get.find<LedgerController>(), now = DateTime.now();
  final selected = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Choose a period',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ...{
            'month': 'This month',
            'last': 'Last month',
            'year': 'This year',
            'all': 'All time',
            'custom': 'Custom date range',
          }.entries.map(
            (e) => ListTile(
              title: Text(e.value),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, e.key),
            ),
          ),
        ],
      ),
    ),
  );
  switch (selected) {
    case 'month':
      c.period.value = Period.month(now);
    case 'last':
      c.period.value = Period.month(DateTime(now.year, now.month - 1));
    case 'year':
      c.period.value = Period.year(now);
    case 'all':
      c.allHistory();
    case 'custom':
      if (!context.mounted) return;
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(1900),
        lastDate: DateTime(2200),
        initialDateRange: DateTimeRange(
          start: c.period.value.start,
          end: c.period.value.end.subtract(const Duration(days: 1)),
        ),
      );
      if (range != null) {
        c.period.value = Period(
          range.start,
          range.end.add(const Duration(days: 1)),
          '${DateFormat('d MMM yy').format(range.start)} – ${DateFormat('d MMM yy').format(range.end)}',
        );
      }
  }
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String message, {
  String action = 'Delete',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

class RankingBars extends StatelessWidget {
  final Map<String, int> values;
  final int? maxItems;
  final String Function(String) label;
  final ValueChanged<String>? onTap;
  const RankingBars(
    this.values, {
    super.key,
    required this.label,
    this.onTap,
    this.maxItems,
  });
  @override
  Widget build(BuildContext context) {
    final c = Get.find<LedgerController>();
    final total = values.values.fold(0, (a, b) => a + b),
        max = values.values.fold(0, (a, b) => a > b ? a : b);
    return Column(
      children: values.entries
          .take(maxItems ?? values.length)
          .map(
            (e) => Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap == null ? null : () => onTap!(e.key),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Text(
                            label(e.key),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${c.fmt(e.value)} · ${total == 0 ? 0 : (e.value / total * 100).round()}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Semantics(
                        label: '${label(e.key)}, ${c.fmt(e.value)}',
                        child: LinearProgressIndicator(
                          value: max == 0 ? 0 : e.value / max,
                          minHeight: 7,
                          borderRadius: BorderRadius.circular(8),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
