import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:csv/csv.dart';
import '../core/models.dart';

class ImportPreview {
  final List<Entry> entries;
  final List<String> errors, warnings;
  final int duplicates, rowCount;
  const ImportPreview(
    this.entries,
    this.errors,
    this.warnings,
    this.duplicates,
    this.rowCount,
  );
}

class CsvImporter {
  static ImportPreview parse(
    String source, {
    required String ledgerId,
    required String walletId,
    Set<String> existingKeys = const {},
  }) {
    final entries = <Entry>[], errors = <String>[], warnings = <String>[];
    var duplicate = 0, snapshots = 0, topups = 0, future = 0;
    final normalized = source
        .replaceFirst('\uFEFF', '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(normalized);
    if (rows.isEmpty) {
      return const ImportPreview([], ['This file is empty.'], [], 0, 0);
    }
    final headers = rows.first.map((e) => e.toString().trim()).toList();
    if (headers.toSet().length != headers.length) {
      return ImportPreview(
        [],
        ['Column names must be unique.'],
        [],
        0,
        rows.length - 1,
      );
    }
    const required = [
      'date',
      'amount',
      'description',
      'category',
      'isIncome',
      'isBalanceForward',
    ];
    if (required.any((h) => !headers.contains(h))) {
      return ImportPreview(
        [],
        [
          'Missing columns: ${required.where((h) => !headers.contains(h)).join(', ')}',
        ],
        [],
        0,
        rows.length - 1,
      );
    }
    final occurrences = <String, int>{};
    for (var i = 1; i < rows.length; i++) {
      if (rows[i].every((v) => v.toString().trim().isEmpty)) continue;
      try {
        if (rows[i].length != headers.length) {
          throw const FormatException(
            'Column count does not match the header.',
          );
        }
        final r = {
          for (var j = 0; j < headers.length; j++)
            headers[j]: rows[i][j].toString().trim(),
        };
        bool flag(String key) {
          if (!['true', 'false'].contains(r[key]!.toLowerCase())) {
            throw FormatException('$key must be true or false.');
          }
          return r[key]!.toLowerCase() == 'true';
        }

        final date = strictDate(r['date']!), amount = parseMoney(r['amount']!);
        if (amount <= 0) {
          throw const FormatException('Amount must be greater than zero.');
        }
        if (r['description']!.isEmpty) {
          throw const FormatException('Description is required.');
        }
        final category = r['category']!.isEmpty
            ? 'other'
            : r['category']!.toLowerCase();
        final isIncome = flag('isIncome'), isForward = flag('isBalanceForward');
        var kind = isForward
            ? EntryKind.checkpoint
            : isIncome
            ? EntryKind.income
            : category == 'investment'
            ? EntryKind.investment
            : EntryKind.expense;
        if (r.containsKey('kind') && r['kind']!.isNotEmpty) {
          kind = EntryKind.values.byName(r['kind']!);
          if (kind == EntryKind.transfer) {
            throw const FormatException(
              'Use a JSON backup to restore transfers and linked wallets.',
            );
          }
        }
        final canonical = jsonEncode([
          dateKey(date),
          amount,
          r['description'],
          category,
          kind.name,
          r['note'] ?? '',
        ]);
        final count = occurrences.update(
          canonical,
          (n) => n + 1,
          ifAbsent: () => 1,
        );
        final key = sha256.convert(utf8.encode('$canonical#$count')).toString();
        if (existingKeys.contains(key)) {
          duplicate++;
          continue;
        }
        if (kind == EntryKind.checkpoint) snapshots++;
        final review = category == 'balance' && kind == EntryKind.expense;
        if (review) topups++;
        if (date.isAfter(dayOnly(DateTime.now()))) future++;
        entries.add(
          Entry(
            id: newId(),
            ledgerId: ledgerId,
            walletId: walletId,
            date: date,
            amount: amount,
            kind: kind,
            description: r['description']!,
            category: category,
            note: r['note'] ?? '',
            importKey: key,
            review: review,
          ),
        );
      } catch (e) {
        errors.add(
          'Row ${i + 1}: ${e is FormatException ? e.message : 'Invalid date or transaction type.'}',
        );
      }
    }
    if (snapshots > 0) {
      warnings.add(
        '$snapshots balance-forward records will be kept as snapshots and excluded from cash flow and wallet balances.',
      );
    }
    if (topups > 0) {
      warnings.add(
        '$topups wallet top-ups need review. They stay expenses until you confirm a destination wallet and change them to transfers.',
      );
    }
    if (future > 0) {
      warnings.add(
        '$future future-dated records will be scheduled, excluded from actual totals until their date.',
      );
    }
    warnings.add(
      'Currency is not present in this CSV. Amounts use the selected ledger currency; no conversion is performed.',
    );
    return ImportPreview(entries, errors, warnings, duplicate, rows.length - 1);
  }

  static String export(List<Entry> entries) =>
      const ListToCsvConverter().convert([
        [
          'date',
          'amount',
          'description',
          'category',
          'isIncome',
          'isBalanceForward',
          'note',
          'kind',
        ],
        ...entries.map(
          (e) => [
            dateKey(e.date),
            decimalMoney(e.amount),
            safeCell(e.description),
            safeCell(e.category),
            e.kind == EntryKind.income,
            e.kind == EntryKind.checkpoint,
            safeCell(e.note),
            e.kind.name,
          ],
        ),
      ]);

  /// Prevent spreadsheet formula execution when exported descriptions are opened.
  static String safeCell(String text) =>
      RegExp(r'^[=+@\-\t\r]').hasMatch(text) ? "'$text" : text;
}
