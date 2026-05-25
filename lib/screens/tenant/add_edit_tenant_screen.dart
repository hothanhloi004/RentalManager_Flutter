import 'package:flutter/material.dart';
import '../../models/tenant_model.dart';
import '../../services/firebase_service.dart';

class AddEditTenantScreen extends StatefulWidget {
  final Tenant? tenant;
  const AddEditTenantScreen({super.key, this.tenant});
  @override
  State<AddEditTenantScreen> createState() => _AddEditTenantScreenState();
}

class _AddEditTenantScreenState extends State<AddEditTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl, _phoneCtrl, _cccdCtrl, _addressCtrl;
  final _service = FirebaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final t = widget.tenant;
    _nameCtrl = TextEditingController(text: t?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: t?.phone ?? '');
    _cccdCtrl = TextEditingController(text: t?.cccd ?? '');
    _addressCtrl = TextEditingController(text: t?.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _cccdCtrl.dispose(); _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final tenant = Tenant(
        id: widget.tenant?.id ?? '',
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        cccd: _cccdCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        moveInDate: widget.tenant?.moveInDate ?? 0,
        deposit: widget.tenant?.deposit ?? 0,
        roomId: widget.tenant?.roomId ?? '',
        imageUrls: widget.tenant?.imageUrls ?? [],
      );
      if (widget.tenant == null) {
        await _service.addTenant(tenant);
      } else {
        await _service.updateTenant(tenant);
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
    final isEdit = widget.tenant != null;
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
                isEdit ? 'Chỉnh sửa người thuê' : 'Thêm người thuê',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 16),
              _buildField(_nameCtrl, 'Họ và tên', TextInputType.text, true),
              const SizedBox(height: 12),
              _buildField(_phoneCtrl, 'Số điện thoại', TextInputType.phone, true),
              const SizedBox(height: 12),
              _buildField(_cccdCtrl, 'Số CCCD', TextInputType.number, false),
              const SizedBox(height: 12),
              _buildField(_addressCtrl, 'Địa chỉ thường trú', TextInputType.text, false),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('HỦY', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor))
                        : const Text('LƯU', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, TextInputType type, bool required) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: required ? (v) => v!.isEmpty ? 'Không được bỏ trống' : null : null,
    );
  }
}
