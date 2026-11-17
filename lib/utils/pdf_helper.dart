import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/asset_model.dart';
import '../models/bill_model.dart';
import '../models/contract_model.dart';
import '../models/room_model.dart';
import '../models/setting_model.dart';
import '../models/tenant_model.dart';
import 'package:intl/intl.dart';

class InvoicePdfHelper {
  static Future<void> generateAndShare(Bill bill, Room room, Tenant tenant, {double? paidAmount}) async {
    final pdf = pw.Document();
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final actualPaid = bill.isPaid ? bill.totalAmount : (paidAmount ?? 0);
    final debt = (bill.totalAmount - actualPaid).clamp(0, double.infinity);

    final ttf = await PdfGoogleFonts.robotoRegular();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('BIÊN LAI THU TIỀN TRỌ', style: pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Center(child: pw.Text('Tháng: ${bill.month}', style: pw.TextStyle(font: ttf))),
                pw.Divider(),
                pw.SizedBox(height: 10),
                _pdfRow(ttf, 'Khách thuê:', tenant.fullName),
                _pdfRow(ttf, 'Phòng:', room.roomName),
                pw.SizedBox(height: 10),
                pw.Text('Chi tiết thanh toán:', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
                _pdfRow(ttf, '- Tiền phòng:', fmt.format(bill.rentPrice)),
                _pdfRow(ttf, '- Tiền điện:', fmt.format(bill.effectiveElectricUsed * bill.electricPrice)),
                _pdfRow(ttf, '- Tiền nước:', fmt.format(bill.effectiveWaterUsed * bill.waterPrice)),
                if (bill.serviceFee > 0) _pdfRow(ttf, '- Dịch vụ khác:', fmt.format(bill.serviceFee)),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TỔNG CỘNG:', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
                    pw.Text(fmt.format(bill.totalAmount), style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  ],
                ),
                pw.SizedBox(height: 4),
                _pdfRow(ttf, 'Đã thanh toán:', fmt.format(actualPaid)),
                _pdfRow(ttf, 'Còn nợ:', fmt.format(debt)),
                pw.SizedBox(height: 30),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Người nộp tiền', style: pw.TextStyle(font: ttf, fontStyle: pw.FontStyle.italic)),
                    pw.Text('Người thu tiền', style: pw.TextStyle(font: ttf, fontStyle: pw.FontStyle.italic)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'HoaDon_${room.roomName}_${bill.month}.pdf');
  }

  static Future<void> generateContractPdf({
    required Contract contract,
    required Room room,
    required Tenant tenant,
    required Setting setting,
    List<Asset> assets = const [],
  }) async {
    final pdf = pw.Document();
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFmt = DateFormat('dd/MM/yyyy');
    final ttf = await PdfGoogleFonts.robotoRegular();
    final ttfBold = await PdfGoogleFonts.robotoBold();
    final ttfItalic = await PdfGoogleFonts.robotoItalic();

    final startStr = contract.startDate > 0
        ? dateFmt.format(DateTime.fromMillisecondsSinceEpoch(contract.startDate))
        : dateFmt.format(DateTime.now());
    final landlordName = setting.landlordName.trim().isNotEmpty ? setting.landlordName.trim() : 'Chủ nhà trọ';
    final landlordPhone = setting.landlordPhone.trim().isNotEmpty ? setting.landlordPhone.trim() : '....................';
    final hostelName = setting.hostelName.trim().isNotEmpty ? setting.hostelName.trim() : 'Khu nhà trọ';
    final hostelAddress = setting.hostelAddress.trim().isNotEmpty ? setting.hostelAddress.trim() : '........................................................';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
        build: (pw.Context context) => [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text('CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM', style: pw.TextStyle(font: ttfBold, fontSize: 12)),
                pw.SizedBox(height: 2),
                pw.Text('Độc lập - Tự do - Hạnh phúc', style: pw.TextStyle(font: ttfBold, fontSize: 11)),
                pw.SizedBox(height: 4),
                pw.Container(width: 120, height: 1, color: PdfColors.black),
                pw.SizedBox(height: 14),
                pw.Text('HỢP ĐỒNG THUÊ PHÒNG TRỌ', style: pw.TextStyle(font: ttfBold, fontSize: 16)),
                pw.SizedBox(height: 4),
                pw.Text('($hostelName - Phòng: ${room.roomName})', style: pw.TextStyle(font: ttfItalic, fontSize: 11)),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text('Hôm nay, ngày ${dateFmt.format(DateTime.now())}, tại địa chỉ: $hostelAddress, chúng tôi gồm có:', style: pw.TextStyle(font: ttf, fontSize: 10.5)),
          pw.SizedBox(height: 10),
          pw.Text('I. BÊN CHO THUÊ PHÒNG TRỌ (BÊN A):', style: pw.TextStyle(font: ttfBold, fontSize: 11)),
          pw.SizedBox(height: 4),
          _pdfBullet(ttf, 'Họ và tên chủ trọ: $landlordName'),
          _pdfBullet(ttf, 'Số điện thoại liên hệ: $landlordPhone'),
          _pdfBullet(ttf, 'Địa chỉ khu trọ: $hostelAddress'),
          pw.SizedBox(height: 8),
          pw.Text('II. BÊN THUÊ PHÒNG TRỌ (BÊN B):', style: pw.TextStyle(font: ttfBold, fontSize: 11)),
          pw.SizedBox(height: 4),
          _pdfBullet(ttf, 'Họ và tên khách thuê: ${tenant.fullName.isNotEmpty ? tenant.fullName : "................................"}'),
          _pdfBullet(ttf, 'Số điện thoại: ${tenant.phone.isNotEmpty ? tenant.phone : "................................"}'),
          _pdfBullet(ttf, 'Số CCCD/CMND: ${tenant.cccd.isNotEmpty ? tenant.cccd : "................................"}'),
          _pdfBullet(ttf, 'Địa chỉ thường trú: ${tenant.address.isNotEmpty ? tenant.address : "........................................................"}'),
          pw.SizedBox(height: 10),
          pw.Text('III. NỘI DUNG HỢP ĐỒNG & GIÁ CẢ DỊCH VỤ:', style: pw.TextStyle(font: ttfBold, fontSize: 11)),
          pw.SizedBox(height: 4),
          _pdfBullet(ttf, 'Bên A đồng ý cho Bên B thuê phòng số: ${room.roomName}${room.area > 0 ? " (Diện tích: ${room.area} m²)" : ""}.'),
          _pdfBullet(ttf, 'Ngày bắt đầu tính tiền thuê: $startStr.'),
          _pdfBullet(ttf, 'Giá thuê phòng hàng tháng: ${fmt.format(contract.rentPrice)} / tháng.'),
          _pdfBullet(ttf, 'Tiền đặt cọc giữ phòng: ${fmt.format(contract.deposit)}.'),
          _pdfBullet(ttf, 'Đơn giá điện: ${fmt.format(setting.electricPrice)} / kWh (Chỉ số điện bàn giao đầu kỳ: ${contract.lastElectric} kWh).'),
          _pdfBullet(ttf, 'Đơn giá nước: ${fmt.format(setting.waterPrice)} / m³ (Chỉ số nước bàn giao đầu kỳ: ${contract.lastWater} m³).'),
          if (contract.useWifi) _pdfBullet(ttf, 'Phí Wi-Fi: ${fmt.format(setting.wifiPrice)} / tháng.'),
          if (contract.useTrash) _pdfBullet(ttf, 'Phí vệ sinh / rác: ${fmt.format(setting.trashFee)} / tháng.'),
          if (contract.useServiceFee) _pdfBullet(ttf, 'Phí dịch vụ chung: ${fmt.format(setting.serviceFee)} / tháng.'),
          if (assets.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text('IV. BIÊN BẢN BÀN GIAO TÀI SẢN & THIẾT BỊ TRONG PHÒNG:', style: pw.TextStyle(font: ttfBold, fontSize: 11)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: ['STT', 'Tên tài sản / Thiết bị', 'Số lượng', 'Tình trạng / Ghi chú'],
              data: [
                for (var i = 0; i < assets.length; i++)
                  [
                    '${i + 1}',
                    assets[i].name,
                    '${assets[i].quantity}',
                    assets[i].note.isNotEmpty ? assets[i].note : 'Hoạt động tốt',
                  ],
              ],
              headerStyle: pw.TextStyle(font: ttfBold, fontSize: 9.5),
              cellStyle: pw.TextStyle(font: ttf, fontSize: 9.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            ),
          ],
          pw.SizedBox(height: 10),
          pw.Text('ĐIỀU KHOẢN CHUNG:', style: pw.TextStyle(font: ttfBold, fontSize: 11)),
          pw.SizedBox(height: 4),
          _pdfBullet(ttf, '1. Bên B thanh toán đầy đủ tiền thuê phòng và điện nước đúng hạn hàng tháng.'),
          _pdfBullet(ttf, '2. Bên B có trách nhiệm giữ gìn tài sản trong phòng, chấp hành quy định an ninh trật tự, PCCC và khai báo tạm trú theo quy định.'),
          _pdfBullet(ttf, '3. Khi muốn chấm dứt hợp đồng, mỗi bên cần thông báo trước ít nhất 15 - 30 ngày. Bên A hoàn trả tiền cọc sau khi đối chiếu công nợ và hiện trạng phòng.'),
          pw.SizedBox(height: 24),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Column(
                children: [
                  pw.Text('ĐẠI DIỆN BÊN B (KHÁCH THUÊ)', style: pw.TextStyle(font: ttfBold, fontSize: 10.5)),
                  pw.Text('(Ký và ghi rõ họ tên)', style: pw.TextStyle(font: ttfItalic, fontSize: 9.5)),
                  pw.SizedBox(height: 48),
                  pw.Text(tenant.fullName, style: pw.TextStyle(font: ttfBold, fontSize: 10.5)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('ĐẠI DIỆN BÊN A (CHỦ TRỌ)', style: pw.TextStyle(font: ttfBold, fontSize: 10.5)),
                  pw.Text('(Ký và ghi rõ họ tên)', style: pw.TextStyle(font: ttfItalic, fontSize: 9.5)),
                  pw.SizedBox(height: 48),
                  pw.Text(landlordName, style: pw.TextStyle(font: ttfBold, fontSize: 10.5)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'HopDong_${room.roomName}_${tenant.fullName}.pdf',
    );
  }

  static pw.Widget _pdfBullet(pw.Font font, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Text('- $text', style: pw.TextStyle(font: font, fontSize: 10.5, lineSpacing: 1.5)),
    );
  }

  static pw.Widget _pdfRow(pw.Font font, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font)),
          pw.Text(value, style: pw.TextStyle(font: font)),
        ],
      ),
    );
  }
}

