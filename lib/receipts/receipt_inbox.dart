import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'receipt_parser.dart';

class SharedReceipt {
  final String id, path, text, hash;
  final String? error;
  final bool reading;
  SharedReceipt(Map<dynamic, dynamic> m)
    : id = m['id'] as String,
      path = m['path'] as String,
      text = m['text'] as String? ?? '',
      hash = m['hash'] as String? ?? '',
      error = m['error'] as String?,
      reading = m['reading'] == true;
  ReceiptDraft get draft => ReceiptDraft.parse(text, imageHash: hash);
}

class ReceiptInbox extends GetxService {
  static const channel = MethodChannel('app.lumaledger/receipts');
  final items = <SharedReceipt>[].obs;
  final error = RxnString();
  final revision = 0.obs;
  Future<void> start() async {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'changed') await refresh();
    });
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final data = await channel.invokeMapMethod<String, dynamic>('list');
      items.assignAll(
        (data?['items'] as List? ?? []).map((m) => SharedReceipt(m as Map)),
      );
      error.value = data?['error'] as String?;
      revision.value++;
    } on PlatformException {
      error.value =
          'Receipt import is unavailable. Close and reopen Luma to try again.';
    }
  }

  Future<void> pick() async {
    try {
      await channel.invokeMethod<void>('pick');
    } on PlatformException {
      error.value =
          'Could not open the image picker. Try sharing the receipt from your bank app.';
    }
  }

  Future<void> discard(String id) async {
    await channel.invokeMethod<void>('discard', {'id': id});
    await refresh();
  }

  @override
  void onClose() {
    channel.setMethodCallHandler(null);
    super.onClose();
  }
}
