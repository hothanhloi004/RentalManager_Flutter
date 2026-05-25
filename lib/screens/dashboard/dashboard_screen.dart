import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/bill_model.dart';
import '../../models/payment_model.dart';
import '../../models/room_model.dart';
import '../../models/setting_model.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../../services/inquiry_read_store.dart';
import '../../utils/app_nav.dart';
import '../notification/contact_request_screen.dart';
import '../report/report_screen.dart';
import '../setting/setting_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = FirebaseService();
  late final Stream<List<Room>> _roomsStream;
  late final Stream<List<Payment>> _paymentsStream;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _roomsStream = _service.getRooms();
    _paymentsStream = _service.getPayments();
    InquiryReadStore.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final monthStr = DateFormat('yyyy-MM').format(_selectedMonth);
    final monthDisplay = DateFormat('MM/yyyy').format(_selectedMonth);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppTheme.primary,
              padding: EdgeInsets.fromLTRB(20, topPad + 16, 12, 56),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StreamBuilder<Setting>(
                          stream: _service.getSettingsStream(),
                          builder: (context, snapshot) {
                            final s = snapshot.data;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (s?.hostelName.isNotEmpty ?? false)
                                      ? s!.hostelName
                                      : 'Nhà Trọ Của Tôi',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  (s?.landlordName.isNotEmpty ?? false)
                                      ? 'Chủ trọ: ${s!.landlordName}'
                                      : 'Chủ trọ',
                                  style: const TextStyle(color: AppTheme.headerTint, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      _HeaderIconButton(
                        icon: Icons.notifications_outlined,
                        onPressed: () => pushSubPage(context, const NotificationScreen()),
                        badgeStream: _unreadInquiriesStream(),
                      ),
                      _HeaderIconButton(
                        icon: Icons.settings_outlined,
                        onPressed: () => pushSubPage(context, const SettingScreen()),
                      ),
                      _HeaderIconButton(
                        icon: Icons.power_settings_new_rounded,
                        onPressed: () => _confirmLogout(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 20),
                        onPressed: () => setState(
                          () => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Tháng $monthDisplay',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 20),
                        onPressed: () => setState(
                          () => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
                        tooltip: 'Báo cáo',
                        onPressed: () => pushSubPage(context, const ReportScreen()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreamBuilder<List<Bill>>(
                  stream: _service.getBillsByMonth(monthStr),
                  builder: (context, billSnapshot) {
                    return StreamBuilder<List<Room>>(
                      stream: _roomsStream,
                      builder: (context, roomSnapshot) {
                        return StreamBuilder<List<Payment>>(
                          stream: _paymentsStream,
                          builder: (context, paymentSnapshot) {
                        final bills = billSnapshot.data ?? [];
                        final rooms = roomSnapshot.data ?? [];
                        final payments = paymentSnapshot.data ?? [];
                        final paidByBill = _paidByBill(payments);
                        final revenue = bills.fold(0.0, (sum, bill) => sum + _paidAmountFor(bill, paidByBill));
                        final debt = bills.fold(0.0, (sum, bill) {
                          final remaining = bill.totalAmount - _paidAmountFor(bill, paidByBill);
                          return sum + (remaining <= 0 ? 0 : remaining);
                        });
                        final rented = rooms.where((r) => r.isRented).length;
                        final totalRooms = rooms.length;
                        final unpaid = bills.where((b) => !b.isPaid && b.totalAmount > _paidAmountFor(b, paidByBill)).length;
                        final overdue = bills.where((b) {
                          final hasDebt = !b.isPaid && b.totalAmount > _paidAmountFor(b, paidByBill);
                          if (!hasDebt || !b.meterUpdated || b.dueDate <= 0) return false;
                          return DateTime.fromMillisecondsSinceEpoch(b.dueDate).isBefore(DateTime.now());
                        }).length;
                        final electric = bills.fold(0.0, (a, b) => a + (b.newElectric - b.oldElectric));
                        final water = bills.fold(0.0, (a, b) => a + (b.newWater - b.oldWater));
                        final meterPending = bills.where((b) => !b.meterUpdated).length;
                        final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 24),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Doanh thu', style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant)),
                                            const SizedBox(height: 4),
                                            Text(
                                              fmt.format(revenue),
                                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.success),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Container(width: 1, height: 56, color: AppTheme.divider),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 20, right: 16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Còn nợ', style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant)),
                                            const SizedBox(height: 4),
                                            Text(
                                              fmt.format(debt),
                                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.error),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _metricTile(
                                    icon: Icons.bed_outlined,
                                    iconColor: AppTheme.primary,
                                    iconBg: AppTheme.iconPurpleBg,
                                    title: 'Phòng thuê',
                                    value: '$rented/$totalRooms',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _metricTile(
                                    icon: Icons.receipt_long_outlined,
                                    iconColor: AppTheme.error,
                                    iconBg: AppTheme.iconRedBg,
                                    title: 'Chưa thu',
                                    value: '$unpaid h\u00f3a \u0111\u01a1n',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _metricTile(
                                    icon: Icons.bolt_rounded,
                                    iconColor: AppTheme.iconOrange,
                                    iconBg: AppTheme.iconOrangeBg,
                                    title: 'Điện tiêu thụ',
                                    value: '${electric.toStringAsFixed(0)} kWh',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _metricTile(
                                    icon: Icons.water_drop_outlined,
                                    iconColor: AppTheme.iconTeal,
                                    iconBg: AppTheme.iconTealBg,
                                    title: 'Nước tiêu thụ',
                                    value: '${water.toStringAsFixed(0)} m³',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 8),
                              child: Text(
                                'Cảnh báo',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.onSurfaceVariant),
                              ),
                            ),
                            if (overdue > 0)
                              _alertCard(
                                bg: AppTheme.alertRedBg,
                                fg: AppTheme.alertRedText,
                                text: 'C\u00f3 $overdue h\u00f3a \u0111\u01a1n qu\u00e1 h\u1ea1n',
                              ),
                            if (meterPending > 0)
                              _alertCard(
                                bg: AppTheme.alertOrangeBg,
                                fg: AppTheme.alertOrangeText,
                                text: 'Có $meterPending phòng chưa chốt điện nước',
                              ),
                            if (rented < totalRooms)
                              _alertCard(
                                bg: AppTheme.alertOrangeBg,
                                fg: AppTheme.alertOrangeText,
                                text: 'Còn ${totalRooms - rented} phòng đang trống',
                              ),
                            const SizedBox(height: 88),
                          ],
                        );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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

  static double _paidAmountFor(Bill bill, Map<String, double> paidByBill) {
    if (bill.isPaid) return bill.totalAmount;
    final paid = paidByBill[bill.paymentKey] ?? paidByBill[bill.id] ?? 0;
    return paid.clamp(0, bill.totalAmount).toDouble();
  }

  Widget _metricTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertCard({required Color bg, required Color fg, required String text}) {
    return Card(
      color: bg,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: fg, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('HỦY')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _service.signOut();
            },
            child: const Text('ĐĂNG XUẤT', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  Stream<int>? _unreadInquiriesStream() {
    final uid = _service.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('inquiries')
        .doc(uid)
        .collection('requests')
        .snapshots()
        .map((snap) => InquiryReadStore.instance.countUnread(snap.docs.map((d) => d.id)));
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Stream<int>? badgeStream;

  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
    this.badgeStream,
  });

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      icon: Icon(icon, color: AppTheme.headerTint, size: 22),
      onPressed: onPressed,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );

    if (badgeStream == null) return button;

    return ListenableBuilder(
      listenable: InquiryReadStore.instance,
      builder: (context, _) {
        return StreamBuilder<int>(
          stream: badgeStream,
          builder: (context, snap) {
            final count = snap.data ?? 0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(icon, color: count > 0 ? Colors.white : AppTheme.headerTint, size: 24),
                  onPressed: onPressed,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                if (count > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, height: 1.1),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
