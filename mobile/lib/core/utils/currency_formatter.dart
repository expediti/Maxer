import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(num? amount) => formatInr(amount);

  static String formatInr(num? amount) {
    if (amount == null) return 'Refer official notice';
    if (amount == 0) return '₹0 (Free / Exempted)';
    return '₹${NumberFormat('#,##,###').format(amount)}';
  }
}
