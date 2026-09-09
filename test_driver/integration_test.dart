import 'dart:convert';
import 'dart:io';
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  writeResponseOnFailure: true,
  responseDataCallback: (data) async {
    final directory = Directory(
      Platform.environment['LUMA_SCREENSHOTS'] ?? 'docs/screenshots',
    );
    await directory.create(recursive: true);
    final captures = data?['captures'] as Map<String, dynamic>? ?? {};
    for (final item in captures.entries) {
      await File(
        '${directory.path}/${item.key}.png',
      ).writeAsBytes(base64Decode(item.value as String));
    }
  },
);
