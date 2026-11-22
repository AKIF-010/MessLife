// File: lib/core/validators.dart
/// Converts Bangla digits (০-৯) to ASCII so phone fields work in both languages.
String asciiDigits(String s) {
  const bn = '০১২৩৪৫৬৭৮৯';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = bn.indexOf(ch);
    b.write(i >= 0 ? '$i' : ch);
  }
  return b.toString();
}

/// Returns an E.164 Bangladeshi mobile number (+8801XXXXXXXXX) or null if invalid.
/// Accepts: 01712345678, 1712345678, +8801712345678, 8801712345678.
String? normalizeBdPhone(String input) {
  var d = asciiDigits(input).replaceAll(RegExp(r'[^0-9]'), '');
  if (d.startsWith('880')) d = d.substring(3);
  if (d.startsWith('0')) d = d.substring(1);
  if (!RegExp(r'^1[3-9]\d{8}$').hasMatch(d)) return null;
  return '+880$d';
}

/// Splits a full name: the last word becomes last_name, the rest first_name.
({String first, String last}) splitFullName(String full) {
  final parts =
  full.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return (first: '', last: '');
  if (parts.length == 1) return (first: parts.first, last: '');
  return (
  first: parts.sublist(0, parts.length - 1).join(' '),
  last: parts.last,
  );
}