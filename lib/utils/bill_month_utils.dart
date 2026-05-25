/// Chuẩn hóa tháng hóa đơn (Android `yyyy-MM`, Flutter `MM/yyyy`).
class BillMonthUtils {
  BillMonthUtils._();

  /// Khóa thống nhất `yyyy-MM` để so sánh / gom nhóm.
  static String normalizeKey(String month) {
    final m = month.trim();
    if (m.isEmpty) return m;

    if (m.contains('/')) {
      final parts = m.split('/');
      if (parts.length == 2) {
        final mm = parts[0].padLeft(2, '0');
        final yyyy = parts[1].length == 2 ? '20${parts[1]}' : parts[1];
        return '$yyyy-$mm';
      }
    }

    if (m.contains('-')) {
      final parts = m.split('-');
      if (parts.length == 2) {
        if (parts[0].length == 4) {
          return '${parts[0]}-${parts[1].padLeft(2, '0')}';
        }
        return '${parts[1]}-${parts[0].padLeft(2, '0')}';
      }
    }

    return m;
  }

  /// `count` tháng gần nhất (cũ → mới), kết thúc tại [anchor].
  static List<String> lastMonthKeys(DateTime anchor, int count) {
    final keys = <String>[];
    for (var i = count - 1; i >= 0; i--) {
      final d = DateTime(anchor.year, anchor.month - i);
      keys.add('${d.year}-${d.month.toString().padLeft(2, '0')}');
    }
    return keys;
  }

  /// Nhãn trục biểu đồ: T3, T4...
  static String chartLabel(String yyyyMm) {
    final parts = yyyyMm.split('-');
    if (parts.length != 2) return yyyyMm;
    return 'T${int.tryParse(parts[1]) ?? parts[1]}';
  }
}
