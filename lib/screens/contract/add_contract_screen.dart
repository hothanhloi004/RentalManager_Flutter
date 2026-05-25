import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/contract_model.dart';
import '../../models/room_model.dart';
import '../../models/tenant_model.dart';
import '../../services/firebase_service.dart';
import '../../utils/price_input_formatter.dart';

class AddContractScreen extends StatefulWidget {
  final String? roomId;

  const AddContractScreen({super.key, this.roomId});

  @override
  State<AddContractScreen> createState() => _AddContractScreenState();
}

class _AddContractScreenState extends State<AddContractScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirebaseService();
  final _rentPriceCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _lastElecCtrl = TextEditingController(text: '0');
  final _lastWaterCtrl = TextEditingController(text: '0');

  bool _isLoading = false;
  bool _useWifi = true;
  bool _useTrash = true;
  bool _useServiceFee = true;
  bool _loadingMeter = false;
  DateTime _startDate = DateTime.now();

  Room? _selectedRoom;
  Tenant? _selectedTenant;
  List<Room> _rooms = [];
  List<Tenant> _tenants = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _rentPriceCtrl.dispose();
    _depositCtrl.dispose();
    _lastElecCtrl.dispose();
    _lastWaterCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final rooms = await _service.getRooms().first;
      final tenants = await _service.getTenants().first;
      final contracts = await _service.getContracts().first;
      final busyTenantIds = contracts.where((c) => c.isActive).map((c) => c.tenantId).toSet();

      if (!mounted) return;
      setState(() {
        _rooms = rooms.where((r) => r.isEmpty || r.id == widget.roomId || r.roomKey == widget.roomId).toList();
        _tenants = tenants.where((t) => !busyTenantIds.contains(t.id) && !busyTenantIds.contains(t.tenantKey)).toList();

        if (widget.roomId != null) {
          _selectedRoom = _rooms.where((r) => r.id == widget.roomId || r.roomKey == widget.roomId).firstOrNull;
          if (_selectedRoom != null) {
            _rentPriceCtrl.text = PriceInputFormatter.format(_selectedRoom!.price);
          }
        }
      });
      if (_selectedRoom != null) {
        _loadLastMeterForRoom(_selectedRoom!);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  void _selectRoom(Room? room) {
    setState(() {
      _selectedRoom = room;
      if (room != null) {
        _rentPriceCtrl.text = PriceInputFormatter.format(room.price);
      }
      _lastElecCtrl.text = '0';
      _lastWaterCtrl.text = '0';
    });
    if (room != null) _loadLastMeterForRoom(room);
  }

  Future<void> _loadLastMeterForRoom(Room room) async {
    final roomKey = room.roomKey;
    setState(() => _loadingMeter = true);
    try {
      final meter = await _service.getLastMeterForRoom(roomKey);
      if (!mounted || _selectedRoom?.roomKey != roomKey) return;
      setState(() {
        _lastElecCtrl.text = meter.electric.toString();
        _lastWaterCtrl.text = meter.water.toString();
      });
    } finally {
      if (mounted && _selectedRoom?.roomKey == roomKey) {
        setState(() => _loadingMeter = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedRoom == null || _selectedTenant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn đầy đủ phòng và khách thuê'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final contract = Contract(
        id: '',
        roomId: _selectedRoom!.roomKey,
        tenantId: _selectedTenant!.tenantKey,
        rentPrice: PriceInputFormatter.parse(_rentPriceCtrl.text, fallback: _selectedRoom!.price),
        deposit: PriceInputFormatter.parse(_depositCtrl.text),
        startDate: _startDate.millisecondsSinceEpoch,
        status: 'HIEU_LUC',
        useWifi: _useWifi,
        useTrash: _useTrash,
        useServiceFee: _useServiceFee,
        lastElectric: int.tryParse(_lastElecCtrl.text) ?? 0,
        lastWater: int.tryParse(_lastWaterCtrl.text) ?? 0,
      );
      await _service.addContract(contract);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6366F1);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: primaryColor,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _sectionCard([
                        DropdownButtonFormField<Room>(
                          value: _selectedRoom,
                          decoration: _inputDeco('Chọn phòng đang trống'),
                          items: _rooms.map((r) => DropdownMenuItem(value: r, child: Text(r.roomName))).toList(),
                          onChanged: _selectRoom,
                          validator: (v) => v == null ? 'Vui lòng chọn phòng' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _rentPriceCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [VndInputFormatter()],
                          decoration: _inputDeco('Giá thuê phòng (VNĐ/tháng)'),
                          validator: (v) => PriceInputFormatter.parse(v ?? '') <= 0 ? 'Vui lòng nhập giá thuê' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<Tenant>(
                          value: _selectedTenant,
                          decoration: _inputDeco('Chọn khách hàng thuê'),
                          items: _tenants.map((t) => DropdownMenuItem(value: t, child: Text(t.fullName))).toList(),
                          onChanged: (t) => setState(() => _selectedTenant = t),
                          validator: (v) => v == null ? 'Vui lòng chọn khách thuê' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _depositCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [VndInputFormatter()],
                          decoration: _inputDeco('Tiền đặt cọc (VNĐ)'),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _sectionTitle('CHỈ SỐ ĐẦU KỲ'),
                      if (_loadingMeter)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: LinearProgressIndicator(minHeight: 2, color: Color(0xFF6366F1)),
                        ),
                      _sectionCard([
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _lastElecCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _inputDeco('Số điện đầu'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _lastWaterCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _inputDeco('Số nước đầu'),
                              ),
                            ),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _sectionTitle('DỊCH VỤ SỬ DỤNG'),
                      _sectionCard([
                        _checkItem('Sử dụng WiFi', _useWifi, (v) => setState(() => _useWifi = v ?? false)),
                        _checkItem('Thu tiền rác hàng tháng', _useTrash, (v) => setState(() => _useTrash = v ?? false)),
                        _checkItem('Phí dịch vụ khác', _useServiceFee, (v) => setState(() => _useServiceFee = v ?? false)),
                      ]),
                      const SizedBox(height: 16),
                      _sectionTitle('NGÀY BẮT ĐẦU'),
                      _sectionCard([
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(DateFormat('dd/MM/yyyy').format(_startDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.calendar_month_rounded, color: primaryColor),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null && mounted) setState(() => _startDate = picked);
                          },
                        ),
                      ]),
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
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('TẠO HỢP ĐỒNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 20, 18),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 2),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thêm hợp đồng',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Điền thông tin hợp đồng mới',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6366F1), letterSpacing: 0.5),
        ),
      );

  Widget _sectionCard(List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(children: children),
      );

  Widget _checkItem(String title, bool value, ValueChanged<bool?> onChanged) => CheckboxListTile(
        value: value,
        title: Text(title, style: const TextStyle(fontSize: 14)),
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        activeColor: const Color(0xFF6366F1),
        dense: true,
        visualDensity: VisualDensity.compact,
      );

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );
}
