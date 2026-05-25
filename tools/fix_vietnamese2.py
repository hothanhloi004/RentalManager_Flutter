# ASCII-only fix script
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib"

def u(*codes):
    return "".join(chr(c) for c in codes)

# Vietnamese strings
V = {
    "hoa_don": u(0x48, 0xF3, 0x61, 0x20, 0x111, 0x01A1, 0x6E),
    "tao_hang_loat": u(0x54, 0x1EA1, 0x6F, 0x20, 0x68, 0xE0, 0x6E, 0x67, 0x20, 0x6C, 0x1EE3, 0x74),
    "ghi_lo_chot": u(0x47, 0x68, 0x69, 0x20, 0x6C, 0x1EBB, 0x20, 0x2F, 0x20, 0x43, 0x68, 0x1ED1, 0x74),
    "tim_phong": u(0x54, 0xEC, 0x6D, 0x20, 0x74, 0x68, 0x65, 0x6F, 0x20, 0x70, 0xF2, 0x6E, 0x67, 0x20, 0x68, 0x1EB7, 0x63, 0x20, 0x74, 0x68, 0xE1, 0x6E, 0x67, 0x2E, 0x2E, 0x2E),
    "tat_ca": u(0x54, 0x1EA5, 0x74, 0x20, 0x63, 0x1EA3),
    "chua_chot": u(0x43, 0x68, 0x1B0, 0x61, 0x20, 0x63, 0x68, 0x1ED1, 0x74),
    "chua_tra": u(0x43, 0x68, 0x1B0, 0x61, 0x20, 0x74, 0x72, 0x1EA3),
    "da_tra": u(0x110, 0xE3, 0x20, 0x74, 0x72, 0x1EA3),
    "chua_co_hd": u(0x43, 0x68, 0x1B0, 0x61, 0x20, 0x63, 0xF3, 0x20, 0x68, 0xF3, 0x61, 0x20, 0x111, 0x01A1, 0x6E, 0x20, 0x6E, 0xE0, 0x6F),
    "thanh_cong": u(0x54, 0x68, 0xE0, 0x6E, 0x68, 0x20, 0x63, 0xF4, 0x6E, 0x67),
    "chua_thu": u(0x43, 0x68, 0x1B0, 0x61, 0x20, 0x74, 0x68, 0x75),
    "tong_cong": u(0x54, 0x1ED5, 0x6E, 0x67, 0x20, 0x63, 0x1ED9, 0x6E, 0x67),
    "han_thu": u(0x48, 0x1EA1, 0x6E, 0x20, 0x74, 0x68, 0x75),
    "da_thu": u(0x110, 0xE3, 0x20, 0x74, 0x68, 0x75),
    "thu_tien": u(0x54, 0x68, 0x75, 0x20, 0x74, 0x69, 0x1EC1, 0x6E),
    "chi_tiet": u(0x43, 0x68, 0x69, 0x20, 0x74, 0x69, 0x1EBF, 0x74),
    "phong_khong_ro": u(0x50, 0x68, 0xF2, 0x6E, 0x67, 0x20, 0x3F),
    "snack_tao": u(0x110, 0xE3, 0x20, 0x74, 0x1EA1, 0x6F, 0x20, 0x7B, 0x7D, 0x20, 0x68, 0xF3, 0x61, 0x20, 0x111, 0x01A1, 0x6E, 0x20, 0x6D, 0x1EDB, 0x69, 0x20, 0x63, 0x68, 0x6F, 0x20, 0x74, 0x68, 0xE1, 0x6E, 0x67, 0x20, 0x7B, 0x7D),
    "dang_co": u(0x110, 0xE0, 0x6E, 0x67, 0x20, 0x63, 0xF3, 0x20, 0x6E, 0x67, 0x1B0, 0x1EDD, 0x69, 0x20, 0x74, 0x68, 0xEA, 0x75, 0xEA),
    "chua_co_nt": u(0x43, 0x68, 0x1B0, 0x61, 0x20, 0x63, 0xF3, 0x20, 0x6E, 0x67, 0x1B0, 0x1EDD, 0x69, 0x20, 0x74, 0x68, 0xEA, 0x75, 0xEA),
    "dien_tich": u(0x50, 0x68, 0xF2, 0x6E, 0x67, 0x20, 0x64, 0x69, 0x1EC7, 0x6E, 0x20, 0x74, 0xED, 0x63, 0x68, 0x20, 0x7B, 0x7D, 0x20, 0x6D, 0xB2),
    "tao_hd": u(0x2B, 0x20, 0x54, 0x1EA1, 0x6F, 0x20, 0x68, 0x1EE3, 0x70, 0x20, 0x111, 0x1ED3, 0x6E, 0x67, 0x20, 0x63, 0x68, 0x6F, 0x20, 0x70, 0x68, 0xF2, 0x6E, 0x67, 0x20, 0x6E, 0xE0, 0x79),
    "trong": u(0x54, 0x72, 0x1ED1, 0x6E, 0x67),
    "bao_tri": u(0x42, 0x1EA3, 0x6F, 0x20, 0x74, 0x72, 0xEC),
    "dang_thue": u(0x110, 0xE0, 0x6E, 0x67, 0x20, 0x74, 0x68, 0xEA, 0x75, 0xEA),
}

