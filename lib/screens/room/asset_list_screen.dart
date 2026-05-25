import 'package:flutter/material.dart';
import '../../models/room_model.dart';
import '../../models/asset_model.dart';
import '../../services/firebase_service.dart';

class AssetListScreen extends StatefulWidget {
  final Room room;
  const AssetListScreen({super.key, required this.room});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  final _service = FirebaseService();

  void _showAddEditDialog([Asset? asset]) {
    final isNew = asset == null;
    final nameCtrl = TextEditingController(text: isNew ? '' : asset.name);
    final qtyCtrl = TextEditingController(text: isNew ? '1' : asset.quantity.toString());
    final noteCtrl = TextEditingController(text: isNew ? '' : asset.note);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isNew ? 'Thêm mới tài sản' : 'Chỉnh sửa tài sản', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1F2937))),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Tên tài sản',
                  hintText: 'VD: Máy lạnh, Giường...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số lượng',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Số lượng không hợp lệ' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  labelText: 'Ghi chú thêm',
                  hintText: 'Tình trạng, nhãn hiệu...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy bỏ', style: TextStyle(color: Color(0xFF6B7280)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5764F1),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newAsset = Asset(
                  id: isNew ? '' : asset.id,
                  roomId: widget.room.roomKey,
                  name: nameCtrl.text.trim(),
                  quantity: int.parse(qtyCtrl.text.trim()),
                  note: noteCtrl.text.trim(),
                  createdAt: isNew ? DateTime.now().millisecondsSinceEpoch : asset.createdAt,
                );
                try {
                  if (isNew) {
                    await _service.addAsset(newAsset);
                  } else {
                    await _service.updateAsset(newAsset);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Lưu lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF2F6),
      appBar: AppBar(
        title: Text('Tài sản: ${widget.room.roomName}'),
      ),
      body: StreamBuilder<List<Asset>>(
        stream: _service.getAssetsByRoom(widget.room.roomKey),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF5764F1)));
          }
          final assets = snapshot.data ?? [];
          if (assets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Chưa có danh mục tài sản', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: assets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final a = assets[index];
              return Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.chair_outlined, color: Color(0xFF5764F1)),
                  ),
                  title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  subtitle: Text('Số lượng: ${a.quantity}${a.note.isNotEmpty ? ' • ${a.note}' : ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF5764F1)), onPressed: () => _showAddEditDialog(a)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: const Text('Xác nhận xóa?'),
                              content: Text('Bạn có muốn xóa tài sản "${a.name}" không?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      await _service.deleteAsset(a.id);
                                      if (c.mounted) Navigator.pop(c);
                                    } catch (e) {
                                      if (!c.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
                                      );
                                    }
                                  },
                                  child: const Text('Xác nhận xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF5764F1),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
