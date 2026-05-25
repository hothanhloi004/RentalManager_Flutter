import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/firebase_service.dart';
import '../services/imgbb_service.dart';

class TenantPhotoGallery extends StatefulWidget {
  final String tenantId;
  final List<String> imageUrls;
  final ValueChanged<List<String>>? onChanged;

  const TenantPhotoGallery({
    super.key,
    required this.tenantId,
    required this.imageUrls,
    this.onChanged,
  });

  @override
  State<TenantPhotoGallery> createState() => _TenantPhotoGalleryState();
}

class _TenantPhotoGalleryState extends State<TenantPhotoGallery> {
  static const _primary = Color(0xFF6366F1);

  final _picker = ImagePicker();
  final _service = FirebaseService();
  late List<String> _imageUrls;
  bool _uploading = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _imageUrls = _cleanUrls(widget.imageUrls);
  }

  @override
  void didUpdateWidget(covariant TenantPhotoGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls != widget.imageUrls) {
      _imageUrls = _cleanUrls(widget.imageUrls);
    }
  }

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: _primary),
              title: const Text('Chụp ảnh mới'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _primary),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final url = await ImgBBService.uploadImage(picked);
      if (url == null || url.trim().isEmpty) {
        throw Exception('Không tải ảnh lên Cloud được');
      }

      final next = [url.trim(), ..._imageUrls.where((item) => item != url.trim())];
      await _saveUrls(next);
      _showMessage('Đã thêm ảnh tài liệu', backgroundColor: const Color(0xFF16A34A));
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _confirmDelete(int index) async {
    if (index < 0 || index >= _imageUrls.length) return;

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
    if (ok != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      final next = List<String>.from(_imageUrls)..removeAt(index);
      await _saveUrls(next);
      _showMessage('Đã xóa ảnh');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _saveUrls(List<String> urls) async {
    final next = _cleanUrls(urls);
    await _service.updateTenantImageUrls(widget.tenantId, next);
    if (!mounted) return;
    setState(() => _imageUrls = next);
    widget.onChanged?.call(List.unmodifiable(next));
  }

  void _viewPhoto(int index) {
    if (index < 0 || index >= _imageUrls.length) return;
    final url = _imageUrls[index];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white, size: 48),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
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
                  _confirmDelete(index);
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Xóa ảnh'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _uploading || _deleting;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tài liệu & CCCD',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _primary),
                ),
              ),
              TextButton(
                onPressed: busy ? null : _addPhoto,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFEDEBFF),
                  foregroundColor: _primary,
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _uploading
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _primary))
                    : const Text('+ Thêm ảnh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_imageUrls.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Text(
                "Chưa có tài liệu. Bấm '+ Thêm ảnh' để chụp.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13, height: 1.35),
              ),
            )
          else ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ảnh tài liệu',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF64748B), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    '${_imageUrls.length} ảnh',
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _imageUrls.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) => _photoTile(index),
            ),
          ],
        ],
      ),
    );
  }

  Widget _photoTile(int index) {
    final url = _imageUrls[index];

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () => _viewPhoto(index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: const Color(0xFFF3F4F6),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _primary)),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFF3F4F6),
                child: const Icon(Icons.broken_image_outlined, color: Color(0xFF94A3B8)),
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
            child: const Text('Tài liệu', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
          ),
        ),
        Positioned(
          right: 3,
          bottom: 3,
          child: Material(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: _deleting ? null : () => _confirmDelete(index),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(Icons.delete_outline, color: Colors.white, size: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<String> _cleanUrls(List<String> urls) {
    return urls.map((url) => url.trim()).where((url) => url.isNotEmpty).toSet().toList();
  }
}
