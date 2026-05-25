import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/room_model.dart';
import '../../models/bill_model.dart';
import '../../models/payment_model.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/bill_month_utils.dart';
import '../../utils/report_calculator.dart';
import '../../widgets/gradient_sub_page_header.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _service = FirebaseService();
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: '\u0111');
  late final Stream<List<Room>> _roomsStream;
  late final Stream<List<Bill>> _billsStream;
  late final Stream<List<Payment>> _paymentsStream;

  @override
  void initState() {
    super.initState();
    _roomsStream = _service.getRooms();
    _billsStream = _service.getBills();
    _paymentsStream = _service.getPayments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: StreamBuilder<List<Room>>(
        stream: _roomsStream,
        builder: (context, roomSnap) {
          return StreamBuilder<List<Bill>>(
            stream: _billsStream,
            builder: (context, billSnap) {
              if (roomSnap.hasError || billSnap.hasError) {
                return _errorBody((roomSnap.error ?? billSnap.error).toString());
              }
              if (!roomSnap.hasData || !billSnap.hasData) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
              }
              return StreamBuilder<List<Payment>>(
                stream: _paymentsStream,
                builder: (context, paymentSnap) {
                  if (paymentSnap.hasError) {
                    return _errorBody(paymentSnap.error.toString());
                  }
                  if (!paymentSnap.hasData) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                  }
                  final summary = ReportCalculator.build(
                    bills: billSnap.data ?? const <Bill>[],
                    rooms: roomSnap.data ?? const <Room>[],
                    paidByBill: _paidByBill(paymentSnap.data ?? const <Payment>[]),
                  );
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const GradientSubPageHeader(
                          subtitle: 'Th\u1ed1ng k\u00ea',
                          title: 'B\u00e1o c\u00e1o doanh thu',
                        ),
                        _summaryRow(summary),
                        _chartCard(
                          'Doanh thu \u0111\u00e3 thu (6 th\u00e1ng)',
                          _buildBarChart(summary),
                        ),
                        _chartCard(
                          'T\u00ecnh tr\u1ea1ng ph\u00f2ng',
                          _buildPieChart(summary),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static Map<String, double> _paidByBill(List<Payment> payments) {
    final result = <String, double>{};
    for (final payment in payments) {
      result[payment.billId] = (result[payment.billId] ?? 0) + payment.amount;
    }
    return result;
  }

  Widget _errorBody(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: AppTheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Kh\u00f4ng t\u1ea3i \u0111\u01b0\u1ee3c d\u1eef li\u1ec7u',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(error, style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(ReportSummary s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(child: _summaryTile('T\u1ed5ng \u0111\u00e3 thu', _currency.format(s.totalPaid), AppTheme.success)),
          const SizedBox(width: 12),
          Expanded(child: _summaryTile('C\u00f2n n\u1ee3', _currency.format(s.totalUnpaid), AppTheme.error)),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, String value, Color valueColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartCard(String title, Widget chart) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
          const SizedBox(height: 24),
          SizedBox(height: 240, child: chart),
        ],
      ),
    );
  }

  Widget _buildBarChart(ReportSummary s) {
    final months = s.months;
    if (months.every((m) => m.paid == 0)) {
      return const Center(
        child: Text(
          'Ch\u01b0a c\u00f3 doanh thu \u0111\u00e3 thu trong 6 th\u00e1ng',
          style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }

    final maxY = s.maxMonthlyPaid();
    final chartMax = maxY <= 0 ? 1.0 : maxY * 1.15;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartMax,
        barGroups: [
          for (var i = 0; i < months.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: months[i].paid,
                  color: AppTheme.primary,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= months.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    BillMonthUtils.chartLabel(months[i].monthKey),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildPieChart(ReportSummary s) {
    if (s.totalRooms == 0) {
      return const Center(child: Text('Kh\u00f4ng c\u00f3 d\u1eef li\u1ec7u ph\u00f2ng'));
    }

    final rented = s.rentedRooms.toDouble();
    final vacant = s.vacantRooms.toDouble();

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 44,
        sections: [
          if (rented > 0)
            PieChartSectionData(
              value: rented,
              title: '\u0110ang thu\u00ea\n${s.rentedRooms}',
              color: AppTheme.primary,
              radius: 58,
              titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          if (vacant > 0)
            PieChartSectionData(
              value: vacant,
              title: 'Tr\u1ed1ng\n${s.vacantRooms}',
              color: const Color(0xFFE5E7EB),
              radius: 48,
              titleStyle: const TextStyle(color: Color(0xFF4B5563), fontSize: 11),
            ),
        ],
      ),
    );
  }
}
