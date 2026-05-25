import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/contract_model.dart';
import '../../models/room_model.dart';
import '../../models/tenant_model.dart';
import '../../services/firebase_service.dart';
import 'add_contract_screen.dart';
import '../../utils/string_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/list_page_header.dart';
import '../../widgets/list_search_field.dart';

class ContractListScreen extends StatefulWidget {
  const ContractListScreen({super.key});
  @override
  State<ContractListScreen> createState() => _ContractListScreenState();
}

class _ContractListScreenState extends State<ContractListScreen> {
  final _service = FirebaseService();
  late final Stream<List<Contract>> _contractsStream;
  late final Stream<List<Room>> _roomsStream;
  late final Stream<List<Tenant>> _tenantsStream;
  String _currentFilter = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _contractsStream = _service.getContracts();
    _roomsStream = _service.getRooms();
    _tenantsStream = _service.getTenants();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6366F1);
    const textColor = Color(0xFF111827);
    const mutedText = Color(0xFF64748B);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      body: SafeArea(
        child: Column(
          children: [
            ListPageHeader(
              title: 'H\u1ee3p \u0111\u1ed3ng',
              actionLabel: '+ Th\u00eam h\u1ee3p \u0111\u1ed3ng',
              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddContractScreen())),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  ListSearchField(
                    hintText: 'T\u00ecm theo ph\u00f2ng ho\u1eb7c ng\u01b0\u1eddi thu\u00ea...',
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        _filterChip('T\u1ea5t c\u1ea3', 'ALL'),
                        _filterChip('\u0110ang hi\u1ec7u l\u1ef1c', 'active'),
                        _filterChip('\u0110\u00e3 k\u1ebft th\u00fac', 'ended'),
                        _filterChip('S\u1eafp h\u1ebft h\u1ea1n', 'ending'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: StreamBuilder<List<Contract>>(
                stream: _contractsStream,
                builder: (ctx, contractSnap) {
                  if (!contractSnap.hasData) return const Center(child: CircularProgressIndicator(color: primaryColor));
                  return StreamBuilder<List<Room>>(
                    stream: _roomsStream,
                    builder: (ctx, roomSnap) {
                      return StreamBuilder<List<Tenant>>(
                        stream: _tenantsStream,
                        builder: (ctx, tenantSnap) {
                          var contracts = List<Contract>.of(contractSnap.data ?? []);
                          final rooms = roomSnap.data ?? [];
                          final tenants = tenantSnap.data ?? [];
                          contracts.sort((a, b) => b.id.compareTo(a.id));
                          if (_currentFilter != 'ALL') {
                            if (_currentFilter == 'active') {
                              contracts = contracts.where((c) => c.isActive).toList();
                            } else if (_currentFilter == 'ended') {
                              contracts = contracts.where((c) => c.isEnded).toList();
                            } else if (_currentFilter == 'ending') {
                              final now = DateTime.now().millisecondsSinceEpoch;
                              final soon = DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch;
                              contracts = contracts.where((c) => c.isActive && c.endDate != null && c.endDate! >= now && c.endDate! <= soon).toList();
                            } else {
                              contracts = contracts.where((c) => c.status == _currentFilter).toList();
                            }
                          }
                          if (_searchQuery.isNotEmpty) {
                            contracts = contracts.where((c) {
                              final room = _roomForContract(rooms, c);
                              final tenant = _tenantForContract(tenants, c);
                              return StringUtils.containsSearch(room?.roomName ?? '', _searchQuery) ||
                                  StringUtils.containsSearch(tenant?.fullName ?? '', _searchQuery);
                            }).toList();
                          }
                          if (contracts.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 8),
                                  const Text('Ch\u01b0a c\u00f3 h\u1ee3p \u0111\u1ed3ng n\u00e0o', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                ],
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 88),
                            itemCount: contracts.length,
                            itemBuilder: (ctx, i) {
                              final c = contracts[i];
                              final room = _roomForContract(rooms, c);
                              final tenant = _tenantForContract(tenants, c);
                              final isLive = c.isActive;
                              final startText = c.startDate > 0 ? dateFmt.format(DateTime.fromMillisecondsSinceEpoch(c.startDate)) : '-';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: const Color(0xFF94A3B8).withValues(alpha: 0.14), blurRadius: 10, offset: const Offset(0, 3))],
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(room?.roomName ?? 'Ph\u00f2ng ?', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: textColor, height: 1.1)),
                                          _statusBadge(isLive),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        tenant?.fullName ?? 'Kh\u00e1ch l\u1ebd',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: mutedText, height: 1.15),
                                      ),
                                      const SizedBox(height: 5),
                                      const Text('T\u1eeb:', style: TextStyle(color: mutedText, fontSize: 12, fontWeight: FontWeight.w500, height: 1.1)),
                                      const SizedBox(height: 1),
                                      Text(startText, style: const TextStyle(color: primaryColor, fontSize: 15, fontWeight: FontWeight.w800, height: 1.1)),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          if (c.useWifi) _serviceTag('WiFi', Icons.wifi),
                                          if (c.useTrash) _serviceTag('R\u00e1c', Icons.delete_outline),
                                          if (c.useServiceFee) _serviceTag('Ph\u00ed DV', Icons.cleaning_services_outlined),
                                        ],
                                      ),
                                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                                      Row(
                                        children: [
                                          OutlinedButton(
                                            onPressed: isLive ? () => _showEndContractDialog(c.id) : null,
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                                              foregroundColor: textColor,
                                              disabledForegroundColor: const Color(0xFFCBD5E1),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              minimumSize: const Size(0, 32),
                                              padding: const EdgeInsets.symmetric(horizontal: 22),
                                            ),
                                            child: const Text('K\u1ebft th\u00fac', style: TextStyle(fontSize: 12)),
                                          ),
                                          const SizedBox(width: 12),
                                          TextButton(
                                            onPressed: () {
                                              var w = c.useWifi;
                                              var t = c.useTrash;
                                              var s = c.useServiceFee;
                                              showDialog(
                                                context: context,
                                                builder: (ctx) => StatefulBuilder(
                                                  builder: (ctx, setDlgState) => AlertDialog(
                                                    title: const Text('S\u1eeda d\u1ecbch v\u1ee5'),
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        CheckboxListTile(title: const Text('WiFi'), value: w, onChanged: (v) => setDlgState(() => w = v ?? false)),
                                                        CheckboxListTile(title: const Text('R\u00e1c'), value: t, onChanged: (v) => setDlgState(() => t = v ?? false)),
                                                        CheckboxListTile(title: const Text('Ph\u00ed d\u1ecbch v\u1ee5'), value: s, onChanged: (v) => setDlgState(() => s = v ?? false)),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hu\u1ef7', style: TextStyle(color: Colors.grey))),
                                                      TextButton(
                                                        onPressed: () async {
                                                          try {
                                                            await _service.updateContractServices(c.id, w, t, s);
                                                            if (!ctx.mounted) return;
                                                            Navigator.pop(ctx);
                                                            if (!context.mounted) return;
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(
                                                                content: Text('\u0110\u00e3 l\u01b0u d\u1ecbch v\u1ee5. H\u00f3a \u0111\u01a1n t\u1ea1o sau s\u1ebd d\u00f9ng ph\u00ed m\u1edbi.'),
                                                                backgroundColor: Color(0xFF16A34A),
                                                              ),
                                                            );
                                                          } catch (e) {
                                                            if (!context.mounted) return;
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
                                                            );
                                                          }
                                                        },
                                                        child: const Text('L\u01b0u', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text('S\u1eeda d\u1ecbch v\u1ee5', style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            onPressed: () async {
                                              final phone = tenant?.phone;
                                              if (phone != null && phone.isNotEmpty) {
                                                final uri = Uri.parse('tel:$phone');
                                                if (await canLaunchUrl(uri)) await launchUrl(uri);
                                              }
                                            },
                                            icon: const Icon(Icons.phone_in_talk_rounded, color: primaryColor, size: 24),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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

  Widget _filterChip(String label, String value) {
    final isSelected = _currentFilter == value;
    const primaryColor = Color(0xFF6366F1);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _currentFilter = value),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFFBFF7F4),
        checkmarkColor: primaryColor,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        labelStyle: TextStyle(
          color: isSelected ? primaryColor : const Color(0xFF475569),
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        ),
        shape: StadiumBorder(side: BorderSide(color: isSelected ? const Color(0xFFBFF7F4) : Colors.grey.shade200)),
      ),
    );
  }

  static Room? _roomForContract(List<Room> rooms, Contract contract) {
    return rooms.where((r) => r.id == contract.roomId || r.roomKey == contract.roomId).firstOrNull;
  }

  static Tenant? _tenantForContract(List<Tenant> tenants, Contract contract) {
    return tenants.where((t) => t.id == contract.tenantId || t.tenantKey == contract.tenantId).firstOrNull;
  }

  Future<void> _showEndContractDialog(String contractId) async {
    final status = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kết thúc hợp đồng'),
        content: const Text('Sau khi kết thúc, bạn muốn chuyển phòng sang trạng thái nào?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'BAO_TRI'),
            child: const Text('Bảo trì', style: TextStyle(color: Color(0xFFD97706))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'TRONG'),
            child: const Text('Báo trống', style: TextStyle(color: Color(0xFF16A34A))),
          ),
        ],
      ),
    );
    if (status == null) return;
    try {
      await _service.endContract(contractId, nextRoomStatus: status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã kết thúc hợp đồng')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  Widget _statusBadge(bool isLive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isLive ? 'Hi\u1ec7u l\u1ef1c' : '\u0110\u00e3 k\u1ebft th\u00fac',
        style: TextStyle(color: isLive ? const Color(0xFF16A34A) : const Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 9.5),
      ),
    );
  }

  Widget _serviceTag(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF64748B)),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
      ],
    );
  }
}
