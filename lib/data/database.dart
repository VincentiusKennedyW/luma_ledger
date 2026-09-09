import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../core/models.dart';

class LedgerDatabase {
  final Database db;
  LedgerDatabase(this.db);
  static Future<LedgerDatabase> open({String? path}) async {
    final db = await openDatabase(
      path ?? p.join(await getDatabasesPath(), 'luma_ledger_v1.db'),
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        for (final sql in schema) {
          await db.execute(sql);
        }
      },
    );
    return LedgerDatabase(db);
  }

  static const schema = [
    'CREATE TABLE ledgers(id TEXT PRIMARY KEY, name TEXT NOT NULL, currency TEXT NOT NULL)',
    'CREATE TABLE wallets(id TEXT PRIMARY KEY, ledger_id TEXT NOT NULL REFERENCES ledgers(id) ON DELETE CASCADE, name TEXT NOT NULL, opening INTEGER NOT NULL DEFAULT 0, UNIQUE(ledger_id,name))',
    'CREATE TABLE categories(ledger_id TEXT NOT NULL REFERENCES ledgers(id) ON DELETE CASCADE, name TEXT NOT NULL, PRIMARY KEY(ledger_id,name))',
    '''CREATE TABLE entries(id TEXT PRIMARY KEY, ledger_id TEXT NOT NULL REFERENCES ledgers(id) ON DELETE CASCADE,
       wallet_id TEXT NOT NULL REFERENCES wallets(id), to_wallet_id TEXT REFERENCES wallets(id),
       date TEXT NOT NULL, amount INTEGER NOT NULL CHECK(amount>0),
       kind TEXT NOT NULL CHECK(kind IN ('expense','income','investment','transfer','checkpoint')),
       description TEXT NOT NULL, category TEXT NOT NULL, note TEXT NOT NULL DEFAULT '',
       import_key TEXT, review INTEGER NOT NULL DEFAULT 0,
       CHECK(kind!='transfer' OR (to_wallet_id IS NOT NULL AND to_wallet_id!=wallet_id)), UNIQUE(ledger_id,import_key))''',
    'CREATE INDEX entries_ledger_date ON entries(ledger_id,date)',
    'CREATE INDEX entries_category ON entries(ledger_id,category,kind)',
    'CREATE TABLE budgets(id TEXT PRIMARY KEY, ledger_id TEXT NOT NULL REFERENCES ledgers(id) ON DELETE CASCADE, category TEXT NOT NULL, amount INTEGER NOT NULL CHECK(amount>0), UNIQUE(ledger_id,category))',
    '''CREATE TABLE recurring(id TEXT PRIMARY KEY, ledger_id TEXT NOT NULL REFERENCES ledgers(id) ON DELETE CASCADE,
       wallet_id TEXT NOT NULL REFERENCES wallets(id), description TEXT NOT NULL, category TEXT NOT NULL,
       amount INTEGER NOT NULL CHECK(amount>0), kind TEXT NOT NULL CHECK(kind IN ('expense','income','investment')),
       frequency TEXT NOT NULL CHECK(frequency IN ('weekly','monthly','yearly')), next_date TEXT NOT NULL,
       anchor INTEGER NOT NULL CHECK(anchor BETWEEN 1 AND 31), active INTEGER NOT NULL DEFAULT 1)''',
    'CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)',
  ];
  Future<List<DbRow>> rows(String table, {String? ledgerId}) => db.query(
    table,
    where: ledgerId == null ? null : 'ledger_id=?',
    whereArgs: ledgerId == null ? null : [ledgerId],
  );
  Future<void> setSetting(String key, String value) async => db.insert(
    'settings',
    {'key': key, 'value': value},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
  Future<String?> setting(String key) async {
    final r = await db.query('settings', where: 'key=?', whereArgs: [key]);
    return r.isEmpty ? null : r.first['value'] as String;
  }

  Future<Ledger> createLedger(String name, String currency) async {
    if (name.trim().isEmpty ||
        !['IDR', 'USD', 'EUR', 'SGD', 'AUD'].contains(currency)) {
      throw const FormatException('Enter a name and supported currency.');
    }
    final ledger = Ledger(newId(), name.trim(), currency);
    await db.transaction((txn) async {
      await txn.insert('ledgers', {
        'id': ledger.id,
        'name': ledger.name,
        'currency': currency,
      });
      await txn.insert('wallets', {
        'id': newId(),
        'ledger_id': ledger.id,
        'name': 'Main wallet',
        'opening': 0,
      });
      for (final c in defaultCategories) {
        await txn.insert('categories', {'ledger_id': ledger.id, 'name': c});
      }
    });
    return ledger;
  }

  Future<void> validateEntry(DatabaseExecutor txn, Entry e) async {
    if (e.amount <= 0 || e.description.trim().isEmpty || e.category.isEmpty) {
      throw const FormatException('Add an amount, description, and category.');
    }
    final ids = [e.walletId, if (e.toWalletId != null) e.toWalletId!];
    for (final id in ids) {
      final r = await txn.query(
        'wallets',
        where: 'id=? AND ledger_id=?',
        whereArgs: [id, e.ledgerId],
      );
      if (r.isEmpty) {
        throw const FormatException('Choose a wallet in this ledger.');
      }
    }
    if (e.kind == EntryKind.transfer &&
        (e.toWalletId == null || e.toWalletId == e.walletId)) {
      throw const FormatException('Choose a different destination wallet.');
    }
    if (e.kind != EntryKind.transfer && e.toWalletId != null) {
      throw const FormatException(
        'Only transfers can have a destination wallet.',
      );
    }
  }

  Future<void> saveEntry(Entry e) => db.transaction((txn) async {
    await validateEntry(txn, e);
    await txn.insert('categories', {
      'ledger_id': e.ledgerId,
      'name': e.category,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    final existing = await txn.query(
      'entries',
      columns: ['id'],
      where: 'id=?',
      whereArgs: [e.id],
    );
    if (existing.isEmpty) {
      await txn.insert('entries', e.toRow());
    } else {
      await txn.update('entries', e.toRow(), where: 'id=?', whereArgs: [e.id]);
    }
  });
  Future<int> importEntries(List<Entry> entries) => db.transaction((txn) async {
    var count = 0;
    for (final e in entries) {
      await validateEntry(txn, e);
      if (e.importKey != null &&
          (await txn.query(
            'entries',
            columns: ['id'],
            where: 'ledger_id=? AND import_key=?',
            whereArgs: [e.ledgerId, e.importKey],
          )).isNotEmpty) {
        continue;
      }
      await txn.insert('categories', {
        'ledger_id': e.ledgerId,
        'name': e.category,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await txn.insert('entries', e.toRow());
      count++;
    }
    return count;
  });
  Future<void> recordRecurring(DbRow rule) => db.transaction((txn) async {
    final current = await txn.query(
      'recurring',
      where: 'id=?',
      whereArgs: [rule['id']],
    );
    if (current.isEmpty) {
      throw const FormatException('This recurring entry no longer exists.');
    }
    final r = current.first;
    if (r['next_date'] != rule['next_date']) return;
    final date = strictDate(r['next_date'] as String);
    if (date.isAfter(dayOnly(DateTime.now()))) {
      throw const FormatException('This entry is not due yet.');
    }
    final e = Entry(
      id: newId(),
      ledgerId: r['ledger_id'] as String,
      walletId: r['wallet_id'] as String,
      date: date,
      amount: r['amount'] as int,
      kind: EntryKind.values.byName(r['kind'] as String),
      description: r['description'] as String,
      category: r['category'] as String,
      note: 'Recorded from a recurring schedule.',
    );
    await validateEntry(txn, e);
    await txn.insert('entries', e.toRow());
    await txn.update(
      'recurring',
      {
        'next_date': dateKey(
          nextOccurrence(date, r['frequency'] as String, r['anchor'] as int),
        ),
      },
      where: 'id=?',
      whereArgs: [r['id']],
    );
  });
  static const backupTables = [
    'ledgers',
    'wallets',
    'categories',
    'entries',
    'budgets',
    'recurring',
    'settings',
  ];
  Future<String> backup() => db.transaction((txn) async {
    final data = <String, Object?>{
      'format': 'luma-ledger',
      'version': 1,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    for (final table in backupTables) {
      data[table] = await txn.query(table);
    }
    return const JsonEncoder.withIndent('  ').convert(data);
  });
  Future<void> restore(String source) async {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != 'luma-ledger' ||
        decoded['version'] != 1 ||
        backupTables.any((t) => decoded[t] is! List)) {
      throw const FormatException('Choose a version 1 Luma JSON backup.');
    }
    await db.transaction((txn) async {
      for (final table in backupTables.reversed) {
        await txn.delete(table);
      }
      for (final table in backupTables) {
        for (final raw in decoded[table] as List) {
          final r = Map<String, Object?>.from(raw as Map);
          _validateBackupRow(table, r);
          if (table == 'ledgers' &&
              (!['IDR', 'USD', 'EUR', 'SGD', 'AUD'].contains(r['currency']) ||
                  (r['name'] as String).trim().isEmpty)) {
            throw const FormatException('Backup contains an invalid ledger.');
          }
          if (table == 'entries') {
            await validateEntry(txn, Entry.fromRow(r));
            final categories = await txn.query(
              'categories',
              where: 'ledger_id=? AND name=?',
              whereArgs: [r['ledger_id'], r['category']],
            );
            if (categories.isEmpty) {
              throw const FormatException(
                'Backup is missing a transaction category.',
              );
            }
          }
          if (table == 'recurring') {
            strictDate(r['next_date'] as String);
            final wallets = await txn.query(
              'wallets',
              where: 'id=? AND ledger_id=?',
              whereArgs: [r['wallet_id'], r['ledger_id']],
            );
            if (wallets.isEmpty) {
              throw const FormatException(
                'Recurring wallet does not belong to this ledger.',
              );
            }
          }
          await txn.insert(table, r);
        }
      }
      for (final ledger in await txn.query('ledgers')) {
        if ((await txn.query(
          'wallets',
          where: 'ledger_id=?',
          whereArgs: [ledger['id']],
        )).isEmpty) {
          throw const FormatException(
            'Each restored ledger needs at least one wallet.',
          );
        }
        for (final category in defaultCategories) {
          await txn.insert('categories', {
            'ledger_id': ledger['id'],
            'name': category,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
      if ((await txn.rawQuery('PRAGMA foreign_key_check')).isNotEmpty) {
        throw const FormatException('Backup contains broken wallet links.');
      }
    });
  }

  void _validateBackupRow(String table, DbRow row) {
    final stringFields = <String, List<String>>{
      'ledgers': ['id', 'name', 'currency'],
      'wallets': ['id', 'ledger_id', 'name'],
      'categories': ['ledger_id', 'name'],
      'entries': [
        'id',
        'ledger_id',
        'wallet_id',
        'date',
        'kind',
        'description',
        'category',
      ],
      'budgets': ['id', 'ledger_id', 'category'],
      'recurring': [
        'id',
        'ledger_id',
        'wallet_id',
        'description',
        'category',
        'kind',
        'frequency',
        'next_date',
      ],
      'settings': ['key'],
    };
    for (final key in stringFields[table]!) {
      if (row[key] is! String || (row[key] as String).trim().isEmpty) {
        throw FormatException('Backup contains invalid $table.$key.');
      }
    }
    final integerFields = <String, List<String>>{
      'wallets': ['opening'],
      'entries': ['amount', 'review'],
      'budgets': ['amount'],
      'recurring': ['amount', 'anchor', 'active'],
    };
    for (final key in integerFields[table] ?? <String>[]) {
      if (row[key] is! int) {
        throw FormatException('Backup contains invalid $table.$key.');
      }
    }
    if (row.containsKey('amount') &&
        ((row['amount'] as int) <= 0 ||
            (row['amount'] as int) > 900000000000000)) {
      throw const FormatException(
        'Backup amount is outside the supported range.',
      );
    }
    if (table == 'entries' &&
        (row['note'] is! String || ![0, 1].contains(row['review']))) {
      throw const FormatException('Invalid transaction metadata.');
    }
    if (table == 'settings' && row['value'] is! String) {
      throw const FormatException('Invalid backup settings.');
    }
    if (table == 'recurring' && ![0, 1].contains(row['active'])) {
      throw const FormatException('Invalid schedule status.');
    }
  }
}
