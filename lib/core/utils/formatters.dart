import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _taka = NumberFormat.decimalPattern('en_US');

  /// "৳6,000" from 6000, "6000" or "6,000". Returns '' when not a number.
  static String taka(dynamic value) {
    final n = num.tryParse(value?.toString().replaceAll(',', '') ?? '');
    if (n == null) return '';
    return '৳${_taka.format(n)}';
  }

  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Map && value[r'$date'] != null) {
      return parseDate(value[r'$date']);
    }
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static String date(dynamic value) {
    final d = parseDate(value);
    return d == null ? '' : DateFormat('d MMM yyyy').format(d);
  }

  static String dateTime(dynamic value) {
    final d = parseDate(value);
    return d == null ? '' : DateFormat('d MMM yyyy, h:mm a').format(d);
  }

  static String time(dynamic value) {
    final d = parseDate(value);
    return d == null ? '' : DateFormat('h:mm a').format(d);
  }

  /// Strips HTML tags for short previews.
  static String plain(String? html) => (html ?? '')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
