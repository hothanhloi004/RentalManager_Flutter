# -*- coding: utf-8 -*-
from pathlib import Path

def u(*codes):
    return "".join(chr(c) for c in codes)

S = {
    "subtitle": u(0x59, 0xEA, 0x75, 0x20, 0x63, 0x1EA7, 0x75, 0x20, 0x78, 0x65, 0x6D, 0x20, 0x70, 0x68, 0xF2, 0x6E, 0x67, 0x20, 0x74, 0x1EEB, 0x20, 0x6B, 0x68, 0xE1, 0x63, 0x68),
    "clear_all": u(0x58, 0xF3, 0x61, 0x20, 0x74, 0x1EA5, 0x74, 0x20, 0x63, 0x1EA3),
    "all": u(0x54, 0x1EA5, 0x74, 0x20, 0x63, 0x1EA3),
    "unread": u(0x43, 0x68, 0x1B0, 0x61, 0x20, 0x111, 0x1ECD, 0x63),
    "read": u(0x110, 0xE3, 0x20, 0x111, 0x1ECD, 0x63),
    "empty_title": u(0x43, 0x68, 0x1B0, 0x61, 0x20, 0x63, 0xF3, 0x20, 0x74, 0x68, 0xF4, 0x6E, 0x67, 0x20, 0x62, 0xE1, 0x6F, 0x20, 0x6E, 0xE0, 0x6F),
    "empty_sub": u(0x4B, 0x68, 0x69, 0x20, 0x6B, 0x68, 0xE1, 0x63, 0x68, 0x20, 0x67, 0x1EED, 0x69, 0x20, 0x79, 0xEA, 0x75, 0x20, 0x63, 0x1EA7, 0x75, 0x20, 0x78, 0x65, 0x6D, 0x20, 0x70, 0x68, 0xF2, 0x6E, 0x67, 0x2C, 0xA, 0x74, 0x68, 0xF4, 0x6E, 0x67, 0x20, 0x62, 0xE1, 0x6F, 0x20, 0x73, 0x1EBD, 0x20, 0x78, 0x75, 0x1EA5, 0x74, 0x20, 0x68, 0x69, 0x1EC7, 0x6E, 0x20, 0x1F, 0x6F, 0x20, 0x111, 0xE2, 0x79, 0x2E),
    "new_badge": u(0x4D, 0x1EDA, 0x49),
    "room_default": u(0x50, 0x68, 0xF2, 0x6E, 0x67, 0x20, 0x71, 0x75, 0x61, 0x6E, 0x20, 0x74, 0xE2, 0x6D),
    "note_prefix": u(0x4C, 0x1EDD, 0x69, 0x20, 0x6E, 0x68, 0x1EAF, 0x6E, 0x3A, 0x20),
    "mark_read": u(0x110, 0xE1, 0x6E, 0x68, 0x20, 0x64, 0x1EA5, 0x75, 0x20, 0x111, 0xE3, 0x20, 0x111, 0x1ECD, 0x63),
    "delete_title": u(0x58, 0xF3, 0x61, 0x20, 0x74, 0x68, 0xF4, 0x6E, 0x67, 0x20, 0x62, 0xE1, 0x6F),
    "delete_msg": u(0x42, 0x1EA1, 0x6E, 0x20, 0x63, 0xF3, 0x20, 0x63, 0x68, 0x1EAF, 0x20, 0x6D, 0x1ED1, 0x6E, 0x20, 0x78, 0xF3, 0x61, 0x20, 0x74, 0x68, 0xF4, 0x6E, 0x67, 0x20, 0x62, 0xE1, 0x6F, 0x20, 0x6E, 0xE0, 0x79, 0x20, 0x6B, 0x68, 0xF4, 0x6E, 0x67, 0x3F),
    "delete": u(0x58, 0xF3, 0x61),
    "cancel": u(0x48, 0x1EE7, 0x79),
    "deleted": u(0x110, 0xE3, 0x20, 0x78, 0xF3, 0x61, 0x20, 0x74, 0x68, 0xF4, 0x6E, 0x67, 0x20, 0x62, 0xE1, 0x6F),
    "clear_title": u(0x58, 0xF3, 0x61, 0x20, 0x74, 0x1EA5, 0x74, 0x20, 0x63, 0x1EA3, 0x20, 0x74, 0x68, 0xF4, 0x6E, 0x67, 0x20, 0x62, 0xE1, 0x6F),
    "clear_msg": u(0x42, 0x1EA1, 0x6E, 0x20, 0x63, 0xF3, 0x20, 0x63, 0x68, 0x1EAF, 0x20, 0x6D, 0x1ED1, 0x6E, 0x20, 0x78, 0xF3, 0x61, 0x20, 0x74, 0x1EA5, 0x74, 0x20, 0x63, 0x1EA3, 0x20, 0x74, 0x68, 0xF4, 0x6E, 0x67, 0x20, 0x62, 0xE1, 0x6F, 0x20, 0x74, 0x72, 0xEA, 0x6E, 0x20, 0x68, 0x1EC7, 0x20, 0x74, 0x68, 0x1ED1, 0x6E, 0x67, 0x3F),
    "clearing": u(0x110, 0x61, 0x6E, 0x67, 0x20, 0x78, 0xF3, 0x61, 0x2E, 0x2E, 0x2E),
    "login": u(0x56, 0x75, 0x69, 0x20, 0x6C, 0xF2, 0x6E, 0x67, 0x20, 0x111, 0x103, 0x6E, 0x67, 0x20, 0x6E, 0x68, 0x1EAD, 0x70, 0x20, 0x111, 0x1EC3, 0x20, 0x78, 0x65, 0x6D, 0x20, 0x74, 0x68, 0xF4, 0x6E, 0x67, 0x20, 0x62, 0xE1, 0x6F),
    "load_err": u(0x4C, 0x1ED7, 0x69, 0x20, 0x74, 0x1EA3, 0x69, 0x20, 0x74, 0x68, 0xF4, 0x6E, 0x67, 0x20, 0x62, 0xE1, 0x6F),
}

