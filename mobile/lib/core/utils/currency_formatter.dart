import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(num? amount) => formatInr(amount);

  static String formatInr(num? amount) {
    if (amount == null) return 'Free / Nil';
    if (amount == 0) return '₹0 (Exempted)';
    return '₹${NumberFormat('#,##,###').format(amount)}';
  }
}
