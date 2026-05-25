import 'package:flutter_test/flutter_test.dart';
import 'package:rental_manager/models/bill_model.dart';
import 'package:rental_manager/models/room_model.dart';
import 'package:rental_manager/utils/report_calculator.dart';

void main() {
  test('counts partial payments as paid revenue and remaining debt', () {
    final summary = ReportCalculator.build(
      anchor: DateTime(2026, 5, 24),
      bills: [
        Bill(
          id: 'doc-bill-1',
          billId: 'android-bill-1',
          contractId: 'contract-1',
          month: '05/2026',
          oldElectric: 0,
          newElectric: 0,
          electricUsed: 0,
          oldWater: 0,
          newWater: 0,
          waterUsed: 0,
          electricPrice: 0,
          waterPrice: 0,
          rentPrice: 1000000,
          serviceFee: 200000,
          totalAmount: 1200000,
          paymentStatus: 'DONG_THIEU',
          dueDate: 0,
          meterUpdated: true,
        ),
      ],
      rooms: const [],
      paidByBill: const {'android-bill-1': 500000},
    );

    final may2026 = summary.months.last;
    expect(may2026.paid, 500000);
    expect(may2026.unpaid, 700000);
  });

  test('counts paid bills by full total even without payment rows', () {
    final summary = ReportCalculator.build(
      anchor: DateTime(2026, 5, 24),
      bills: [
        Bill(
          id: 'bill-paid',
          contractId: 'contract-1',
          month: '2026-05',
          oldElectric: 0,
          newElectric: 0,
          electricUsed: 0,
          oldWater: 0,
          newWater: 0,
          waterUsed: 0,
          electricPrice: 0,
          waterPrice: 0,
          rentPrice: 1000000,
          serviceFee: 0,
          totalAmount: 1000000,
          paymentStatus: 'DA_THANH_TOAN',
          dueDate: 0,
          meterUpdated: true,
        ),
      ],
      rooms: [
        Room(id: 'room-1', roomName: 'Phong 1', price: 1000000, status: 'DANG_THUE'),
        Room(id: 'room-2', roomName: 'Phong 2', price: 1000000, status: 'TRONG'),
      ],
    );

    final may2026 = summary.months.last;
    expect(may2026.paid, 1000000);
    expect(may2026.unpaid, 0);
    expect(summary.rentedRooms, 1);
    expect(summary.vacantRooms, 1);
  });
}