dart = f'''import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/inquiry_model.dart';
import '../../services/firebase_service.dart';
import '../../services/inquiry_read_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/relative_time.dart';
import '../../widgets/gradient_sub_page_header.dart';

enum _InquiryFilter {{ all, unread, read }}

class NotificationScreen extends StatefulWidget {{
  const NotificationScreen({{super.key}});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}}

class _NotificationScreenState extends State<NotificationScreen> {{
  final _service = FirebaseService();
  final _readStore = InquiryReadStore.instance;
  _InquiryFilter _filter = _InquiryFilter.all;
  List<Inquiry> _all = [];

  @override
  void initState() {{
    super.initState();
    _readStore.ensureLoaded();
  }}

  List<Inquiry> get _filtered {{
    return _all.where((inq) {{
      final read = _readStore.isRead(inq.id);
      switch (_filter) {{
        case _InquiryFilter.unread:
          return !read;
        case _InquiryFilter.read:
          return read;
        case _InquiryFilter.all:
          return true;
      }}
    }}).toList();
  }}

  @override
  Widget build(BuildContext context) {{
    final uid = _service.currentUser?.uid;
    if (uid == null) {{
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
          title: const Text('Th\u00f4ng b\u00e1o'),
        ),
        body: Center(child: Text('{S["login"]}')),
      );
    }}

    return ListenableBuilder(
      listenable: _readStore,
      builder: (context, _) {{
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Column(
            children: [
              GradientSubPageHeader(
                title: 'Th\u00f4ng b\u00e1o',
                subtitle: '{S["subtitle"]}',
                trailing: OutlinedButton(
                  onPressed: _all.isEmpty ? null : () => _confirmClearAll(uid),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text('{S["clear_all"]}', style: const TextStyle(fontSize: 12)),
                ),
              ),
              _filterRow(),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('inquiries')
                      .doc(uid)
                      .collection('requests')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {{
                    if (snapshot.hasError) {{
                      return Center(child: Text('{S["load_err"]}'));
                    }}
                    if (!snapshot.hasData) {{
                      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                    }}

                    _all = snapshot.data!.docs
                        .map((d) => Inquiry.fromFirestore(d.data(), d.id))
                        .toList();

                    final list = _filtered;
                    if (list.isEmpty) {{
                      return _emptyState();
                    }}

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
                  }},
                ),
              ),
            ],
          ),
        );
      }},
    );
  }}

  Widget _filterRow() {{
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip('{S["all"]}', _InquiryFilter.all),
            _chip('{S["unread"]}', _InquiryFilter.unread),
            _chip('{S["read"]}', _InquiryFilter.read),
          ],
        ),
      ),
    );
  }}

  Widget _chip(String label, _InquiryFilter value) {{
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: AppTheme.iconPurpleBg,
        checkmarkColor: AppTheme.primary,
        labelStyle: TextStyle(
          color: selected ? AppTheme.primary : AppTheme.onSurface,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13,
        ),
        shape: StadiumBorder(
          side: BorderSide(color: selected ? AppTheme.primary : AppTheme.divider),
        ),
      ),
    );
  }}

  Widget _emptyState() {{
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('\U0001f514', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('{S["empty_title"]}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              '{S["empty_sub"]}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }}

  Future<void> _deleteOne(String uid, Inquiry item) async {{
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('{S["delete_title"]}'),
        content: Text('{S["delete_msg"]}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('{S["cancel"]}')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('{S["delete"]}', style: const TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await FirebaseFirestore.instance.collection('inquiries').doc(uid).collection('requests').doc(item.id).delete();
    if (mounted) {{
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('{S["deleted"]}')));
    }}
  }}

  Future<void> _confirmClearAll(String uid) async {{
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('{S["clear_title"]}'),
        content: Text('{S["clear_msg"]}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('{S["cancel"]}')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('{S["clear_all"]}', style: const TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('{S["clearing"]}')));
    final batch = FirebaseFirestore.instance.batch();
    for (final inq in _all) {{
      final ref = FirebaseFirestore.instance.collection('inquiries').doc(uid).collection('requests').doc(inq.id);
      batch.delete(ref);
    }}
    await batch.commit();
  }}
}}

class _InquiryCard extends StatelessWidget {{
  final Inquiry inquiry;
  final bool isRead;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const _InquiryCard({{
    required this.inquiry,
    required this.isRead,
    required this.onMarkRead,
    required this.onDelete,
  }});

  @override
  Widget build(BuildContext context) {{
    final room = inquiry.roomName.isNotEmpty ? inquiry.roomName : '{S["room_default"]}';

    return Opacity(
      opacity: isRead ? 0.62 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isRead ? AppTheme.divider : const Color(0xFFE0E7FF), width: isRead ? 1 : 1.5),
          boxShadow: [
            if (!isRead)
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
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
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      inquiry.name.isNotEmpty ? inquiry.name : 'Kh\u00e1ch',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isRead ? AppTheme.onSurfaceVariant : AppTheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (!isRead)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '{S["new_badge"]}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: AppTheme.onSurfaceVariant,
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.home_outlined, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(room, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 16, color: AppTheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(inquiry.phone, style: const TextStyle(fontSize: 13, color: AppTheme.onSurface)),
                ],
              ),
              if (inquiry.note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '{S["note_prefix"]}${{inquiry.note}}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant, height: 1.35),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      RelativeTime.format(inquiry.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
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
                      child: Text('{S["mark_read"]}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }}
}}
'''

# Fix empty_sub newline - use explicit \n
dart = dart.replace(S["empty_sub"], "Khi khách gửi yêu cầu xem phòng,\nthông báo sẽ xuất hiện ở đây.")

out = Path(__file__).resolve().parent.parent / "lib" / "screens" / "notification" / "contact_request_screen.dart"
out.write_text(dart, encoding="utf-8")
print("wrote", out)
