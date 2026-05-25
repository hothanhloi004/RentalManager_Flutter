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
                  Text(
                    'Hóa đơn',
                    style: const TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 22, height: 1.1),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final settings = await _service.getSettings();
                              final monthStr = DateFormat('MM/yyyy').format(DateTime.now());
                              final count = await _service.bulkCreateBills(monthStr, settings);
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
                                            icon: const Text('\$', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
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
                                            onPressed: () => InvoicePdfHelper.generateAndShare(b, displayRoom, tenant),
                                            icon: const Icon(Icons.share_outlined, color: Colors.grey, size: 20),
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
    await _service.updateBillMeter(bill, newElectric, newWater);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã chốt điện nước'), backgroundColor: Color(0xFF16A34A)),
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
            onTap: () {
              if (_electricCtrl.text == _initialElectric) _selectAll(_electricCtrl);
            },
            decoration: InputDecoration(labelText: 'Điện mới (cũ: ${bill.oldElectric})'),
          ),
          TextField(
            controller: _waterCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            onTap: () {
              if (_waterCtrl.text == _initialWater) _selectAll(_waterCtrl);
            },
            decoration: InputDecoration(labelText: 'Nước mới (cũ: ${bill.oldWater})'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        TextButton(onPressed: _submit, child: const Text('Lưu')),
      ],
    );
  }
}
