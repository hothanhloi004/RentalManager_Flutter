/// Loại ảnh phòng — tên file prefix giống app Android (`TAG_WEB_...`).
enum RoomPhotoCategory {
  web('TAG_WEB', 'Ảnh đăng web'),
  beforeRent('TAG_TRUOCTHUE', 'Ảnh trước thuê'),
  meter('TAG_DONGHO', 'Ảnh đồng hồ'),
  other('TAG_KHAC', 'Khác');

  const RoomPhotoCategory(this.filePrefix, this.label);

  final String filePrefix;
  final String label;

  /// Chỉ ảnh đăng web được đẩy ImgBB + cập nhật `imageUrl` (hiển thị web trọ).
  bool get syncsToWeb => this == RoomPhotoCategory.web;

  static RoomPhotoCategory fromFileName(String name) {
    if (name.startsWith('TAG_WEB_')) return RoomPhotoCategory.web;
    if (name.startsWith('TAG_TRUOCTHUE_')) return RoomPhotoCategory.beforeRent;
    if (name.startsWith('TAG_DONGHO_')) return RoomPhotoCategory.meter;
    return RoomPhotoCategory.other;
  }

  static const List<RoomPhotoCategory> displayOrder = [
    RoomPhotoCategory.web,
    RoomPhotoCategory.beforeRent,
    RoomPhotoCategory.meter,
    RoomPhotoCategory.other,
  ];
}
