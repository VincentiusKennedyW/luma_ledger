import 'package:flutter_test/flutter_test.dart';
import 'package:luma_ledger/receipts/receipt_parser.dart';

// Fictional text with the same labels as the user's Wondr example. No personal image or account data.
const receiptExample = '''wondr by BNI
Pembayaran QRIS berhasil
Rp1
10 Sep 2026 · 12:25:52 WIB
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
Detail merchant
Nama acquirer
DOMPET ANAK BANGSA
Nama issuer
BNI''';
void main() {
  ReceiptDraft parse(String text, [String hash = 'sample-a']) =>
      ReceiptDraft.parse(text, imageHash: hash);
  test(
    'Wondr rupiah1 is100minor units; payer and acquirer are not the merchant or bank',
    () {
      final r = parse(receiptExample);
      expect(r.amount, 100);
      expect(r.date, DateTime(2026, 9, 10));
      expect(r.merchant, 'TOKO CONTOH');
      expect(r.provider, 'BNI');
      expect(r.status, ReceiptStatus.successful);
      expect(r.reference, '20260910000000000999');
    },
  );
  test('Indonesian thousands, decimals and labeled total including a fee', () {
    final r = parse(
      'Pembayaran berhasil\nNominal Rp25.000\nBiaya Rp1.500\nTotal\nRp26.500,50',
    );
    expect(r.amount, 2650050);
    expect(parseRupiah('1.234.567,89'), 123456789);
    expect(parseRupiah('1.00'), isNull);
    expect(parseRupiah('1,234'), isNull);
    expect(parseRupiah('9000000000001'), isNull);
  });
  test('Ambiguous amounts and missing details stay empty', () {
    final r = parse('Rp25.000\nRp1.500\nSumber dana\nREKENING CONTOH 12345678');
    expect(r.amount, isNull);
    expect(r.merchant, isNull);
    expect(r.date, isNull);
    expect(r.status, ReceiptStatus.uncertain);
    expect(parse('Saldo 123456789').amount, isNull);
    expect(parse('Ref ID:\nPenerima\nContoh').reference, isNull);
  });
  test(
    'Pending failure and refund override success; no silent successful fallback',
    () {
      for (final word in [
        'gagal',
        'pending',
        'dibatalkan',
        'belum berhasil',
        'tidak berhasil',
        'refund',
      ]) {
        expect(
          parse('Pembayaran berhasil\n$word').status,
          ReceiptStatus.failed,
        );
      }
      expect(parse('Pembayaran QRIS\nRp100').status, ReceiptStatus.uncertain);
    },
  );
  test(
    'Reference dedup survives different image bytes and screenshot without header',
    () {
      final a = parse(receiptExample);
      final b = parse(
        receiptExample
            .replaceAll('wondr by BNI', '')
            .replaceAll('Nama issuer\nBNI', ''),
        'different-image',
      );
      expect(a.importKey, b.importKey);
      expect(a.importKey, isNot(contains('20260910000000000999')));
      expect(
        parse('Rp100', 'a').importKey,
        isNot(parse('Rp100', 'b').importKey),
      );
      expect(parse('Rp100', 'a').importKey, parse('Rp100', 'a').importKey);
    },
  );
  test('Other providers use generic labels without claiming layout support', () {
    expect(
      parse(
        'GoPay\nPayment successful\nIDR 10.000\nRecipient: Fictional Cafe\n11/09/2026',
      ).provider,
      'GoPay',
    );
    final r = parse(
      'PermataME\nTransaksi berhasil\nRp12.000\nNama merchant: TOKO DEMO\n2026-09-11',
    );
    expect(r.provider, 'Permata');
    expect(r.merchant, 'TOKO DEMO');
    expect(r.date, DateTime(2026, 9, 11));
    expect(parse('31 Feb 2026 Rp1').date, isNull);
    expect(parse('29 Feb 2024 Rp1').date, DateTime(2024, 2, 29));
    expect(parse('Total USD 10.00').rupiah, false);
  });
}
