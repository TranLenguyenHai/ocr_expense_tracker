import 'package:intl/intl.dart';

class CurrencyFormatter {
  // Avoid MissingLocaleDataException: format manually without vi_VN locale.
  static String format(double amount) {
    final intAmount = amount.toInt();
    return '${_addThousandSeparators(intAmount)} ₫';
  }

  static String _addThousandSeparators(int value) {
    final str = value.abs().toString();
    final buffer = StringBuffer();
    final startOffset = str.length % 3;
    for (int i = 0; i < str.length; i++) {
      if (i != 0 && (i - startOffset) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return value < 0 ? '-${buffer.toString()}' : buffer.toString();
  }

  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}Tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String formatWeekday(DateTime date) {
    const weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return weekdays[date.weekday - 1];
  }
}