snack = (
    u(0x110, 0xE3, 0x20, 0x74, 0x1EA1, 0x6F)
    + " $count "
    + u(0x68, 0xF3, 0x61, 0x20, 0x111, 0x01A1, 0x6E, 0x20, 0x6D, 0x1EDB, 0x69, 0x20, 0x63, 0x68, 0x6F, 0x20, 0x74, 0x68, 0xE1, 0x6E, 0x67, 0x20)
    + "$monthStr"
)

ROOM_DETAIL = f"""import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/room_model.dart';
import '../../services/firebase_service.dart';
import '../../widgets/room_photo_gallery.dart';
import '../contract/add_contract_screen.dart';
import 'add_edit_room_screen.dart';

class RoomDetailScreen extends StatefulWidget {{
  final Room room;
  const RoomDetailScreen({{super.key, required this.room}});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}}

class _RoomDetailScreenState extends State<RoomDetailScreen> {{
  final _service = FirebaseService();
  late Room _currentRoom;

  @override
  void initState() {{
    super.initState();
    _currentRoom = widget.room;
  }}

  void _editRoom() {{
    showDialog(
      context: context,
      builder: (ctx) => AddEditRoomScreen(room: _currentRoom),
    ).then((_) => _loadRoom());
  }}

  Future<void> _loadRoom() async {{
    final rooms = await _service.getRooms().first;
    final updated = rooms.where((r) => r.id == _currentRoom.id).firstOrNull;
    if (updated != null && mounted) {{
      setState(() => _currentRoom = updated);
    }}
  }}

  @override
  Widget build(BuildContext context) {{
    const primaryColor = Color(0xFF6366F1);
    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '\\u0111');
    final isRented = _currentRoom.isRented;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Xem chi ti\u1ebft', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: true,
        actions: [
          TextButton(
            onPressed: _editRoom,
            child: const Text('S\u1eeda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(color: const Color(0xFFF3F2FF), borderRadius: BorderRadius.circular(50)),
                child: const Icon(Icons.home_rounded, color: primaryColor, size: 48),
              ),
            ),
            const SizedBox(height: 16),
            Text(_currentRoom.roomName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            _statusBadge(_currentRoom.status),
            const SizedBox(height: 40),
            _infoRow(Icons.monetization_on_rounded, currencyFmt.format(_currentRoom.price), color: primaryColor, isBold: true),
            _infoRow(Icons.person_rounded, isRented ? '{V["dang_co"]}' : '{V["chua_co_nt"]}'),
            if (_currentRoom.area > 0)
              _infoRow(Icons.square_foot_rounded, 'Ph\u00f2ng di\u1ec7n t\u00edch ${{_currentRoom.area}} m\u00b2'),
            if (_currentRoom.note.isNotEmpty)
              _infoRow(Icons.notes_rounded, _currentRoom.note),
            const SizedBox(height: 24),
            if (!isRented)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddContractScreen(roomId: _currentRoom.id)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('{V["tao_hd"]}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            RoomPhotoGallery(
              roomId: _currentRoom.id,
              webImageUrl: _currentRoom.imageUrl,
              onWebImageUrlChanged: (url) => setState(() => _currentRoom = _currentRoom.copyWith(imageUrl: url)),
            ),
          ],
        ),
      ),
    );
  }}

  Widget _infoRow(IconData icon, String text, {{Color color = const Color(0xFF6B7280), bool isBold = false}}) {{
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isBold ? color : const Color(0xFF374151),
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }}

  Widget _statusBadge(String status) {{
    final isVacant = status == 'TRONG' || status == 'empty' || status == 'AVAILABLE';
    final isMaintenance = status == 'BAO_TRI';
    late Color bg;
    late Color fg;
    late String label;
    if (isVacant) {{
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF166534);
      label = '{V["trong"]}';
    }} else if (isMaintenance) {{
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
      label = '{V["bao_tri"]}';
    }} else {{
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF991B1B);
      label = '{V["dang_thue"]}';
    }}
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }}
}}
"""

