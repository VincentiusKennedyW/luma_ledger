import 'package:intl/intl.dart';

typedef DbRow = Map<String, Object?>;
String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
String newId() => '${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';
int _sequence = 0;

/// Exact decimal parsing: all supported currencies use 100 internal units.
/// UI and imports use a decimal point; grouping separators are not accepted.
int parseMoney(String raw, {bool signed = false}) {
  final s = raw.trim();
  if (!RegExp(signed ? r'^-?\d+(\.\d+)?$' : r'^\d+(\.\d+)?$').hasMatch(s)) {
    throw const FormatException(
      'Use digits and a decimal point, without grouping separators.',
    );
  }
  final negative = s.startsWith('-');
  final parts = s.replaceFirst('-', '').split('.');
  final fraction = parts.length == 1
      ? ''
      : parts[1].replaceFirst(RegExp(r'0+$'), '');
  if (fraction.length > 2) {
    throw const FormatException('Use no more than 2 decimal places.');
  }
  final whole = int.tryParse(parts[0]);
  if (whole == null || whole > 9000000000000) {
    throw const FormatException('Amount is too large.');
  }
  final amount = whole * 100 + int.parse(fraction.padRight(2, '0'));
  return negative ? -amount : amount;
}

String decimalMoney(int n) =>
    '${n < 0 ? '-' : ''}${n.abs() ~/ 100}.${(n.abs() % 100).toString().padLeft(2, '0')}';
String money(int n, String currency, {bool compact = false}) {
  final symbol =
      {
        'IDR': 'Rp',
        'USD': '\$',
        'EUR': '€',
        'SGD': 'S\$',
        'AUD': 'A\$',
      }[currency] ??
      currency;
  final locale = currency == 'IDR' ? 'id_ID' : 'en_US';
  if (compact && n.abs() >= 100000000) {
    return '$symbol ${NumberFormat.compact(locale: 'en_US').format(n / 100)}';
  }
  return NumberFormat.currency(
    locale: locale,
    symbol: symbol,
    decimalDigits: currency == 'IDR' && n % 100 == 0 ? 0 : 2,
  ).format(n / 100);
}

DateTime strictDate(String input) {
  final parsed = DateFormat('yyyy-MM-dd').parseStrict(input);
  if (parsed.year < 1900 || parsed.year > 2200) {
    throw const FormatException('Date must be between 1900 and 2200.');
  }
  return parsed;
}

enum EntryKind { expense, income, investment, transfer, checkpoint }

String kindLabel(EntryKind kind) => switch (kind) {
  EntryKind.expense => 'Expense',
  EntryKind.income => 'Income',
  EntryKind.investment => 'Investment',
  EntryKind.transfer => 'Transfer',
  EntryKind.checkpoint => 'Balance snapshot',
};

class Ledger {
  final String id, name, currency;
  const Ledger(this.id, this.name, this.currency);
  factory Ledger.fromRow(DbRow r) =>
      Ledger(r['id'] as String, r['name'] as String, r['currency'] as String);
}

class Wallet {
  final String id, ledgerId, name;
  final int opening;
  const Wallet(this.id, this.ledgerId, this.name, this.opening);
  factory Wallet.fromRow(DbRow r) => Wallet(
    r['id'] as String,
    r['ledger_id'] as String,
    r['name'] as String,
    r['opening'] as int,
  );
}

class Entry {
  final String id, ledgerId, walletId, description, category, note;
  final String? toWalletId, importKey;
  final DateTime date;
  final int amount;
  final EntryKind kind;
  final bool review;
  const Entry({
    required this.id,
    required this.ledgerId,
    required this.walletId,
    required this.date,
    required this.amount,
    required this.kind,
    required this.description,
    required this.category,
    this.note = '',
    this.toWalletId,
    this.importKey,
    this.review = false,
  });
  factory Entry.fromRow(DbRow r) => Entry(
    id: r['id'] as String,
    ledgerId: r['ledger_id'] as String,
    walletId: r['wallet_id'] as String,
    date: strictDate(r['date'] as String),
    amount: r['amount'] as int,
    kind: EntryKind.values.byName(r['kind'] as String),
    description: r['description'] as String,
    category: r['category'] as String,
    note: r['note'] as String? ?? '',
    toWalletId: r['to_wallet_id'] as String?,
    importKey: r['import_key'] as String?,
    review: r['review'] == 1,
  );
  DbRow toRow() => {
    'id': id,
    'ledger_id': ledgerId,
    'wallet_id': walletId,
    'date': dateKey(date),
    'amount': amount,
    'kind': kind.name,
    'description': description,
    'category': category,
    'note': note,
    'to_wallet_id': toWalletId,
    'import_key': importKey,
    'review': review ? 1 : 0,
  };
  Entry copy({String? id, DateTime? date, bool clearImport = false}) => Entry(
    id: id ?? this.id,
    ledgerId: ledgerId,
    walletId: walletId,
    date: date ?? this.date,
    amount: amount,
    kind: kind,
    description: description,
    category: category,
    note: note,
    toWalletId: toWalletId,
    importKey: clearImport ? null : importKey,
    review: review,
  );
}

