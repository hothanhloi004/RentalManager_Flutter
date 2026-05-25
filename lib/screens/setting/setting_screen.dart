import 'package:flutter/material.dart';
import '../../models/setting_model.dart';
import '../../services/firebase_service.dart';
import '../../utils/price_input_formatter.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});
  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final _service = FirebaseService();
  bool _isLoading = true;
  bool _pinEnabled = false;

  late TextEditingController _hostelNameCtrl, _landlordNameCtrl, _landlordPhoneCtrl, _hostelAddressCtrl;
  late TextEditingController _electricPriceCtrl, _waterPriceCtrl, _trashFeeCtrl, _wifiFeeCtrl, _serviceFeeCtrl;
  late TextEditingController _pinCtrl;
  late TextEditingController _bankCodeCtrl, _bankAccountCtrl;

  @override
  void initState() {
    super.initState();
    _hostelNameCtrl = TextEditingController();
    _landlordNameCtrl = TextEditingController();
    _landlordPhoneCtrl = TextEditingController();
    _hostelAddressCtrl = TextEditingController();
    _electricPriceCtrl = TextEditingController();
    _waterPriceCtrl = TextEditingController();
    _trashFeeCtrl = TextEditingController();
    _wifiFeeCtrl = TextEditingController();
    _serviceFeeCtrl = TextEditingController();
    _pinCtrl = TextEditingController();
    _bankCodeCtrl = TextEditingController();
    _bankAccountCtrl = TextEditingController();
    _applyToForm(Setting()); // mặc định giống Android trước khi tải Cloud
    _loadSettings();
  }

  void _applyToForm(Setting s) {
    _hostelNameCtrl.text = s.hostelName;
    _landlordNameCtrl.text = s.landlordName;
    _landlordPhoneCtrl.text = s.landlordPhone;
    _hostelAddressCtrl.text = s.hostelAddress;
    _electricPriceCtrl.text = PriceInputFormatter.format(s.electricPrice);
    _waterPriceCtrl.text = PriceInputFormatter.format(s.waterPrice);
    _trashFeeCtrl.text = PriceInputFormatter.format(s.trashFee);
    _wifiFeeCtrl.text = PriceInputFormatter.format(s.wifiPrice);
    _serviceFeeCtrl.text = PriceInputFormatter.format(s.serviceFee);
    _pinCtrl.text = s.pinCode ?? '';
    _pinEnabled = s.pinEnabled;
    _bankCodeCtrl.text = s.bankCode.isNotEmpty ? s.bankCode : 'MB';
    _bankAccountCtrl.text = s.bankAccount;
  }

  Future<void> _loadSettings() async {
    try {
      final s = await _service.getSettings();
      if (!mounted) return;
      _applyToForm(s);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được cài đặt Cloud: $e'), backgroundColor: Colors.orange),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final pin = _pinCtrl.text.trim();
    if (_pinEnabled && !RegExp(r'^\d{6}$').hasMatch(pin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mã PIN phải gồm đúng 6 chữ số'), backgroundColor: Colors.orange),
      );
      return;
    }
    final setting = Setting(
      hostelName: _hostelNameCtrl.text.trim(),
      landlordName: _landlordNameCtrl.text.trim(),
      landlordPhone: _landlordPhoneCtrl.text.trim(),
      hostelAddress: _hostelAddressCtrl.text.trim(),
      electricPrice: PriceInputFormatter.parse(_electricPriceCtrl.text, fallback: 3500),
      waterPrice: PriceInputFormatter.parse(_waterPriceCtrl.text, fallback: 20000),
      trashFee: PriceInputFormatter.parse(_trashFeeCtrl.text, fallback: 30000),
      wifiPrice: PriceInputFormatter.parse(_wifiFeeCtrl.text),
      serviceFee: PriceInputFormatter.parse(_serviceFeeCtrl.text),
      pinEnabled: _pinEnabled,
      pinCode: _pinEnabled ? pin : '',
      bankCode: _bankCodeCtrl.text.trim(),
      bankAccount: _bankAccountCtrl.text.trim(),
    );
    try {
      await _service.saveSettings(setting);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu cài đặt'), backgroundColor: Color(0xFF4CAF50)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _hostelNameCtrl.dispose(); _landlordNameCtrl.dispose(); _landlordPhoneCtrl.dispose(); _hostelAddressCtrl.dispose();
    _electricPriceCtrl.dispose(); _waterPriceCtrl.dispose(); _trashFeeCtrl.dispose(); _wifiFeeCtrl.dispose(); _serviceFeeCtrl.dispose();
    _pinCtrl.dispose(); _bankCodeCtrl.dispose(); _bankAccountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6366F1);
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                // Header gradient giống Android
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(8, topInset + 10, 20, 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Cài đặt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 23, height: 1.1)),
                            SizedBox(height: 5),
                            Text('Thiết lập đơn giá và bảo mật', style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 13, height: 1.2)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Card 1: Thông tin chủ trọ
                        _settingCard('Thông tin Chủ trọ & Khu trọ', [
                          _field(_hostelNameCtrl, 'Tên Khu trọ (VD: Trọ Sinh Viên Hạnh Phúc)'),
                          _field(_landlordNameCtrl, 'Tên Chủ trọ'),
                          _field(_landlordPhoneCtrl, 'Số điện thoại Chủ trọ', type: TextInputType.phone),
                          _field(_hostelAddressCtrl, 'Địa chỉ khu trọ'),
                        ]),
                        const SizedBox(height: 12),

                        // Card 2: Đơn giá dịch vụ
                        _settingCard('Đơn giá dịch vụ', [
                          _field(_electricPriceCtrl, 'Giá điện (đ/kWh)', type: TextInputType.number, suffix: 'đ/kWh'),
                          _field(_waterPriceCtrl, 'Giá nước (đ/m³)', type: TextInputType.number, suffix: 'đ/m³'),
                          _field(_trashFeeCtrl, 'Phí rác (đ/tháng)', type: TextInputType.number, suffix: 'đ/tháng'),
                          _field(_wifiFeeCtrl, 'Phí WiFi (đ/tháng)', type: TextInputType.number, suffix: 'đ/tháng'),
                          _field(_serviceFeeCtrl, 'Phí dịch vụ khác (đ/tháng)', type: TextInputType.number, suffix: 'đ/tháng'),
                        ]),
                        const SizedBox(height: 12),

                        // Card 3: Bảo mật
                        _settingCard('Bảo mật', [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Bật khóa màn hình PIN', style: TextStyle(fontSize: 15)),
                              Switch(value: _pinEnabled, onChanged: (v) => setState(() => _pinEnabled = v), activeColor: primaryColor),
                            ],
                          ),
                          if (_pinEnabled) _field(_pinCtrl, 'Mã PIN (6 chữ số)', type: TextInputType.number, obscure: true),
                        ]),
                        const SizedBox(height: 12),

                        // Card 4: VietQR
                        _settingCard('Tài khoản VietQR', [
                          _field(_bankCodeCtrl, 'Mã ngân hàng (VD: MB, VCB, TCB...)'),
                          _field(_bankAccountCtrl, 'Số tài khoản', type: TextInputType.number),
                        ]),
                        const SizedBox(height: 16),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Lưu cài đặt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _settingCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {TextInputType type = TextInputType.text, String? suffix, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        obscureText: obscure,
        inputFormatters: suffix != null ? [VndInputFormatter()] : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          suffixText: suffix,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
