import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Định dạng/số giá giống app Android (vi_VN: 3.500, 20.000).
class PriceInputFormatter {
  static final NumberFormat _nf = NumberFormat('#,###', 'vi_VN');

  static String format(double value) {
    if (value <= 0) return '';
    return _nf.format(value.round());
  }

  static double parse(String text, {double fallback = 0}) {
    final digits = text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return fallback;
    return double.tryParse(digits) ?? fallback;
  }
}

class VndInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final value = double.tryParse(digits) ?? 0;
    final formatted = PriceInputFormatter.format(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