const defaultCategories = [
  'food',
  'transport',
  'shopping',
  'gift',
  'entertainment',
  'gym',
  'bills',
  'health',
  'education',
  'subscription',
  'other',
  'income',
  'investment',
  'balance',
];
String categoryLabel(String value) =>
    {
      'food': 'Food & drinks',
      'transport': 'Transport',
      'shopping': 'Shopping',
      'gift': 'Giving & gifts',
      'entertainment': 'Entertainment',
      'gym': 'Fitness',
      'bills': 'Bills & utilities',
      'health': 'Health',
      'education': 'Education',
      'subscription': 'Subscriptions',
      'other': 'Other',
      'income': 'Income',
      'investment': 'Investments',
      'balance': 'Wallet top-ups',
    }[value] ??
    '${value[0].toUpperCase()}${value.substring(1)}';

class Period {
  final DateTime start, end;
  final String label;
  const Period(this.start, this.end, this.label);
  factory Period.month(DateTime date) => Period(
    DateTime(date.year, date.month),
    DateTime(date.year, date.month + 1),
    DateFormat('MMMM yyyy').format(date),
  );
  factory Period.year(DateTime date) =>
      Period(DateTime(date.year), DateTime(date.year + 1), '${date.year}');
  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);
  Period previous() {
    final span = end.difference(start).inDays;
    return Period(
      start.subtract(Duration(days: span)),
      start,
      'Previous period',
    );
  }
}

class Report {
  final List<Entry> entries;
  final Period period;
  final DateTime asOf;
  Report(List<Entry> all, this.period, {DateTime? now})
    : asOf = dayOnly(now ?? DateTime.now()),
      entries = all
          .where(
            (e) =>
                period.contains(e.date) &&
                !e.date.isAfter(dayOnly(now ?? DateTime.now())),
          )
          .toList();
  int total(EntryKind kind) =>
      entries.where((e) => e.kind == kind).fold(0, (sum, e) => sum + e.amount);
  int get income => total(EntryKind.income);
  int get expense => total(EntryKind.expense);
  int get investment => total(EntryKind.investment);
  int get net => income - expense - investment;
  double? get retainedRate => income == 0 ? null : net / income;
  List<Entry> get expenses =>
      entries.where((e) => e.kind == EntryKind.expense).toList();
  Map<String, int> groupBy(
    String Function(Entry) key, {
    EntryKind kind = EntryKind.expense,
  }) {
    final totals = <String, int>{};
    for (final e in entries.where((e) => e.kind == kind)) {
      totals.update(key(e), (n) => n + e.amount, ifAbsent: () => e.amount);
    }
    return Map.fromEntries(
      totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  int get elapsedDays {
    final cutoff = asOf.add(const Duration(days: 1));
    final until = endBefore(cutoff, period.end);
    return until.isBefore(period.start)
        ? 0
        : until.difference(period.start).inDays;
  }

  int get dailyAverage =>
      elapsedDays == 0 ? 0 : (expense / elapsedDays).round();
  DateTime endBefore(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
}

DateTime nextOccurrence(DateTime date, String frequency, int anchor) {
  if (frequency == 'weekly') return date.add(const Duration(days: 7));
  final month = DateTime(
    date.year,
    date.month + (frequency == 'yearly' ? 12 : 1),
  );
  final maxDay = DateTime(month.year, month.month + 1, 0).day;
  return DateTime(month.year, month.month, anchor > maxDay ? maxDay : anchor);
}
