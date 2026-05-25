import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/room_model.dart';
import '../../services/firebase_service.dart';
import '../../widgets/room_photo_gallery.dart';
import '../contract/add_contract_screen.dart';
import 'add_edit_room_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final Room room;
  const RoomDetailScreen({super.key, required this.room});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final _service = FirebaseService();
  late Room _currentRoom;

  @override
  void initState() {
    super.initState();
    _currentRoom = widget.room;
  }

  void _editRoom() {
    showDialog(
      context: context,
      builder: (ctx) => AddEditRoomScreen(room: _currentRoom),
    ).then((_) => _loadRoom());
  }

  Future<void> _loadRoom() async {
    try {
      final rooms = await _service.getRooms().first;
      final updated = rooms.where((r) => r.id == _currentRoom.id).firstOrNull;
      if (updated != null && mounted) {
        setState(() => _currentRoom = updated);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6366F1);
    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '\u0111');
    final isRented = _currentRoom.isRented;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: primaryColor,
          statusBarIconBrightness: Brightness.light,
        ),
        title: const Text('Xem chi tiết', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: true,
        actions: [
          TextButton(
            onPressed: _editRoom,
            child: const Text('Sửa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                    child: const Icon(Icons.meeting_room_rounded, color: Colors.white, size: 34),
                  ),
                  const SizedBox(height: 14),
                  Text(_currentRoom.roomName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF1F2937))),
                  const SizedBox(height: 8),
                  _statusText(_currentRoom.status),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.monetization_on_rounded, currencyFmt.format(_currentRoom.price), color: primaryColor, isBold: true),
                  _divider(),
                  _infoRow(Icons.person_rounded, isRented ? 'Đang có người thuê' : 'Chưa có người thuê'),
                  if (_currentRoom.area > 0) ...[
                    _divider(),
                    _infoRow(Icons.square_foot_rounded, 'Phòng diện tích ${_currentRoom.area} m²'),
                  ],
                  if (_currentRoom.note.isNotEmpty) ...[
                    _divider(),
                    _infoRow(Icons.notes_rounded, _currentRoom.note),
                  ],
                  if (!isRented) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AddContractScreen(roomId: _currentRoom.roomKey)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tạo hợp đồng cho phòng này', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: RoomPhotoGallery(
                roomId: _currentRoom.roomKey,
                webImageUrl: _currentRoom.imageUrl,
                onWebImageUrlChanged: (url) => setState(() => _currentRoom = _currentRoom.copyWith(imageUrl: url)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color color = const Color(0xFF6B7280), bool isBold = false}) {
    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isBold ? color : const Color(0xFF374151),
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Divider(height: 1, color: Color(0xFFE5E7EB)),
      );

  Widget _statusText(String status) {
    return Text(
      _statusLabel(status),
      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
    );
  }

  String _statusLabel(String status) {
    final normalized = status.trim().toUpperCase();
    final isVacant = normalized == 'TRONG' || normalized == 'EMPTY' || normalized == 'AVAILABLE';
    final isMaintenance = normalized == 'BAO_TRI' || normalized == 'MAINTENANCE';
    if (isVacant) return 'Trống';
    if (isMaintenance) return 'Bảo trì';
    return 'Đang thuê';
  }

  Widget _statusBadge(String status) {
    final normalized = status.trim().toUpperCase();
    final isVacant = normalized == 'TRONG' || normalized == 'EMPTY' || normalized == 'AVAILABLE';
    final isMaintenance = normalized == 'BAO_TRI' || normalized == 'MAINTENANCE';
    late Color bg;
    late Color fg;
    late String label;
    if (isVacant) {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF166534);
      label = 'Trống';
    } else if (isMaintenance) {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
      label = 'Bảo trì';
    } else {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF991B1B);
      label = '\u0110ang thu\u00ea';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
