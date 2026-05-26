import 'package:flutter/material.dart';
import '../../models/room_model.dart';
import '../../services/firebase_service.dart';
import '../../utils/price_input_formatter.dart';

class AddEditRoomScreen extends StatefulWidget {
  final Room? room;
  const AddEditRoomScreen({super.key, this.room});
  @override
  State<AddEditRoomScreen> createState() => _AddEditRoomScreenState();
}

class _AddEditRoomScreenState extends State<AddEditRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl, _priceCtrl, _noteCtrl;
  final _service = FirebaseService();
  bool _isLoading = false;
  late String _status;

  @override
  void initState() {
    super.initState();
    final r = widget.room;
    _nameCtrl = TextEditingController(text: r?.roomName ?? '');
    _priceCtrl = TextEditingController(text: r != null ? PriceInputFormatter.format(r.price) : '');
    _noteCtrl = TextEditingController(text: r?.note ?? '');
    _status = r?.status ?? 'TRONG';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (widget.room != null && _status != 'DANG_THUE') {
        final hasActiveContract = await _service.roomHasActiveContract(widget.room!.roomKey);
        if (hasActiveContract) {
          throw Exception('Phòng đang có hợp đồng hiệu lực, không thể đổi sang Trống/Bảo trì.');
        }
      }

      final room = Room(
        id: widget.room?.id ?? '',
        roomName: _nameCtrl.text.trim(),
        price: PriceInputFormatter.parse(_priceCtrl.text),
        status: _status,
        note: _noteCtrl.text.trim(),
        floor: widget.room?.floor ?? 0,
        area: widget.room?.area ?? 0,
        imageUrl: widget.room?.imageUrl ?? '',
        amenities: widget.room?.amenities ?? [],
        electricRate: widget.room?.electricRate ?? 0,
        waterRate: widget.room?.waterRate ?? 0,
      );
      if (widget.room == null) {
        await _service.addRoom(room);
      } else {
        await _service.updateRoom(room);
      }
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
    final isEdit = widget.room != null;
    const primaryColor = Color(0xFF6366F1);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Chỉnh sửa phòng' : 'Thêm phòng mới',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Tên phòng',
                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên phòng' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [VndInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Giá phòng (VNĐ/tháng)',
                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập giá phòng' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteCtrl,
                decoration: InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Trạng thái phòng',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statusChoice('TRONG', 'Trống', const Color(0xFFDCFCE7), const Color(0xFF166534)),
                  _statusChoice('DANG_THUE', 'Đang thuê', const Color(0xFFEDE9FE), primaryColor),
                  _statusChoice('BAO_TRI', 'Bảo trì', const Color(0xFFFEF3C7), const Color(0xFF92400E)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('HỦY', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor))
                        : const Text('LƯU', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChoice(String value, String label, Color selectedBg, Color selectedFg) {
    final selected = _status.trim().toUpperCase() == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _status = value),
      showCheckmark: false,
      backgroundColor: const Color(0xFFF9FAFB),
      selectedColor: selectedBg,
      side: BorderSide(color: selected ? selectedFg.withValues(alpha: 0.35) : const Color(0xFFE5E7EB)),
      labelStyle: TextStyle(
        color: selected ? selectedFg : const Color(0xFF4B5563),
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}
