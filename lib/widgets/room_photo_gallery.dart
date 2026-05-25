import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/room_photo_category.dart';
import '../services/firebase_service.dart';
import '../services/imgbb_service.dart';
import '../services/room_photo_storage.dart';

/// Gallery ảnh phòng theo nhóm (giống Android DocPhotoAdapter).
class RoomPhotoGallery extends StatefulWidget {
  final String roomId;
  final String webImageUrl;
  final ValueChanged<String>? onWebImageUrlChanged;

  const RoomPhotoGallery({
    super.key,
    required this.roomId,
    this.webImageUrl = '',
    this.onWebImageUrlChanged,
  });

  @override
  State<RoomPhotoGallery> createState() => _RoomPhotoGalleryState();
}

class _RoomPhotoGalleryState extends State<RoomPhotoGallery> {
  final _picker = ImagePicker();
  final _firebase = FirebaseService();

  List<File> _photos = [];
  bool _loading = true;
  bool _uploading = false;
  String _webImageUrl = '';

  @override
  void initState() {
    super.initState();
    _webImageUrl = widget.webImageUrl;
    _reload();
  }

  @override
  void didUpdateWidget(covariant RoomPhotoGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.webImageUrl != widget.webImageUrl) {
      _webImageUrl = widget.webImageUrl;
    }
  }

  Future<void> _reload() async {
    try {
      final list = await RoomPhotoStorage.listPhotos(widget.roomId);
      if (!mounted) return;
      setState(() {
        _photos = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickCategoryAndSource() async {
    final category = await showDialog<RoomPhotoCategory>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Chọn loại ảnh'),
        children: RoomPhotoCategory.displayOrder
            .map(
              (c) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, c),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (c.syncsToWeb)
                      const Text(
                        'Hiển thị trên web trọ (đồng bộ Cloud)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (category == null || !mounted) return;

    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Thêm ảnh'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: const Text('📷 Chụp ảnh mới'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            child: const Text('🖼️ Chọn từ thư viện'),
          ),
        ],
      ),
    );
    if (source == null || !mounted) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      await RoomPhotoStorage.saveImage(
        roomId: widget.roomId,
        category: category,
        source: picked,
        sourceTag: source == ImageSource.camera ? 'camera' : 'gallery',
      );

      if (category.syncsToWeb) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang tải ảnh đăng web lên Cloud...')),
        );
        final url = await ImgBBService.uploadImage(picked);
        if (url == null || url.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lưu ảnh trên máy OK nhưng upload web thất bại'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          await _firebase.updateRoomImageUrl(widget.roomId, url);
          _webImageUrl = url;
          widget.onWebImageUrlChanged?.call(url);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã đăng ảnh lên web trọ ✓'),
                backgroundColor: Color(0xFF4CAF50),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã thêm ${category.label}')),
          );
        }
      }

      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _clearWebImageOnCloud() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gỡ ảnh khỏi web trọ'),
        content: const Text('Ảnh sẽ không còn hiển thị trên trang web. Bạn có chắc không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gỡ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _firebase.updateRoomImageUrl(widget.roomId, '');
      _webImageUrl = '';
      widget.onWebImageUrlChanged?.call('');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gỡ ảnh khỏi web trọ')),
        );
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deletePhoto(File file, RoomPhotoCategory category) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa ảnh'),
        content: const Text('Bạn có chắc muốn xóa ảnh này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await RoomPhotoStorage.deletePhoto(file);

      if (category.syncsToWeb && _webImageUrl.isNotEmpty) {
        await _firebase.updateRoomImageUrl(widget.roomId, '');
        _webImageUrl = '';
        widget.onWebImageUrlChanged?.call('');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa ảnh')),
        );
        setState(() {});
      }
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  void _viewPhoto(ImageProvider provider, {File? file, RoomPhotoCategory? category}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(child: Image(image: provider, fit: BoxFit.contain)),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            if (file != null && category != null)
              Positioned(
                top: 8,
                right: 8,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _deletePhoto(file, category);
                  },
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('Xóa ảnh'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6366F1);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    final grouped = RoomPhotoStorage.groupByCategory(_photos);
    final hasWebCloud = _webImageUrl.isNotEmpty;
    final hasAny = _photos.isNotEmpty || hasWebCloud;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hình ảnh phòng',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
              ),
              TextButton(
                onPressed: _uploading ? null : _pickCategoryAndSource,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFCCFBF1),
                  foregroundColor: const Color(0xFF0F766E),
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: const StadiumBorder(),
                ),
                child: _uploading
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: primary))
                    : const Text('+ Thêm ảnh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
        ),
        if (!hasAny)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Text(
              'Chưa có hình ảnh phòng',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ..._buildCategorySections(grouped, hasWebCloud),
        const SizedBox(height: 16),
      ],
    );
  }

  List<Widget> _buildCategorySections(
    Map<RoomPhotoCategory, List<File>> grouped,
    bool hasWebCloud,
  ) {
    final widgets = <Widget>[];
    for (final category in RoomPhotoCategory.displayOrder) {
      final files = grouped[category]!;
      if (files.isEmpty && !(category == RoomPhotoCategory.web && hasWebCloud)) {
        continue;
      }
      final displayCount = category == RoomPhotoCategory.web && hasWebCloud && files.isEmpty ? 1 : files.length;
      widgets.add(_sectionHeader(category, displayCount));
      if (category.syncsToWeb && files.isEmpty && hasWebCloud) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: _networkPhotoTile(),
          ),
        );
      }
      if (files.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: files.length,
              itemBuilder: (context, index) => _photoTile(files[index], category),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _sectionHeader(RoomPhotoCategory category, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category.label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1F2937)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFF64748B), borderRadius: BorderRadius.circular(12)),
            child: Text('$count ảnh', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _networkPhotoTile() {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 92,
        height: 92,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => _viewPhoto(NetworkImage(_webImageUrl)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  _webImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                child: const Text('Ảnh đăng web', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: IconButton(
                onPressed: _clearWebImageOnCloud,
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.black45, minimumSize: const Size(28, 28)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoTile(File file, RoomPhotoCategory category) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () => _viewPhoto(FileImage(file), file: file, category: category),
          onLongPress: () => _showPhotoActions(file, category),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(file, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          left: 4,
          top: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              category.label,
              style: const TextStyle(color: Colors.white, fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Positioned(
          right: 4,
          bottom: 4,
          child: Material(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(8),
            elevation: 2,
            child: InkWell(
              onTap: () => _deletePhoto(file, category),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline, color: Colors.white, size: 14),
                    SizedBox(width: 2),
                    Text('Xóa', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPhotoActions(File file, RoomPhotoCategory category) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.zoom_in),
              title: const Text('Xem ảnh'),
              onTap: () {
                Navigator.pop(ctx);
                _viewPhoto(FileImage(file), file: file, category: category);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Xóa ảnh', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deletePhoto(file, category);
              },
            ),
          ],
        ),
      ),
    );
  }
}
