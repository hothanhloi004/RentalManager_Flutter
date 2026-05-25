import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/tenant_model.dart';
import '../../services/firebase_service.dart';
import 'add_edit_tenant_screen.dart';
import 'tenant_detail_screen.dart';
import '../../utils/string_utils.dart';
import '../../widgets/list_page_header.dart';
import '../../widgets/list_search_field.dart';

class TenantListScreen extends StatefulWidget {
  const TenantListScreen({super.key});

  @override
  State<TenantListScreen> createState() => _TenantListScreenState();
}

class _TenantListScreenState extends State<TenantListScreen> {
  final _service = FirebaseService();
  late final Stream<List<Tenant>> _tenantsStream;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tenantsStream = _service.getTenants();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6366F1);
    const textColor = Color(0xFF111827);
    const mutedText = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
          ListPageHeader(
            title: 'Khách thuê',
            actionLabel: '+ Thêm khách',
            onAction: () => showDialog(context: context, builder: (_) => const AddEditTenantScreen()),
          ),
          ListSearchField(
            hintText: 'Tìm theo tên, SĐT hoặc CCCD...',
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final rowHeight = (constraints.maxHeight / 5.85).clamp(96.0, 108.0);
                return StreamBuilder<List<Tenant>>(
                  stream: _tenantsStream,
                  builder: (ctx, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryColor));
                
                    var list = List<Tenant>.of(snapshot.data ?? []);
                
                    // Sắp xếp khách mới ở trên đầu
                    list.sort((a, b) => b.id.compareTo(a.id));

                    if (_searchQuery.isNotEmpty) {
                      list = list.where((t) => 
                        StringUtils.containsSearch(t.fullName, _searchQuery) ||
                        t.phone.contains(_searchQuery) ||
                        t.cccd.contains(_searchQuery)
                      ).toList();
                    }

                    if (list.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_outline, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            const Text('Chưa có người thuê nào', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(top: 8, bottom: 88),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 58, endIndent: 10, color: Color(0xFFE5E7EB)),
                      itemBuilder: (ctx, i) {
                        final t = list[i];
                        return SizedBox(
                          height: rowHeight,
                          child: InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TenantDetailScreen(tenant: t))),
                            onLongPress: () => _confirmDeleteTenant(t),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 6, 0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(color: Color(0xFFEDEBFF), shape: BoxShape.circle),
                                    child: const Icon(Icons.person_rounded, color: primaryColor, size: 27),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          t.fullName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textColor, height: 1.15),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          t.phone,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: mutedText, fontSize: 13, fontWeight: FontWeight.w500, height: 1.1),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'CCCD: ${t.cccd}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w600, height: 1.1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.phone_in_talk_rounded, color: primaryColor, size: 21),
                                    onPressed: () => launchUrl(Uri.parse('tel:${t.phone}')),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTenant(Tenant tenant) async {
    final hasContract = await _service.tenantHasActiveContract(tenant.id);
    if (!mounted) return;
    if (hasContract) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xóa khách đang có hợp đồng hiệu lực'), backgroundColor: Colors.red),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa khách thuê'),
        content: Text('Bạn có chắc chắn muốn xóa ${tenant.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _service.deleteTenant(tenant.id);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }
}
