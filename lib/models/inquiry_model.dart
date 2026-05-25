import 'package:cloud_firestore/cloud_firestore.dart';

/// Yêu cầu xem phòng từ web → `inquiries/{uid}/requests`.
class Inquiry {
  final String id;
  final String name;
  final String phone;
  final String roomName;
  final String note;
  final DateTime? createdAt;

  const Inquiry({
    required this.id,
    required this.name,
    required this.phone,
    required this.roomName,
    this.note = '',
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
      name: (data['name'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      roomName: (data['roomName'] ?? '').toString(),
      note: (data['note'] ?? '').toString(),
      createdAt: created,
    );
  }
}
