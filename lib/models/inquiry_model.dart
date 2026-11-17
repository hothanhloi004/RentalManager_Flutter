import 'package:cloud_firestore/cloud_firestore.dart';

/// Yêu cầu xem phòng hoặc báo sửa chữa từ web → `inquiries/{uid}/requests`.
class Inquiry {
  final String id;
  final String type; // '' | 'MAINTENANCE' | 'REPORT'
  final String roomId;
  final String roomDocId;
  final String name;
  final String phone;
  final String roomName;
  final String note;
  final String category;
  final String priority;
  final String repairStatus;
  final String landlordReply;
  final DateTime? createdAt;

  bool get isMaintenance => type.toUpperCase() == 'MAINTENANCE';
  bool get isReport => type.toUpperCase() == 'REPORT';

  const Inquiry({
    required this.id,
    this.type = '',
    this.roomId = '',
    this.roomDocId = '',
    required this.name,
    required this.phone,
    required this.roomName,
    this.note = '',
    this.category = '',
    this.priority = 'NORMAL',
    this.repairStatus = 'PENDING',
    this.landlordReply = '',
    this.createdAt,
  });

  factory Inquiry.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? created;
    final raw = data['createdAt'];
    if (raw is Timestamp) {
      created = raw.toDate();
    } else if (raw is int) {
      created = DateTime.fromMillisecondsSinceEpoch(raw);
    }

    return Inquiry(
      id: id,
      type: (data['type'] ?? '').toString(),
      roomId: (data['roomId'] ?? '').toString(),
      roomDocId: (data['roomDocId'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      roomName: (data['roomName'] ?? '').toString(),
      note: (data['description'] ?? data['note'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      priority: (data['priority'] ?? 'NORMAL').toString(),
      repairStatus: (data['repairStatus'] ?? data['status'] ?? 'PENDING').toString(),
      landlordReply: (data['landlordReply'] ?? '').toString(),
      createdAt: created,
    );
  }
}
