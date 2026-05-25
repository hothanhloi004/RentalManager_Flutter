import '../models/bill_model.dart';
import '../models/room_model.dart';
import 'bill_month_utils.dart';

class MonthlyRevenue {
  final String monthKey;
  final double paid;
  final double unpaid;

  const MonthlyRevenue({
    required this.monthKey,
    required this.paid,
    required this.unpaid,
  });
}

class ReportSummary {
  final List<MonthlyRevenue> months;
  final int rentedRooms;
  final int vacantRooms;
  final int totalRooms;

  const ReportSummary({
    required this.months,
    required this.rentedRooms,
    required this.vacantRooms,
    required this.totalRooms,
  });

  double get totalPaid =>
      months.fold(0.0, (sum, m) => sum + m.paid);

  double get totalUnpaid =>
      months.fold(0.0, (sum, m) => sum + m.unpaid);

  double maxMonthlyPaid() {
    if (months.isEmpty) return 0;
    return months.map((m) => m.paid).reduce((a, b) => a > b ? a : b);
  }
}

class ReportCalculator {
  ReportCalculator._();

  static ReportSummary build({
    required List<Bill> bills,
    required List<Room> rooms,
    Map<String, double> paidByBill = const {},
    DateTime? anchor,
    int monthCount = 6,
  }) {
    final now = anchor ?? DateTime.now();
    final keys = BillMonthUtils.lastMonthKeys(now, monthCount);
    final byMonth = <String, MonthlyRevenue>{
      for (final k in keys)
        k: MonthlyRevenue(monthKey: k, paid: 0, unpaid: 0),
    };

    for (final bill in bills) {
      final key = BillMonthUtils.normalizeKey(bill.month);
      final bucket = byMonth[key];
      if (bucket == null) continue;
      final paid = _paidAmountFor(bill, paidByBill);
      final unpaid = (bill.totalAmount - paid).clamp(0, double.infinity).toDouble();
      byMonth[key] = MonthlyRevenue(
        monthKey: key,
        paid: bucket.paid + paid,
        unpaid: bucket.unpaid + unpaid,
      );
    }

    final rented = rooms.where((r) => r.isRented).length;
    return ReportSummary(
      months: keys.map((k) => byMonth[k]!).toList(),
      rentedRooms: rented,
      vacantRooms: rooms.length - rented,
      totalRooms: rooms.length,
    );
  }

  static double _paidAmountFor(Bill bill, Map<String, double> paidByBill) {
    if (bill.isPaid) return bill.totalAmount;
    final paid = paidByBill[bill.paymentKey] ?? paidByBill[bill.id] ?? 0;
    return paid.clamp(0, bill.totalAmount).toDouble();
  }
}
