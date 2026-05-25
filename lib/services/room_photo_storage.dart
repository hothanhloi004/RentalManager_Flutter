import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/room_photo_category.dart';

/// Lưu ảnh phòng trên máy (cùng quy ước thư mục/tên file như Android).
class RoomPhotoStorage {
  static Future<Directory> roomDir(String roomId) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'room_photos', 'room_$roomId'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<List<File>> listPhotos(String roomId) async {
    final dir = await roomDir(roomId);
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.jpg'))
        .toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  static Future<File> saveImage({
    required String roomId,
    required RoomPhotoCategory category,
    required XFile source,
    required String sourceTag,
  }) async {
    final dir = await roomDir(roomId);
    final name =
        '${category.filePrefix}_${sourceTag}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final dest = File(p.join(dir.path, name));
    await File(source.path).copy(dest.path);
    return dest;
  }

  static Future<bool> deletePhoto(File file) async {
    if (!await file.exists()) return false;
    await file.delete();
    return true;
  }

  static Map<RoomPhotoCategory, List<File>> groupByCategory(List<File> photos) {
    final map = {
      for (final c in RoomPhotoCategory.displayOrder) c: <File>[],
    };
    for (final file in photos) {
      final key = RoomPhotoCategory.fromFileName(p.basename(file.path));
      map[key]!.add(file);
    }
    return map;
  }
}
