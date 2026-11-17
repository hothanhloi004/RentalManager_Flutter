import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/inquiry_model.dart';
import '../../models/room_model.dart';
import '../../models/tenant_model.dart';
import '../../services/firebase_service.dart';
import '../../services/inquiry_read_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/relative_time.dart';
import '../../widgets/gradient_sub_page_header.dart';
import '../contract/add_contract_screen.dart';

enum _InquiryFilter { all, unread, read }

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _service = FirebaseService();
  final _readStore = InquiryReadStore.instance;
  _InquiryFilter _filter = _InquiryFilter.all;
  List<Inquiry> _all = [];
  bool _markedInitialListAsRead = false;

  @override
  void initState() {
    super.initState();
    _readStore.ensureLoaded();
  }

  List<Inquiry> get _filtered {
    return _all.where((inq) {
      final read = _readStore.isRead(inq.id);
      switch (_filter) {
        case _InquiryFilter.unread:
          return !read;
        case _InquiryFilter.read:
          return read;
        case _InquiryFilter.all:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _service.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
          title: const Text('Thông báo'),
        ),
        body: Center(child: Text('Vui lòng đăng nhập để xem thông báo')),
      );
    }

    return ListenableBuilder(
      listenable: _readStore,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Column(
            children: [
              GradientSubPageHeader(
                title: 'Thông báo',
                subtitle: 'Khách hỏi phòng & Báo sửa chữa',
                trailing: OutlinedButton(
                  onPressed: () => _confirmClearAll(uid),
                  style: ButtonStyle(
                    foregroundColor: const WidgetStatePropertyAll(Colors.white),
                    backgroundColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.12)),
                    side: const WidgetStatePropertyAll(BorderSide(color: Colors.white, width: 1.1)),
                    minimumSize: const WidgetStatePropertyAll(Size(0, 34)),
                    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
                    overlayColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: Text(
                    'Xóa tất cả',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
              _filterRow(),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('inquiries')
                      .doc(uid)
                      .collection('requests')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Lỗi tải thông báo'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                    }

                    _all = snapshot.data!.docs
                        .map((d) => Inquiry.fromFirestore(d.data(), d.id))
                        .where((inq) => !inq.isReport)
                        .toList()
                      ..sort((a, b) {
                        final ta = a.createdAt?.millisecondsSinceEpoch ?? 0;
                        final tb = b.createdAt?.millisecondsSinceEpoch ?? 0;
                        return tb.compareTo(ta);
                      });

                    // Màn hình này là nơi chủ trọ đọc danh sách yêu cầu.
                    // Đánh dấu các yêu cầu hiện có sau khi danh sách đã hiển thị
                    // để badge trên Dashboard không còn báo số cũ.
                    if (!_markedInitialListAsRead && _all.isNotEmpty) {
                      _markedInitialListAsRead = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        _readStore.markAllRead(_all.map((inquiry) => inquiry.id));
                      });
                    }
                    final list = _filtered;
                    if (list.isEmpty) {
                      return _emptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      itemCount: list.length,
                      itemBuilder: (context, index) => _InquiryCard(
                        inquiry: list[index],
                        isRead: _readStore.isRead(list[index].id),
                        onMarkRead: () => _readStore.markRead(list[index].id),
                        onDelete: () => _deleteOne(uid, list[index]),
                        onConvertToContract: () => _convertToContract(list[index]),
                        onUpdateRepair: () => _showUpdateRepairDialog(uid, list[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            _chip('Tất cả', _InquiryFilter.all),
            _chip('Chưa đọc', _InquiryFilter.unread),
            _chip('Đã đọc', _InquiryFilter.read),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, _InquiryFilter value) {
    final selected = _filter == value;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF64748B).withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _filter = value),
            borderRadius: BorderRadius.circular(20),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppTheme.primary : const Color(0xFF475569),
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔔', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Chưa có thông báo nào', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'Khi kh\u00e1ch g\u1eedi y\u00eau c\u1ea7u xem ph\u00f2ng,\nth\u00f4ng b\u00e1o s\u1ebd xu\u1ea5t hi\u1ec7n \u1edf \u0111\u00e2y.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteOne(String uid, Inquiry item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa thông báo'),
        content: Text('Bạn có chắc muốn xóa thông báo này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Xóa', style: const TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await FirebaseFirestore.instance.collection('inquiries').doc(uid).collection('requests').doc(item.id).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xóa thông báo')));
    }
  }

  Future<void> _confirmClearAll(String uid) async {
    if (_all.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chưa có thông báo để xóa')));
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa tất cả thông báo'),
        content: Text('Bạn có chắc muốn xóa tất cả thông báo trên hệ thống?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Xóa tất cả', style: const TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đang xóa...')));
    final batch = FirebaseFirestore.instance.batch();
    for (final inq in _all) {
      final ref = FirebaseFirestore.instance.collection('inquiries').doc(uid).collection('requests').doc(inq.id);
      batch.delete(ref);
    }
    await batch.commit();
  }

  Future<void> _convertToContract(Inquiry inquiry) async {
    _readStore.markRead(inquiry.id);
    try {
      final results = await Future.wait([
        _service.getTenants().first,
        _service.getRooms().first,
      ]);
      final tenants = results[0] as List<Tenant>;
      final rooms = results[1] as List<Room>;

      final cleanPhone = inquiry.phone.replaceAll(RegExp(r'[^\d]'), '');
      Tenant? matchedTenant = tenants.where((t) {
        final tPhone = t.phone.replaceAll(RegExp(r'[^\d]'), '');
        return cleanPhone.isNotEmpty && tPhone == cleanPhone;
      }).firstOrNull;

      String tenantKey;
      if (matchedTenant != null) {
        tenantKey = matchedTenant.tenantKey;
      } else {
        tenantKey = await _service.addTenant(
          Tenant(
            id: '',
            fullName: inquiry.name.trim().isNotEmpty ? inquiry.name.trim() : 'Khách thuê mới',
            phone: inquiry.phone.trim(),
            cccd: '',
            address: '',
          ),
        );
      }

      Room? matchedRoom = rooms.where((r) {
        if (inquiry.roomId.isNotEmpty && (r.id == inquiry.roomId || r.roomKey == inquiry.roomId)) return true;
        if (inquiry.roomDocId.isNotEmpty && r.id == inquiry.roomDocId) return true;
        return r.roomName.trim().toLowerCase() == inquiry.roomName.trim().toLowerCase();
      }).firstOrNull;

      if (!mounted) return;
      if (matchedRoom != null && !matchedRoom.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã lưu khách "${inquiry.name}", nhưng ${matchedRoom.roomName} hiện không còn trống.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddContractScreen(
            roomId: (matchedRoom != null && matchedRoom.isEmpty) ? matchedRoom.roomKey : null,
            tenantId: tenantKey,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showUpdateRepairDialog(String uid, Inquiry item) async {
    _readStore.markRead(item.id);
    final replyCtrl = TextEditingController(text: item.landlordReply);
    String selectedStatus = item.repairStatus.toUpperCase() == 'DONE' ? 'DONE' : 'IN_PROGRESS';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Xử lý sửa chữa · ${item.roomName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hạng mục: ${item.category.isNotEmpty ? item.category : "Sửa chữa"}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              Text(item.note, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
              const SizedBox(height: 14),
              const Text('Trạng thái xử lý:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('🔧 Đang sửa chữa'),
                    selected: selectedStatus == 'IN_PROGRESS',
                    onSelected: (_) => setDialogState(() => selectedStatus = 'IN_PROGRESS'),
                  ),
                  ChoiceChip(
                    label: const Text('✅ Đã hoàn thành'),
                    selected: selectedStatus == 'DONE',
                    onSelected: (_) => setDialogState(() => selectedStatus = 'DONE'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: replyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phản hồi cho khách thuê (hiển thị trên Web)',
                  hintText: 'VD: Chiều 15h thợ điện qua kiểm tra nhé',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cập nhật')),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    final reply = replyCtrl.text.trim();
    try {
      final payload = {
        'repairStatus': selectedStatus,
        'status': selectedStatus,
        'landlordReply': reply,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection('inquiries')
          .doc(uid)
          .collection('requests')
          .doc(item.id)
          .update(payload);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('maintenance')
          .doc(item.id)
          .set({
        'type': 'MAINTENANCE',
        'roomName': item.roomName,
        'roomId': item.roomId,
        'name': item.name,
        'phone': item.phone,
        'category': item.category,
        'priority': item.priority,
        'description': item.note,
        'note': item.note,
        ...payload,
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật trạng thái sửa chữa!'), backgroundColor: Color(0xFF16A34A)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }
}

class _InquiryCard extends StatelessWidget {
  final Inquiry inquiry;
  final bool isRead;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;
  final VoidCallback onConvertToContract;
  final VoidCallback onUpdateRepair;

  const _InquiryCard({
    required this.inquiry,
    required this.isRead,
    required this.onMarkRead,
    required this.onDelete,
    required this.onConvertToContract,
    required this.onUpdateRepair,
  });

  @override
  Widget build(BuildContext context) {
    final room = inquiry.roomName.isNotEmpty ? inquiry.roomName : 'Phòng quan tâm';
    const strongText = Color(0xFF1F2937);
    const bodyText = Color(0xFF475569);
    const metaText = Color(0xFF64748B);
    const cardBorder = Color(0xFFE1E7F0);
    const unreadBg = Color(0xFFF8FAFF);
    const unreadBorder = Color(0xFF818CF8);

    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : unreadBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isRead ? cardBorder : unreadBorder, width: isRead ? 1 : 1.6),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withValues(alpha: isRead ? 0.10 : 0.18),
              blurRadius: isRead ? 12 : 18,
              offset: Offset(0, isRead ? 4 : 7),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isRead)
                    Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.only(top: 7, right: 8),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      inquiry.name.isNotEmpty ? inquiry.name : 'Khách',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                        color: strongText,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (!isRead)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Chưa đọc',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: metaText,
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.home_outlined, size: 16, color: isRead ? AppTheme.primary : const Color(0xFF4F46E5)),
                  const SizedBox(width: 6),
                  Text(
                    room,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                      color: isRead ? AppTheme.primary : const Color(0xFF4F46E5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 16, color: AppTheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(inquiry.phone, style: const TextStyle(fontSize: 13, color: bodyText, fontWeight: FontWeight.w500)),
                  ),
                  if (inquiry.phone.trim().isNotEmpty) ...[
                    TextButton.icon(
                      onPressed: () {
                        onMarkRead();
                        launchUrl(Uri(scheme: 'tel', path: inquiry.phone.trim()));
                      },
                      icon: const Icon(Icons.call_outlined, size: 14),
                      label: const Text('Gọi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        backgroundColor: const Color(0xFFEDEBFF),
                        minimumSize: const Size(0, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    TextButton.icon(
                      onPressed: () {
                        onMarkRead();
                        final digits = inquiry.phone.replaceAll(RegExp(r'[^\d]'), '');
                        final zalo = digits.startsWith('0') ? '84${digits.substring(1)}' : digits;
                        launchUrl(Uri.parse('https://zalo.me/$zalo'), mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                      label: const Text('Zalo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0F766E),
                        backgroundColor: const Color(0xFFCCFBF1),
                        minimumSize: const Size(0, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ],
              ),
              if (inquiry.isMaintenance) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '🔧 Báo sửa chữa: ${inquiry.category.isNotEmpty ? inquiry.category : "Thiết bị"}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: inquiry.repairStatus.toUpperCase() == 'DONE'
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        inquiry.repairStatus.toUpperCase() == 'DONE'
                            ? 'Đã hoàn thành'
                            : (inquiry.repairStatus.toUpperCase() == 'IN_PROGRESS' ? 'Đang sửa chữa' : 'Chờ xử lý'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: inquiry.repairStatus.toUpperCase() == 'DONE'
                              ? const Color(0xFF166534)
                              : const Color(0xFF0369A1),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (inquiry.note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  inquiry.isMaintenance ? 'Mô tả sự cố: ${inquiry.note}' : 'Lời nhắn: ${inquiry.note}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: bodyText, height: 1.35),
                ),
              ],
              if (inquiry.landlordReply.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '💬 Phản hồi: ${inquiry.landlordReply}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.w700),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      RelativeTime.format(inquiry.createdAt),
                      style: TextStyle(fontSize: 11, color: isRead ? metaText : AppTheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (!isRead)
                    TextButton(
                      onPressed: onMarkRead,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                      ),
                      child: Text('Đánh dấu đã đọc', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(width: 6),
                  if (inquiry.isMaintenance)
                    FilledButton.icon(
                      onPressed: onUpdateRepair,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.build_circle_outlined, size: 15),
                      label: const Text('Cập nhật sửa chữa', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    )
                  else
                    FilledButton.icon(
                      onPressed: onConvertToContract,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.assignment_turned_in_outlined, size: 15),
                      label: const Text('Nhận khách & Lập HĐ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
  }
}
