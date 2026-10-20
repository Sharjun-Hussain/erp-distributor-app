import 'package:intl/intl.dart';

class F {
  static final NumberFormat _money =
      NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);
  static final NumberFormat _qty = NumberFormat('#,##0.####');

  static String money(num value) => _money.format(value);
  static String qty(num value) => _qty.format(value);

  static String date(DateTime d) => DateFormat('dd MMM yyyy').format(d);
  static String dateTime(DateTime d) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(d);
  static String shortDate(DateTime d) => DateFormat('dd MMM').format(d);
}
