import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/inquiry_model.dart';
import '../../services/firebase_service.dart';
import '../../services/inquiry_read_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/relative_time.dart';
import '../../widgets/gradient_sub_page_header.dart';

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
                subtitle: 'Yêu cầu xem phòng từ khách',
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
                        .toList()
                      ..sort((a, b) {
                        final ta = a.createdAt?.millisecondsSinceEpoch ?? 0;
                        final tb = b.createdAt?.millisecondsSinceEpoch ?? 0;
                        return tb.compareTo(ta);
                      });
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
}

class _InquiryCard extends StatelessWidget {
  final Inquiry inquiry;
  final bool isRead;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const _InquiryCard({
    required this.inquiry,
    required this.isRead,
    required this.onMarkRead,
    required this.onDelete,
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
                  Text(inquiry.phone, style: const TextStyle(fontSize: 13, color: bodyText, fontWeight: FontWeight.w500)),
                ],
              ),
              if (inquiry.note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Lời nhắn: ${inquiry.note}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: bodyText, height: 1.35),
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
                ],
              ),
            ],
          ),
        ),
      );
  }
}