BILL_LIST = f"""import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/bill_model.dart';
import '../../models/contract_model.dart';
import '../../models/room_model.dart';
import '../../models/tenant_model.dart';
import '../../services/firebase_service.dart';
import 'add_bill_screen.dart';
import 'bill_detail_dialog.dart';
import '../../utils/string_utils.dart';

class BillListScreen extends StatefulWidget {{
  const BillListScreen({{super.key}});

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}}

class _BillListScreenState extends State<BillListScreen> {{
  final _service = FirebaseService();
  String _currentFilter = 'ALL';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {{
    const primaryColor = Color(0xFF6366F1);
    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '\\u0111');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '{V["hoa_don"]}',
                    style: const TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {{
                            final settings = await _service.getSettings();
                            final monthStr = DateFormat('MM/yyyy').format(DateTime.now());
                            final count = await _service.bulkCreateBills(monthStr, settings);
                            if (mounted) {{
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('{snack}')),
                              );
                            }}
                          }},
                          icon: const Icon(Icons.auto_awesome_motion_rounded, size: 18),
                          label: Text('{V["tao_hang_loat"]}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                            minimumSize: const Size(0, 44),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBillScreen())),
                          icon: const Icon(Icons.edit_note_rounded, size: 20),
                          label: Text('{V["ghi_lo_chot"]}'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            foregroundColor: const Color(0xFF4B5563),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size(0, 44),
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
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: '{V["tim_phong"]}',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        fillColor: const Color(0xFFF1F3F9),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _filterChip('{V["tat_ca"]}', 'ALL'),
                        _filterChip('{V["chua_chot"]}', 'PENDING'),
                        _filterChip('{V["chua_tra"]}', 'unpaid'),
                        _filterChip('{V["da_tra"]}', 'paid'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: StreamBuilder<List<Bill>>(
                stream: _service.getBills(),
                builder: (ctx, billSnap) {{
                  if (!billSnap.hasData) return const Center(child: CircularProgressIndicator(color: primaryColor));
                  return StreamBuilder<List<Contract>>(
                    stream: _service.getContracts(),
                    builder: (ctx, contractSnap) {{
                      return StreamBuilder<List<Room>>(
                        stream: _service.getRooms(),
                        builder: (ctx, roomSnap) {{
                          var bills = billSnap.data ?? [];
                          final contracts = contractSnap.data ?? [];
                          final rooms = roomSnap.data ?? [];
                          bills.sort((a, b) => b.id.compareTo(a.id));
                          if (_currentFilter != 'ALL') {{
                            if (_currentFilter == 'PENDING') {{
                              bills = bills.where((b) => !b.meterUpdated).toList();
                            }} else if (_currentFilter == 'paid') {{
                              bills = bills.where((b) => b.isPaid).toList();
                            }} else if (_currentFilter == 'unpaid') {{
                              bills = bills.where((b) => b.isUnpaid).toList();
                            }} else {{
                              bills = bills.where((b) => b.paymentStatus == _currentFilter).toList();
                            }}
                          }}
                          if (_searchQuery.isNotEmpty) {{
                            bills = bills.where((b) {{
                              final contract = contracts.where((c) => c.id == b.contractId).firstOrNull;
                              final room = rooms.where((r) => r.id == contract?.roomId).firstOrNull;
                              return StringUtils.containsSearch(room?.roomName ?? '', _searchQuery) ||
                                  b.month.contains(_searchQuery);
                            }}).toList();
                          }}
                          if (bills.isEmpty) {{
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_outlined, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 8),
                                  Text('{V["chua_co_hd"]}', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                                ],
                              ),
                            );
                          }}
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: bills.length,
                            itemBuilder: (ctx, i) {{
                              final b = bills[i];
                              final contract = contracts.where((c) => c.id == b.contractId).firstOrNull;
                              final room = rooms.where((r) => r.id == contract?.roomId).firstOrNull;
                              final isPaid = b.isPaid;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${{room?.roomName ?? "{V["phong_khong_ro"]}"}} \u00b7 ${{b.month}}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF111827))),
                                          _statusBadge(isPaid ? '{V["thanh_cong"]}' : '{V["chua_thu"]}', isPaid ? const Color(0xFF059669) : const Color(0xFFDC2626)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('{V["tong_cong"]}: ${{currencyFmt.format(b.totalAmount)}}', style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 15)),
                                          Text('{V["han_thu"]}: ${{DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(b.dueDate))}}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                      const Divider(height: 24, color: Color(0xFFF3F4F6)),
                                      Row(
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {{}},
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isPaid ? Colors.grey.shade100 : const Color(0xFFDCFCE7),
                                              foregroundColor: isPaid ? Colors.grey : const Color(0xFF166534),
                                              elevation: 0,
                                              minimumSize: const Size(0, 36),
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              shape: const StadiumBorder(),
                                            ),
                                            child: Text(isPaid ? '{V["da_thu"]}' : '{V["thu_tien"]}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton(
                                            onPressed: () => showDialog(context: context, builder: (_) => BillDetailDialog(bill: b)),
                                            child: Text('{V["chi_tiet"]}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                          ),
                                          const Spacer(),
                                          IconButton(onPressed: () {{}}, icon: const Icon(Icons.share_outlined, color: Colors.grey, size: 20)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }},
                          );
                        }},
                      );
                    }},
                  );
                }},
              ),
            ),
          ],
        ),
      ),
    );
  }}

  Widget _filterChip(String label, String value) {{
    final isSelected = _currentFilter == value;
    const primaryColor = Color(0xFF6366F1);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _currentFilter = value),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFFE8E7FF),
        checkmarkColor: primaryColor,
        labelStyle: TextStyle(color: isSelected ? primaryColor : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
        shape: StadiumBorder(side: BorderSide(color: isSelected ? primaryColor : Colors.grey.shade200)),
      ),
    );
  }}

  Widget _statusBadge(String label, Color color) {{
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }}
}}
"""

def main():
    (ROOT / "screens/room/room_detail_screen.dart").write_text(ROOM_DETAIL, encoding="utf-8")
    (ROOT / "screens/bill/bill_list_screen.dart").write_text(BILL_LIST, encoding="utf-8")
    print("done room + bill")

if __name__ == "__main__":
    main()
