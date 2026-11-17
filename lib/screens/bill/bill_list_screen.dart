import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/bill_model.dart';
import '../../models/contract_model.dart';
import '../../models/payment_model.dart';
import '../../models/room_model.dart';
import '../../models/tenant_model.dart';
import '../../services/firebase_service.dart';
import '../../utils/pdf_helper.dart';
import '../../utils/price_input_formatter.dart';
import 'add_bill_screen.dart';
import 'bill_detail_dialog.dart';
import '../../utils/string_utils.dart';
import '../../widgets/list_search_field.dart';

class _BillFilterSpec {
  final String label;
  final String value;
  const _BillFilterSpec({required this.label, required this.value});
}

class BillListScreen extends StatefulWidget {
  const BillListScreen({super.key});

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends State<BillListScreen> {
  final _service = FirebaseService();
  late final Stream<List<Bill>> _billsStream;
  late final Stream<List<Contract>> _contractsStream;
  late final Stream<List<Room>> _roomsStream;
  late final Stream<List<Tenant>> _tenantsStream;
  late final Stream<List<Payment>> _paymentsStream;
  String _currentFilter = 'ALL';
  String _searchQuery = '';

  Future<String?> _pickBulkBillingMonth() async {
    final now = DateTime.now();
    return showDialog<String>(
      context: context,
      builder: (_) => _BulkMonthDialog(defaultYear: now.year),
    );
  }

  @override
  void initState() {
    super.initState();
    _billsStream = _service.getBills();
    _contractsStream = _service.getContracts();
    _roomsStream = _service.getRooms();
    _tenantsStream = _service.getTenants();
    _paymentsStream = _service.getPayments();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6366F1);
    const textColor = Color(0xFF111827);
    const mutedText = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hóa đơn',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 22, height: 1.1),
                      ),
                      TextButton.icon(
                        onPressed: _openQuickMeterSheet,
                        icon: const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFFD97706)),
                        label: const Text(
                          'Sổ ghi điện nước nhanh',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFEF3C7),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final monthStr = await _pickBulkBillingMonth();
                              if (monthStr == null || !context.mounted) return;
                              final settings = await _service.getSettings();
                              final parts = monthStr.split('/');
                              final month = int.parse(parts[0]);
                              final year = int.parse(parts[1]);
                              final dueDate = DateTime(year, month + 1, 0);
                              final count = await _service.bulkCreateBills(monthStr, settings, dueDate: dueDate);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    count > 0
                                        ? 'Đã tạo $count hóa đơn mới cho tháng $monthStr'
                                        : 'Không có hóa đơn mới cần tạo',
                                  ),
                                  backgroundColor: count > 0 ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceFirst('Exception: ', '')),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.auto_awesome_motion_rounded, size: 18),
                          label: const Text('Tạo hàng loạt'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                            minimumSize: const Size(0, 42),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddBillScreen()),
                          ),
                          icon: const Icon(Icons.edit_note_rounded, size: 20),
                          label: const Text('Tạo hóa đơn /\nChốt điện nước', textAlign: TextAlign.center),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            foregroundColor: const Color(0xFF374151),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            minimumSize: const Size(0, 42),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  ListSearchField(
                    hintText: 'Tìm theo phòng hoặc tháng...',
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: const [
                        _BillFilterSpec(label: 'Tất cả', value: 'ALL'),
                        _BillFilterSpec(label: 'Chưa chốt', value: 'PENDING'),
                        _BillFilterSpec(label: 'Chưa trả', value: 'unpaid'),
                        _BillFilterSpec(label: 'Thiếu', value: 'partial'),
                        _BillFilterSpec(label: 'Đã trả', value: 'paid'),
                      ].map((spec) => _filterChip(spec.label, spec.value)).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: StreamBuilder<List<Bill>>(
                stream: _billsStream,
                builder: (ctx, billSnap) {
                  if (!billSnap.hasData) {
                    return const Center(child: CircularProgressIndicator(color: primaryColor));
                  }
                  return StreamBuilder<List<Contract>>(
                    stream: _contractsStream,
                    builder: (ctx, contractSnap) {
                      return StreamBuilder<List<Room>>(
                        stream: _roomsStream,
                        builder: (ctx, roomSnap) {
                          return StreamBuilder<List<Tenant>>(
                            stream: _tenantsStream,
                            builder: (ctx, tenantSnap) {
                              return StreamBuilder<List<Payment>>(
                                stream: _paymentsStream,
                                builder: (ctx, paymentSnap) {
                          var bills = List<Bill>.of(billSnap.data ?? []);
                          final contracts = contractSnap.data ?? [];
                          final rooms = roomSnap.data ?? [];
                          final tenants = tenantSnap.data ?? [];
                          final payments = paymentSnap.data ?? [];
                          final paidByBill = _paidByBill(payments);
                          bills.sort((a, b) => b.id.compareTo(a.id));
                          if (_currentFilter != 'ALL') {
                            if (_currentFilter == 'PENDING') {
                              bills = bills.where((b) => !b.meterUpdated).toList();
                            } else if (_currentFilter == 'paid') {
                              bills = bills.where((b) => b.isPaid).toList();
                            } else if (_currentFilter == 'unpaid') {
                              bills = bills.where((b) => b.isUnpaid && _paidAmountFor(b, paidByBill) <= 0).toList();
                            } else if (_currentFilter == 'partial') {
                              bills = bills.where((b) => b.isPartial && _paidAmountFor(b, paidByBill) > 0).toList();
                            } else {
                              bills = bills.where((b) => b.paymentStatus == _currentFilter).toList();
                            }
                          }
                          if (_searchQuery.isNotEmpty) {
                            bills = bills.where((b) {
                              final contract = _contractForBill(contracts, b);
                              final room = _roomForContract(rooms, contract);
                              return StringUtils.containsSearch(room?.roomName ?? '', _searchQuery) ||
                                  b.month.contains(_searchQuery);
                            }).toList();
                          }
                          if (bills.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_outlined, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 8),
                                  Text('Chưa có hóa đơn nào', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                                ],
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 88),
                            itemCount: bills.length,
                            itemBuilder: (ctx, i) {
                              final b = bills[i];
                              final contract = _contractForBill(contracts, b);
                              final room = _roomForContract(rooms, contract);
                              final tenant = _tenantForContract(tenants, contract) ??
                                  Tenant(id: '', fullName: 'Khách thuê', phone: '', cccd: '', address: '');
                              final displayRoom = room ?? Room(id: '', roomName: 'Phòng không rõ', price: 0);
                              final isPaid = b.isPaid;
                              final roomLabel = displayRoom.roomName;
                              final paidAmount = isPaid ? b.totalAmount : _paidAmountFor(b, paidByBill);
                              final debtAmount = (b.totalAmount - paidAmount).clamp(0, double.infinity).toDouble();
                              final dueDate = DateTime.fromMillisecondsSinceEpoch(b.dueDate);
                              final isOverdue = !isPaid && b.meterUpdated && dueDate.isBefore(DateTime.now());
                              final isPartial = !isPaid && paidAmount > 0;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAFAFF),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF94A3B8).withValues(alpha: 0.16),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '$roomLabel - ${b.month}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                                color: textColor,
                                                height: 1.1,
                                              ),
                                            ),
                                          ),
                                          _statusBadge(
                                            !b.meterUpdated ? 'Chưa chốt' : (isPaid ? 'Đã trả' : (isPartial ? 'Thiếu' : (isOverdue ? 'Quá hạn' : 'Chưa trả'))),
                                            !b.meterUpdated
                                                ? const Color(0xFFF97316)
                                                : (isPaid ? const Color(0xFF16A34A) : (isPartial ? const Color(0xFFF97316) : const Color(0xFFEF4444))),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        tenant.fullName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: mutedText, fontSize: 12, fontWeight: FontWeight.w600, height: 1.1),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            'Tổng: ${_money(b.totalAmount)}',
                                            style: const TextStyle(fontWeight: FontWeight.w800, color: textColor, fontSize: 12),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Đã trả: ${_money(paidAmount)}',
                                            style: const TextStyle(color: Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Còn nợ: ${_money(debtAmount)}',
                                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 15, fontWeight: FontWeight.w900, height: 1.1),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Hạn thu: ${DateFormat('dd/MM/yyyy').format(dueDate)}',
                                        style: const TextStyle(color: mutedText, fontSize: 11, fontWeight: FontWeight.w500),
                                      ),
                                      const Divider(height: 18, color: Color(0xFFF1F5F9)),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 130,
                                            child: ElevatedButton.icon(
                                            onPressed: isPaid
                                                ? null
                                                : () async {
                                                    if (!b.meterUpdated) {
                                                      _showMeterDialog(b);
                                                      return;
                                                    }
                                                    await _showPaymentDialog(b, paidAmount);
                                                  },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isPaid ? const Color(0xFFE2E8F0) : primaryColor,
                                              foregroundColor: isPaid ? const Color(0xFF64748B) : Colors.white,
                                              elevation: 0,
                                              minimumSize: const Size(0, 34),
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                                            ),
                                            icon: Icon(
                                              isPaid
                                                  ? Icons.check_circle_outline_rounded
                                                  : (b.meterUpdated ? Icons.payments_outlined : Icons.electric_meter_outlined),
                                              size: 16,
                                            ),
                                            label: Text(
                                              isPaid ? 'Đã thu' : (b.meterUpdated ? (isPartial ? 'Thu thêm' : 'Thu tiền') : 'Chốt số'),
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton(
                                            onPressed: () => showDialog(
                                              context: context,
                                              builder: (_) => BillDetailDialog(bill: b, room: displayRoom, tenant: tenant, paidAmount: paidAmount),
                                            ),
                                            child: Text(
                                              'Chi tiết',
                                              style: const TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            tooltip: 'Chia sẻ PDF',
                                            onPressed: () => InvoicePdfHelper.generateAndShare(b, displayRoom, tenant, paidAmount: paidAmount),
                                            icon: const Icon(Icons.share_outlined, color: Colors.grey, size: 20),
                                          ),
                                          if (!isPaid && paidAmount <= 0)
                                            IconButton(
                                              tooltip: 'Xóa hóa đơn',
                                              onPressed: () => _confirmDeleteBill(b, roomLabel),
                                              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _currentFilter == value;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _currentFilter = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected ? _chipColor(value, true) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isSelected ? _chipColor(value, false) : const Color(0xFFE5E7EB)),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected && value != 'ALL') ...[
                      Icon(Icons.check_rounded, size: 13, color: _chipTextColor(value)),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        color: isSelected ? _chipTextColor(value) : const Color(0xFF64748B),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _chipColor(String value, bool fill) {
    if (value == 'paid') return fill ? const Color(0xFFDCFCE7) : const Color(0xFFBBF7D0);
    if (value == 'partial') return fill ? const Color(0xFFFFEDD5) : const Color(0xFFFED7AA);
    if (value == 'unpaid') return fill ? const Color(0xFFFFE4E6) : const Color(0xFFFFCDD5);
    return fill ? const Color(0xFFEFF6FF) : const Color(0xFFBFDBFE);
  }

  static Color _chipTextColor(String value) {
    if (value == 'paid') return const Color(0xFF16A34A);
    if (value == 'partial') return const Color(0xFFF97316);
    if (value == 'unpaid') return const Color(0xFFEF4444);
    return const Color(0xFF6366F1);
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  static String _money(double value) {
    return '${NumberFormat.decimalPattern('vi_VN').format(value.round())}đ';
  }

  static Map<String, double> _paidByBill(List<Payment> payments) {
    final result = <String, double>{};
    for (final payment in payments) {
      result[payment.billId] = (result[payment.billId] ?? 0) + payment.amount;
    }
    return result;
  }

  static double _paidAmountFor(Bill bill, Map<String, double> paidByBill) {
    return paidByBill[bill.paymentKey] ?? paidByBill[bill.id] ?? 0;
  }

  static Contract? _contractForBill(List<Contract> contracts, Bill bill) {
    return contracts
        .where((c) => c.id == bill.contractId || c.contractKey == bill.contractId)
        .firstOrNull;
  }

  static Room? _roomForContract(List<Room> rooms, Contract? contract) {
    if (contract == null) return null;
    return rooms.where((r) => r.id == contract.roomId || r.roomKey == contract.roomId).firstOrNull;
  }

  static Tenant? _tenantForContract(List<Tenant> tenants, Contract? contract) {
    if (contract == null) return null;
    return tenants.where((t) => t.id == contract.tenantId || t.tenantKey == contract.tenantId).firstOrNull;
  }

  Future<void> _showPaymentDialog(Bill bill, double paidAmount) async {
    final remaining = (bill.totalAmount - paidAmount).clamp(0, double.infinity).toDouble();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => _PaymentAmountDialog(
        initialAmount: remaining,
        helperText: 'Còn nợ: ${_money(remaining)}',
      ),
    );
    if (amount == null) return;
    try {
      await _service.addPayment(bill, amount, paidAmount);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanh toán thành công'), backgroundColor: Color(0xFF16A34A)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showMeterDialog(Bill bill) async {
    final result = await showDialog<_MeterReadingInput>(
      context: context,
      builder: (ctx) => _MeterReadingDialog(bill: bill),
    );
    if (result == null) return;
    final newElectric = result.electric;
    final newWater = result.water;
    if (newElectric < bill.oldElectric || newWater < bill.oldWater) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số mới không được nhỏ hơn số cũ'), backgroundColor: Colors.orange),
      );
      return;
    }
    try {
      await _service.updateBillMeter(bill, newElectric, newWater);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã chốt điện nước'), backgroundColor: Color(0xFF16A34A)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmDeleteBill(Bill bill, String roomLabel) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa hóa đơn'),
        content: Text('Bạn có chắc chắn muốn xóa hóa đơn $roomLabel - ${bill.month}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _service.deleteBill(bill.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa hóa đơn')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openQuickMeterSheet() async {
    try {
      final results = await Future.wait([
        _service.getBills().first,
        _service.getContracts().first,
        _service.getRooms().first,
      ]);
      if (!mounted) return;
      final allBills = results[0] as List<Bill>;
      final contracts = results[1] as List<Contract>;
      final rooms = results[2] as List<Room>;

      var targetBills = allBills.where((b) => !b.meterUpdated).toList();
      if (targetBills.isEmpty) {
        targetBills = allBills.where((b) => !b.isPaid).toList();
      }
      if (targetBills.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không có hóa đơn nào cần chốt điện nước. Hãy bấm "Tạo hàng loạt" trước!'),
            backgroundColor: Color(0xFF64748B),
          ),
        );
        return;
      }

      final entries = targetBills.map((b) {
        final contract = _contractForBill(contracts, b);
        final room = _roomForContract(rooms, contract);
        return _QuickMeterItem(
          bill: b,
          roomName: room?.roomName ?? 'Phòng',
        );
      }).toList()
        ..sort((a, b) => a.roomName.compareTo(b.roomName));

      final savedCount = await showDialog<int>(
        context: context,
        builder: (_) => _QuickMeterSheetDialog(items: entries, service: _service),
      );
      if (savedCount != null && savedCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã chốt điện nước nhanh cho $savedCount phòng!'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }
}

class _BulkMonthDialog extends StatefulWidget {
  final int defaultYear;

  const _BulkMonthDialog({required this.defaultYear});

  @override
  State<_BulkMonthDialog> createState() => _BulkMonthDialogState();
}

class _BulkMonthDialogState extends State<_BulkMonthDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: DateTime.now().month.toString().padLeft(2, '0'));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _controller.text.trim();
    final value = raw.contains('/') ? raw : '$raw/${widget.defaultYear}';
    final parts = value.split('/');
    final month = parts.length == 2 ? int.tryParse(parts[0]) : null;
    final year = parts.length == 2 ? int.tryParse(parts[1]) : null;
    if (month == null || year == null || month < 1 || month > 12 || year < 2000 || year > widget.defaultYear + 1) {
      setState(() => _error = 'Nhập tháng hợp lệ, ví dụ 07 hoặc 07/${widget.defaultYear}');
      return;
    }
    Navigator.of(context).pop('${month.toString().padLeft(2, '0')}/$year');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tạo hóa đơn hàng loạt'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: 'Nhập tháng',
          hintText: 'Ví dụ: 07',
          helperText: 'Năm mặc định: ${widget.defaultYear}. Có thể nhập MM/yyyy.',
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Hủy')),
        FilledButton(onPressed: _submit, child: const Text('Tạo')),
      ],
    );
  }
}

class _PaymentAmountDialog extends StatefulWidget {
  final double initialAmount;
  final String helperText;

  const _PaymentAmountDialog({
    required this.initialAmount,
    required this.helperText,
  });

  @override
  State<_PaymentAmountDialog> createState() => _PaymentAmountDialogState();
}

class _PaymentAmountDialogState extends State<_PaymentAmountDialog> {
  late final TextEditingController _amountCtrl;
  late final String _initialText;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: PriceInputFormatter.format(widget.initialAmount));
    _initialText = _amountCtrl.text;
    _selectAll();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _selectAll() {
    _amountCtrl.selection = TextSelection(baseOffset: 0, extentOffset: _amountCtrl.text.length);
  }

  void _submit() {
    Navigator.pop(context, PriceInputFormatter.parse(_amountCtrl.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thu tiền hóa đơn'),
      content: TextField(
        controller: _amountCtrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [VndInputFormatter()],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        onTap: () {
          if (_amountCtrl.text == _initialText) _selectAll();
        },
        decoration: InputDecoration(
          labelText: 'Số tiền thu',
          helperText: widget.helperText,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        TextButton(onPressed: _submit, child: const Text('Xác nhận')),
      ],
    );
  }
}

class _MeterReadingInput {
  final int electric;
  final int water;

  const _MeterReadingInput({required this.electric, required this.water});
}

class _MeterReadingDialog extends StatefulWidget {
  final Bill bill;

  const _MeterReadingDialog({required this.bill});

  @override
  State<_MeterReadingDialog> createState() => _MeterReadingDialogState();
}

class _MeterReadingDialogState extends State<_MeterReadingDialog> {
  late final TextEditingController _electricCtrl;
  late final TextEditingController _waterCtrl;
  late final String _initialElectric;
  late final String _initialWater;

  @override
  void initState() {
    super.initState();
    _electricCtrl = TextEditingController(text: widget.bill.newElectric.toString());
    _waterCtrl = TextEditingController(text: widget.bill.newWater.toString());
    _initialElectric = _electricCtrl.text;
    _initialWater = _waterCtrl.text;
    _selectAll(_electricCtrl);
  }

  @override
  void dispose() {
    _electricCtrl.dispose();
    _waterCtrl.dispose();
    super.dispose();
  }

  void _selectAll(TextEditingController controller) {
    controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
  }

  void _submit() {
    Navigator.pop(
      context,
      _MeterReadingInput(
        electric: int.tryParse(_electricCtrl.text.trim()) ?? widget.bill.oldElectric,
        water: int.tryParse(_waterCtrl.text.trim()) ?? widget.bill.oldWater,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    final newElec = int.tryParse(_electricCtrl.text.trim()) ?? bill.oldElectric;
    final newWater = int.tryParse(_waterCtrl.text.trim()) ?? bill.oldWater;
    final elecUsed = newElec - bill.oldElectric;
    final waterUsed = newWater - bill.oldWater;
    final isAnomaly = elecUsed > 300 || waterUsed > 30;

    return AlertDialog(
      title: const Text('Chốt điện nước'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _electricCtrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            onTap: () {
              if (_electricCtrl.text == _initialElectric) _selectAll(_electricCtrl);
            },
            decoration: InputDecoration(labelText: 'Điện mới (cũ: ${bill.oldElectric})'),
          ),
          TextField(
            controller: _waterCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
            onTap: () {
              if (_waterCtrl.text == _initialWater) _selectAll(_waterCtrl);
            },
            decoration: InputDecoration(labelText: 'Nước mới (cũ: ${bill.oldWater})'),
          ),
          if (isAnomaly) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Text(
                '⚠️ Tiêu thụ cao bất thường (${elecUsed > 0 ? "$elecUsed kWh" : ""}${elecUsed > 0 && waterUsed > 0 ? ", " : ""}${waterUsed > 0 ? "$waterUsed khối" : ""}). Hãy kiểm tra lại đồng hồ!',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E), fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        TextButton(onPressed: _submit, child: const Text('Lưu')),
      ],
    );
  }
}

class _QuickMeterItem {
  final Bill bill;
  final String roomName;

  const _QuickMeterItem({required this.bill, required this.roomName});
}

class _QuickMeterSheetDialog extends StatefulWidget {
  final List<_QuickMeterItem> items;
  final FirebaseService service;

  const _QuickMeterSheetDialog({
    required this.items,
    required this.service,
  });

  @override
  State<_QuickMeterSheetDialog> createState() => _QuickMeterSheetDialogState();
}

class _QuickMeterSheetDialogState extends State<_QuickMeterSheetDialog> {
  late final List<TextEditingController> _elecCtrls;
  late final List<TextEditingController> _waterCtrls;
  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _elecCtrls = widget.items
        .map((e) => TextEditingController(text: e.bill.newElectric.toString()))
        .toList();
    _waterCtrls = widget.items
        .map((e) => TextEditingController(text: e.bill.newWater.toString()))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _elecCtrls) {
      c.dispose();
    }
    for (final c in _waterCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAll() async {
    setState(() {
      _saving = true;
      _errorText = null;
    });
    int updatedCount = 0;
    try {
      for (var i = 0; i < widget.items.length; i++) {
        final item = widget.items[i];
        final bill = item.bill;
        final newElec = int.tryParse(_elecCtrls[i].text.trim()) ?? bill.oldElectric;
        final newWater = int.tryParse(_waterCtrls[i].text.trim()) ?? bill.oldWater;

        if (newElec < bill.oldElectric || newWater < bill.oldWater) {
          setState(() {
            _saving = false;
            _errorText = '${item.roomName}: Chỉ số mới không được nhỏ hơn chỉ số cũ';
          });
          return;
        }

        if (!bill.meterUpdated || newElec != bill.newElectric || newWater != bill.newWater) {
          await widget.service.updateBillMeter(bill, newElec, newWater);
          updatedCount++;
        }
      }
      if (mounted) Navigator.pop(context, updatedCount);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6366F1);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Sổ ghi điện nước nhanh',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                    ),
                  ),
                  Text(
                    '${widget.items.length} phòng',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Đi dọc hành lang, nhập chỉ số mới của các phòng rồi bấm Lưu tất cả.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorText!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 16, color: Color(0xFFE5E7EB)),
                  itemBuilder: (ctx, i) {
                    final item = widget.items[i];
                    final b = item.bill;
                    final newE = int.tryParse(_elecCtrls[i].text.trim()) ?? b.oldElectric;
                    final newW = int.tryParse(_waterCtrls[i].text.trim()) ?? b.oldWater;
                    final diffE = newE - b.oldElectric;
                    final diffW = newW - b.oldWater;
                    final warn = diffE > 300 || diffW > 30;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.roomName} (${b.month})',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF1E293B)),
                            ),
                            if (warn)
                              const Text(
                                '⚠️ Cao bất thường',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFD97706)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _elecCtrls[i],
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelText: 'Điện mới (cũ: ${b.oldElectric})',
                                  labelStyle: const TextStyle(fontSize: 11.5),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _waterCtrls[i],
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelText: 'Nước mới (cũ: ${b.oldWater})',
                                  labelStyle: const TextStyle(fontSize: 11.5),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _saveAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Lưu tất cả', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
