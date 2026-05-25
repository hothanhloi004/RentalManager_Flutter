import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/room_model.dart';
import '../../models/contract_model.dart';
import '../../models/tenant_model.dart';
import '../../services/firebase_service.dart';
import 'add_edit_room_screen.dart';
import 'room_detail_screen.dart';
import '../../theme/app_theme.dart';
import '../../utils/string_utils.dart';
import '../../widgets/list_page_header.dart';
import '../../widgets/list_search_field.dart';

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  final _service = FirebaseService();
  late final Stream<List<Room>> _roomsStream;
  late final Stream<List<Contract>> _contractsStream;
  late final Stream<List<Tenant>> _tenantsStream;
  String _currentFilter = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _roomsStream = _service.getRooms();
    _contractsStream = _service.getContracts();
    _tenantsStream = _service.getTenants();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '\u0111');
    const primaryColor = Color(0xFF6366F1);

    return Scaffold(
      backgroundColor: AppTheme.background, // Màu nền Android chuẩn
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF6366F1),
          statusBarIconBrightness: Brightness.light,
        ),
        child: SafeArea(
          child: Column(
        children: [
          ListPageHeader(
            title: 'Quản lý phòng',
            actionLabel: '+ Thêm phòng',
            onAction: () => showDialog(context: context, builder: (_) => const AddEditRoomScreen()),
          ),
          // Search & Filter Section (Sticky at top)
          Container(
            color: Colors.white,
            child: Column(
              children: [
                ListSearchField(
                  hintText: 'Tìm tên phòng hoặc người thuê...',
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      _filterChip('Tất cả', 'ALL'),
                      _filterChip('Trống', 'empty'),
                      _filterChip('Đang thuê', 'rented'),
                      _filterChip('Bảo trì', 'BAO_TRI'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Room>>(
              stream: _roomsStream,
              builder: (context, roomSnap) {
                if (roomSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primaryColor));
                }
                
                final roomsData = roomSnap.data ?? [];
                if (roomsData.isEmpty) {
                  return _buildEmptyState();
                }

                return StreamBuilder<List<Contract>>(
                  stream: _contractsStream,
                  builder: (context, contractSnap) {
                    return StreamBuilder<List<Tenant>>(
                      stream: _tenantsStream,
                      builder: (context, tenantSnap) {
                        var rooms = List<Room>.of(roomsData);
                        final contracts = contractSnap.data ?? [];
                        final tenants = tenantSnap.data ?? [];

                        // Sắp xếp ID mới nhất lên đầu (giả định Firebase ID có tính thời gian)
                        rooms.sort((a, b) => b.id.compareTo(a.id));

                        if (_currentFilter != 'ALL') {
                          if (_currentFilter == 'rented') rooms = rooms.where((r) => r.isRented).toList();
                          else if (_currentFilter == 'empty') rooms = rooms.where((r) => r.isEmpty).toList();
                          else rooms = rooms.where((r) => r.status == _currentFilter).toList();
                        }
                        if (_searchQuery.isNotEmpty) {
                          rooms = rooms.where((r) {
                            final c = contracts.firstWhere((con) => _contractBelongsToRoom(con, r) && con.isActive, orElse: () => Contract(id: '', roomId: '', tenantId: '', rentPrice: 0, deposit: 0, startDate: 0, status: 'NONE', useWifi: false, useTrash: false, useServiceFee: false));
                            final t = _tenantForContract(tenants, c) ?? Tenant(id: '', fullName: '', phone: '', cccd: '', address: '');
                            return StringUtils.containsSearch(r.roomName, _searchQuery) ||
                                   StringUtils.containsSearch(t.fullName, _searchQuery);
                          }).toList();
                        }

                        if (rooms.isEmpty) return const Center(child: Text('Không tìm thấy phòng phù hợp'));

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: rooms.length,
                          itemBuilder: (context, i) {
                            final r = rooms[i];
                            final contract = contracts.firstWhere((c) => _contractBelongsToRoom(c, r) && c.isActive, orElse: () => Contract(id: '', roomId: '', tenantId: '', rentPrice: 0, deposit: 0, startDate: 0, status: 'NONE', useWifi: false, useTrash: false, useServiceFee: false));
                            final tenant = _tenantForContract(tenants, contract) ?? Tenant(id: '', fullName: 'Chưa có người thuê', phone: '', cccd: '', address: '');
                            
                            bool isRented = r.isRented;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(r.roomName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppTheme.onSurface, letterSpacing: -0.3)),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _statusBg(r.status),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                _statusLabel(r.status),
                                                style: TextStyle(color: _statusColor(r.status), fontSize: 11, fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text('${currencyFmt.format(r.price)}/tháng', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 17, letterSpacing: -0.2)),
                                        const SizedBox(height: 12),
                                        Text(isRented ? tenant.fullName : 'Chưa có người thuê', style: TextStyle(fontWeight: isRented ? FontWeight.bold : FontWeight.normal, color: const Color(0xFF374151), fontSize: 13)),
                                        if (isRented) ...[
                                          const SizedBox(height: 4),
                                          Text('Từ: ${_formatDate(contract.startDate)}', style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                                        ],
                                        const SizedBox(height: 4),
                                        Text('Ghi chú: ${r.note.isEmpty ? 'Không có' : r.note}', style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13, height: 1.3)),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RoomDetailScreen(room: r))),
                                          icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: Colors.grey),
                                          label: const Text('Xem chi tiết', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: () => showDialog(context: context, builder: (_) => AddEditRoomScreen(room: r)),
                                          icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                                          label: const Text('Sửa', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          tooltip: 'Xóa phòng',
                                          onPressed: () => _confirmDeleteRoom(r),
                                          icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    final normalized = status.trim().toUpperCase();
    if (normalized == 'BAO_TRI' || normalized == 'MAINTENANCE') return 'B\u1ea3o tr\u00ec';
    if (normalized == 'TRONG' || normalized == 'EMPTY' || normalized == 'AVAILABLE') return 'Tr\u1ed1ng';
    return '\u0110ang thu\u00ea';
  }

  Color _statusBg(String status) {
    final normalized = status.trim().toUpperCase();
    if (normalized == 'BAO_TRI' || normalized == 'MAINTENANCE') return const Color(0xFFFEF3C7);
    if (normalized == 'TRONG' || normalized == 'EMPTY' || normalized == 'AVAILABLE') return const Color(0xFFF3F4F6);
    return const Color(0xFFDCFCE7);
  }

  Color _statusColor(String status) {
    final normalized = status.trim().toUpperCase();
    if (normalized == 'BAO_TRI' || normalized == 'MAINTENANCE') return const Color(0xFF92400E);
    if (normalized == 'TRONG' || normalized == 'EMPTY' || normalized == 'AVAILABLE') return AppTheme.onSurfaceVariant;
    return const Color(0xFF166534);
  }

  String _formatDate(int ms) {
    if (ms <= 0) return '\u2014';
    return DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(ms));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Chưa có phòng nào được tạo', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Bấm nút "+ Thêm phòng" để bắt đầu', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    bool isSelected = _currentFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _currentFilter = value),
        backgroundColor: Colors.white,
        selectedColor: AppTheme.iconPurpleBg,
        checkmarkColor: AppTheme.primary,
        labelStyle: TextStyle(color: isSelected ? AppTheme.primary : AppTheme.onSurface, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, fontSize: 13),
        shape: StadiumBorder(side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.divider)),
      ),
    );
  }

  static bool _contractBelongsToRoom(Contract contract, Room room) {
    return contract.roomId == room.id || contract.roomId == room.roomKey;
  }

  static Tenant? _tenantForContract(List<Tenant> tenants, Contract contract) {
    return tenants.where((t) => t.id == contract.tenantId || t.tenantKey == contract.tenantId).firstOrNull;
  }

  Future<void> _confirmDeleteRoom(Room room) async {
    if (room.isRented) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xóa phòng đang thuê'), backgroundColor: AppTheme.error),
      );
      return;
    }
    final hasContract = await _service.roomHasActiveContract(room.id);
    if (!mounted) return;
    if (hasContract) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xóa phòng đang có hợp đồng hiệu lực'), backgroundColor: AppTheme.error),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa phòng'),
        content: Text('Bạn có chắc chắn muốn xóa ${room.roomName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _service.deleteRoom(room.id);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppTheme.error),
        );
      }
    }
  }
}
