import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/bill_model.dart';
import '../models/room_model.dart';
import '../models/tenant_model.dart';
import 'package:intl/intl.dart';

class InvoicePdfHelper {
  static Future<void> generateAndShare(Bill bill, Room room, Tenant tenant) async {
    final pdf = pw.Document();
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

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

