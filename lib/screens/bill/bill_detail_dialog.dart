import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/bill_model.dart';
import '../../models/room_model.dart';
import '../../models/setting_model.dart';
import '../../models/tenant_model.dart';
import '../../services/firebase_service.dart';
import '../../utils/pdf_helper.dart';

class BillDetailDialog extends StatefulWidget {
  final Bill bill;
  final Room room;
  final Tenant tenant;
  final double paidAmount;
  const BillDetailDialog({
    super.key,
    required this.bill,
    required this.room,
    required this.tenant,
    this.paidAmount = 0,
  });
  @override
  State<BillDetailDialog> createState() => _BillDetailDialogState();
}

class _BillDetailDialogState extends State<BillDetailDialog> {
  final _service = FirebaseService();
  late final Future<Setting> _settingFuture = _service.getSettings();
  bool _showQR = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.bill;
    const primaryColor = Color(0xFF6366F1);
    const textColor = Color(0xFF111827);
    const mutedText = Color(0xFF64748B);
    final electricUsed = b.effectiveElectricUsed;
    final waterUsed = b.effectiveWaterUsed;
    final electricAmount = electricUsed * b.electricPrice;
    final waterAmount = waterUsed * b.waterPrice;
    final paidAmount = b.isPaid ? b.totalAmount : widget.paidAmount;
    final debtAmount = (b.totalAmount - paidAmount).clamp(0, double.infinity);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chi tiết hóa đơn ${b.month}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 8),
            _detailItem(
              'Nước',
              'Chỉ số cũ: ${b.oldWater}\nChỉ số mới: ${b.newWater}\nTiêu thụ: $waterUsed x ${_money(b.waterPrice)} = ${_money(waterAmount)}',
              const Color(0xFFE0F2F1),
              const Color(0xFF00897B),
            ),
            if (electricAmount > 0)
              _detailItem(
                'Điện',
                'Chỉ số cũ: ${b.oldElectric}\nChỉ số mới: ${b.newElectric}\nTiêu thụ: $electricUsed x ${_money(b.electricPrice)} = ${_money(electricAmount)}',
                const Color(0xFFFFF7E6),
                const Color(0xFFF57C00),
              ),
            _detailItem('Tiền phòng', _money(b.rentPrice), const Color(0xFFF0EEFF), primaryColor),
            _detailItem('Phí dịch vụ', _money(b.serviceFee), const Color(0xFFF1F5F9), const Color(0xFF475569)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng cộng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
                Text(_money(b.totalAmount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: primaryColor)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Đã trả', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                Text(_money(paidAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Còn nợ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                Text(_money(debtAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => setState(() => _showQR = !_showQR),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 34),
                foregroundColor: primaryColor,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                shape: const StadiumBorder(),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              child: Text(_showQR ? 'Ẩn mã QR' : 'Tạo mã QR'),
            ),
            if (_showQR) ...[
              const SizedBox(height: 10),
              FutureBuilder<Setting>(
                future: _settingFuture,
                builder: (context, snapshot) {
                  final setting = snapshot.data ?? Setting();
                  if (!snapshot.hasData) {
                    return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: primaryColor)));
                  }
                  if (setting.bankAccount.trim().isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Chưa có số tài khoản VietQR trong Cài đặt.', style: TextStyle(fontSize: 12, color: mutedText)),
                    );
                  }
                  final bankId = _vietQrBankId(setting.bankCode);
                  final addInfo = Uri.encodeComponent('Thanh toan ${widget.room.roomName} ${b.month}');
                  final accountName = Uri.encodeComponent(setting.landlordName.isNotEmpty ? setting.landlordName : 'CHU TRO');
                  final qrAmount = debtAmount > 0 ? debtAmount : b.totalAmount;
                  final url =
                      'https://img.vietqr.io/image/$bankId-${setting.bankAccount.trim()}-compact2.jpg?amount=${qrAmount.round()}&addInfo=$addInfo&accountName=$accountName';
                  return Column(
                    children: [
                      Center(
                        child: Image.network(
                          url,
                          height: 190,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('Không tải được mã QR. Kiểm tra mã ngân hàng và số tài khoản.', textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Center(child: Text('Quét mã bằng app ngân hàng để thanh toán', style: TextStyle(fontSize: 10.5, color: mutedText))),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _sendZaloReminder(b, paidAmount, debtAmount),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 36),
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 0,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: const Text('Nhắc nợ Zalo (Tự chép nội dung HĐ)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => InvoicePdfHelper.generateAndShare(b, widget.room, widget.tenant, paidAmount: paidAmount),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 36),
                foregroundColor: primaryColor,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                shape: const StadiumBorder(),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
              label: const Text('Xuất PDF / Chia sẻ hóa đơn'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendZaloReminder(Bill b, double paidAmount, double debtAmount) async {
    final setting = await _settingFuture;
    final electricUsed = b.effectiveElectricUsed;
    final waterUsed = b.effectiveWaterUsed;
    final electricAmount = electricUsed * b.electricPrice;
    final waterAmount = waterUsed * b.waterPrice;

    final buffer = StringBuffer()
      ..writeln('📋 THÔNG BÁO TIỀN PHÒNG THÁNG ${b.month}')
      ..writeln('Phòng: ${widget.room.roomName}')
      ..writeln('Khách thuê: ${widget.tenant.fullName}')
      ..writeln('--------------------------')
      ..writeln('• Tiền phòng: ${_money(b.rentPrice)}')
      ..writeln('• Điện: ${b.oldElectric} -> ${b.newElectric} ($electricUsed kWh) = ${_money(electricAmount)}')
      ..writeln('• Nước: ${b.oldWater} -> ${b.newWater} ($waterUsed khối) = ${_money(waterAmount)}');
    if (b.serviceFee > 0) {
      buffer.writeln('• Phí dịch vụ: ${_money(b.serviceFee)}');
    }
    buffer
      ..writeln('--------------------------')
      ..writeln('💰 TỔNG CỘNG: ${_money(b.totalAmount)}');
    if (paidAmount > 0) {
      buffer.writeln('✅ Đã thanh toán: ${_money(paidAmount)}');
    }
    buffer.writeln('❗ CÒN CẦN THANH TOÁN: ${_money(debtAmount)}');
    if (setting.bankAccount.trim().isNotEmpty) {
      buffer
        ..writeln('--------------------------')
        ..writeln('🏦 Chuyển khoản: ${setting.bankCode.toUpperCase()} - ${setting.bankAccount.trim()}')
        ..writeln('Chủ TK: ${setting.landlordName.isNotEmpty ? setting.landlordName : "Chủ nhà"}')
        ..writeln('Nội dung: Thanh toan ${widget.room.roomName} ${b.month}');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép chi tiết hóa đơn vào bộ nhớ tạm! Chỉ cần Dán (Paste) vào Zalo.'),
        backgroundColor: Color(0xFF0284C7),
      ),
    );

    final digits = widget.tenant.phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isNotEmpty) {
      final zaloPhone = digits.startsWith('84') ? '0${digits.substring(2)}' : digits;
      final uri = Uri.parse('https://zalo.me/$zaloPhone');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _detailItem(String title, String desc, Color bg, Color textColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: textColor)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.25)),
        ],
      ),
    );
  }

  static String _money(num value) {
    return '${NumberFormat.decimalPattern('vi_VN').format(value.round())} đ';
  }

  static String _vietQrBankId(String code) {
    final normalized = code.trim().toUpperCase();
    if (RegExp(r'^\d+$').hasMatch(normalized)) return normalized;
    const banks = {
      'MB': '970422',
      'MBBANK': '970422',
      'VCB': '970436',
      'VIETCOMBANK': '970436',
      'TCB': '970407',
      'TECHCOMBANK': '970407',
      'BIDV': '970418',
      'CTG': '970415',
      'VIETINBANK': '970415',
      'ACB': '970416',
      'VPB': '970432',
      'VPBANK': '970432',
      'VIB': '970441',
      'TPB': '970423',
      'TPBANK': '970423',
      'STB': '970403',
      'SACOMBANK': '970403',
      'HDB': '970437',
      'HDBANK': '970437',
      'OCB': '970448',
    };
    return banks[normalized] ?? normalized;
  }
}
