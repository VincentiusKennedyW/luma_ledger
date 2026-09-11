import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../core/models.dart';

enum ReceiptStatus { successful, failed, uncertain }

/// A suggestion from untrusted OCR, never an authenticated payment event.
class ReceiptDraft {
  final int? amount;
  final DateTime? date;
  final String? merchant, reference, provider;
  final ReceiptStatus status;
  final bool rupiah;
  final String fingerprint;
  const ReceiptDraft({
    required this.amount,
    required this.date,
    required this.merchant,
    required this.reference,
    required this.provider,
    required this.status,
    required this.rupiah,
    required this.fingerprint,
  });
  String get importKey => 'receipt:v1:$fingerprint';

  static ReceiptDraft parse(String text, {required String imageHash}) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final normalized = lines.join('\n');
    final lower = normalized.toLowerCase();
    final failed = RegExp(
      r'\b(gagal|failed|dibatalkan|canceled|cancelled|pending|diproses|menunggu|belum berhasil|tidak berhasil|refund|dikembalikan)\b',
    ).hasMatch(lower);
    final success = RegExp(
      r'\b(berhasil|successful|succeeded|success|completed)\b',
    ).hasMatch(lower);
    final status = failed
        ? ReceiptStatus.failed
        : success
        ? ReceiptStatus.successful
        : ReceiptStatus.uncertain;
    final header = lines.take(6).join(' ').toLowerCase();
    String? provider;
    if (RegExp(r'\bwondr\b').hasMatch(header)) {
      provider = 'BNI';
    } else if (RegExp(r'\bgopay\b').hasMatch(header)) {
      provider = 'GoPay';
    } else if (RegExp(r'\bpermata(?:bank|me)?\b').hasMatch(header)) {
      provider = 'Permata';
    } else if (RegExp(r'\bbni\b').hasMatch(header) ||
        RegExp(
          r'nama issuer\s*:?\s*bni\b',
          caseSensitive: false,
        ).hasMatch(normalized)) {
      provider = 'BNI';
    }
    // Never infer the payer's bank from the merchant acquirer or source name.
    String? merchant;
    for (var i = 0; i < lines.length; i++) {
      final m = RegExp(
        r'^(?:penerima|nama merchant|nama penerima|merchant name|recipient)\s*:?\s*(.*)$',
        caseSensitive: false,
      ).firstMatch(lines[i]);
      if (m == null) continue;
      final candidate = m[1]!.isNotEmpty
          ? m[1]!
          : i + 1 < lines.length
          ? lines[i + 1]
          : '';
      if (candidate.isNotEmpty &&
          !RegExp(
            r'^(sumber dana|detail|ref|rp\s*\d)',
            caseSensitive: false,
          ).hasMatch(candidate)) {
        merchant = candidate.length > 200
            ? candidate.substring(0, 200)
            : candidate;
        break;
      }
    }
    final refMatch = RegExp(
      r'(?:ref\s*id|reference(?:\s*(?:id|number))?|nomor referensi|no\.?\s*referensi|id transaksi|transaction id)\s*[:#]?\s*([A-Za-z0-9][A-Za-z0-9-]{5,63})',
      caseSensitive: false,
    ).firstMatch(normalized);
    final candidateRef = refMatch?[1]?.toUpperCase();
    final reference =
        candidateRef != null && RegExp(r'\d').hasMatch(candidateRef)
        ? candidateRef
        : null;
    DateTime? date;
    final named = RegExp(
      r'\b(\d{1,2})\s+(Jan(?:uari|uary)?|Feb(?:ruari|ruary)?|Mar(?:et|ch)?|Apr(?:il)?|Mei|May|Jun(?:i|e)?|Jul(?:i|y)?|Agu(?:stus)?|Aug(?:ust)?|Sep(?:tember)?|Okt(?:ober)?|Oct(?:ober)?|Nov(?:ember)?|Des(?:ember)?|Dec(?:ember)?)\s+(20\d{2})\b',
      caseSensitive: false,
    ).firstMatch(normalized);
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'mei': 5,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'agu': 8,
      'aug': 8,
      'sep': 9,
      'okt': 10,
      'oct': 10,
      'nov': 11,
      'des': 12,
      'dec': 12,
    };
    DateTime? checked(int y, int m, int d) {
      final value = DateTime(y, m, d);
      return value.year == y && value.month == m && value.day == d
          ? value
          : null;
    }

    if (named != null) {
      date = checked(
        int.parse(named[3]!),
        months[named[2]!.substring(0, 3).toLowerCase()]!,
        int.parse(named[1]!),
      );
    } else {
      final numeric = RegExp(
        r'\b(\d{2})[/-](\d{2})[/-](20\d{2})\b',
      ).firstMatch(normalized);
      final iso = RegExp(
        r'\b(20\d{2})-(\d{2})-(\d{2})\b',
      ).firstMatch(normalized);
      if (numeric != null) {
        date = checked(
          int.parse(numeric[3]!),
          int.parse(numeric[2]!),
          int.parse(numeric[1]!),
        );
      }
      if (date == null && iso != null) {
        date = checked(
          int.parse(iso[1]!),
          int.parse(iso[2]!),
          int.parse(iso[3]!),
        );
      }
    }
    final rp = RegExp(
      r'\b(?:Rp\.?|IDR)\s*([0-9][0-9.,]*)',
      caseSensitive: false,
    );
    final candidates = <int>[];
    int? total;
    for (var i = 0; i < lines.length; i++) {
      for (final m in rp.allMatches(lines[i])) {
        final value = parseRupiah(m[1]!);
        if (value != null && value > 0) candidates.add(value);
      }
      if (RegExp(
        r'^(?:total(?: pembayaran| bayar| transaksi)?|total payment)\s*:?\s*(?:Rp|IDR|$)',
        caseSensitive: false,
      ).hasMatch(lines[i])) {
        final m =
            rp.firstMatch(lines[i]) ??
            (i + 1 < lines.length ? rp.firstMatch(lines[i + 1]) : null);
        if (m != null) total = parseRupiah(m[1]!);
      }
    }
    // A labeled total wins over the subtotal or fee. Otherwise only fill an
    // unambiguous repeated amount; never treat account/reference digits as money.
    final unique = candidates.toSet();
    final amount = total != null && total > 0
        ? total
        : unique.length == 1
        ? unique.single
        : null;
    final fingerprint = reference == null
        ? sha256.convert(utf8.encode('image:$imageHash')).toString()
        : sha256.convert(utf8.encode('ref:$reference')).toString();
    return ReceiptDraft(
      amount: amount,
      date: date,
      merchant: merchant,
      reference: reference,
      provider: provider,
      status: status,
      rupiah: rp.hasMatch(normalized),
      fingerprint: fingerprint,
    );
  }
}

/// Strict Indonesian grouping and decimal separators. OCR ambiguity stays empty.
int? parseRupiah(String raw) {
  if (!RegExp(r'^(?:\d+|\d{1,3}(?:\.\d{3})+)(?:,\d{1,2})?$').hasMatch(raw)) {
    return null;
  }
  try {
    return parseMoney(raw.replaceAll('.', '').replaceAll(',', '.'));
  } on FormatException {
    return null;
  }
}
