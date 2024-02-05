import 'dart:convert';
import 'dart:math';

final _random = Random.secure();

String genRandomString(int len) {
  final values = List<int>.generate(len, (i) => _random.nextInt(256));
  return base64UrlEncode(values);
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
