import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final electricAmount = b.electricUsed * b.electricPrice;
    final waterAmount = b.waterUsed * b.waterPrice;
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
              'Chỉ số cũ: ${b.oldWater}\nChỉ số mới: ${b.newWater}\nTiêu thụ: ${b.waterUsed} x ${_money(b.waterPrice)} = ${_money(waterAmount)}',
              const Color(0xFFE0F2F1),
              const Color(0xFF00897B),
            ),
            if (electricAmount > 0)
              _detailItem(
                'Điện',
                'Chỉ số cũ: ${b.oldElectric}\nChỉ số mới: ${b.newElectric}\nTiêu thụ: ${b.electricUsed} x ${_money(b.electricPrice)} = ${_money(electricAmount)}',
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
              child: Text(_showQR ? 'Ẩn mã QR' : 'Tạo mã QR'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 34),
                foregroundColor: primaryColor,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                shape: const StadiumBorder(),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
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
                          errorBuilder: (_, __, ___) => const Padding(
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
            OutlinedButton(
              onPressed: () => InvoicePdfHelper.generateAndShare(b, widget.room, widget.tenant),
              child: const Text('Xuất PDF / Chia sẻ hóa đơn'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 34),
                foregroundColor: primaryColor,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                shape: const StadiumBorder(),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => InvoicePdfHelper.generateAndShare(b, widget.room, widget.tenant),
              style: TextButton.styleFrom(foregroundColor: primaryColor, padding: EdgeInsets.zero),
              child: const Text('Chia sẻ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
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
