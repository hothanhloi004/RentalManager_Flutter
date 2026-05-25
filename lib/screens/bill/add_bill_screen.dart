import 'package:flutter/material.dart';
import '../../models/bill_model.dart';
import '../../models/contract_model.dart';
import '../../models/room_model.dart';
import '../../models/setting_model.dart';
import '../../services/firebase_service.dart';
import 'package:intl/intl.dart';

class AddBillScreen extends StatefulWidget {
  const AddBillScreen({super.key});
  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final _service = FirebaseService();
  final _formKey = GlobalKey<FormState>();

  Contract? _selectedContract;
  List<Contract> _contracts = [];
  List<Room> _rooms = [];
  Setting _setting = Setting();
  bool _isLoading = false;
  bool _isLoadingMeter = false;
  int _meterLoadToken = 0;

  final _monthCtrl = TextEditingController();
  final _oldElecCtrl = TextEditingController(text: '0');
  final _newElecCtrl = TextEditingController(text: '0');
  final _oldWaterCtrl = TextEditingController(text: '0');
  final _newWaterCtrl = TextEditingController(text: '0');
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  double _totalAmount = 0;
  final _fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthCtrl.text = DateFormat('MM/yyyy').format(now);
    _loadData();
  }

  @override
  void dispose() {
    _monthCtrl.dispose();
    _oldElecCtrl.dispose();
    _newElecCtrl.dispose();
    _oldWaterCtrl.dispose();
    _newWaterCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final contracts = await _service.getContracts().first;
      final rooms = await _service.getRooms().first;
      final setting = await _service.getSettings();
      if (!mounted) return;
      setState(() {
        _contracts = contracts.where((c) => c.isActive).toList();
        _rooms = rooms;
        _setting = setting;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  void _calculate() {
    if (_selectedContract == null) return;
    final oldE = int.tryParse(_oldElecCtrl.text) ?? 0;
    final newE = int.tryParse(_newElecCtrl.text) ?? 0;
    final oldW = int.tryParse(_oldWaterCtrl.text) ?? 0;
    final newW = int.tryParse(_newWaterCtrl.text) ?? 0;
    
    final elecUsed = (newE - oldE).clamp(0, 999999);
    final waterUsed = (newW - oldW).clamp(0, 999999);
    
    final c = _selectedContract!;
    final elecCost = elecUsed * _setting.electricPrice;
    final waterCost = waterUsed * _setting.waterPrice;
    final trashCost = c.useTrash ? _setting.trashFee : 0;
    final wifiCost = c.useWifi ? _setting.wifiPrice : 0;
    final serviceCost = c.useServiceFee ? _setting.serviceFee : 0;
    
    setState(() {
      _totalAmount = c.rentPrice + elecCost + waterCost + trashCost + wifiCost + serviceCost;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedContract == null) return;
    
    final newE = int.tryParse(_newElecCtrl.text) ?? 0;
    final oldE = int.tryParse(_oldElecCtrl.text) ?? 0;
    final newW = int.tryParse(_newWaterCtrl.text) ?? 0;
    final oldW = int.tryParse(_oldWaterCtrl.text) ?? 0;

    if (newE < oldE || newW < oldW) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số mới không được nhỏ hơn số cũ!'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final c = _selectedContract!;
      final bill = Bill(
        id: '',
        contractId: c.contractKey,
        month: _monthCtrl.text.trim(),
        oldElectric: oldE,
        newElectric: newE,
        electricUsed: newE - oldE,
        oldWater: oldW,
        newWater: newW,
        waterUsed: newW - oldW,
        electricPrice: _setting.electricPrice,
        waterPrice: _setting.waterPrice,
        rentPrice: c.rentPrice,
        serviceFee: (c.useTrash ? _setting.trashFee : 0) +
                    (c.useWifi ? _setting.wifiPrice : 0) +
                    (c.useServiceFee ? _setting.serviceFee : 0),
        totalAmount: _totalAmount,
        paymentStatus: 'CHUA_THANH_TOAN',
        dueDate: _dueDate.millisecondsSinceEpoch,
        meterUpdated: true,
      );
      
      await _service.addBill(bill);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu hóa đơn'), backgroundColor: Color(0xFF16A34A)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      final message = _friendlyError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: message.contains('đã tồn tại') ? const Color(0xFFF59E0B) : Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectContract(Contract? contract) async {
    final token = ++_meterLoadToken;
    setState(() {
      _selectedContract = contract;
      _isLoadingMeter = contract != null;
      if (contract != null) {
        _oldElecCtrl.text = contract.lastElectric.toString();
        _newElecCtrl.text = contract.lastElectric.toString();
        _oldWaterCtrl.text = contract.lastWater.toString();
        _newWaterCtrl.text = contract.lastWater.toString();
      } else {
        _totalAmount = 0;
      }
    });

    if (contract == null) return;
    _calculate();

    try {
      final meter = await _service.getLastMeterForRoom(contract.roomId);
      if (!mounted || token != _meterLoadToken || _selectedContract?.id != contract.id) return;
      setState(() {
        _oldElecCtrl.text = meter.electric.toString();
        _newElecCtrl.text = meter.electric.toString();
        _oldWaterCtrl.text = meter.water.toString();
        _newWaterCtrl.text = meter.water.toString();
        _isLoadingMeter = false;
      });
      _calculate();
    } catch (e) {
      if (!mounted || token != _meterLoadToken) return;
      setState(() => _isLoadingMeter = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không lấy được chỉ số cũ: ${_friendlyError(e)}'), backgroundColor: Colors.orange),
      );
    }
  }

  String? _validateMonth(String? value) {
    final text = (value ?? '').trim();
    final match = RegExp(r'^(0?[1-9]|1[0-2])\/\d{4}$').hasMatch(text);
    return match ? null : 'Nhập tháng theo dạng MM/yyyy';
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty) return 'Không thể lưu hóa đơn. Vui lòng thử lại.';
    return message;
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6366F1);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Lập hóa đơn ghi lẻ', style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 1, color: const Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('CHỌN PHÒNG & THÁNG'),
                    _card([
                      DropdownButtonFormField<Contract>(
                        value: _selectedContract,
                        decoration: _inputDeco('Chọn phòng đang thuê'),
                        items: _contracts.map((c) {
                          final room = _rooms.firstWhere((r) => r.id == c.roomId || r.roomKey == c.roomId, orElse: () => Room(id: '', roomName: '?', price: 0));
                          return DropdownMenuItem(value: c, child: Text(room.roomName));
                        }).toList(),
                        onChanged: _selectContract,
                        validator: (v) => v == null ? 'Vui lòng chọn phòng' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _monthCtrl,
                        decoration: _inputDeco('Tháng thanh toán (MM/YYYY)'),
                        validator: _validateMonth,
                        onChanged: (_) => _calculate(),
                      ),
                    ]),

                    const SizedBox(height: 24),
                    _sectionTitle(_isLoadingMeter ? 'CHỈ SỐ ĐIỆN NƯỚC - ĐANG LẤY SỐ CŨ...' : 'CHỈ SỐ ĐIỆN NƯỚC'),
                    _card([
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _oldElecCtrl, decoration: _inputDeco('Điện cũ'), keyboardType: TextInputType.number, onChanged: (_) => _calculate())),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _newElecCtrl, decoration: _inputDeco('Điện mới').copyWith(fillColor: const Color(0xFFEEF2FF)), keyboardType: TextInputType.number, onChanged: (_) => _calculate())),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _oldWaterCtrl, decoration: _inputDeco('Nước cũ'), keyboardType: TextInputType.number, onChanged: (_) => _calculate())),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _newWaterCtrl, decoration: _inputDeco('Nước mới').copyWith(fillColor: const Color(0xFFEFF6FF)), keyboardType: TextInputType.number, onChanged: (_) => _calculate())),
                        ],
                      ),
                    ]),

                    const SizedBox(height: 24),
                    _sectionTitle('HẠN THANH TOÁN'),
                    _card([
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(DateFormat('dd/MM/yyyy').format(_dueDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        trailing: const Icon(Icons.calendar_month_rounded, color: primaryColor),
                        onTap: () async {
                          final p = await showDatePicker(context: context, initialDate: _dueDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                          if (p != null) setState(() => _dueDate = p);
                        },
                      ),
                    ]),

                    const SizedBox(height: 32),
                    // Tổng tiền nổi bật
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TỔNG CỘNG', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B7280), fontSize: 13)),
                          Text(_fmt.format(_totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 22)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('LƯU HÓA ĐƠN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280), letterSpacing: 0.5)),
  );

  Widget _card(List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF3F4F6)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
    ),
    child: Column(children: children),
  );

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.2)),
  );
}
